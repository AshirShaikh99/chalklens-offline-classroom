// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_context_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LessonContextModel _$LessonContextModelFromJson(Map<String, dynamic> json) =>
    _LessonContextModel(
      grade: json['grade'] as String,
      subject: json['subject'] as String,
      language: $enumDecode(_$AppLanguageEnumMap, json['language']),
      classDurationMinutes:
          (json['class_duration_minutes'] as num?)?.toInt() ?? 35,
      studentLevel:
          $enumDecodeNullable(_$StudentLevelEnumMap, json['student_level']) ??
          StudentLevel.standard,
    );

Map<String, dynamic> _$LessonContextModelToJson(_LessonContextModel instance) =>
    <String, dynamic>{
      'grade': instance.grade,
      'subject': instance.subject,
      'language': _$AppLanguageEnumMap[instance.language]!,
      'class_duration_minutes': instance.classDurationMinutes,
      'student_level': _$StudentLevelEnumMap[instance.studentLevel]!,
    };

const _$AppLanguageEnumMap = {AppLanguage.english: 'en'};

const _$StudentLevelEnumMap = {
  StudentLevel.easy: 'easy',
  StudentLevel.standard: 'standard',
  StudentLevel.advanced: 'advanced',
};
