import '../models/glossary_term_model.dart';
import '../models/lesson_context_model.dart';
import '../models/lesson_kit_model.dart';
import '../models/quiz_question_model.dart';
import 'local_teaching_pack.dart';

/// Builds a usable classroom kit when Gemma produced useful text but malformed
/// JSON. This keeps offline generation demo-safe without running the model a
/// second time.
class LessonKitRecoveryBuilder {
  const LessonKitRecoveryBuilder();

  LessonKitModel build({
    required LessonContextModel context,
    required TeachingPackContext teachingPack,
    required String rawOutput,
  }) {
    final concepts = _concepts(rawOutput, teachingPack);
    final title = _title(rawOutput, context, concepts);
    final primaryConcept = concepts.isEmpty ? 'the main idea' : concepts.first;
    final localExample = _localExample(context, concepts);

    return LessonKitModel(
      lessonTitle: title,
      grade: context.grade,
      subject: context.subject,
      language: context.language,
      sourceConcepts: concepts,
      likelyMisconceptions: _misconceptions(teachingPack, primaryConcept),
      teacherMoves: _teacherMoves(context, title, primaryConcept, localExample),
      checksForUnderstanding: _checks(primaryConcept, concepts),
      learningObjectives: _objectives(primaryConcept, concepts),
      simpleExplanation:
          _stringField(rawOutput, const [
            'simple_explanation',
            'simpleExplanation',
            'easy_version',
          ]) ??
          _simpleExplanation(title, concepts, localExample),
      blackboardNotes: _blackboardNotes(title, concepts, primaryConcept),
      localExample: localExample,
      oralQuiz: _quiz(primaryConcept, concepts),
      groupActivity: _groupActivity(primaryConcept, localExample),
      homework: _homework(primaryConcept, concepts),
      glossary: _glossary(concepts),
      easyVersion: _easyVersion(primaryConcept, concepts),
      confidence: 0.55,
    );
  }

  String _title(
    String rawOutput,
    LessonContextModel context,
    List<String> concepts,
  ) {
    final extracted = _stringField(rawOutput, const [
      'lesson_title',
      'lessonTitle',
      'title',
    ]);
    if (extracted != null && extracted.length >= 4) return extracted;
    if (concepts.isNotEmpty) return 'Introduction to ${concepts.first}';
    return '${context.subject} lesson';
  }

  List<String> _concepts(String rawOutput, TeachingPackContext teachingPack) {
    final items = <String>[
      ..._arrayStrings(rawOutput, 'source_concepts'),
      ..._arrayStrings(rawOutput, 'sourceConcepts'),
      ..._conceptsFromTeachingPack(teachingPack),
    ];
    final seen = <String>{};
    final concepts = <String>[];
    for (final item in items) {
      final cleaned = _cleanConcept(item);
      if (cleaned == null) continue;
      final key = cleaned.toLowerCase();
      if (seen.add(key)) concepts.add(cleaned);
      if (concepts.length >= 8) break;
    }
    if (concepts.isNotEmpty) return concepts;
    return const ['Main idea from the textbook source'];
  }

  List<String> _conceptsFromTeachingPack(TeachingPackContext teachingPack) {
    final concepts = <String>[];
    for (final hint in teachingPack.sourceConceptHints) {
      final quoted = RegExp('"([^"]+)"').firstMatch(hint);
      concepts.add(quoted?.group(1) ?? hint);
    }
    return concepts;
  }

