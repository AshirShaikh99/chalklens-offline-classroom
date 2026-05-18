import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:background_downloader/background_downloader.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../errors/exceptions.dart';

enum ModelFileStatus { missing, incomplete, checksumMismatch, ready }

enum ModelDownloadState {
  idle,
  enqueued,
  running,
  paused,
  waitingForWiFi,
  waitingForNetwork,
  retrying,
  verifying,
  ready,
  failed,
}

class ModelDownloadStatus {
  const ModelDownloadStatus({
    required this.state,
    this.bytesReceived = 0,
    this.bytesTotal,
    this.networkSpeedMbps,
    this.eta,
    this.retryAttempt = 0,
    this.errorMessage,
    this.result,
  });

  const ModelDownloadStatus.idle()
    : state = ModelDownloadState.idle,
      bytesReceived = 0,
      bytesTotal = null,
      networkSpeedMbps = null,
      eta = null,
      retryAttempt = 0,
      errorMessage = null,
      result = null;

  final ModelDownloadState state;
  final int bytesReceived;
  final int? bytesTotal;
  final double? networkSpeedMbps;
  final Duration? eta;
  final int retryAttempt;
  final String? errorMessage;
  final ModelFileCheck? result;

  double? get fractionComplete {
    final total = bytesTotal;
    if (total == null || total <= 0) return null;
    return (bytesReceived / total).clamp(0.0, 1.0);
  }

  bool get isActive => switch (state) {
    ModelDownloadState.enqueued ||
    ModelDownloadState.running ||
    ModelDownloadState.paused ||
    ModelDownloadState.waitingForWiFi ||
    ModelDownloadState.waitingForNetwork ||
    ModelDownloadState.retrying ||
    ModelDownloadState.verifying => true,
    _ => false,
  };

  bool get isTerminal =>
      state == ModelDownloadState.ready || state == ModelDownloadState.failed;

  ModelDownloadStatus copyWith({
    ModelDownloadState? state,
    int? bytesReceived,
    int? bytesTotal,
    double? networkSpeedMbps,
    bool clearSpeed = false,
    Duration? eta,
    bool clearEta = false,
    int? retryAttempt,
    String? errorMessage,
    bool clearError = false,
    ModelFileCheck? result,
  }) {
    return ModelDownloadStatus(
      state: state ?? this.state,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      networkSpeedMbps: clearSpeed
          ? null
          : networkSpeedMbps ?? this.networkSpeedMbps,
      eta: clearEta ? null : eta ?? this.eta,
      retryAttempt: retryAttempt ?? this.retryAttempt,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      result: result ?? this.result,
    );
  }
}

class ModelFileCheck {
  const ModelFileCheck({
    required this.status,
    required this.path,
    required this.expectedSizeBytes,
    required this.expectedSha256,
    this.sizeBytes,
    this.sha256Digest,
    this.message,
  });

  final ModelFileStatus status;
  final String path;
  final int expectedSizeBytes;
  final String expectedSha256;
  final int? sizeBytes;
  final String? sha256Digest;
  final String? message;

  bool get isReady => status == ModelFileStatus.ready;

  double? get sizeProgress {
    final size = sizeBytes;
    if (size == null || expectedSizeBytes <= 0) return null;
    return (size / expectedSizeBytes).clamp(0, 1).toDouble();
  }
}

class _VerifiedFile {
  const _VerifiedFile({
    required this.size,
    required this.modifiedMicros,
    required this.sha256,
  });
  final int size;
  final int modifiedMicros;
  final String sha256;
}

class GemmaModelSpec {
  const GemmaModelSpec({
    required this.displayName,
    required this.fileName,
    required this.expectedSizeBytes,
    required this.expectedSha256,
    required this.modelType,
    required this.fileType,
  });

  final String displayName;
  final String fileName;
  final int expectedSizeBytes;
  final String expectedSha256;
  final ModelType modelType;
  final ModelFileType fileType;

  bool get hasExpectedSha256 => expectedSha256.trim().isNotEmpty;
}

/// Resolves, validates, and registers the local LiteRT-LM model file.
///
/// The model is intentionally not bundled as a Flutter asset because it is
/// multi-GB. Production installs should import or download the model once,
/// verify it, then run fully offline from the app documents directory.
class GemmaModelInstaller {
  GemmaModelInstaller({
    GemmaModelSpec? modelSpec,
    String? modelFileName,
    int? expectedSizeBytes,
    String? expectedSha256,
    ModelType? modelType,
    ModelFileType? fileType,
  }) : modelSpec = modelSpec ?? defaultModelSpec,
       modelFileName =
           modelFileName ?? (modelSpec ?? defaultModelSpec).fileName,
       expectedSizeBytes =
           expectedSizeBytes ??
           (modelSpec ?? defaultModelSpec).expectedSizeBytes,
       expectedSha256 =
           expectedSha256 ?? (modelSpec ?? defaultModelSpec).expectedSha256,
       modelType = modelType ?? (modelSpec ?? defaultModelSpec).modelType,
       fileType = fileType ?? (modelSpec ?? defaultModelSpec).fileType;

