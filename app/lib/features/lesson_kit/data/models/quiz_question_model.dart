import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/quiz_question.dart';

part 'quiz_question_model.freezed.dart';
part 'quiz_question_model.g.dart';

/// Wire-format DTO for [QuizQuestion]. Owns JSON serialization. Maps to
/// and from the domain entity so the domain layer never sees JSON.
@freezed
abstract class QuizQuestionModel with _$QuizQuestionModel {
  const QuizQuestionModel._();

  const factory QuizQuestionModel({
    required String question,
    String? expectedAnswer,
  }) = _QuizQuestionModel;

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionModelFromJson(json);

  factory QuizQuestionModel.fromEntity(QuizQuestion entity) =>
      QuizQuestionModel(
        question: entity.question,
        expectedAnswer: entity.expectedAnswer,
      );

  QuizQuestion toEntity() =>
      QuizQuestion(question: question, expectedAnswer: expectedAnswer);
}
