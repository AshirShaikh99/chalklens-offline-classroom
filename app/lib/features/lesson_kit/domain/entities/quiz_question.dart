import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_question.freezed.dart';

/// A single oral quiz question for the lesson. Pure domain — no JSON
/// concerns. Wire format lives in `data/models/quiz_question_model.dart`.
@freezed
abstract class QuizQuestion with _$QuizQuestion {
  const factory QuizQuestion({
    required String question,
    String? expectedAnswer,
  }) = _QuizQuestion;
}
