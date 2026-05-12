import 'dart:typed_data';

import '../../domain/entities/lesson_generation_progress.dart';
import '../models/lesson_context_model.dart';
import '../models/lesson_kit_model.dart';

/// Data-layer contract for the actual model invocation.
///
/// Throws [ModelOutputException] on parse failure or
/// [ModelUnavailableException] if the model cannot run.
abstract class LessonKitDatasource {
  /// Generate a kit. At least one of [passage] / [imageBytes] must be
  /// non-null. When [imageBytes] is present, the active Gemma model receives
  /// the image directly as multimodal input.
  ///
  /// If [cancelSignal] completes before generation finishes, the underlying
  /// streaming session is cancelled and the call throws [GenerationCancelled].
  Future<LessonKitModel> generate({
    required LessonContextModel context,
    String? passage,
    Uint8List? imageBytes,
    LessonGenerationProgressCallback? onProgress,
    Future<void>? cancelSignal,
  });
}
