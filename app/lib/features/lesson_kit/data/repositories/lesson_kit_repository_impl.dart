import 'dart:typed_data';

import '../../domain/entities/lesson_context.dart';
import '../../domain/entities/lesson_generation_progress.dart';
import '../../domain/entities/lesson_kit.dart';
import '../../domain/repositories/lesson_kit_repository.dart';
import '../datasources/lesson_kit_datasource.dart';
import '../models/lesson_context_model.dart';

/// Bridges the domain repository contract to the data-layer datasource.
/// Every method takes/returns domain entities and translates them to/from
/// DTOs at the boundary so the domain layer stays JSON-free.
class LessonKitRepositoryImpl implements LessonKitRepository {
  const LessonKitRepositoryImpl({required this.datasource});

  final LessonKitDatasource datasource;

  @override
  Future<LessonKit> generate({
    required LessonContext context,
    String? passage,
    Uint8List? imageBytes,
    LessonGenerationProgressCallback? onProgress,
  }) async {
    final model = await datasource.generate(
      context: LessonContextModel.fromEntity(context),
      passage: passage,
      imageBytes: imageBytes,
      onProgress: onProgress,
    );
    return model.toEntity();
  }
}
