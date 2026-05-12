import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final ModelFileCheck check;
  final bool runtimeReady;
  final ModelSetupActivity activity;
  final double? progress;
  final String? notice;

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
  }) {
    return ModelSetupState(
      check: check ?? this.check,
      runtimeReady: runtimeReady ?? this.runtimeReady,
      activity: activity ?? this.activity,
      progress: clearProgress ? null : progress ?? this.progress,
      notice: clearNotice ? null : notice ?? this.notice,
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
    final check = await _installer.inspect(verifyChecksum: true);
    return _stateForCheck(check);
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
      return _stateForCheck(check);
    });
  }

  Future<void> importFromFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      type: FileType.any,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    await _runInstall(
      activity: ModelSetupActivity.importing,
      operation: () =>
          _installer.importModelFile(path, onProgress: _setProgress),
    );
  }

  Future<void> downloadFromUrl(String rawUrl) async {
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
    final allowed = _isHostAllowed(host);
    if (!allowed) {
      _setNotice(
        'Downloads are only allowed from trusted hosts '
        '(${_allowedDownloadHosts.join(', ')}).',
      );
      return;
    }

    await _runInstall(
      activity: ModelSetupActivity.downloading,
      operation: () =>
          _installer.downloadModelFile(uri, onProgress: _setProgress),
    );
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
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          activity: activity,
          progress: activity == ModelSetupActivity.downloading ? null : 0,
          clearProgress: activity == ModelSetupActivity.downloading,
          clearNotice: true,
        ),
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
          ),
        );
      }
      state = AsyncValue.data(
        await _stateForCheck(
          check,
          successNotice: 'Offline model verified and ready.',
        ),
      );
    } catch (e) {
      final fallback = await _installer.inspect(verifyChecksum: true);
      _log('${activity.name} failed: $e');
      state = AsyncValue.data(
        ModelSetupState(check: fallback, notice: _friendlyError(e)),
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

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ModelSetup] $message');
    }
  }
}
