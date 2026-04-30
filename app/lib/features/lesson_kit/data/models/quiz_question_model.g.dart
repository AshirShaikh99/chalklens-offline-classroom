// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_question_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuizQuestionModel _$QuizQuestionModelFromJson(Map<String, dynamic> json) =>
    _QuizQuestionModel(
      question: json['question'] as String,
      expectedAnswer: json['expected_answer'] as String?,
    );

Map<String, dynamic> _$QuizQuestionModelToJson(_QuizQuestionModel instance) =>
    <String, dynamic>{
      'question': instance.question,
      'expected_answer': instance.expectedAnswer,
    };
