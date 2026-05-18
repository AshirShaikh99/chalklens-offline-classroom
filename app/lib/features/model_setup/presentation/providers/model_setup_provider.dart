import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/model/gemma_model_installer.dart';

enum ModelSetupActivity { idle, importing, downloading, verifying }

class ModelSetupState {
  const ModelSetupState({
    required this.check,
    this.runtimeReady = false,
    this.activity = ModelSetupActivity.idle,
    this.progress,
    this.notice,
    this.download,
    this.allowMobileData = false,
  });

  final ModelFileCheck check;
  final bool runtimeReady;
  final ModelSetupActivity activity;
  final double? progress;
  final String? notice;
  final ModelDownloadStatus? download;
  final bool allowMobileData;

  bool get isBusy => activity != ModelSetupActivity.idle;
  bool get isReady => check.isReady && runtimeReady;
  bool get canContinue => isReady && !isBusy;

  ModelSetupState copyWith({
    ModelFileCheck? check,
    bool? runtimeReady,
    ModelSetupActivity? activity,
    double? progress,
    bool clearProgress = false,
    String? notice,
    bool clearNotice = false,
    ModelDownloadStatus? download,
    bool clearDownload = false,
    bool? allowMobileData,
  }) {
    return ModelSetupState(
      check: check ?? this.check,
      runtimeReady: runtimeReady ?? this.runtimeReady,
      activity: activity ?? this.activity,
      progress: clearProgress ? null : progress ?? this.progress,
      notice: clearNotice ? null : notice ?? this.notice,
      download: clearDownload ? null : download ?? this.download,
      allowMobileData: allowMobileData ?? this.allowMobileData,
    );
  }
}

final gemmaModelInstallerProvider = Provider<GemmaModelInstaller>(
  (ref) => GemmaModelInstaller(),
);

final modelSetupProvider =
    AsyncNotifierProvider<ModelSetupNotifier, ModelSetupState>(
      ModelSetupNotifier.new,
    );

class ModelSetupNotifier extends AsyncNotifier<ModelSetupState> {
  static const String _allowMobileDataPrefKey =
      'chalklens.modelSetup.allowMobileData';

  /// Hosts the user is allowed to download a model from. Restricts the
  /// runtime URL field to known good origins, so a misuser cannot point the
  /// app at an arbitrary server, breaking the offline-by-default promise.
  static const Set<String> _allowedDownloadHosts = {
    'huggingface.co',
    'storage.googleapis.com',
    'kaggle.com',
    'github.com',
    'objects.githubusercontent.com',
    'github-cloud.s3.amazonaws.com',
    'github-cloud.githubusercontent.com',
  };

  GemmaModelInstaller get _installer => ref.read(gemmaModelInstallerProvider);
  StreamSubscription<ModelDownloadStatus>? _downloadSub;

  ModelSetupState? get _current {
    final current = state;
    return switch (current) {
      AsyncData<ModelSetupState>(:final value) => value,
      _ => null,
    };
  }

  bool get _installRunning {
    final current = _current;
    return current != null && current.isBusy;
  }

  @override
  Future<ModelSetupState> build() async {
    ref.onDispose(() {
      _downloadSub?.cancel();
      _downloadSub = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final allowMobile = prefs.getBool(_allowMobileDataPrefKey) ?? false;

    final check = await _installer.inspect(verifyChecksum: true);
    final initial = await _stateForCheck(check);
    final withPrefs = initial.copyWith(allowMobileData: allowMobile);

    // If a download was already in flight from a previous app session, attach
    // to it now so the UI can pick up exactly where it left off.
    final hasInFlight = await _installer.hasInProgressDownload();
    if (hasInFlight) {
      _subscribeToDownloadStatus();
      return _applyDownloadStatus(withPrefs, _installer.currentDownloadStatus);
    }
    return withPrefs;
  }

  Future<void> refresh() async {
    final current = _current;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          activity: ModelSetupActivity.verifying,
          clearProgress: true,
          clearNotice: true,
        ),
      );
    }

