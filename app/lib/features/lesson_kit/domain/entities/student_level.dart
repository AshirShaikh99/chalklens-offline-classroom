import 'package:json_annotation/json_annotation.dart';

/// How much classroom support the lesson should be tuned for. Drives the
/// "easy version" generation and the difficulty of quiz questions.
enum StudentLevel {
  @JsonValue('easy')
  easy(label: 'Needs extra support'),

  @JsonValue('standard')
  standard(label: 'Standard'),

  @JsonValue('advanced')
  advanced(label: 'Ready for challenge');

  const StudentLevel({required this.label});

  final String label;
}
