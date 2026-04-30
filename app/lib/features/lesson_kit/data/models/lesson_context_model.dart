import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/languages.dart';
import '../../domain/entities/lesson_context.dart';
import '../../domain/entities/student_level.dart';

part 'lesson_context_model.freezed.dart';
part 'lesson_context_model.g.dart';

/// Wire-format DTO for [LessonContext].
@freezed
abstract class LessonContextModel with _$LessonContextModel {
  const LessonContextModel._();

  const factory LessonContextModel({
    required String grade,
    required String subject,
    required AppLanguage language,
    @Default(35) int classDurationMinutes,
    @Default(StudentLevel.standard) StudentLevel studentLevel,
  }) = _LessonContextModel;

  factory LessonContextModel.fromJson(Map<String, dynamic> json) =>
      _$LessonContextModelFromJson(json);

  factory LessonContextModel.fromEntity(LessonContext entity) =>
      LessonContextModel(
        grade: entity.grade,
        subject: entity.subject,
        language: entity.language,
        classDurationMinutes: entity.classDurationMinutes,
        studentLevel: entity.studentLevel,
      );

  LessonContext toEntity() => LessonContext(
    grade: grade,
    subject: subject,
    language: language,
    classDurationMinutes: classDurationMinutes,
    studentLevel: studentLevel,
  );
}
