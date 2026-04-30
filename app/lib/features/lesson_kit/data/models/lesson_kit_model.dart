import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/languages.dart';
import '../../domain/entities/lesson_kit.dart';
import 'glossary_term_model.dart';
import 'quiz_question_model.dart';

part 'lesson_kit_model.freezed.dart';
part 'lesson_kit_model.g.dart';

/// Wire-format DTO for [LessonKit]. Mirrors the JSON Gemma 4 emits via
/// the LessonKit schema in the system prompt. Maps to the pure domain
/// entity for consumption by the rest of the app.
@freezed
abstract class LessonKitModel with _$LessonKitModel {
  const LessonKitModel._();

  const factory LessonKitModel({
    required String lessonTitle,
    required String grade,
    required String subject,
    required AppLanguage language,
    @Default(<String>[]) List<String> learningObjectives,
    required String simpleExplanation,
    @Default(<String>[]) List<String> blackboardNotes,
    @Default('') String localExample,
    @Default(<QuizQuestionModel>[]) List<QuizQuestionModel> oralQuiz,
    @Default('') String groupActivity,
    @Default(<String>[]) List<String> homework,
    @Default(<GlossaryTermModel>[]) List<GlossaryTermModel> glossary,
    @Default('') String easyVersion,
    @Default(0.0) double confidence,
  }) = _LessonKitModel;

  factory LessonKitModel.fromJson(Map<String, dynamic> json) =>
      _$LessonKitModelFromJson(json);

  factory LessonKitModel.fromEntity(LessonKit entity) => LessonKitModel(
    lessonTitle: entity.lessonTitle,
    grade: entity.grade,
    subject: entity.subject,
    language: entity.language,
    learningObjectives: entity.learningObjectives,
    simpleExplanation: entity.simpleExplanation,
    blackboardNotes: entity.blackboardNotes,
    localExample: entity.localExample,
    oralQuiz: entity.oralQuiz.map(QuizQuestionModel.fromEntity).toList(),
    groupActivity: entity.groupActivity,
    homework: entity.homework,
    glossary: entity.glossary.map(GlossaryTermModel.fromEntity).toList(),
    easyVersion: entity.easyVersion,
    confidence: entity.confidence,
  );

  LessonKit toEntity() => LessonKit(
    lessonTitle: lessonTitle,
    grade: grade,
    subject: subject,
    language: language,
    learningObjectives: learningObjectives,
    simpleExplanation: simpleExplanation,
    blackboardNotes: blackboardNotes,
    localExample: localExample,
    oralQuiz: oralQuiz.map((m) => m.toEntity()).toList(),
    groupActivity: groupActivity,
    homework: homework,
    glossary: glossary.map((m) => m.toEntity()).toList(),
    easyVersion: easyVersion,
    confidence: confidence,
  );
}
