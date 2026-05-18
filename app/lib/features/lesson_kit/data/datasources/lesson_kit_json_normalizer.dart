import '../../../../core/constants/languages.dart';
import '../models/lesson_context_model.dart';

/// Converts valid-but-loose model JSON into the exact LessonKit wire shape.
///
/// On-device models often follow the meaning of a schema while drifting on
/// details: camelCase keys, "English" instead of "en", quiz answers under
/// "answer", or bullet strings where the DTO expects a string list. This pass
/// keeps those recoverable outputs from becoming user-facing generation
/// failures.
class LessonKitJsonNormalizer {
  const LessonKitJsonNormalizer._();

  static Map<String, dynamic> normalize(
    Map<String, dynamic> raw, {
    required LessonContextModel context,
  }) {
    final reader = _LooseJsonReader(raw);

    final title = _text(
      reader.first(['lesson_title', 'lessonTitle', 'title', 'topic', 'name']),
      fallback: '${context.subject} lesson',
    );
    final sourceConcepts = _stringList(
      reader.first([
        'source_concepts',
        'sourceConcepts',
        'key_ideas',
        'keyIdeas',
        'concepts',
      ]),
    );
    final simpleExplanation = _text(
      reader.first([
        'simple_explanation',
        'simpleExplanation',
        'explanation',
        'summary',
        'lesson',
        'content',
      ]),
      fallback: _fallbackExplanation(title, sourceConcepts),
    );

    return <String, dynamic>{
      'lesson_title': title,
      'grade': _text(reader.first(['grade', 'class']), fallback: context.grade),
      'subject': _text(reader.first(['subject']), fallback: context.subject),
      'language': _languageCode(
        reader.first(['language', 'lang']),
        fallback: context.language,
      ),
      'source_concepts': sourceConcepts,
      'likely_misconceptions': _stringList(
        reader.first([
          'likely_misconceptions',
          'likelyMisconceptions',
          'misconceptions',
          'common_mistakes',
          'commonMistakes',
        ]),
      ),
      'teacher_moves': _stringList(
        reader.first([
          'teacher_moves',
          'teacherMoves',
          'teaching_steps',
          'teachingSteps',
        ]),
      ),
      'checks_for_understanding': _stringList(
        reader.first([
          'checks_for_understanding',
          'checksForUnderstanding',
          'quick_checks',
          'quickChecks',
          'cfu',
        ]),
      ),
      'learning_objectives': _stringList(
        reader.first([
          'learning_objectives',
          'learningObjectives',
          'objectives',
          'goals',
        ]),
      ),
      'simple_explanation': simpleExplanation,
      'blackboard_notes': _stringList(
        reader.first([
          'blackboard_notes',
          'blackboardNotes',
          'board_notes',
          'boardNotes',
          'notes',
        ]),
      ),
      'local_example': _text(
        reader.first(['local_example', 'localExample', 'example']),
      ),
      'oral_quiz': _quizList(
        reader.first(['oral_quiz', 'oralQuiz', 'quiz', 'questions']),
      ),
      'group_activity': _text(
        reader.first(['group_activity', 'groupActivity', 'activity']),
      ),
      'homework': _stringList(
        reader.first(['homework', 'home_work', 'practice', 'tasks']),
      ),
      'glossary': _glossaryList(
        reader.first(['glossary', 'vocabulary', 'terms']),
      ),
      'easy_version': _text(
        reader.first([
          'easy_version',
          'easyVersion',
          'simpler_explanation',
          'simplerExplanation',
        ]),
      ),
      'confidence': _confidence(reader.first(['confidence', 'score'])),
    };
  }

  static String _fallbackExplanation(String title, List<String> concepts) {
    if (concepts.isEmpty) return title;
    return '$title: ${concepts.join(', ')}.';
  }

  static String _languageCode(Object? value, {required AppLanguage fallback}) {
    final text = _text(value).toLowerCase();
    if (text.isEmpty) return fallback.code;
    for (final language in AppLanguage.values) {
      final accepted = {
        language.code.toLowerCase(),
        language.label.toLowerCase(),
        language.native.toLowerCase(),
        language.name.toLowerCase(),
      };
      if (accepted.contains(text)) return language.code;
    }
    return fallback.code;
  }

