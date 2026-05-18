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
      sourceWordCount: _sourceWordCount(passage),
      hasTextSource: passage != null && passage.trim().isNotEmpty,
      sourceConceptHints: _sourceConceptHints(passage, subject: subject),
      pedagogyRules: _pedagogyRules(context),
      activityTemplates: _activityTemplates(subject),
      misconceptionChecks: _misconceptionChecks(subject),
    );
  }

  int _sourceWordCount(String? passage) {
    final text = passage?.trim();
    if (text == null || text.isEmpty) return 0;
    return text
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .length;
  }

  List<String> _sourceConceptHints(String? passage, {required String subject}) {
    final text = passage?.trim();
    if (text == null || text.isEmpty) {
      return const [
        'Image-only source: extract concepts from the visible textbook page.',
      ];
    }

    final terms = _candidateTerms(text, subject: subject);
    if (terms.isEmpty) {
      return const [
        'Use only the pasted textbook passage as the factual source.',
      ];
    }

    return terms
        .take(10)
        .map((term) => 'Check whether "$term" is a key source concept.')
        .toList();
  }

  List<String> _candidateTerms(String text, {required String subject}) {
    final structuredTerms = _structuredSourceTerms(text, subject: subject);
    final normalized = text
        .replaceAll(RegExp(r'[^A-Za-z0-9\s-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return structuredTerms;

    final knownTerms = _knownSubjectTerms(
      normalized.toLowerCase(),
      subject: subject,
    );

    const stopWords = {
      'about',
      'after',
      'also',
      'because',
      'between',
      'class',
      'could',
      'definite',
      'every',
      'example',
      'examples',
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

    return _dedupe([
      ...knownTerms,
      ...structuredTerms,
      for (final entry in entries)
        if (!knownTerms.contains(entry.key)) entry.key,
    ]);
  }

  List<String> _structuredSourceTerms(String text, {required String subject}) {
    final terms = <String>[];
    void add(String term) {
      final cleaned = _cleanSourceTerm(term);
      if (cleaned == null) return;
      if (!terms.contains(cleaned)) terms.add(cleaned);
    }

    final titleMatch = RegExp(
      r'(?:^|\n)\s*(?:lesson|topic|title)\s*:\s*([^\n.]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (titleMatch != null) add(titleMatch.group(1)!);

    final inlineLists = RegExp(
      r'(?:key\s+words|words|word\s+bank|vocabulary)\s*:\s*([^\n.]+)',
      caseSensitive: false,
    ).allMatches(text);
    for (final match in inlineLists) {
      for (final term in _splitSourceWords(match.group(1)!)) {
        add(term);
      }
    }

    final lines = text.split(RegExp(r'\r?\n'));
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();
      final inlineWordList = RegExp(
        r'^(?:key\s+words|words|word\s+bank|vocabulary)\s*:\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line);
      if (inlineWordList != null) {
        for (final term in _splitSourceWords(inlineWordList.group(1)!)) {
          add(term);
        }
        continue;
      }

      final isWordBankHeading =
          lower == 'word bank' ||
          RegExp(r'^\d+\.\s*word bank$', caseSensitive: false).hasMatch(line);
      if (!isWordBankHeading) continue;

      for (var j = i + 1; j < lines.length; j++) {
        final next = lines[j].trim();
        if (next.isEmpty) continue;
        if (RegExp(r'^\d+\.\s+').hasMatch(next)) break;
        for (final term in _splitSourceWords(next)) {
          add(term);
        }
      }
    }

    return terms;
  }

  String? _cleanSourceTerm(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\-\s:]+|[\-\s:,;]+$'), '')
        .trim();
    if (cleaned.length < 2) return null;
    if (RegExp(r'^\d+$').hasMatch(cleaned)) return null;
    return cleaned.toLowerCase();
  }

  List<String> _splitSourceWords(String value) {
    return value
        .split(RegExp(r'[\s,;]+'))
        .map((word) => word.trim())
        .where((word) => word.length >= 2)
        .toList(growable: false);
  }

  List<String> _dedupe(Iterable<String> terms) {
    final seen = <String>{};
    return [
      for (final term in terms)
        if (seen.add(term.toLowerCase())) term,
    ];
  }

  List<String> _knownSubjectTerms(String lowerText, {required String subject}) {
    if (subject.contains('english') || subject.contains('language')) {
      return _knownEnglishTerms(lowerText);
    }
    if (!subject.contains('science')) return const [];
    const terms = [
      'matter',
      'mass',
      'volume',
      'solid',
      'liquid',
      'gas',
      'gases',
      'particles',
      'physical properties',
      'change of state',
      'melting',
      'freezing',
      'evaporation',
      'boiling',
      'condensation',
      'sublimation',
    ];
    return [
      for (final term in terms)
        if (RegExp('\\b${RegExp.escape(term)}s?\\b').hasMatch(lowerText)) term,
    ];
  }

  List<String> _knownEnglishTerms(String lowerText) {
    final terms = <String>[];
    void add(String term) {
      if (!terms.contains(term)) terms.add(term);
    }

    final hasShortA =
        RegExp(r'\bshort\s+a(?:\s+sound)?\b').hasMatch(lowerText) ||
        lowerText.contains('/a/');
    if (hasShortA) {
      add('short a sound');
      add('/a/');
      add('short a words');
    }

    const shortAWords = [
      'cat',
      'mat',
      'hat',
      'bag',
      'fan',
      'jam',
      'cap',
      'map',
      'apple',
    ];
    for (final word in shortAWords) {
      if (RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(lowerText)) {
        add(word);
      }
    }

    return terms;
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
    required this.sourceWordCount,
    required this.hasTextSource,
    required this.sourceConceptHints,
    required this.pedagogyRules,
    required this.activityTemplates,
    required this.misconceptionChecks,
  });

  final String subject;
  final String grade;
  final int sourceWordCount;
  final bool hasTextSource;
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