    state = await AsyncValue.guard(() async {
      final check = await _installer.inspect(verifyChecksum: true);
      final next = await _stateForCheck(check);
      final pref = current?.allowMobileData ?? false;
      return next.copyWith(allowMobileData: pref);
    });
  }

  Future<void> importFromFiles() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.any,
        withData: false,
      );
    } on PlatformException catch (e) {
      _setNotice(_friendlyFilePickerError(e));
      return;
    }
    final path = result?.files.single.path;
    if (path == null) return;

    await _runInstall(
      activity: ModelSetupActivity.importing,
      operation: () =>
          _installer.importModelFile(path, onProgress: _setProgress),
    );
  }

  Future<void> startDefaultDownload() async {
    final configured = GemmaModelInstaller.defaultDownloadUrl;
    if (configured.trim().isEmpty) {
      _setNotice(
        'No model URL was configured at build time. Set GEMMA_MODEL_URL '
        'and rebuild, or import '
        '${GemmaModelInstaller.defaultModelDisplayName} from device storage.',
      );
      return;
    }
    return downloadFromUrl(configured);
  }

  Future<void> downloadFromUrl(String rawUrl) async {
    if (_installRunning) {
      _log('ignored downloadFromUrl; install already running');
      return;
    }
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      _setNotice('Enter a direct model download URL first.');
      return;
    }
    if (!uri.isScheme('https')) {
      _setNotice('Model URL must use https:// for safety.');
      return;
    }
    final host = uri.host.toLowerCase();
    if (!_isHostAllowed(host)) {
      _setNotice(
        'Downloads are only allowed from trusted hosts '
        '(${_allowedDownloadHosts.join(', ')}).',
      );
      return;
    }

    final current = _current;
    final allowMobile = current?.allowMobileData ?? false;
    _subscribeToDownloadStatus();
    try {
      await _installer.startBackgroundDownload(uri, requiresWiFi: !allowMobile);
    } catch (e) {
      _log('startBackgroundDownload failed: $e');
      _setNotice(_friendlyError(e));
    }
  }

  Future<void> pauseDownload() => _installer.pauseDownload();
  Future<void> resumeDownload() => _installer.resumeDownload();

  Future<void> cancelDownload() async {
    await _installer.cancelDownload();
    final fallback = await _installer.inspect(verifyChecksum: true);
    final pref = _current?.allowMobileData ?? false;
    final next = await _stateForCheck(fallback);
    state = AsyncValue.data(
      next.copyWith(allowMobileData: pref, clearDownload: true),
    );
  }

  Future<void> setAllowMobileData(bool value) async {
    final current = _current;
    if (current == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_allowMobileDataPrefKey, value);
    state = AsyncValue.data(current.copyWith(allowMobileData: value));
  }

  /// A URL is accepted when its host is on the static allowlist OR matches
  /// the host of the build-time configured URL. The latter lets a release
  /// build supply its own host without listing it in source.
  bool _isHostAllowed(String host) {
    final staticMatch = _allowedDownloadHosts.any(
      (h) => host == h || host.endsWith('.$h'),
    );
    if (staticMatch) return true;

    final configured = Uri.tryParse(GemmaModelInstaller.defaultDownloadUrl);
    if (configured == null || configured.host.isEmpty) return false;
    return configured.host.toLowerCase() == host;
  }

  void _subscribeToDownloadStatus() {
    if (_downloadSub != null) return;
    _downloadSub = _installer.downloadStatus.listen(_onDownloadStatus);
  }

  void _onDownloadStatus(ModelDownloadStatus status) {
    final current = _current;
    if (current == null) return;

    if (status.state == ModelDownloadState.ready) {
      _downloadSub?.cancel();
      _downloadSub = null;
      // Re-run the post-install verification flow so runtime is registered.
      unawaited(_finalizeAfterReady(status));
      return;
    }

    state = AsyncValue.data(_applyDownloadStatus(current, status));
  }

  Future<void> _finalizeAfterReady(ModelDownloadStatus status) async {
    final current = _current;
    if (current == null) return;

    final result =
        status.result ?? await _installer.inspect(verifyChecksum: true);
    final next = await _stateForCheck(
      result,
      successNotice: 'Offline model verified and ready.',
    );
    state = AsyncValue.data(
      next.copyWith(
        allowMobileData: current.allowMobileData,
        clearDownload: true,
        clearProgress: true,
      ),
    );
  }

  ModelSetupState _applyDownloadStatus(
    ModelSetupState current,
    ModelDownloadStatus status,
  ) {
    final activity = switch (status.state) {
      ModelDownloadState.idle => ModelSetupActivity.idle,
      ModelDownloadState.ready => ModelSetupActivity.idle,
      ModelDownloadState.failed => ModelSetupActivity.idle,
      ModelDownloadState.verifying => ModelSetupActivity.verifying,
      _ => ModelSetupActivity.downloading,
    };

    final notice = switch (status.state) {
      ModelDownloadState.failed => status.errorMessage,
      _ => current.notice,
    };

    return current.copyWith(
      activity: activity,
      progress: status.fractionComplete,
      clearProgress: status.fractionComplete == null,
      download: status,
      notice: notice,
      clearNotice:
          status.state == ModelDownloadState.running &&
          (current.notice == null || current.notice == status.errorMessage),
    );
  }

  Future<void> _runInstall({
    required ModelSetupActivity activity,
    required Future<ModelFileCheck> Function() operation,
  }) async {
    if (_installRunning) {
      _log('ignored ${activity.name}; install already running');
      return;
    }
    _log('${activity.name} started');

    final current = _current;
    final allowMobile = current?.allowMobileData ?? false;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(activity: activity, progress: 0, clearNotice: true),
      );
    }

    try {
      final check = await operation();
      _log('${activity.name} finished with status=${check.status.name}');
      if (check.isReady) {
        state = AsyncValue.data(
          ModelSetupState(
            check: check,
            activity: ModelSetupActivity.verifying,
            notice: 'Verifying runtime.',
            allowMobileData: allowMobile,
          ),
        );
      }
      final next = await _stateForCheck(
        check,
        successNotice: 'Offline model verified and ready.',
      );
      state = AsyncValue.data(next.copyWith(allowMobileData: allowMobile));
    } catch (e) {
      final fallback = await _installer.inspect(verifyChecksum: true);
      _log('${activity.name} failed: $e');
      state = AsyncValue.data(
        ModelSetupState(
          check: fallback,
          notice: _friendlyError(e),
          allowMobileData: allowMobile,
        ),
      );
    }
  }

  void _setProgress(double progress) {
    final current = _current;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(progress: progress));
  }

  void _setNotice(String notice) {
    final current = _current;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(notice: notice));
  }

  Future<ModelSetupState> _stateForCheck(
    ModelFileCheck check, {
    String? successNotice,
  }) async {
    if (!check.isReady) {
      return ModelSetupState(check: check, notice: check.message);
    }

    try {
      // Only register the file with the Gemma plugin here. Do not boot an
      // inference engine — the splash path uses different modality flags
      // (audio on / image off) than lesson generation (audio off / image on),
      // and warming the wrong engine first leaves flutter_gemma in a state
      // that fails to switch into image mode on iOS.
      await _installer.ensureInstalled();
      return ModelSetupState(
        check: check,
        runtimeReady: true,
        notice: successNotice,
      );
    } catch (e) {
      return ModelSetupState(check: check, notice: _friendlyError(e));
    }
  }

  String _friendlyError(Object e) {
    if (e is ModelUnavailableException) return e.message;
    final text = e.toString();
    const prefix = 'ModelUnavailableException: ';
    return text.startsWith(prefix) ? text.substring(prefix.length) : text;
  }

  String _friendlyFilePickerError(PlatformException e) {
    if (e.code == 'ENTITLEMENT_NOT_FOUND') {
      return 'macOS needs permission to open a selected model file. Rebuild the app and try Import again.';
    }
    return e.message ?? _friendlyError(e);
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ModelSetup] $message');
    }
  }
}
