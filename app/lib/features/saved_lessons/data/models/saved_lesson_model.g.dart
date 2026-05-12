// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_lesson_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SavedLessonModel _$SavedLessonModelFromJson(Map<String, dynamic> json) =>
    _SavedLessonModel(
      id: json['id'] as String,
      kit: LessonKitModel.fromJson(json['kit'] as Map<String, dynamic>),
      context: LessonContextModel.fromJson(
        json['context'] as Map<String, dynamic>,
      ),
      savedAt: DateTime.parse(json['saved_at'] as String),
    );

Map<String, dynamic> _$SavedLessonModelToJson(_SavedLessonModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kit': instance.kit.toJson(),
      'context': instance.context.toJson(),
      'saved_at': instance.savedAt.toIso8601String(),
    };