  static List<String> _stringList(Object? value) {
    if (value == null) return const <String>[];
    if (value is String) return _splitLooseList(value);
    if (value is Iterable) {
      return value
          .map(_text)
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is Map) {
      return value.values
          .map(_text)
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    final text = _text(value);
    return text.isEmpty ? const <String>[] : <String>[text];
  }

  static List<String> _splitLooseList(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const <String>[];
    final pieces = trimmed
        .split(RegExp(r'(?:\r?\n)+|(?:^|\s)[\-•]\s+|;\s+'))
        .map((item) => item.replaceFirst(RegExp(r'^\d+[\).\s-]+'), '').trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return pieces.isEmpty ? <String>[trimmed] : pieces;
  }

  static List<Map<String, dynamic>> _quizList(Object? value) {
    final items = value is Iterable
        ? value
        : value == null
        ? const []
        : [value];
    return items
        .map((item) {
          if (item is Map) {
            final reader = _LooseJsonReader(item.cast<String, dynamic>());
            final question = _text(
              reader.first(['question', 'q', 'prompt', 'ask']),
            );
            if (question.isEmpty) return null;
            final answer = _text(
              reader.first([
                'expected_answer',
                'expectedAnswer',
                'answer',
                'a',
              ]),
            );
            return <String, dynamic>{
              'question': question,
              if (answer.isNotEmpty) 'expected_answer': answer,
            };
          }
          final question = _text(item);
          if (question.isEmpty) return null;
          return <String, dynamic>{'question': question};
        })
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _glossaryList(Object? value) {
    final items = value is Iterable
        ? value
        : value == null
        ? const []
        : [value];
    return items
        .map((item) {
          if (item is Map) {
            final reader = _LooseJsonReader(item.cast<String, dynamic>());
            final term = _text(reader.first(['term', 'word', 'name']));
            final meaning = _text(
              reader.first(['meaning', 'definition', 'description']),
            );
            if (term.isEmpty || meaning.isEmpty) return null;
            final example = _text(reader.first(['example']));
            return <String, dynamic>{
              'term': term,
              'meaning': meaning,
              if (example.isNotEmpty) 'example': example,
            };
          }
          final text = _text(item);
          if (text.isEmpty) return null;
          final parts = text.split(RegExp(r'\s*[:\-]\s*'));
          if (parts.length >= 2) {
            return <String, dynamic>{
              'term': parts.first.trim(),
              'meaning': parts.skip(1).join(' - ').trim(),
            };
          }
          return <String, dynamic>{'term': text, 'meaning': text};
        })
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static double _confidence(Object? value) {
    if (value is num) return value.toDouble().clamp(0, 1);
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.endsWith('%')) {
        final parsed = double.tryParse(
          trimmed.substring(0, trimmed.length - 1),
        );
        if (parsed != null) return (parsed / 100).clamp(0, 1);
      }
      final parsed = double.tryParse(trimmed);
      if (parsed != null) return parsed.toDouble().clamp(0, 1);
    }
    return 0.0;
  }

  static String _text(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? fallback : trimmed;
    }
    if (value is num || value is bool) return value.toString();
    if (value is Iterable) {
      final joined = value
          .map(_text)
          .where((item) => item.isNotEmpty)
          .join(' ');
      return joined.isEmpty ? fallback : joined;
    }
    if (value is Map) {
      final reader = _LooseJsonReader(value.cast<String, dynamic>());
      final direct = _text(
        reader.first(['text', 'value', 'content', 'description', 'meaning']),
      );
      if (direct.isNotEmpty) return direct;
      final joined = value.entries
          .map((entry) => '${entry.key}: ${_text(entry.value)}')
          .where((item) => item.trim().isNotEmpty)
          .join('; ');
      return joined.isEmpty ? fallback : joined;
    }
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class _LooseJsonReader {
  _LooseJsonReader(Map<String, dynamic> raw)
    : _raw = raw,
      _normalized = {
        for (final entry in raw.entries) _normalizeKey(entry.key): entry.value,
      };

  final Map<String, dynamic> _raw;
  final Map<String, dynamic> _normalized;

  Object? first(List<String> keys) {
    for (final key in keys) {
      if (_raw.containsKey(key)) return _raw[key];
      final normalized = _normalizeKey(key);
      if (_normalized.containsKey(normalized)) return _normalized[normalized];
    }
    return null;
  }

  static String _normalizeKey(String key) =>
      key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
