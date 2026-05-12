// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_kit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LessonKitModel _$LessonKitModelFromJson(
  Map<String, dynamic> json,
) => _LessonKitModel(
  lessonTitle: json['lesson_title'] as String,
  grade: json['grade'] as String,
  subject: json['subject'] as String,
  language: $enumDecode(_$AppLanguageEnumMap, json['language']),
  sourceConcepts:
      (json['source_concepts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  likelyMisconceptions:
      (json['likely_misconceptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  teacherMoves:
      (json['teacher_moves'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  checksForUnderstanding:
      (json['checks_for_understanding'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  learningObjectives:
      (json['learning_objectives'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  simpleExplanation: json['simple_explanation'] as String,
  blackboardNotes:
      (json['blackboard_notes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  localExample: json['local_example'] as String? ?? '',
  oralQuiz:
      (json['oral_quiz'] as List<dynamic>?)
          ?.map((e) => QuizQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <QuizQuestionModel>[],
  groupActivity: json['group_activity'] as String? ?? '',
  homework:
      (json['homework'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  glossary:
      (json['glossary'] as List<dynamic>?)
          ?.map((e) => GlossaryTermModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <GlossaryTermModel>[],
  easyVersion: json['easy_version'] as String? ?? '',
  confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$LessonKitModelToJson(_LessonKitModel instance) =>
    <String, dynamic>{
      'lesson_title': instance.lessonTitle,
      'grade': instance.grade,
      'subject': instance.subject,
      'language': _$AppLanguageEnumMap[instance.language]!,
      'source_concepts': instance.sourceConcepts,
      'likely_misconceptions': instance.likelyMisconceptions,
      'teacher_moves': instance.teacherMoves,
      'checks_for_understanding': instance.checksForUnderstanding,
      'learning_objectives': instance.learningObjectives,
      'simple_explanation': instance.simpleExplanation,
      'blackboard_notes': instance.blackboardNotes,
      'local_example': instance.localExample,
      'oral_quiz': instance.oralQuiz.map((e) => e.toJson()).toList(),
      'group_activity': instance.groupActivity,
      'homework': instance.homework,
      'glossary': instance.glossary.map((e) => e.toJson()).toList(),
      'easy_version': instance.easyVersion,
      'confidence': instance.confidence,
    };

const _$AppLanguageEnumMap = {AppLanguage.english: 'en'};
