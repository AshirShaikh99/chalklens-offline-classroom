import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/languages.dart';
import 'glossary_term.dart';
import 'quiz_question.dart';

part 'lesson_kit.freezed.dart';

/// The classroom kit a teacher consumes. Pure domain — no JSON
/// serialization. Wire format lives in `data/models/lesson_kit_model.dart`.
@freezed
abstract class LessonKit with _$LessonKit {
  const factory LessonKit({
    required String lessonTitle,
    required String grade,
    required String subject,
    required AppLanguage language,
    @Default(<String>[]) List<String> sourceConcepts,
    @Default(<String>[]) List<String> likelyMisconceptions,
    @Default(<String>[]) List<String> teacherMoves,
    @Default(<String>[]) List<String> checksForUnderstanding,
    @Default(<String>[]) List<String> learningObjectives,
    required String simpleExplanation,
    @Default(<String>[]) List<String> blackboardNotes,
    @Default('') String localExample,
    @Default(<QuizQuestion>[]) List<QuizQuestion> oralQuiz,
    @Default('') String groupActivity,
    @Default(<String>[]) List<String> homework,
    @Default(<GlossaryTerm>[]) List<GlossaryTerm> glossary,
    @Default('') String easyVersion,
    @Default(0.0) double confidence,
  }) = _LessonKit;
}
