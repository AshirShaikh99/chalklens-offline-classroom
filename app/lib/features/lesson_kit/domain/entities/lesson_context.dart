import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/languages.dart';
import 'student_level.dart';

part 'lesson_context.freezed.dart';

/// Teacher-supplied input for a generation request. Pure domain.
@freezed
abstract class LessonContext with _$LessonContext {
  const factory LessonContext({
    required String grade,
    required String subject,
    required AppLanguage language,
    @Default(35) int classDurationMinutes,
    @Default(StudentLevel.standard) StudentLevel studentLevel,
  }) = _LessonContext;
}
