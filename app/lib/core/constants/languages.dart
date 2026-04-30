import 'package:json_annotation/json_annotation.dart';

/// Languages ChalkLens can teach in for the current global demo.
///
/// JSON values match BCP-47 language codes so the wire format stays
/// portable; the Dart enum names stay readable.
enum AppLanguage {
  @JsonValue('en')
  english(code: 'en', label: 'English', native: 'English');

  const AppLanguage({
    required this.code,
    required this.label,
    required this.native,
  });

  final String code;
  final String label;
  final String native;

  /// Languages currently exposed in teacher-facing controls.
  static List<AppLanguage> get primaryTeachingLanguages => const [
    AppLanguage.english,
  ];
}
