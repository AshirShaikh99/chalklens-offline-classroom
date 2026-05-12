import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

import '../errors/exceptions.dart';

enum ModelFileStatus { missing, incomplete, checksumMismatch, ready }

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

/// Resolves, validates, and registers the local Gemma 4 LiteRT-LM file.
///
/// The model is intentionally not bundled as a Flutter asset because it is
/// multi-GB. Production installs should import or download the model once,
/// verify it, then run fully offline from the app documents directory.
class GemmaModelInstaller {
  GemmaModelInstaller({
    this.modelFileName = defaultModelFileName,
    this.expectedSizeBytes = defaultModelSizeBytes,
    this.expectedSha256 = defaultModelSha256,
  });

  static const String defaultModelFileName = 'gemma-4-E2B-it.litertlm';
  static const int defaultModelSizeBytes = 2583085056;
  static const String defaultModelSha256 =
      'ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42';

  static const String _definedModelPath = String.fromEnvironment(
    'GEMMA_MODEL_PATH',
  );
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

  // Process-wide queue serialising every Gemma model session. Without this,
  // a concurrent lesson generation and student-help generation can both call
  // FlutterGemma.getActiveModel(), and the first one's `model.close()` in its
  // finally tears down the second one's session mid-stream.
  static Future<void> _gemmaQueue = Future<void>.value();

  final String modelFileName;
  final int expectedSizeBytes;
  final String expectedSha256;
  String? _installedPath;

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
      verifiedDigest = prepared.sha256Digest!;
      await _replaceTargetWithPreparedFile(prepared: tmp, target: target);
      _log('import installed: ${target.path}');
    } finally {
      if (await tmp.exists()) await tmp.delete();
      _verifiedCache.remove(tmp.path);
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
      verifiedDigest = prepared.sha256Digest!;
      await _replaceTargetWithPreparedFile(prepared: tmp, target: target);
      _log('download installed: ${target.path}');
    } finally {
      client.close(force: true);
      if (await tmp.exists()) await tmp.delete();
      _verifiedCache.remove(tmp.path);
    }
    _installedPath = null;
    return _finalizeInstalledFile(target, verifiedDigest);
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

    if (!verifyChecksum) {
      return ModelFileCheck(
        status: ModelFileStatus.ready,
        path: path,
        expectedSizeBytes: expectedSizeBytes,
        expectedSha256: expectedSha256,
        sizeBytes: size,
      );
    }

    // Skip the ~20s SHA-256 if we already verified this exact file content
    // earlier in the process. Cache key includes mtime so any external write
    // invalidates it.
    final modifiedMicros = stat.modified.microsecondsSinceEpoch;
    final cached = _verifiedCache[path];
    if (cached != null &&
        cached.size == size &&
        cached.modifiedMicros == modifiedMicros) {
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
    _verifiedCache[path] = _VerifiedFile(
      size: size,
      modifiedMicros: modifiedMicros,
      sha256: digest,
    );
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
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return File('${temp.path}/$modelFileName.$suffix.$timestamp');
  }

  Future<void> _deleteWorkingFiles(String suffix) async {
    final temp = await getTemporaryDirectory();
    await _deleteWorkingFilesInDirectory(temp, suffix);

    final docs = await getApplicationDocumentsDirectory();
    await _deleteWorkingFilesInDirectory(docs, suffix);
  }

  Future<void> _deleteWorkingFilesInDirectory(
    Directory directory,
    String suffix,
  ) async {
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
      _verifiedCache.remove(target.path);
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
    _verifiedCache[target.path] = _VerifiedFile(
      size: stat.size,
      modifiedMicros: stat.modified.microsecondsSinceEpoch,
      sha256: verifiedDigest,
    );
    return ModelFileCheck(
      status: ModelFileStatus.ready,
      path: target.path,
      expectedSizeBytes: expectedSizeBytes,
      expectedSha256: expectedSha256,
      sizeBytes: stat.size,
      sha256Digest: verifiedDigest,
    );
  }

  /// Hot-path eligibility check. Verifies size *and* SHA-256, using a process
  /// cache keyed by `(path, size, mtime)` so subsequent calls are O(stat).
  /// First call after install pays the ~20s hash cost on a background isolate.
  Future<bool> _isUsableModelFile(File file) async {
    if (!await file.exists()) return false;
    final stat = await file.stat();
    if (stat.size != expectedSizeBytes) return false;

    final fingerprint = stat.modified.microsecondsSinceEpoch;
    final cached = _verifiedCache[file.path];
    if (cached != null &&
        cached.size == stat.size &&
        cached.modifiedMicros == fingerprint) {
      return cached.sha256 == expectedSha256;
    }

    final digest = await sha256OfFile(file);
    _verifiedCache[file.path] = _VerifiedFile(
      size: stat.size,
      modifiedMicros: fingerprint,
      sha256: digest,
    );
    return digest == expectedSha256;
  }

  Future<String> sha256OfFile(File file) async {
    return compute(_hashFileInIsolate, file.path);
  }

  Future<void> ensureInstalled() async {
    if (_installedPath != null) return;
    final path = await resolveModelPath();

    try {
      _log('runtime registration started: $path');
      await FlutterGemma.installModel(
        modelType: ModelType.gemma4,
        fileType: ModelFileType.litertlm,
      ).fromFile(path).install();
      _installedPath = path;
      _log('runtime registration finished');
    } catch (e) {
      _log('runtime registration failed: $e');
      throw ModelUnavailableException(
        'flutter_gemma could not register the Gemma 4 LiteRT-LM model.',
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
