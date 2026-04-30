import 'package:freezed_annotation/freezed_annotation.dart';

part 'glossary_term.freezed.dart';

/// One row of the key-terms glossary. Pure domain — no JSON concerns.
/// Wire format lives in `data/models/glossary_term_model.dart`.
@freezed
abstract class GlossaryTerm with _$GlossaryTerm {
  const factory GlossaryTerm({
    required String term,
    required String meaning,
    String? example,
  }) = _GlossaryTerm;
}
