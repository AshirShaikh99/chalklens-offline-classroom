// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'glossary_term_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GlossaryTermModel _$GlossaryTermModelFromJson(Map<String, dynamic> json) =>
    _GlossaryTermModel(
      term: json['term'] as String,
      meaning: json['meaning'] as String,
      example: json['example'] as String?,
    );

Map<String, dynamic> _$GlossaryTermModelToJson(_GlossaryTermModel instance) =>
    <String, dynamic>{
      'term': instance.term,
      'meaning': instance.meaning,
      'example': instance.example,
    };
