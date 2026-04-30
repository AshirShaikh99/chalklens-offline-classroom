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

/// Resolves, validates, and registers the local Gemma 4 LiteRT-LM file.
///
/// The model is intentionally not bundled as a Flutter asset because it is
/// multi-GB. Production installs should import or download the model once,
/// verify it, then run fully offline from the app documents directory.
class GemmaModelInstaller {
  GemmaModelInstaller({this.modelFileName = defaultModelFileName});

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
  static const String _localDemoModelPath =
      '/Users/ashirshaikh/Downloads/gemma-4-E2B-it.litertlm';
  static const int _downloadLogStepBytes = 64 * 1024 * 1024;
  static const double _downloadLogStepProgress = 0.05;
  static const int _storageSafetyBufferBytes = 512 * 1024 * 1024;
  static const MethodChannel _storageChannel = MethodChannel(
    'chalk_lens/storage',
  );

  final String modelFileName;
  String? _installedPath;

  Future<String> documentsModelPath() async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$modelFileName';
  }

  Future<ModelFileCheck> inspect({bool verifyChecksum = false}) async {
    try {
      final documentsPath = await documentsModelPath();
      final candidates = <String>[
        if (_definedModelPath.trim().isNotEmpty) _definedModelPath.trim(),
        documentsPath,
        _localDemoModelPath,
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
        expectedSizeBytes: defaultModelSizeBytes,
        expectedSha256: defaultModelSha256,
        message: 'Could not read the model folder. Import the model again.',
      );
    }
  }

  Future<String> resolveModelPath() async {
    final documentsPath = await documentsModelPath();

    final candidates = <String>[
      if (_definedModelPath.trim().isNotEmpty) _definedModelPath.trim(),
      documentsPath,
      _localDemoModelPath,
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
    try {
      await _copyFileWithProgress(source, tmp, onProgress: onProgress);
      await _validatePreparedFile(tmp);
      await _replaceTargetWithPreparedFile(prepared: tmp, target: target);
      _log('import installed: ${target.path}');
    } finally {
      if (await tmp.exists()) await tmp.delete();
    }
    _installedPath = null;
    return inspect(verifyChecksum: true);
  }

  Future<ModelFileCheck> downloadModelFile(
    Uri uri, {
    void Function(double progress)? onProgress,
  }) async {
    if (!uri.isScheme('http') && !uri.isScheme('https')) {
      throw ModelUnavailableException(
        'Model URL must start with http or https.',
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
    try {
      final request = await client.getUrl(uri);
      request.followRedirects = true;
      final response = await request.close();
      try {
        if (response.redirects.isNotEmpty) {
          _log('download redirects: ${response.redirects.length}');
        }
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
          payloadBytes: total > 0 ? total : defaultModelSizeBytes,
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

      await _validatePreparedFile(tmp);
      await _replaceTargetWithPreparedFile(prepared: tmp, target: target);
      _log('download installed: ${target.path}');
    } finally {
      client.close(force: true);
      if (await tmp.exists()) await tmp.delete();
    }
    _installedPath = null;
    return inspect(verifyChecksum: true);
  }

  Future<ModelFileCheck> _checkFile(
    File file, {
    required bool verifyChecksum,
  }) async {
    final path = file.path;
    if (!await file.exists()) {
      return const ModelFileCheck(
        status: ModelFileStatus.missing,
        path: '',
        expectedSizeBytes: defaultModelSizeBytes,
        expectedSha256: defaultModelSha256,
      ).copyWithPath(path);
    }

    final size = await file.length();
    if (modelFileName == defaultModelFileName &&
        size != defaultModelSizeBytes) {
      return ModelFileCheck(
        status: ModelFileStatus.incomplete,
        path: path,
        expectedSizeBytes: defaultModelSizeBytes,
        expectedSha256: defaultModelSha256,
        sizeBytes: size,
        message: 'Model file is incomplete or from another build.',
      );
    }

    if (!verifyChecksum || modelFileName != defaultModelFileName) {
      return ModelFileCheck(
        status: ModelFileStatus.ready,
        path: path,
        expectedSizeBytes: defaultModelSizeBytes,
        expectedSha256: defaultModelSha256,
        sizeBytes: size,
      );
    }

    final digest = await sha256OfFile(file);
    if (digest != defaultModelSha256) {
      return ModelFileCheck(
        status: ModelFileStatus.checksumMismatch,
        path: path,
        expectedSizeBytes: defaultModelSizeBytes,
        expectedSha256: defaultModelSha256,
        sizeBytes: size,
        sha256Digest: digest,
        message: 'Model checksum does not match this build.',
      );
    }

    return ModelFileCheck(
      status: ModelFileStatus.ready,
      path: path,
      expectedSizeBytes: defaultModelSizeBytes,
      expectedSha256: defaultModelSha256,
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
    final check = await _checkFile(target, verifyChecksum: true);
    if (check.status == ModelFileStatus.missing || check.isReady) return;
    try {
      final size = await target.length();
      await target.delete();
      _log(
        'deleted invalid existing model before install: ${target.path} '
        '(${_formatBytes(size)})',
      );
    } on FileSystemException catch (e) {
      _log('could not delete invalid existing model: ${target.path} ($e)');
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
    if (await target.exists()) await target.delete();

    try {
      _log('installing prepared file: ${prepared.path} -> ${target.path}');
      await prepared.rename(target.path);
    } on FileSystemException {
      _log('rename unavailable; copying prepared file into final location');
      await prepared.copy(target.path);
      await prepared.delete();
    }
  }

  Future<void> _validatePreparedFile(File file) async {
    _log('validation started: ${file.path}');
    final check = await _checkFile(file, verifyChecksum: true);
    if (check.isReady) {
      _log(
        'validation passed: size=${_formatBytes(check.sizeBytes ?? 0)}, '
        'sha256=${check.sha256Digest ?? 'not checked'}',
      );
      return;
    }

    final size = check.sizeBytes;
    _log(
      'validation failed: status=${check.status.name}, '
      'size=${_formatBytes(size ?? 0)}, message=${check.message}',
    );
    if (await file.exists()) await file.delete();
    throw ModelUnavailableException(
      check.message ??
          'Model validation failed. Expected $defaultModelSizeBytes bytes; '
              'found ${size ?? 0} bytes.',
    );
  }

  Future<bool> _isUsableModelFile(File file) async {
    if (!await file.exists()) return false;
    if (modelFileName != defaultModelFileName) return true;
    return await file.length() == defaultModelSizeBytes;
  }

  Future<String> sha256OfFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<void> ensureInstalled() async {
    if (_installedPath != null) return;
    final path = await resolveModelPath();

    try {
      _log('runtime registration started: $path');
      await FlutterGemma.installModel(
        modelType: ModelType.gemmaIt,
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

  void _log(String message) {
    debugPrint('[GemmaModelInstaller] $message');
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

extension on ModelFileCheck {
  ModelFileCheck copyWithPath(String path) {
    return ModelFileCheck(
      status: status,
      path: path,
      expectedSizeBytes: expectedSizeBytes,
      expectedSha256: expectedSha256,
      sizeBytes: sizeBytes,
      sha256Digest: sha256Digest,
      message: message,
    );
  }
}
