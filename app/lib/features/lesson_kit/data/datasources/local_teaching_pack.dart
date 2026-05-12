import '../models/lesson_context_model.dart';

/// Small offline retrieval layer for classroom-specific guidance.
///
/// This is deliberately local and deterministic: it gives Gemma a compact
/// teaching frame before generation without sending classroom data anywhere.
class LocalTeachingPack {
  const LocalTeachingPack();

  TeachingPackContext build({
    required LessonContextModel context,
    String? passage,
  }) {
    final subject = context.subject.toLowerCase();
    return TeachingPackContext(
      subject: context.subject,
      grade: context.grade,
      sourceConceptHints: _sourceConceptHints(passage),
      pedagogyRules: _pedagogyRules(context),
      activityTemplates: _activityTemplates(subject),
      misconceptionChecks: _misconceptionChecks(subject),
    );
  }

  List<String> _sourceConceptHints(String? passage) {
    final text = passage?.trim();
    if (text == null || text.isEmpty) {
      return const [
        'Image-only source: extract concepts from the visible textbook page.',
      ];
    }

    final terms = _candidateTerms(text);
    if (terms.isEmpty) {
      return const [
        'Use only the pasted textbook passage as the factual source.',
      ];
    }

    return terms
        .take(8)
        .map((term) => 'Check whether "$term" is a key source concept.')
        .toList();
  }

  List<String> _candidateTerms(String text) {
    final normalized = text
        .replaceAll(RegExp(r'[^A-Za-z0-9\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return const [];

    const stopWords = {
      'about',
      'after',
      'also',
      'because',
      'between',
      'class',
      'could',
      'every',
      'from',
      'have',
      'into',
      'lesson',
      'more',
      'only',
      'other',
      'page',
      'some',
      'that',
      'their',
      'there',
      'these',
      'they',
      'this',
      'through',
      'when',
      'where',
      'which',
      'with',
      'would',
    };

    final counts = <String, int>{};
    for (final raw in normalized.split(' ')) {
      final word = raw.toLowerCase();
      if (word.length < 5 || stopWords.contains(word)) continue;
      counts[word] = (counts[word] ?? 0) + 1;
    }

    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });

    return entries.map((entry) => entry.key).toList();
  }

  List<String> _pedagogyRules(LessonContextModel context) => [
    'Use one blackboard-friendly sequence for a ${context.classDurationMinutes}-minute class.',
    'Start from a concrete example before naming the formal idea.',
    'Keep sentences short for ${_studentLevelPhrase(context)}.',
    'Ask oral checks before giving written homework.',
  ];

  String _studentLevelPhrase(LessonContextModel context) {
    return switch (context.studentLevel.name) {
      'easy' => 'students who need extra support',
      'advanced' => 'students ready for challenge',
      _ => 'standard learners',
    };
  }

  List<String> _activityTemplates(String subject) {
    if (subject.contains('science')) {
      return const [
        'Observation activity using classroom objects or the environment.',
        'Predict, observe, explain: ask students to guess before revealing.',
        'Draw-and-label board diagram that students copy and explain aloud.',
      ];
    }
    if (subject.contains('math')) {
      return const [
        'Solve one example together, then change one number for pairs.',
        'Use fingers, stones, sticks, or chalk marks instead of worksheets.',
        'Ask students to explain the step, not just the answer.',
      ];
    }
    if (subject.contains('english') || subject.contains('language')) {
      return const [
        'Read one sentence aloud, then ask students to restate it simply.',
        'Build a word bank on the board before asking for answers.',
        'Pair practice: one student asks, one student explains.',
      ];
    }
    if (subject.contains('social')) {
      return const [
        'Connect the idea to a local place, family routine, or community role.',
        'Use a quick board timeline, map, or cause-effect chain.',
        'Ask students to compare the textbook idea with daily life.',
      ];
    }
    return const [
      'Use think-pair-share before whole-class answers.',
      'Turn the main idea into a two-column board note.',
      'Ask one easy, one standard, and one stretch oral question.',
    ];
  }

  List<String> _misconceptionChecks(String subject) {
    if (subject.contains('science')) {
      return const [
        'Check whether students confuse observation with explanation.',
        'Check whether students treat a process as one instant event.',
        'Check whether students use everyday words differently from science terms.',
      ];
    }
    if (subject.contains('math')) {
      return const [
        'Check whether students memorize the rule without knowing when to use it.',
        'Check whether place value or operation order is being mixed up.',
        'Check whether students can explain the answer in words.',
      ];
    }
    if (subject.contains('english') || subject.contains('language')) {
      return const [
        'Check whether students know the meaning before pronunciation.',
        'Check whether students can use the word in a new sentence.',
        'Check whether grammar labels are hiding comprehension gaps.',
      ];
    }
    return const [
      'Check for one vocabulary confusion from the page.',
      'Check for one cause-effect confusion from the page.',
      'Check whether students can give a local example in their own words.',
    ];
  }
}

class TeachingPackContext {
  const TeachingPackContext({
    required this.subject,
    required this.grade,
    required this.sourceConceptHints,
    required this.pedagogyRules,
    required this.activityTemplates,
    required this.misconceptionChecks,
  });

  final String subject;
  final String grade;
  final List<String> sourceConceptHints;
  final List<String> pedagogyRules;
  final List<String> activityTemplates;
  final List<String> misconceptionChecks;

  String toPromptBlock() {
    return '''
OFFLINE TEACHING PACK
Retrieved locally for $grade $subject before model generation.
Use this as pedagogy guidance, not as extra textbook facts.

Source concept hints:
${_bullets(sourceConceptHints)}

Pedagogy rules:
${_bullets(pedagogyRules)}

Low-resource activity templates:
${_bullets(activityTemplates)}

Misconception checks:
${_bullets(misconceptionChecks)}

When filling source_concepts, likely_misconceptions, teacher_moves, and
checks_for_understanding, stay grounded in the textbook input and the local
teaching pack above.
''';
  }

  String _bullets(List<String> items) {
    if (items.isEmpty) return '- N/A';
    return items.map((item) => '- $item').join('\n');
  }
}