  static const GemmaModelSpec gemma4E2B = GemmaModelSpec(
    displayName: 'Gemma 4 E2B',
    fileName: 'gemma-4-E2B-it.litertlm',
    expectedSizeBytes: 2583085056,
    expectedSha256:
        'ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42',
    modelType: ModelType.gemma4,
    fileType: ModelFileType.litertlm,
  );

  static GemmaModelSpec get defaultModelSpec => gemma4E2B;

  static String get defaultModelDisplayName => defaultModelSpec.displayName;
  static String get defaultModelFileName => defaultModelSpec.fileName;
  static int get defaultModelSizeBytes => defaultModelSpec.expectedSizeBytes;
  static String get defaultModelSha256 => defaultModelSpec.expectedSha256;

  static const String _definedModelPath = String.fromEnvironment(
    'GEMMA_MODEL_PATH',
  );

  /// Put the model download URL here so the app fetches it on first launch.
  /// Or pass it at build time: --dart-define=GEMMA_MODEL_URL=https://...
  static const String defaultDownloadUrl = String.fromEnvironment(
    'GEMMA_MODEL_URL',
    defaultValue: '',
  );
  static const int _downloadLogStepBytes = 64 * 1024 * 1024;
  static const double _downloadLogStepProgress = 0.05;
  static const int _storageSafetyBufferBytes = 512 * 1024 * 1024;
  static const int _maxRedirects = 5;
  static const MethodChannel _storageChannel = MethodChannel(
    'chalk_lens/storage',
  );

  // Process-wide cache of (path -> verified hash) keyed by stat fingerprint,
  // so the inference hot path skips re-hashing a model that has not changed.
  static final Map<String, _VerifiedFile> _verifiedCache = {};
  static const String _verifiedPrefsPrefix =
      'chalklens.modelInstaller.verified.v1.';

  // Process-wide queue serialising every Gemma model session. Without this,
  // a concurrent lesson generation and student-help generation can both call
  // FlutterGemma.getActiveModel(), and the first one's `model.close()` in its
  // finally tears down the second one's session mid-stream.
  static Future<void> _gemmaQueue = Future<void>.value();

  // Stable id for the background_downloader task so we can find it again
  // after app restarts or screen rotations.
  static const String _bgDownloadTaskId = 'chalklens_gemma_model';

  // Singleton subscription + status state. The downloader plugin is process-
  // global, so we keep the bridge to it process-global as well.
  static StreamController<ModelDownloadStatus>? _downloadStatusController;
  static StreamSubscription<TaskUpdate>? _downloadUpdatesSub;
  static ModelDownloadStatus _lastDownloadStatus =
      const ModelDownloadStatus.idle();
  static bool _downloaderConfigured = false;
  static Future<void>? _runtimeInitialization;

  final GemmaModelSpec modelSpec;
  final String modelFileName;
  final int expectedSizeBytes;
  final String expectedSha256;
  final ModelType modelType;
  final ModelFileType fileType;
  String? _installedPath;

  String get modelDisplayName => modelSpec.displayName;
  bool get hasExpectedSha256 => expectedSha256.trim().isNotEmpty;

  static Future<void> ensurePluginInitialized() {
    final inFlight = _runtimeInitialization;
    if (inFlight != null) return inFlight;

    final initialized = _initializePlugin();
    _runtimeInitialization = initialized;
    return initialized;
  }

  static Future<void> _initializePlugin() async {
    try {
      // flutter_gemma needs a one-time initialization. It can be slow on some
      // devices, so callers invoke it from the async setup path after runApp.
      await FlutterGemma.initialize(maxDownloadRetries: 3);

      // Configure before any background model task is enqueued so the
      // downloader does not create a fallback OS notification.
      await configureBackgroundDownloader();
    } catch (_) {
      _runtimeInitialization = null;
      rethrow;
    }
  }

