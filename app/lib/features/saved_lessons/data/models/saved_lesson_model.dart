import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../lesson_kit/data/models/lesson_context_model.dart';
import '../../../lesson_kit/data/models/lesson_kit_model.dart';
import '../../domain/entities/saved_lesson.dart';

part 'saved_lesson_model.freezed.dart';
part 'saved_lesson_model.g.dart';

/// Wire-format DTO for [SavedLesson]. Persists alongside the kit + context
/// DTOs so the entire payload round-trips through one fromJson call.
@freezed
abstract class SavedLessonModel with _$SavedLessonModel {
  const SavedLessonModel._();

  const factory SavedLessonModel({
    required String id,
    required LessonKitModel kit,
    required LessonContextModel context,
    required DateTime savedAt,
    String? sourceImagePath,
  }) = _SavedLessonModel;

  factory SavedLessonModel.fromJson(Map<String, dynamic> json) =>
      _$SavedLessonModelFromJson(json);

  factory SavedLessonModel.fromEntity(SavedLesson entity) => SavedLessonModel(
    id: entity.id,
    kit: LessonKitModel.fromEntity(entity.kit),
    context: LessonContextModel.fromEntity(entity.context),
    savedAt: entity.savedAt,
    sourceImagePath: entity.sourceImagePath,
  );

  SavedLesson toEntity() => SavedLesson(
    id: id,
    kit: kit.toEntity(),
    context: context.toEntity(),
    savedAt: savedAt,
    sourceImagePath: sourceImagePath,
  );
}
