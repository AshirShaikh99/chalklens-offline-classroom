import 'dart:typed_data';

import '../../../../core/usecases/usecase.dart';
import '../entities/lesson_context.dart';
import '../entities/lesson_generation_progress.dart';
import '../entities/lesson_kit.dart';
import '../repositories/lesson_kit_repository.dart';

/// Orchestrates a single generation call. Wraps the repository so the
/// presentation layer never imports the data layer directly.
class GenerateLessonKit implements UseCase<LessonKit, GenerateLessonKitParams> {
  const GenerateLessonKit(this.repository);

  final LessonKitRepository repository;

  @override
  Future<LessonKit> call(GenerateLessonKitParams params) {
    return repository.generate(
      context: params.context,
      passage: params.passage,
      imageBytes: params.imageBytes,
      onProgress: params.onProgress,
    );
  }
}

class GenerateLessonKitParams {
  const GenerateLessonKitParams({
    required this.context,
    this.passage,
    this.imageBytes,
    this.onProgress,
  });

  final LessonContext context;
  final String? passage;
  final Uint8List? imageBytes;
  final LessonGenerationProgressCallback? onProgress;
}
