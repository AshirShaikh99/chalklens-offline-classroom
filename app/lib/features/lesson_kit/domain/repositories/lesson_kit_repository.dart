import 'dart:typed_data';

import '../entities/lesson_context.dart';
import '../entities/lesson_generation_progress.dart';
import '../entities/lesson_kit.dart';

/// Domain-layer contract for generating a classroom kit. The data layer
/// implements this against the on-device Gemma 4 backend.
/// Use cases depend on this interface — never on the impl.
///
/// At least one of [passage] / [imageBytes] must be provided.
abstract class LessonKitRepository {
  Future<LessonKit> generate({
    required LessonContext context,
    String? passage,
    Uint8List? imageBytes,
    LessonGenerationProgressCallback? onProgress,
    Future<void>? cancelSignal,
  });
}