  List<String> _arrayStrings(String rawOutput, String field) {
    final fieldMatch = RegExp(
      '"${RegExp.escape(field)}"\\s*:\\s*\\[',
      caseSensitive: false,
    ).firstMatch(rawOutput);
    if (fieldMatch == null) return const <String>[];

    final start = fieldMatch.end;
    var end = rawOutput.indexOf(']', start);
    final nextFields = RegExp(r',\s*"[\w_]+"\s*:').allMatches(rawOutput, start);
    final nextField = nextFields.isEmpty ? null : nextFields.first;
    if (end == -1 || (nextField != null && nextField.start < end)) {
      end = nextField?.start ?? (start + 1600).clamp(start, rawOutput.length);
    }
    final body = rawOutput.substring(start, end);
    return RegExp(r'"((?:\\.|[^"\\])*)"')
        .allMatches(body)
        .map((match) => _cleanText(match.group(1) ?? ''))
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String? _stringField(String rawOutput, List<String> fields) {
    for (final field in fields) {
      final match = RegExp(
        '"${RegExp.escape(field)}"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"',
        caseSensitive: false,
      ).firstMatch(rawOutput);
      if (match == null) continue;
      final cleaned = _cleanText(match.group(1) ?? '');
      if (cleaned.isNotEmpty) return cleaned;
    }
    return null;
  }

  String? _cleanConcept(String raw) {
    final cleaned = _titleCase(_cleanText(raw));
    if (cleaned.length < 4) return null;
    final lower = cleaned.toLowerCase();
    const weak = {
      'classroom',
      'definite',
      'example',
      'examples',
      'lesson',
      'main idea from the textbook source',
      'source',
      'textbook',
    };
    if (weak.contains(lower)) return null;
    if (lower.startsWith('check whether')) return null;
    if (lower.startsWith('use only')) return null;
    return cleaned;
  }

  String _cleanText(String value) => value
      .replaceAll(r'\"', '"')
      .replaceAll(r'\n', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'^[\-\s:]+|[\-\s:,;]+$'), '');

