import '../../../../core/constants/languages.dart';
import '../entities/lesson_context.dart';

class LessonContextInference {
  const LessonContextInference._();

  static LessonContext fromSource({
    String? sourceText,
    int classDurationMinutes = 50,
  }) {
    final text = sourceText?.trim() ?? '';
    return LessonContext(
      grade: _inferGrade(text) ?? 'Class from source',
      subject: _inferSubject(text) ?? 'Subject from source',
      language: AppLanguage.english,
      classDurationMinutes: classDurationMinutes,
    );
  }

  static String? _inferGrade(String text) {
    if (text.isEmpty) return null;

    final numeric = RegExp(
      r'\b(class|grade|standard|std\.?|year)\s*[-:]?\s*(\d{1,2})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (numeric != null) {
      final label = numeric.group(1)!.toLowerCase();
      final value = numeric.group(2)!;
      return label.startsWith('grade') || label.startsWith('year')
          ? 'Grade $value'
          : 'Class $value';
    }

    final roman = RegExp(
      r'\b(class|grade|standard|std\.?|year)\s*[-:]?\s*([ivx]{1,5})\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (roman != null) {
      final value = _romanToInt(roman.group(2)!);
      if (value != null) {
        final label = roman.group(1)!.toLowerCase();
        return label.startsWith('grade') || label.startsWith('year')
            ? 'Grade $value'
            : 'Class $value';
      }
    }

    return null;
  }

  static int? _romanToInt(String raw) {
    const values = {'i': 1, 'v': 5, 'x': 10};
    final text = raw.toLowerCase();
    var total = 0;
    var previous = 0;
    for (var i = text.length - 1; i >= 0; i--) {
      final value = values[text[i]];
      if (value == null) return null;
      if (value < previous) {
        total -= value;
      } else {
        total += value;
        previous = value;
      }
    }
    return total >= 1 && total <= 12 ? total : null;
  }

  static String? _inferSubject(String text) {
    if (text.isEmpty) return null;
    final explicit = RegExp(
      r'\bsubject\s*:\s*([A-Za-z ]{3,40})',
      caseSensitive: false,
    ).firstMatch(text);
    if (explicit != null) {
      final subject = _knownSubjectLabel(explicit.group(1)!);
      if (subject != null) return subject;
    }

    final lower = text.toLowerCase();
    final firstLine = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => text)
        .toLowerCase();

    for (final subject in _subjects) {
      if (RegExp(
        '\\b${RegExp.escape(subject.toLowerCase())}\\b',
      ).hasMatch(firstLine)) {
        return subject;
      }
    }

    final scores = <String, int>{
      'Science': _keywordScore(lower, const [
        'matter',
        'mass',
        'volume',
        'solid',
        'liquid',
        'gas',
        'cell',
        'photosynthesis',
        'force',
        'energy',
        'evaporation',
        'condensation',
        'organism',
        'experiment',
      ]),
      'Math': _keywordScore(lower, const [
        'number',
        'fraction',
        'decimal',
        'percentage',
        'equation',
        'angle',
        'triangle',
        'multiply',
        'divide',
        'calculate',
        'graph',
        'area',
        'perimeter',
      ]),
      'English': _keywordScore(lower, const [
        'phonics',
        'sound',
        'vowel',
        'consonant',
        'word bank',
        'sentence',
        'grammar',
        'noun',
        'verb',
        'adjective',
        'reading practice',
        'short a',
        'rhym',
      ]),
      'Social Studies': _keywordScore(lower, const [
        'community',
        'citizen',
        'government',
        'map',
        'history',
        'culture',
        'province',
        'country',
        'resources',
        'environment',
      ]),
    };

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ranked.first.value > 0 ? ranked.first.key : null;
  }

  static String? _knownSubjectLabel(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    for (final subject in _subjects) {
      if (cleaned.contains(subject.toLowerCase())) return subject;
    }
    if (cleaned.contains('math')) return 'Math';
    if (cleaned.contains('english') || cleaned.contains('language')) {
      return 'English';
    }
    if (cleaned.contains('social')) return 'Social Studies';
    if (cleaned.contains('science')) return 'Science';
    return null;
  }

  static int _keywordScore(String lowerText, List<String> keywords) {
    var score = 0;
    for (final keyword in keywords) {
      if (lowerText.contains(keyword)) score++;
    }
    return score;
  }

  static const _subjects = [
    'Science',
    'Math',
    'English',
    'Social Studies',
    'Environmental Studies',
    'General Knowledge',
  ];
}
