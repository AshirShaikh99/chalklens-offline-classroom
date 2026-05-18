import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OnDeviceTextRecognition {
  const OnDeviceTextRecognition._();

  static const MethodChannel _channel = MethodChannel(
    'chalk_lens/text_recognition',
  );

  static Future<String?> recognizeImageText(String imagePath) async {
    if (imagePath.trim().isEmpty) return null;

    try {
      final text = await _channel.invokeMethod<String>('recognizeTextFile', {
        'path': imagePath,
      });
      final normalized = text?.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
      return normalized == null || normalized.isEmpty ? null : normalized;
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('[OnDeviceTextRecognition] OCR failed: ${e.message}');
      return null;
    }
  }

  static Future<String?> extractPdfText(String pdfPath) async {
    if (pdfPath.trim().isEmpty) return null;

    try {
      final text = await _channel.invokeMethod<String>('extractPdfTextFile', {
        'path': pdfPath,
      });
      final normalized = text?.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
      return normalized == null || normalized.isEmpty ? null : normalized;
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint(
        '[OnDeviceTextRecognition] PDF text extraction failed: ${e.message}',
      );
      return null;
    }
  }
}
