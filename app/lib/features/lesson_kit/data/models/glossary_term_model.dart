import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/glossary_term.dart';

part 'glossary_term_model.freezed.dart';
part 'glossary_term_model.g.dart';

/// Wire-format DTO for [GlossaryTerm].
@freezed
abstract class GlossaryTermModel with _$GlossaryTermModel {
  const GlossaryTermModel._();

  const factory GlossaryTermModel({
    required String term,
    required String meaning,
    String? example,
  }) = _GlossaryTermModel;

  factory GlossaryTermModel.fromJson(Map<String, dynamic> json) =>
      _$GlossaryTermModelFromJson(json);

  factory GlossaryTermModel.fromEntity(GlossaryTerm entity) =>
      GlossaryTermModel(
        term: entity.term,
        meaning: entity.meaning,
        example: entity.example,
      );

  GlossaryTerm toEntity() =>
      GlossaryTerm(term: term, meaning: meaning, example: example);
}
