import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../lesson_kit/domain/entities/lesson_context.dart';
import '../../../lesson_kit/domain/entities/lesson_kit.dart';

part 'saved_lesson.freezed.dart';

/// A LessonKit the teacher chose to keep, with its input context.
/// Pure domain — wire format lives in `data/models/saved_lesson_model.dart`.
@freezed
abstract class SavedLesson with _$SavedLesson {
  const factory SavedLesson({
    required String id,
    required LessonKit kit,
    required LessonContext context,
    required DateTime savedAt,
  }) = _SavedLesson;
}