  String _titleCase(String value) {
    final words = value.split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words
        .map((word) {
          final lower = word.toLowerCase();
          if (lower.length <= 3 && word == word.toUpperCase()) return word;
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }

  String _localExample(LessonContextModel context, List<String> concepts) {
    final subject = context.subject.toLowerCase();
    final lowerConcepts = concepts.join(' ').toLowerCase();
    if (subject.contains('science') &&
        (lowerConcepts.contains('matter') ||
            lowerConcepts.contains('solid') ||
            lowerConcepts.contains('liquid') ||
            lowerConcepts.contains('gas'))) {
      return 'Use a pencil or book as a solid, water in a cup as a liquid, '
          'and air in a balloon as a gas so students can compare shape and '
          'volume from real classroom objects.';
    }
    if (subject.contains('math')) {
      return 'Use chalk marks, bottle caps, or stones so students can see the '
          'idea before writing the formal rule.';
    }
    return 'Use one familiar classroom or local example first, then connect it '
        'back to the textbook words on the board.';
  }

  List<String> _teacherMoves(
    LessonContextModel context,
    String title,
    String primaryConcept,
    String localExample,
  ) {
    final total = context.classDurationMinutes <= 0
        ? 35
        : context.classDurationMinutes;
    final first = _slot(total, 0.1, 3, 6);
    final second = _slot(total, 0.2, 7, 12);
    final third = _slot(total, 0.38, 14, 22);
    final fourth = _slot(total, 0.58, 22, 34);
    final fifth = _slot(total, 0.78, 30, 44);
    return [
      '0-$first min: Show the local example first and ask, "What do you '
          'notice?" before naming $primaryConcept.',
      '$first-$second min: Write "$title" and the key words on the board; ask '
          'students to say each word in their own language.',
      '$second-$third min: Read the textbook idea in short parts and connect '
          'each part to the example: $localExample',
      '$third-$fourth min: Let pairs sort examples and non-examples, then ask '
          'one pair to explain their reason aloud.',
      '$fourth-$fifth min: Build final blackboard notes with the class and '
          'correct one likely misconception immediately.',
      '$fifth-$total min: Ask quick oral checks, give one exit question, and '
          'assign short homework using the same key words.',
    ];
  }

  int _slot(int total, double fraction, int min, int max) {
    final value = (total * fraction).round().clamp(min, max).toInt();
    return value.clamp(1, total).toInt();
  }

  List<String> _misconceptions(
    TeachingPackContext teachingPack,
    String primaryConcept,
  ) {
    final base = teachingPack.misconceptionChecks.take(3).toList();
    return [
      ...base,
      'Check whether students memorize $primaryConcept without connecting it '
          'to an observable example.',
      'Check whether students can separate an observation from an explanation.',
    ];
  }

  List<String> _checks(String primaryConcept, List<String> concepts) {
    final second = concepts.length > 1 ? concepts[1] : 'the example';
    return [
      'Explain $primaryConcept in your own words.',
      'Give one local example of $primaryConcept.',
      'How is $primaryConcept connected to $second?',
      'What observation did we make before writing the formal definition?',
      'What mistake should we avoid when using this word?',
    ];
  }

  List<String> _objectives(String primaryConcept, List<String> concepts) => [
    'Define $primaryConcept using simple classroom language.',
    'Connect $primaryConcept to at least one local or classroom example.',
    if (concepts.length > 1)
      'Compare $primaryConcept with ${concepts[1]} using one clear difference.',
    'Answer oral questions using the key words from the board.',
  ];

  String _simpleExplanation(
    String title,
    List<String> concepts,
    String localExample,
  ) {
    final keyIdeas = concepts.take(5).join(', ');
    return '$title should start from something students can observe. The '
        'teacher first shows an example, asks students what they notice, and '
        'then connects those observations to the textbook words: $keyIdeas. '
        'The middle of the class should compare examples and non-examples so '
        'students explain the idea instead of only copying it. $localExample '
        'By the end, students should be able to say the meaning in their own '
        'words, give one example, answer quick oral checks, and copy clean '
        'blackboard notes.';
  }

  List<String> _blackboardNotes(
    String title,
    List<String> concepts,
    String primaryConcept,
  ) => [
    title,
    'Today\'s question: What does $primaryConcept mean and how can we '
        'recognize it?',
    'Key words: ${concepts.take(6).join(', ')}',
    '$primaryConcept: write the textbook meaning in simple words.',
    'Example: write one classroom or local example.',
    'Non-example or confusion: write one mistake to avoid.',
    'Activity: predict, observe, explain.',
    'Exit check: one student explains the main idea aloud.',
  ];

  List<QuizQuestionModel> _quiz(String primaryConcept, List<String> concepts) {
    final second = concepts.length > 1 ? concepts[1] : 'the example';
    return [
      QuizQuestionModel(
        question: 'What does $primaryConcept mean in this lesson?',
        expectedAnswer: 'A simple meaning plus one example.',
      ),
      QuizQuestionModel(
        question: 'Give one example of $primaryConcept from home or class.',
        expectedAnswer: 'Any correct local example from the lesson.',
      ),
      QuizQuestionModel(
        question: 'How is $primaryConcept connected to $second?',
        expectedAnswer: 'A clear connection based on the lesson source.',
      ),
      const QuizQuestionModel(
        question: 'What did we observe before writing the definition?',
        expectedAnswer: 'One observation from the classroom example.',
      ),
      const QuizQuestionModel(
        question: 'What is one common mistake we should avoid?',
        expectedAnswer: 'One misconception corrected during the lesson.',
      ),
    ];
  }

  String _groupActivity(String primaryConcept, String localExample) =>
      'In pairs, students observe the local example, write one sentence about '
      '$primaryConcept, and share one example or non-example with the class. '
      '$localExample';

  List<String> _homework(String primaryConcept, List<String> concepts) => [
    'Write the meaning of $primaryConcept in your own words and give two local '
        'examples.',
    'Choose three key words from the board and use each in a correct sentence.',
    'Write one common mistake from class and the correct idea.',
    if (concepts.length > 1)
      'Draw or list one example that connects $primaryConcept and ${concepts[1]}.',
  ];

  List<GlossaryTermModel> _glossary(List<String> concepts) => concepts
      .take(6)
      .map(
        (concept) => GlossaryTermModel(
          term: concept,
          meaning:
              'Key word from the textbook source; explain it using the '
              'class example and board notes.',
          example: 'Use one local example from the lesson.',
        ),
      )
      .toList(growable: false);

  String _easyVersion(String primaryConcept, List<String> concepts) =>
      '$primaryConcept is the main idea today. First look at an example, then '
      'learn the key words: ${concepts.take(4).join(', ')}. A good answer gives '
      'a meaning and one example.';
}