  Future<String> documentsModelPath() async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$modelFileName';
  }

  /// Serialises access to the global Gemma model session.
  Future<T> withGemmaSession<T>(Future<T> Function() body) {
    final completer = Completer<T>();
    final myTurn = Completer<void>();
    final prior = _gemmaQueue;
    _gemmaQueue = myTurn.future;
    prior.whenComplete(() async {
      try {
        completer.complete(await body());
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        myTurn.complete();
      }
    });
    return completer.future;
  }

  Future<ModelFileCheck> inspect({bool verifyChecksum = false}) async {
    try {
      final documentsPath = await documentsModelPath();
      final candidates = <String>[
        if (_definedModelPath.trim().isNotEmpty) _definedModelPath.trim(),
        documentsPath,
      ];

      for (final path in candidates) {
        final check = await _checkFile(
          File(path),
          verifyChecksum: verifyChecksum,
        );
        if (check.status != ModelFileStatus.missing) return check;
      }

      return _checkFile(File(documentsPath), verifyChecksum: verifyChecksum);
    } catch (e) {
      return ModelFileCheck(
        status: ModelFileStatus.incomplete,
        path: modelFileName,
        expectedSizeBytes: expectedSizeBytes,
        expectedSha256: expectedSha256,
        message: 'Could not read the model folder. Import the model again.',
      );
    }
  }

  Future<String> resolveModelPath() async {
    final documentsPath = await documentsModelPath();

    final candidates = <String>[
      if (_definedModelPath.trim().isNotEmpty) _definedModelPath.trim(),
      documentsPath,
    ];

    for (final path in candidates) {
      if (await _isUsableModelFile(File(path))) return path;
    }

    throw ModelUnavailableException(
      'Gemma model file not found. Expected `$modelFileName` in the app '
      'documents folder, or import/download it from Model Setup.',
    );
  }

  Future<ModelFileCheck> importModelFile(
    String sourcePath, {
    void Function(double progress)? onProgress,
  }) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw ModelUnavailableException('Selected model file does not exist.');
    }

    final targetPath = await documentsModelPath();
    final target = File(targetPath);
    await _removeInvalidExistingTarget(target);
    await _deleteWorkingFiles('importing');
    final tmp = await _workingFile('importing');
    if (await tmp.exists()) await tmp.delete();

    _log('import started: source=$sourcePath');
    _log('import target: ${target.path}');
    _log('import working file: ${tmp.path}');
    String verifiedDigest;
    try {
      await _copyFileWithProgress(source, tmp, onProgress: onProgress);
      final prepared = await _validatePreparedFile(tmp);
      verifiedDigest = prepared.sha256Digest ?? '';
      await _replaceTargetWithPreparedFile(prepared: tmp, target: target);
      _log('import installed: ${target.path}');
    } finally {
      if (await tmp.exists()) await tmp.delete();
      await _forgetVerifiedFile(tmp.path);
    }
    _installedPath = null;
    return _finalizeInstalledFile(target, verifiedDigest);
  }

  Future<ModelFileCheck> downloadModelFile(
    Uri uri, {
    void Function(double progress)? onProgress,
  }) async {
    if (!uri.isScheme('https')) {
      throw ModelUnavailableException(
        'Model URL must use https://. Plain HTTP downloads are blocked '
        'because they can be tampered with on shared networks.',
      );
    }

    final targetPath = await documentsModelPath();
    final target = File(targetPath);
    await _removeInvalidExistingTarget(target);
    await _deleteWorkingFiles('downloading');
    final tmp = await _workingFile('downloading');
    if (await tmp.exists()) await tmp.delete();

    _log('download started: ${_safeUri(uri)}');
    _log('download target: ${target.path}');
    _log('download working file: ${tmp.path}');
    final client = HttpClient();
    String verifiedDigest;
    try {
      final response = await _fetchWithHttpsRedirects(client, uri);
      try {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          _log('download failed: HTTP ${response.statusCode}');
          throw ModelUnavailableException(
            'Model download failed with HTTP ${response.statusCode}.',
          );
        }

        final total = response.contentLength;
        _log(
          'download response: HTTP ${response.statusCode}, '
          'content-length=${total > 0 ? _formatBytes(total) : 'unknown'}',
        );
        await _ensureEnoughStorage(
          payloadBytes: total > 0 ? total : expectedSizeBytes,
        );
        final received = await _writeResponseWithProgress(
          response,
          tmp,
          contentLength: total,
          onProgress: onProgress,
        );
        _log('download stream finished: ${_formatBytes(received)} written');
      } on FileSystemException catch (e) {
        _log('download write failed: ${e.message} path=${tmp.path}');
        throw ModelUnavailableException(
          'Could not save the model download. Keep the app open and unlocked, '
          'then try again.',
          cause: e,
        );
      }

      final prepared = await _validatePreparedFile(tmp);
      verifiedDigest = prepared.sha256Digest ?? '';
      await _replaceTargetWithPreparedFile(prepared: tmp, target: target);
      _log('download installed: ${target.path}');
    } finally {
      client.close(force: true);
      if (await tmp.exists()) await tmp.delete();
      await _forgetVerifiedFile(tmp.path);
    }
    _installedPath = null;
    return _finalizeInstalledFile(target, verifiedDigest);
  }

  /// Configure the OS-level notification shown by background_downloader.
  /// Idempotent — safe to call multiple times (e.g. once per app launch).
  static Future<void> configureBackgroundDownloader() async {
    if (_downloaderConfigured) return;
    _downloaderConfigured = true;
    FileDownloader().configureNotification(
      running: const TaskNotification(
        'Preparing ChalkLens',
        'Downloading offline model • {progress}',
      ),
      complete: const TaskNotification(
        'ChalkLens is ready',
        'Offline lesson kits can now be generated.',
      ),
      error: const TaskNotification(
        'Download interrupted',
        'ChalkLens will retry automatically when the network is back.',
      ),
      paused: const TaskNotification(
        'Download paused',
        'Will resume when conditions are met.',
      ),
      progressBar: true,
    );
  }

  /// Live stream of download state transitions and progress for the offline
  /// model. Subscribing also rehydrates state from any in-flight task left
  /// running by a previous app session.
  Stream<ModelDownloadStatus> get downloadStatus {
    _ensureDownloadBridge();
    return _downloadStatusController!.stream;
  }

  ModelDownloadStatus get currentDownloadStatus => _lastDownloadStatus;

  /// Enqueue (or restart) the background download for the offline model.
  /// Returns immediately — the actual transfer is owned by a foreground
  /// service on Android and survives app backgrounding.
  Future<void> startBackgroundDownload(
    Uri uri, {
    required bool requiresWiFi,
  }) async {
    if (!uri.isScheme('https')) {
      throw const ModelUnavailableException(
        'Model URL must use https:// for safety.',
      );
    }
    _ensureDownloadBridge();
    await configureBackgroundDownloader();

    // Cancel any prior task with the same id so we start clean. The .downloading
    // working file is left intact and the plugin will use HTTP Range to resume
    // when possible, or restart from byte 0 if the host doesn't allow it.
    final existing = await FileDownloader().taskForId(_bgDownloadTaskId);
    if (existing != null) {
      await FileDownloader().cancelTaskWithId(_bgDownloadTaskId);
    }

    await _ensureEnoughStorage(payloadBytes: expectedSizeBytes);

    final task = DownloadTask(
      taskId: _bgDownloadTaskId,
      url: uri.toString(),
      filename: '$modelFileName.downloading',
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      requiresWiFi: requiresWiFi,
      allowPause: true,
      retries: 5,
      displayName: 'ChalkLens AI model',
    );

    _emitDownloadStatus(
      _lastDownloadStatus.copyWith(
        state: ModelDownloadState.enqueued,
        bytesReceived: 0,
        bytesTotal: expectedSizeBytes,
        retryAttempt: 0,
        clearError: true,
        clearSpeed: true,
        clearEta: true,
      ),
    );

    final enqueued = await FileDownloader().enqueue(task);
    if (!enqueued) {
      _emitDownloadStatus(
        _lastDownloadStatus.copyWith(
          state: ModelDownloadState.failed,
          errorMessage:
              'The download could not be queued. Free some storage or '
              'restart ChalkLens, then try again.',
        ),
      );
    }
  }

  Future<bool> pauseDownload() async {
    final task = await FileDownloader().taskForId(_bgDownloadTaskId);
    if (task is! DownloadTask) return false;
    return FileDownloader().pause(task);
  }

  Future<bool> resumeDownload() async {
    final task = await FileDownloader().taskForId(_bgDownloadTaskId);
    if (task is! DownloadTask) return false;
    return FileDownloader().resume(task);
  }

  Future<bool> cancelDownload() async {
    final cancelled = await FileDownloader().cancelTaskWithId(
      _bgDownloadTaskId,
    );
    if (cancelled) {
      _emitDownloadStatus(const ModelDownloadStatus.idle());
    }
    return cancelled;
  }

  /// Tear down the singleton download bridge. Intended for tests; production
  /// keeps the bridge alive for the lifetime of the process.
  static Future<void> disposeDownloadBridge() async {
    await _downloadUpdatesSub?.cancel();
    _downloadUpdatesSub = null;
    await _downloadStatusController?.close();
    _downloadStatusController = null;
    _lastDownloadStatus = const ModelDownloadStatus.idle();
  }

  /// Whether the OS-level scheduler still has a task with our id, regardless
  /// of whether the app was killed and restarted in between.
  Future<bool> hasInProgressDownload() async {
    final task = await FileDownloader().taskForId(_bgDownloadTaskId);
    return task != null;
  }

  void _ensureDownloadBridge() {
    if (_downloadStatusController != null) return;
    _downloadStatusController = StreamController<ModelDownloadStatus>.broadcast(
      onListen: () {
        // Replay the last known status so a late subscriber sees current state.
        _downloadStatusController!.add(_lastDownloadStatus);
      },
    );
    _downloadUpdatesSub = FileDownloader().updates.listen(
      _handleDownloadUpdate,
    );
  }

  void _handleDownloadUpdate(TaskUpdate update) {
    if (update.task.taskId != _bgDownloadTaskId) return;
    if (update is TaskStatusUpdate) {
      _handleDownloadStatusUpdate(update);
    } else if (update is TaskProgressUpdate) {
      _handleDownloadProgressUpdate(update);
    }
  }

  void _handleDownloadStatusUpdate(TaskStatusUpdate update) {
    switch (update.status) {
      case TaskStatus.enqueued:
        _emitDownloadStatus(
          _lastDownloadStatus.copyWith(state: ModelDownloadState.enqueued),
        );
      case TaskStatus.running:
        _emitDownloadStatus(
          _lastDownloadStatus.copyWith(
            state: ModelDownloadState.running,
            clearError: true,
          ),
        );
      case TaskStatus.paused:
        _emitDownloadStatus(
          _lastDownloadStatus.copyWith(state: ModelDownloadState.paused),
        );
      case TaskStatus.waitingToRetry:
        _emitDownloadStatus(
          _lastDownloadStatus.copyWith(
            state: ModelDownloadState.retrying,
            retryAttempt: _lastDownloadStatus.retryAttempt + 1,
          ),
        );
      case TaskStatus.complete:
        _finalizeBackgroundDownload();
      case TaskStatus.canceled:
        _emitDownloadStatus(const ModelDownloadStatus.idle());
      case TaskStatus.notFound:
        _emitDownloadStatus(
          _lastDownloadStatus.copyWith(
            state: ModelDownloadState.failed,
            errorMessage:
                'The offline model file is not available at the configured '
                'address. Try again from Model Setup.',
          ),
        );
      case TaskStatus.failed:
        _emitDownloadStatus(
          _lastDownloadStatus.copyWith(
            state: ModelDownloadState.failed,
            errorMessage: _friendlyDownloadError(update.exception),
          ),
        );
    }
  }

  void _handleDownloadProgressUpdate(TaskProgressUpdate update) {
    // Plugin uses sentinel progress values to signal non-running states.
    // Treat those as no-ops here — status updates carry the real transition.
    final progress = update.progress;
    if (progress < 0 || progress > 1) return;

    final total = update.hasExpectedFileSize
        ? update.expectedFileSize
        : (_lastDownloadStatus.bytesTotal ?? expectedSizeBytes);
    final received = (progress * total).round();

    _emitDownloadStatus(
      _lastDownloadStatus.copyWith(
        state: ModelDownloadState.running,
        bytesReceived: received,
        bytesTotal: total,
        networkSpeedMbps: update.hasNetworkSpeed ? update.networkSpeed : null,
        clearSpeed: !update.hasNetworkSpeed,
        eta: update.hasTimeRemaining ? update.timeRemaining : null,
        clearEta: !update.hasTimeRemaining,
        clearError: true,
      ),
    );
  }

  Future<void> _finalizeBackgroundDownload() async {
    _emitDownloadStatus(
      _lastDownloadStatus.copyWith(
        state: ModelDownloadState.verifying,
        clearSpeed: true,
        clearEta: true,
      ),
    );

    final docs = await getApplicationDocumentsDirectory();
    final tmp = File('${docs.path}/$modelFileName.downloading');
    final target = File(await documentsModelPath());

    String verifiedDigest;
    try {
      final prepared = await _validatePreparedFile(tmp);
      verifiedDigest = prepared.sha256Digest ?? '';
      await _replaceTargetWithPreparedFile(prepared: tmp, target: target);
      _installedPath = null;
    } catch (e) {
      _log('background download verification failed: $e');
      // Drop the bad tmp so the next retry starts cleanly.
      if (await tmp.exists()) {
        try {
          await tmp.delete();
        } catch (_) {}
      }
      _emitDownloadStatus(
        _lastDownloadStatus.copyWith(
          state: ModelDownloadState.failed,
          errorMessage: _friendlyVerificationError(e),
        ),
      );
      return;
    }

    try {
      final check = await _finalizeInstalledFile(target, verifiedDigest);
      _emitDownloadStatus(
        _lastDownloadStatus.copyWith(
          state: ModelDownloadState.ready,
          bytesReceived: check.expectedSizeBytes,
          bytesTotal: check.expectedSizeBytes,
          result: check,
          clearSpeed: true,
          clearEta: true,
          clearError: true,
        ),
      );
    } catch (e) {
      _emitDownloadStatus(
        _lastDownloadStatus.copyWith(
          state: ModelDownloadState.failed,
          errorMessage: _friendlyVerificationError(e),
        ),
      );
    }
  }

  void _emitDownloadStatus(ModelDownloadStatus status) {
    _lastDownloadStatus = status;
    _downloadStatusController?.add(status);
  }

  String _friendlyDownloadError(TaskException? e) {
    if (e == null) {
      return 'The download stopped before it finished. Tap retry to '
          'continue from where it left off.';
    }
    final desc = e.description;
    if (desc.toLowerCase().contains('disk') ||
        desc.toLowerCase().contains('space')) {
      return 'Not enough storage on the device to finish the download. '
          'Free up about 3 GB and try again.';
    }
    return 'Download interrupted: $desc';
  }

  String _friendlyVerificationError(Object error) {
    final text = error.toString();
    if (text.contains('checksum') || text.contains('sha256')) {
      return 'The downloaded file looks corrupted. Tap retry to fetch a '
          'fresh copy.';
    }
    return 'The download finished but could not be verified. Tap retry to '
        'fetch a fresh copy.';
  }

  Future<HttpClientResponse> _fetchWithHttpsRedirects(
    HttpClient client,
    Uri uri,
  ) async {
    var current = uri;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      if (!current.isScheme('https')) {
        throw ModelUnavailableException(
          'Model download cannot follow redirect to ${current.scheme}://. '
          'HTTPS is required end-to-end.',
        );
      }
      final request = await client.getUrl(current);
      request.followRedirects = false;
      final response = await request.close();
      if (!response.isRedirect) return response;

      await response.drain<void>();
      final location = response.headers.value(HttpHeaders.locationHeader);
      if (location == null) {
        throw ModelUnavailableException(
          'Server returned a redirect without a Location header.',
        );
      }
      final next = Uri.parse(location);
      current = next.hasAuthority ? next : current.resolveUri(next);
      _log('download redirect hop $hop -> ${_safeUri(current)}');
    }
    throw ModelUnavailableException(
      'Model download exceeded $_maxRedirects redirects.',
    );
  }

  Future<ModelFileCheck> _checkFile(
    File file, {
    required bool verifyChecksum,
  }) async {
    final path = file.path;
    final stat = await file.stat();
    if (stat.type == FileSystemEntityType.notFound) {
      return ModelFileCheck(
        status: ModelFileStatus.missing,
        path: path,
        expectedSizeBytes: expectedSizeBytes,
        expectedSha256: expectedSha256,
      );
    }

    final size = stat.size;
    if (size != expectedSizeBytes) {
      return ModelFileCheck(
        status: ModelFileStatus.incomplete,
        path: path,
        expectedSizeBytes: expectedSizeBytes,
        expectedSha256: expectedSha256,
        sizeBytes: size,
        message: 'Model file is incomplete or from another build.',
      );
    }

    if (!verifyChecksum || !hasExpectedSha256) {
      return ModelFileCheck(
        status: ModelFileStatus.ready,
        path: path,
        expectedSizeBytes: expectedSizeBytes,
        expectedSha256: expectedSha256,
        sizeBytes: size,
      );
    }

    // Skip the ~20s SHA-256 if we already verified this exact file content.
    // The fingerprint is persisted so a normal app reopen is O(stat), not a
    // full re-hash of the multi-GB model.
    final cached = await _cachedVerifiedFile(path, stat);
    if (cached != null) {
      return ModelFileCheck(
        status: cached.sha256 == expectedSha256
            ? ModelFileStatus.ready
            : ModelFileStatus.checksumMismatch,
        path: path,
        expectedSizeBytes: expectedSizeBytes,
        expectedSha256: expectedSha256,
        sizeBytes: size,
        sha256Digest: cached.sha256,
        message: cached.sha256 == expectedSha256
            ? null
            : 'Model checksum does not match this build.',
      );
    }

    final digest = await sha256OfFile(file);
    await _rememberVerifiedFile(path, stat, digest);
    if (digest != expectedSha256) {
      return ModelFileCheck(
        status: ModelFileStatus.checksumMismatch,
        path: path,
        expectedSizeBytes: expectedSizeBytes,
        expectedSha256: expectedSha256,
        sizeBytes: size,
        sha256Digest: digest,
        message: 'Model checksum does not match this build.',
      );
    }

    return ModelFileCheck(
      status: ModelFileStatus.ready,
      path: path,
      expectedSizeBytes: expectedSizeBytes,
      expectedSha256: expectedSha256,
      sizeBytes: size,
      sha256Digest: digest,
    );
  }

  Future<void> _copyFileWithProgress(
    File source,
    File target, {
    void Function(double progress)? onProgress,
  }) async {
    final total = await source.length();
    var copied = 0;
    final sink = target.openWrite();
    try {
      await for (final chunk in source.openRead()) {
        sink.add(chunk);
        copied += chunk.length;
        if (total > 0) {
          onProgress?.call((copied / total).clamp(0, 1).toDouble());
        }
      }
    } finally {
      await sink.close();
    }
  }

  Future<File> _workingFile(String suffix) async {
    final temp = await getTemporaryDirectory();
    await _ensureDirectoryExists(temp);
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return File('${temp.path}/$modelFileName.$suffix.$timestamp');
  }

  Future<void> _deleteWorkingFiles(String suffix) async {
    final temp = await getTemporaryDirectory();
    await _deleteWorkingFilesInDirectory(temp, suffix);

    final docs = await getApplicationDocumentsDirectory();
    await _deleteWorkingFilesInDirectory(docs, suffix);
  }

  Future<void> _ensureDirectoryExists(Directory directory) async {
    if (await directory.exists()) return;
    await directory.create(recursive: true);
  }

  Future<void> _deleteWorkingFilesInDirectory(
    Directory directory,
    String suffix,
  ) async {
    if (!await directory.exists()) return;

    final exactName = '$modelFileName.$suffix';
    final prefix = '$exactName.';
    await for (final entity in directory.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name != exactName && !name.startsWith(prefix)) continue;
      try {
        final size = await entity.length();
        await entity.delete();
        _log(
          'deleted stale working file: ${entity.path} '
          '(${_formatBytes(size)})',
        );
      } on FileSystemException catch (e) {
        _log('could not delete stale working file: ${entity.path} ($e)');
      }
    }
  }

  Future<void> _removeInvalidExistingTarget(File target) async {
    // Size-only preflight: avoid re-hashing the full 2.6 GB file just to
    // decide whether it's worth keeping. _replaceTargetWithPreparedFile will
    // back up any surviving target as `.bak` before swapping. We only delete
    // here when the file is clearly partial (wrong size) so the disk-space
    // preflight has accurate room to work with.
    final stat = await target.stat();
    if (stat.type == FileSystemEntityType.notFound) return;
    if (stat.size == expectedSizeBytes) return;
    try {
      await target.delete();
      await _forgetVerifiedFile(target.path);
      _log(
        'deleted partial existing model before install: ${target.path} '
        '(${_formatBytes(stat.size)})',
      );
    } on FileSystemException catch (e) {
      _log('could not delete partial existing model: ${target.path} ($e)');
    }
  }

  Future<int> _writeResponseWithProgress(
    HttpClientResponse response,
    File target, {
    required int contentLength,
    void Function(double progress)? onProgress,
  }) async {
    var received = 0;
    var nextByteLog = _downloadLogStepBytes;
    var nextProgressLog = 0.0;
    final file = await target.open(mode: FileMode.write);
    try {
      await for (final chunk in response) {
        await file.writeFrom(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          final progress = (received / contentLength).clamp(0, 1).toDouble();
          onProgress?.call(progress);
          if (progress >= nextProgressLog || received >= contentLength) {
            _log(
              'download progress: '
              '${(progress * 100).toStringAsFixed(1)}% '
              '(${_formatBytes(received)} / ${_formatBytes(contentLength)})',
            );
            while (nextProgressLog <= progress) {
              nextProgressLog += _downloadLogStepProgress;
            }
          }
        } else if (received >= nextByteLog) {
          _log('download progress: ${_formatBytes(received)} received');
          while (nextByteLog <= received) {
            nextByteLog += _downloadLogStepBytes;
          }
        }
      }
      await file.flush();
    } finally {
      await file.close();
    }
    return received;
  }

  Future<void> _ensureEnoughStorage({required int payloadBytes}) async {
    final available = await _availableStorageBytes();
    if (available == null) {
      _log('storage preflight skipped: native available space unavailable');
      return;
    }

    final required = payloadBytes + _storageSafetyBufferBytes;
    _log(
      'storage preflight: available=${_formatBytes(available)}, '
      'required=${_formatBytes(required)}',
    );
    if (available >= required) return;

    final missing = required - available;
    throw ModelUnavailableException(
      'Not enough device storage for the offline model. Free at least '
      '${_formatBytes(missing)} and try again.',
    );
  }

  Future<int?> _availableStorageBytes() async {
    try {
      return await _storageChannel.invokeMethod<int>('availableStorageBytes');
    } on MissingPluginException catch (e) {
      _log('storage channel missing: $e');
      return null;
    } on PlatformException catch (e) {
      _log('storage channel failed: ${e.message}');
      return null;
    }
  }

  Future<void> _replaceTargetWithPreparedFile({
    required File prepared,
    required File target,
  }) async {
    await target.parent.create(recursive: true);

    File? backup;
    if (await target.exists()) {
      final backupPath = '${target.path}.bak';
      final existingBackup = File(backupPath);
      if (await existingBackup.exists()) await existingBackup.delete();
      backup = await target.rename(backupPath);
      _log('moved existing target to backup: ${backup.path}');
    }

    try {
      _log('installing prepared file: ${prepared.path} -> ${target.path}');
      try {
        await prepared.rename(target.path);
      } on FileSystemException {
        _log('rename unavailable; copying prepared file into final location');
        await prepared.copy(target.path);
        await prepared.delete();
      }
      if (backup != null && await backup.exists()) {
        await backup.delete();
      }
    } catch (e) {
      _log('install failed; attempting to restore previous target: $e');
      if (backup != null && await backup.exists()) {
        try {
          await backup.rename(target.path);
          _log('restored previous target from backup');
        } on FileSystemException catch (restoreErr) {
          _log('could not restore backup: $restoreErr');
        }
      }
      rethrow;
    }
  }

  Future<ModelFileCheck> _validatePreparedFile(File file) async {
    _log('validation started: ${file.path}');
    final check = await _checkFile(file, verifyChecksum: true);
    if (check.isReady) {
      _log(
        'validation passed: size=${_formatBytes(check.sizeBytes ?? 0)}, '
        'sha256=${check.sha256Digest ?? 'not checked'}',
      );
      return check;
    }

    final size = check.sizeBytes;
    _log(
      'validation failed: status=${check.status.name}, '
      'size=${_formatBytes(size ?? 0)}, message=${check.message}',
    );
    if (await file.exists()) await file.delete();
    throw ModelUnavailableException(
      check.message ??
          'Model validation failed. Expected $expectedSizeBytes bytes; '
              'found ${size ?? 0} bytes.',
    );
  }

  /// After rename, the file's bytes are unchanged — but the cache key uses the
  /// path, so seed the entry under the target path so the next call (e.g. the
  /// runtime registration) hits cache instead of re-hashing 2.6 GB.
  Future<ModelFileCheck> _finalizeInstalledFile(
    File target,
    String verifiedDigest,
  ) async {
    final stat = await target.stat();
    if (verifiedDigest.isNotEmpty) {
      await _rememberVerifiedFile(target.path, stat, verifiedDigest);
    }
    return ModelFileCheck(
      status: ModelFileStatus.ready,
      path: target.path,
      expectedSizeBytes: expectedSizeBytes,
      expectedSha256: expectedSha256,
      sizeBytes: stat.size,
      sha256Digest: verifiedDigest,
    );
  }

  Future<_VerifiedFile?> _cachedVerifiedFile(String path, FileStat stat) async {
    final cached = _verifiedCache[path];
    if (_matchesVerifiedFile(cached, stat)) return cached;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_verifiedCacheKey(path));
      if (raw == null) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final entry = _VerifiedFile(
        size: _jsonInt(json['size']),
        modifiedMicros: _jsonInt(json['modifiedMicros']),
        sha256: json['sha256'] as String? ?? '',
      );
      if (!_matchesVerifiedFile(entry, stat)) {
        await prefs.remove(_verifiedCacheKey(path));
        return null;
      }

      _verifiedCache[path] = entry;
      return entry;
    } catch (e) {
      _log('verification cache read skipped: $e');
      return null;
    }
  }

  Future<void> _rememberVerifiedFile(
    String path,
    FileStat stat,
    String digest,
  ) async {
    final entry = _VerifiedFile(
      size: stat.size,
      modifiedMicros: stat.modified.microsecondsSinceEpoch,
      sha256: digest,
    );
    _verifiedCache[path] = entry;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _verifiedCacheKey(path),
        jsonEncode({
          'size': entry.size,
          'modifiedMicros': entry.modifiedMicros,
          'sha256': entry.sha256,
        }),
      );
    } catch (e) {
      _log('verification cache write skipped: $e');
    }
  }

  Future<void> _forgetVerifiedFile(String path) async {
    _verifiedCache.remove(path);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_verifiedCacheKey(path));
    } catch (e) {
      _log('verification cache remove skipped: $e');
    }
  }

  bool _matchesVerifiedFile(_VerifiedFile? entry, FileStat stat) {
    if (entry == null) return false;
    return entry.size == stat.size &&
        entry.modifiedMicros == stat.modified.microsecondsSinceEpoch &&
        entry.sha256.isNotEmpty;
  }

  String _verifiedCacheKey(String path) {
    final pathHash = sha1.convert(utf8.encode(path)).toString();
    return '$_verifiedPrefsPrefix$pathHash';
  }

  int _jsonInt(Object? value) {
    return switch (value) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? -1,
      _ => -1,
    };
  }

  /// Hot-path eligibility check. Verifies size and, when the spec provides a
  /// SHA-256, verifies content with a cache keyed by `(path, size, mtime)`.
  /// A never-verified sideload pays the hash cost once.
  Future<bool> _isUsableModelFile(File file) async {
    if (!await file.exists()) return false;
    final stat = await file.stat();
    if (stat.size != expectedSizeBytes) return false;
    if (!hasExpectedSha256) return true;

    final cached = await _cachedVerifiedFile(file.path, stat);
    if (cached != null) {
      return cached.sha256 == expectedSha256;
    }

    final digest = await sha256OfFile(file);
    await _rememberVerifiedFile(file.path, stat, digest);
    return digest == expectedSha256;
  }

  Future<String> sha256OfFile(File file) async {
    final path = file.path;
    return Isolate.run(() => _hashFileInIsolate(path));
  }

  Future<void> ensureInstalled() async {
    if (_installedPath != null) return;
    await ensurePluginInitialized();
    final path = await resolveModelPath();

    try {
      _log('runtime registration started: $path');
      await FlutterGemma.installModel(
        modelType: modelType,
        fileType: fileType,
      ).fromFile(path).install();
      _installedPath = path;
      _log('runtime registration finished');
    } catch (e) {
      _log('runtime registration failed: $e');
      throw ModelUnavailableException(
        'flutter_gemma could not register the $modelDisplayName LiteRT-LM '
        'model.',
        cause: e,
      );
    }
  }

  Future<void> ensureRuntimeStarts({bool supportImage = false}) async {
    await ensureInstalled();

    InferenceModel? model;
    try {
      _log('runtime engine check started');
      model = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend: PreferredBackend.cpu,
        supportImage: supportImage,
        supportAudio: false,
        maxNumImages: supportImage ? 1 : null,
      );
      _log('runtime engine check finished');
    } catch (e) {
      _installedPath = null;
      _log('runtime engine check failed: $e');
      throw _runtimeEngineException(e);
    } finally {
      try {
        await model?.close();
      } catch (closeErr) {
        _log('runtime engine close failed: $closeErr');
      }
    }
  }

  ModelUnavailableException _runtimeEngineException(Object e) {
    final text = e.toString().toLowerCase();
    final isEngineFailure =
        text.contains('failed to create engine') ||
        text.contains('model may be invalid') ||
        text.contains('failed to initialize model') ||
        text.contains('litert');
    if (!isEngineFailure) {
      return ModelUnavailableException(
        'The offline model file could not be opened by Gemma.',
        cause: e,
      );
    }
    return ModelUnavailableException(
      'The model file is present, but Gemma could not start it on this '
      'device. Re-import or download the exact '
      '$modelFileName file again.',
      cause: e,
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[GemmaModelInstaller] $message');
    }
  }

  String _safeUri(Uri uri) {
    final port = uri.hasPort ? ':${uri.port}' : '';
    final query = uri.hasQuery ? '?<redacted>' : '';
    return '${uri.scheme}://${uri.host}$port${uri.path}$query';
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final decimals = unit == 0 ? 0 : 2;
    return '${value.toStringAsFixed(decimals)} ${units[unit]}';
  }
}

Future<String> _hashFileInIsolate(String path) async {
  final file = File(path);
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString();
}
