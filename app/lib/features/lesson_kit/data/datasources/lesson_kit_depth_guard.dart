import '../models/glossary_term_model.dart';
import '../models/lesson_context_model.dart';
import '../models/lesson_kit_model.dart';
import '../models/quiz_question_model.dart';
import 'local_teaching_pack.dart';

/// Keeps salvaged model output from becoming a tiny user-facing lesson.
///
/// Gemma can sometimes produce a long response with malformed JSON. The JSON
/// repair path may recover only the top of the object, so this guard expands
/// missing classroom sections locally instead of asking the device to run a
/// second native generation.
class LessonKitDepthGuard {
  const LessonKitDepthGuard();

  bool isSufficient({
    required LessonKitModel kit,
    required LessonContextModel context,
    required TeachingPackContext teachingPack,
  }) {
    return LessonKitDepthTarget.forSource(
      context: context,
      teachingPack: teachingPack,
    ).isSatisfied(kit);
  }

  LessonKitModel expandIfTooShort({
    required LessonKitModel kit,
    required LessonContextModel context,
    required TeachingPackContext teachingPack,
    void Function(String message)? log,
  }) {
    final target = LessonKitDepthTarget.forSource(
      context: context,
      teachingPack: teachingPack,
    );
    if (target.isSatisfied(kit)) return kit;

    log?.call(
      '[GemmaLessonKitDatasource] lesson kit was too short for '
      'the uploaded content; expanding missing classroom sections locally.',
    );

    final concepts = _lessonConcepts(
      kit: kit,
      context: context,
      teachingPack: teachingPack,
      minCount: target.minSourceConcepts,
    );
    final title = _lessonTitle(kit, concepts, context);
    final likelyMisconceptions = _ensureStrings([
      ...kit.likelyMisconceptions,
      ...teachingPack.misconceptionChecks,
      ..._fallbackMisconceptions(concepts, context),
    ], minCount: target.minLikelyMisconceptions);
    final teacherMoves = _ensureStrings([
      ..._fallbackTeacherMoves(concepts, context, target),
      ..._specificTeacherMoves(kit.teacherMoves, context),
    ], minCount: target.minTeacherMoves);
    final checks = _ensureStrings([
      ..._fallbackChecks(concepts),
      ..._specificChecks(kit.checksForUnderstanding, concepts, context),
    ], minCount: target.minChecks);
    final objectives = _ensureStrings([
      ...kit.learningObjectives,
      ..._fallbackObjectives(concepts, context),
    ], minCount: target.minObjectives);
    final blackboardNotes = _ensureStrings([
      ..._fallbackBlackboardNotes(title, concepts),
      ...kit.blackboardNotes,
    ], minCount: target.minBlackboardNotes);
    final oralQuiz = _ensureQuiz([
      ..._fallbackQuiz(concepts),
      ...kit.oralQuiz,
    ], minCount: target.minOralQuiz);
    final homework = _ensureStrings([
      ...kit.homework,
      ..._fallbackHomework(concepts),
    ], minCount: target.minHomework);
    final glossary = _ensureGlossary([
      ...kit.glossary,
      ..._fallbackGlossary(concepts),
    ], minCount: target.minGlossary);

    var expanded = kit.copyWith(
      lessonTitle: title,
      sourceConcepts: concepts,
      likelyMisconceptions: likelyMisconceptions,
      teacherMoves: teacherMoves,
      checksForUnderstanding: checks,
      learningObjectives: objectives,
      simpleExplanation: _simpleExplanation(
        kit: kit,
        context: context,
        title: title,
        concepts: concepts,
        target: target,
      ),
      blackboardNotes: blackboardNotes,
      localExample: _localExample(kit, concepts, context),
      oralQuiz: oralQuiz,
      groupActivity: _groupActivity(kit, concepts, context),
      homework: homework,
      glossary: glossary,
      easyVersion: _easyVersion(kit, concepts),
      confidence: kit.confidence == 0 ? 0.7 : kit.confidence,
    );

    if (target.isSatisfied(expanded)) return expanded;

    expanded = _addTeacherTimingSupport(
      expanded,
      concepts: concepts,
      context: context,
      target: target,
    );
    return expanded;
  }

  LessonKitModel _addTeacherTimingSupport(
    LessonKitModel kit, {
    required List<String> concepts,
    required LessonContextModel context,
    required LessonKitDepthTarget target,
  }) {
    final teacherMoves = _ensureStrings([
      ...kit.teacherMoves,
      '0-5 min: Begin with a familiar object and ask students what they can observe before naming the lesson idea.',
      '5-12 min: Write the key words on the board and ask students to connect each word to one example.',
      '12-22 min: Explain the textbook idea slowly, stopping after each key word for one oral answer.',
      '22-34 min: Let pairs complete the observation or comparison activity and report one finding.',
      '34-43 min: Use quick questions to check whether students can explain, compare, and give examples.',
      if (target.label == 'compact')
        'Extra time: if the teacher has ${context.classDurationMinutes} minutes, use it for more examples, pair explanations, and homework review rather than adding new textbook facts.'
      else
        '43-${context.classDurationMinutes} min: Summarize the board notes, correct one misconception, and give the exit check.',
    ], minCount: target.minTeacherMoves);
    final timingText = target.label == 'compact'
        ? 'For timing, this source is best treated as a compact core lesson. If the teacher has ${context.classDurationMinutes} minutes, the extra time should be used for student examples, pair talk, board practice, and checking rather than inventing new textbook content. Each key term such as ${concepts.take(3).join(', ')} should still be heard, seen on the board, used in a sentence, and connected to one local example.'
        : 'For timing, the teacher can treat this as a ${context.classDurationMinutes}-minute lesson by spending the first part on concrete observation, the middle part on naming and comparing the key ideas, and the final part on oral checking. The lesson should not be rushed as a short summary. Each key term such as ${concepts.take(3).join(', ')} should be heard, seen on the board, used in a sentence, and connected to one local example before students copy the final notes.';
    final explanation = [kit.simpleExplanation, timingText].join('\n\n');

    return kit.copyWith(
      teacherMoves: teacherMoves,
      simpleExplanation: explanation,
    );
  }

  String _lessonTitle(
    LessonKitModel kit,
    List<String> concepts,
    LessonContextModel context,
  ) {
    final title = kit.lessonTitle.trim();
    final lowerTitle = title.toLowerCase();
    final genericTitle =
        lowerTitle.isEmpty ||
        lowerTitle == '${context.subject} lesson'.toLowerCase() ||
        lowerTitle == 'lesson' ||
        lowerTitle == 'science lesson';
    if (!genericTitle) return title;

    final main = concepts.isEmpty ? context.subject : concepts.first;
    return 'Introduction to $main';
  }

  List<String> _conceptsFromTeachingPack(TeachingPackContext teachingPack) {
    final concepts = <String>[];
    final quotedPattern = RegExp('"([^"]+)"');
    for (final hint in teachingPack.sourceConceptHints) {
      final match = quotedPattern.firstMatch(hint);
      if (match != null) {
        concepts.add(_titleCase(match.group(1)!));
      }
    }
    return concepts;
  }

  List<String> _lessonConcepts({
    required LessonKitModel kit,
    required LessonContextModel context,
    required TeachingPackContext teachingPack,
    required int minCount,
  }) {
    final rawConcepts = [
      ...kit.sourceConcepts,
      ..._conceptsFromTeachingPack(teachingPack),
    ];
    final normalized = rawConcepts
        .map((concept) => _normalizeConcept(concept, context))
        .whereType<String>()
        .toList();
    final hasMatter = normalized.any(
      (concept) => concept.toLowerCase() == 'matter',
    );
    final hasStateWord = normalized.any(
      (concept) => {'solid', 'liquid', 'gas'}.contains(concept.toLowerCase()),
    );
    final enriched = [
      ...normalized,
      if (hasMatter) ...['Mass', 'Volume'],
      if (hasMatter && hasStateWord) ...['Solid', 'Liquid', 'Gas'],
    ];
    final ranked = _rankConceptsForLesson(enriched, context).where((concept) {
      if (!hasMatter) return true;
      return concept.toLowerCase() != 'water';
    });
    return _ensureConcepts(
      ranked,
      fillItems: _defaultConcepts(context),
      minCount: minCount,
    );
  }

  String? _normalizeConcept(String raw, LessonContextModel context) {
    final cleaned = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[^A-Za-z0-9]+|[^A-Za-z0-9]+$'), '')
        .trim();
    if (cleaned.isEmpty) return null;

    final lower = cleaned.toLowerCase();
    const weakScienceWords = {
      'definite',
      'example',
      'examples',
      'container',
      'classroom',
      'teacher',
      'student',
      'students',
    };
    if (context.subject.toLowerCase().contains('science') &&
        weakScienceWords.contains(lower)) {
      return null;
    }

    const scienceTerms = {
      'matter': 'Matter',
      'mass': 'Mass',
      'volume': 'Volume',
      'solid': 'Solid',
      'solids': 'Solid',
      'liquid': 'Liquid',
      'liquids': 'Liquid',
      'gas': 'Gas',
      'gases': 'Gas',
      'particle': 'Particles',
      'particles': 'Particles',
      'property': 'Physical properties',
      'properties': 'Physical properties',
      'physical property': 'Physical properties',
      'physical properties': 'Physical properties',
      'change of state': 'Change of state',
      'changes of state': 'Change of state',
      'melting': 'Melting',
      'freezing': 'Freezing',
      'evaporation': 'Evaporation',
      'boiling': 'Boiling',
      'condensation': 'Condensation',
      'sublimation': 'Sublimation',
    };
    final mapped = scienceTerms[lower];
    if (mapped != null) return mapped;

    return _titleCase(cleaned);
  }

  List<String> _rankConceptsForLesson(
    Iterable<String> concepts,
    LessonContextModel context,
  ) {
    final cleaned = _ensureConcepts(concepts, minCount: 0);
    if (!context.subject.toLowerCase().contains('science')) return cleaned;

    const priority = [
      'Matter',
      'Mass',
      'Volume',
      'Solid',
      'Liquid',
      'Gas',
      'Particles',
      'Physical properties',
      'Change of state',
      'Melting',
      'Freezing',
      'Evaporation',
      'Boiling',
      'Condensation',
      'Sublimation',
    ];
    final lookup = {for (final item in cleaned) item.toLowerCase(): item};
    final ranked = <String>[
      for (final item in priority)
        if (lookup.containsKey(item.toLowerCase())) item,
      for (final item in cleaned)
        if (!priority.any((known) => known.toLowerCase() == item.toLowerCase()))
          item,
    ];
    return _ensureConcepts(ranked, minCount: 0);
  }

  List<String> _defaultConcepts(LessonContextModel context) {
    final subject = context.subject.toLowerCase();
    if (subject.contains('science')) {
      return const [
        'Matter',
        'Mass',
        'Volume',
        'Solid',
        'Liquid',
        'Gas',
        'Physical property',
        'Change of state',
      ];
    }
    if (subject.contains('math')) {
      return const [
        'Problem',
        'Known value',
        'Unknown value',
        'Rule',
        'Step',
        'Answer',
      ];
    }
    if (subject.contains('english') || subject.contains('language')) {
      return const [
        'Meaning',
        'Vocabulary',
        'Sentence',
        'Example',
        'Pronunciation',
        'Use in context',
      ];
    }
    return const [
      'Main idea',
      'Key vocabulary',
      'Example',
      'Cause and effect',
      'Comparison',
      'Local connection',
    ];
  }

  List<String> _fallbackMisconceptions(
    List<String> concepts,
    LessonContextModel context,
  ) {
    final subject = context.subject.toLowerCase();
    final main = _conceptAt(concepts, 0, fallback: 'the main idea');
    if (subject.contains('science')) {
      final pair = _comparisonPair(concepts);
      return [
        'Check whether students memorize the word $main without connecting it to an observable example.',
        'Check whether students mix everyday meanings with the science meaning used in the textbook.',
        'Check whether students can separate an observation from an explanation.',
        'Check whether students confuse related ideas such as ${pair.first} and ${pair.last}.',
      ];
    }
    return [
      'Check whether students can explain $main in their own words.',
      'Check whether students can give a correct local example, not only repeat the textbook sentence.',
      'Check whether students confuse two related key words from the lesson.',
    ];
  }

  List<String> _fallbackTeacherMoves(
    List<String> concepts,
    LessonContextModel context,
    LessonKitDepthTarget target,
  ) {
    final main = _conceptAt(concepts, 0, fallback: 'the lesson idea');
    final pair = _comparisonPair(concepts);
    final hasMatter = concepts.any(
      (concept) => concept.toLowerCase() == 'matter',
    );
    if (hasMatter && context.subject.toLowerCase().contains('science')) {
      return [
        '0-5 min Starter: show a book, water in a cup, and air in a balloon. Ask, "Which of these take up space? How do you know?"',
        '5-10 min Name the idea: write "Matter = has mass and occupies space" on the board only after students give observations.',
        '10-18 min Explain mass and volume: mass means amount of matter, volume means space occupied. Ask students to point to the mass/volume idea in each example.',
        '18-28 min Compare states: build a table for Solid, Liquid, and Gas with columns for shape, volume, and one example.',
        '28-36 min Pair practice: students classify classroom/home examples as solid, liquid, or gas and say the reason aloud.',
        '36-43 min Misconception check: ask whether air, light, sound, and heat are matter where relevant to the source, then correct answers using "mass and space".',
        if (target.label == 'compact')
          'Final minutes: students copy the board table, answer one exit question, and use any extra class time for more examples instead of adding new facts.'
        else
          '43-${context.classDurationMinutes} min Close: students copy the final board notes, answer "Is air matter? Why?", and receive homework.',
      ];
    }
    if (target.label == 'compact') {
      return [
        '0-5 min: Hold up or point to a familiar classroom example and ask, "What do you notice?" before naming $main.',
        '5-10 min: Write only the source key words on the board: ${concepts.take(5).join(', ')}.',
        '10-18 min: Explain the short source in small parts and ask students to repeat the important words.',
        '18-26 min: Compare ${pair.first} and ${pair.last} with examples and non-examples from the classroom.',
        '26-35 min: Ask quick oral checks, correct one misconception, and let students copy the final notes.',
        if (context.classDurationMinutes > 35)
          'If class time is ${context.classDurationMinutes} minutes, use the remaining time for more student examples, pair explanations, and homework review instead of adding unsupported content.',
      ];
    }
    return [
      '0-5 min: Hold up or point to a familiar classroom example and ask, "What do you notice?" before naming $main.',
      '5-10 min: Write the lesson title and key words on the board: ${concepts.take(5).join(', ')}.',
      '10-18 min: Read the source idea aloud in short parts and ask students to repeat the important words.',
      '18-28 min: Compare ${pair.first} and ${pair.last} using a two-column board table with examples and non-examples.',
      '28-36 min: Run a predict-observe-explain moment where pairs first guess, then observe, then explain in one sentence.',
      '36-43 min: Ask quick oral checks and correct one misconception immediately on the board.',
      '43-${context.classDurationMinutes} min: Let students copy the final board notes, answer one exit question, and receive homework.',
    ];
  }

  Iterable<String> _specificTeacherMoves(
    Iterable<String> moves,
    LessonContextModel context,
  ) {
    final requestedMinutes = context.classDurationMinutes.toString();
    return moves.where((move) {
      final lower = move.toLowerCase();
      final generic =
          lower.contains('blackboard-friendly sequence') ||
          lower.startsWith('start from a concrete example') ||
          lower.startsWith('observation activity') ||
          lower.startsWith('predict, observe, explain') ||
          lower.contains('use one blackboard-friendly') ||
          lower.contains('without internet or devices');
      return !generic &&
          !lower.contains('$requestedMinutes-minute') &&
          !lower.contains('$requestedMinutes minute') &&
          !lower.contains('full $requestedMinutes') &&
          !lower.contains('for a $requestedMinutes');
    });
  }

  Iterable<String> _specificChecks(
    Iterable<String> checks,
    List<String> concepts,
    LessonContextModel context,
  ) {
    final conceptWords = concepts
        .map((concept) => concept.toLowerCase())
        .toSet();
    return checks.where((check) {
      final lower = check.toLowerCase();
      final generic =
          lower.startsWith('ask one student to explain') ||
          lower.startsWith('ask the class for one local example');
      final weakDefinite =
          lower.contains('definite') &&
          !conceptWords.contains('definite') &&
          context.subject.toLowerCase().contains('science');
      return !generic && !weakDefinite;
    });
  }

  List<String> _fallbackChecks(List<String> concepts) {
    final main = _conceptAt(concepts, 0, fallback: 'the main idea');
    final pair = _comparisonPair(concepts);
    return [
      'Explain $main in your own words; expected response: a simple meaning plus one example.',
      'Give one local example of $main; expected response: an example students can see or imagine nearby.',
      'How is ${pair.first} different from ${pair.last}? expected response: one clear difference from the lesson.',
      'What word from the board is most important today? expected response: a key term with a reason.',
      'What mistake might a student make about this lesson? expected response: one misconception corrected aloud.',
      'Can you use ${pair.first} and ${pair.last} in one sentence? expected response: a sentence that uses both correctly.',
    ];
  }

  List<String> _fallbackObjectives(
    List<String> concepts,
    LessonContextModel context,
  ) {
    final main = _conceptAt(concepts, 0, fallback: 'the main idea');
    final pair = _comparisonPair(concepts);
    return [
      'Students can define $main using simple ${context.grade} language.',
      'Students can identify examples and non-examples connected to ${concepts.take(3).join(', ')}.',
      'Students can compare ${pair.first} and ${pair.last} and explain the difference orally.',
      'Students can answer quick check questions and correct one common misconception.',
    ];
  }

  String _simpleExplanation({
    required LessonKitModel kit,
    required LessonContextModel context,
    required String title,
    required List<String> concepts,
    required LessonKitDepthTarget target,
  }) {
    final existing = kit.simpleExplanation.trim();
    if (_isUsefulText(existing, minLength: target.minSimpleExplanationChars)) {
      return existing;
    }

    final main = _conceptAt(concepts, 0, fallback: 'the main idea');
    final conceptList = concepts.take(6).join(', ');
    final scienceMatter = concepts.any(
      (concept) => concept.toLowerCase() == 'matter',
    );
    if (scienceMatter && context.subject.toLowerCase().contains('science')) {
      return _matterExplanation(context: context, target: target);
    }
    final concreteScience = scienceMatter
        ? 'For this science lesson, use a pencil or book as a solid, water or milk as a liquid, and air in a balloon as a gas. Students should notice that the examples are not just words on the page; they are things they can observe and compare.'
        : 'Use one familiar object, situation, or sentence from the classroom so students meet the idea before they copy the formal words.';

    final pacingSentence = target.label == 'compact'
        ? 'Because the uploaded source is short, this should be treated as a compact source-based lesson. If the class period is longer, the teacher should spend extra time on examples, student talk, board practice, and checking rather than adding facts that were not in the source.'
        : 'This is the part that makes the lesson strong for a ${context.classDurationMinutes}-minute class: students are not only listening, they are observing, predicting, explaining, and checking each other.';

    final buffer = StringBuffer()
      ..writeln(
        '$title begins with $main, but it should be taught as a sequence, not as one short definition. The teacher first shows a concrete example, asks students what they observe, and then connects those observations to the textbook words: $conceptList.',
      )
      ..writeln()
      ..writeln(
        '$concreteScience After the first example, the teacher writes the key words on the blackboard and asks students to say what each word means in their own language before giving the formal class answer.',
      )
      ..writeln()
      ..writeln(
        'The middle of the lesson should help students compare ideas. They can sort examples, explain differences, and correct everyday meanings that do not match the science or textbook meaning. $pacingSentence',
      )
      ..writeln()
      ..writeln(
        'By the end, students should be able to define $main, give a local example, answer quick oral questions, and copy a clean set of board notes. The final minutes should be used for an exit question and homework so the teacher can see whether students can use the key ideas without help.',
      );

    final explanation = buffer.toString().trim();
    if (explanation.length >= target.minSimpleExplanationChars) {
      return explanation;
    }
    return [
      explanation,
      'If students are quiet, the teacher can ask yes-or-no questions first, then ask them to explain their answer. This keeps the lesson accessible while still building toward the formal vocabulary.',
    ].join('\n\n');
  }

  String _matterExplanation({
    required LessonContextModel context,
    required LessonKitDepthTarget target,
  }) {
    final explanation =
        '''
Matter is anything that has mass and takes up space. A book, a pencil, water, milk, and air are all examples of matter because they are made of something and occupy space. Mass means how much matter an object has. Volume means how much space it takes up.

Matter is commonly seen in three states: solid, liquid, and gas. A solid keeps its own shape and volume, like a pencil or stone. A liquid keeps its volume but takes the shape of its container, like water in a glass. A gas spreads out to fill the space available, like air inside a balloon.

The important classroom idea is that students should not only memorize the words. They should observe examples, compare shape and volume, and explain why each example is matter. When they can say, "It has mass and takes up space," they are using the science definition correctly.
'''
            .trim();

    if (target.label == 'compact') return explanation;
    return '''
$explanation

For a ${context.classDurationMinutes}-minute class, the teacher can deepen the same content by adding more student examples, pair classification, a board table, and an exit question. The lesson should still stay grounded in matter, mass, volume, and the states of matter rather than introducing unrelated new facts.
'''
        .trim();
  }

  List<String> _fallbackBlackboardNotes(String title, List<String> concepts) {
    final main = _conceptAt(concepts, 0, fallback: 'Main idea');
    final pair = _comparisonPair(concepts);
    final hasMatter = concepts.any(
      (concept) => concept.toLowerCase() == 'matter',
    );
    if (hasMatter) {
      return [
        title,
        'Matter: anything that has mass and takes up space.',
        'Mass: how much matter an object has.',
        'Volume: how much space matter takes up.',
        'Solid: fixed shape and fixed volume.',
        'Liquid: fixed volume, takes the container shape.',
        'Gas: spreads out to fill the container.',
        'Activity table: object | state | shape | volume.',
        'Exit check: Is air matter? Explain using mass and space.',
      ];
    }
    return [
      title,
      'Today\'s question: What does $main mean and how can we recognize it?',
      'Key words: ${concepts.take(6).join(', ')}',
      '$main: write the textbook meaning in simple words.',
      'Examples: list two classroom or local examples.',
      'Non-example or confusion: write one thing students should not mix up.',
      'Compare: ${pair.first} vs ${pair.last}',
      'Activity: predict, observe, explain.',
      'Exit check: one student explains the main idea aloud.',
    ];
  }

  String _localExample(
    LessonKitModel kit,
    List<String> concepts,
    LessonContextModel context,
  ) {
    final existing = kit.localExample.trim();
    if (_isUsefulText(existing, minLength: 40)) return existing;
    final subject = context.subject.toLowerCase();
    if (subject.contains('science')) {
      return 'Use a pencil or book, water in a cup, and air in a balloon to connect the lesson words to things students can observe in the classroom.';
    }
    return 'Use one object, place, or routine from the classroom and ask students to connect it to ${concepts.take(2).join(' and ')}.';
  }

  List<QuizQuestionModel> _fallbackQuiz(List<String> concepts) {
    final main = _conceptAt(concepts, 0, fallback: 'the main idea');
    final pair = _comparisonPair(concepts);
    final questions = [
      QuizQuestionModel(
        question: 'What does $main mean in this lesson?',
        expectedAnswer: 'A simple definition plus one correct example.',
      ),
      QuizQuestionModel(
        question: 'Give one example of $main from the classroom or home.',
        expectedAnswer: 'Any correct local example connected to the lesson.',
      ),
      QuizQuestionModel(
        question: 'How is ${pair.first} different from ${pair.last}?',
        expectedAnswer: 'One clear difference using the board notes.',
      ),
      const QuizQuestionModel(
        question: 'What was one observation from the activity?',
        expectedAnswer: 'A detail students saw before explaining it.',
      ),
      const QuizQuestionModel(
        question: 'What is one common mistake we should avoid?',
        expectedAnswer: 'One misconception corrected during the lesson.',
      ),
      QuizQuestionModel(
        question: 'Use ${pair.first} and ${pair.last} in one sentence.',
        expectedAnswer: 'A sentence that uses both key words correctly.',
      ),
      const QuizQuestionModel(
        question: 'What should you write first in your homework answer?',
        expectedAnswer: 'The meaning of the key word, then an example.',
      ),
    ];
    return questions;
  }

  String _groupActivity(
    LessonKitModel kit,
    List<String> concepts,
    LessonContextModel context,
  ) {
    final existing = kit.groupActivity.trim();
    if (_isUsefulText(existing, minLength: 90)) return existing;
    final subject = context.subject.toLowerCase();
    if (subject.contains('science')) {
      return 'In groups of three, students observe three examples from the classroom. They fill a two-column board table: "What we observe" and "What it tells us about ${_conceptAt(concepts, 0, fallback: 'the main idea')}". Each group shares one example, one comparison, and one question they still have.';
    }
    return 'In pairs, students choose one local example for ${_conceptAt(concepts, 0, fallback: 'the main idea')}, explain it in one sentence, then compare their explanation with another pair before the teacher writes the strongest answer on the board.';
  }

  List<String> _fallbackHomework(List<String> concepts) {
    final main = _conceptAt(concepts, 0, fallback: 'the main idea');
    final pair = _comparisonPair(concepts);
    return [
      'Write the meaning of $main in your own words and give two local examples.',
      'Choose three key words from the board and use each one in a correct sentence.',
      'Answer: What was one misconception from class, and what is the correct idea?',
      'Draw or list one example from home that connects to ${pair.first} and ${pair.last}.',
    ];
  }

  List<GlossaryTermModel> _fallbackGlossary(List<String> concepts) {
    return concepts.map(_glossaryForTerm).toList(growable: false);
  }

  GlossaryTermModel _glossaryForTerm(String term) {
    final lower = term.toLowerCase();
    if (lower == 'matter') {
      return const GlossaryTermModel(
        term: 'Matter',
        meaning: 'Anything that has mass and takes up space.',
        example: 'A book, water, and air are examples.',
      );
    }
    if (lower == 'mass') {
      return const GlossaryTermModel(
        term: 'Mass',
        meaning: 'The amount of matter in an object.',
        example: 'Measured in grams or kilograms.',
      );
    }
    if (lower == 'volume') {
      return const GlossaryTermModel(
        term: 'Volume',
        meaning: 'The amount of space something takes up.',
        example: 'Water in a cup has volume.',
      );
    }
    if (lower == 'solid') {
      return const GlossaryTermModel(
        term: 'Solid',
        meaning: 'A state of matter with a fixed shape and fixed volume.',
        example: 'A pencil or stone.',
      );
    }
    if (lower == 'liquid') {
      return const GlossaryTermModel(
        term: 'Liquid',
        meaning:
            'A state of matter with fixed volume that takes the container shape.',
        example: 'Milk or water.',
      );
    }
    if (lower == 'gas') {
      return const GlossaryTermModel(
        term: 'Gas',
        meaning: 'A state of matter that spreads to fill its container.',
        example: 'Air in a balloon.',
      );
    }
    if (lower.contains('property')) {
      return GlossaryTermModel(
        term: term,
        meaning: 'A feature that can be observed or measured.',
        example: 'Shape, size, color, mass, or volume.',
      );
    }
    if (lower.contains('definite')) {
      return GlossaryTermModel(
        term: term,
        meaning:
            'Fixed, clear, or not changing in the situation being described.',
        example: 'A solid has a definite shape.',
      );
    }
    return GlossaryTermModel(
      term: term,
      meaning:
          'A key term from the textbook passage that students should define in simple words.',
      example: 'Ask students to give one local example for $term.',
    );
  }

  String _easyVersion(LessonKitModel kit, List<String> concepts) {
    final existing = kit.easyVersion.trim();
    if (_isUsefulText(existing, minLength: 80)) return existing;
    final main = _conceptAt(concepts, 0, fallback: 'the lesson idea');
    return '$main is the main idea of the lesson. First look at an example, then learn the key words, then explain the idea in your own words. A good answer gives a meaning and one example.';
  }

  List<String> _ensureStrings(Iterable<String> items, {required int minCount}) {
    final result = <String>[];
    final seen = <String>{};
    for (final item in items) {
      final cleaned = item.trim();
      if (!_isUsefulText(cleaned, minLength: 2)) continue;
      final key = cleaned.toLowerCase();
      if (seen.add(key)) result.add(cleaned);
    }
    while (result.length < minCount) {
      final number = result.length + 1;
      result.add(
        'Support step $number: add one more classroom example and ask students to explain it aloud.',
      );
    }
    return result;
  }

  List<String> _ensureConcepts(
    Iterable<String> items, {
    Iterable<String> fillItems = const <String>[],
    required int minCount,
  }) {
    final result = <String>[];
    final seen = <String>{};
    void add(String item) {
      final cleaned = item.trim();
      if (!_isUsefulText(cleaned, minLength: 2)) return;
      if (seen.add(cleaned.toLowerCase())) result.add(cleaned);
    }

    for (final item in items) {
      add(item);
    }
    for (final item in fillItems) {
      if (result.length >= minCount) break;
      add(item);
    }
    while (result.length < minCount) {
      add('Main idea ${result.length + 1}');
    }
    return result;
  }

  List<QuizQuestionModel> _ensureQuiz(
    Iterable<QuizQuestionModel> items, {
    required int minCount,
  }) {
    final result = <QuizQuestionModel>[];
    final seen = <String>{};
    for (final item in items) {
      final question = item.question.trim();
      if (!_isUsefulText(question, minLength: 5)) continue;
      if (seen.add(question.toLowerCase())) {
        result.add(
          item.copyWith(
            question: question,
            expectedAnswer: item.expectedAnswer?.trim(),
          ),
        );
      }
    }
    while (result.length < minCount) {
      final number = result.length + 1;
      result.add(
        QuizQuestionModel(
          question:
              'What is one more example connected to this lesson? ($number)',
          expectedAnswer: 'A correct example with a short explanation.',
        ),
      );
    }
    return result;
  }

  List<GlossaryTermModel> _ensureGlossary(
    Iterable<GlossaryTermModel> items, {
    required int minCount,
  }) {
    final result = <GlossaryTermModel>[];
    final seen = <String>{};
    for (final item in items) {
      final term = item.term.trim();
      final meaning = item.meaning.trim();
      if (!_isUsefulText(term, minLength: 2) ||
          !_isUsefulText(meaning, minLength: 5)) {
        continue;
      }
      if (seen.add(term.toLowerCase())) {
        result.add(
          item.copyWith(
            term: term,
            meaning: meaning,
            example: item.example?.trim(),
          ),
        );
      }
    }
    while (result.length < minCount) {
      final number = result.length + 1;
      result.add(
        GlossaryTermModel(
          term: 'Key word $number',
          meaning:
              'A lesson word that students should explain in simple words.',
          example: 'Use it in one classroom sentence.',
        ),
      );
    }
    return result;
  }

  bool _isUsefulText(String value, {required int minLength}) {
    final text = value.trim();
    if (text.length < minLength) return false;
    final lower = text.toLowerCase();
    return lower != 'n/a' && lower != 'na' && lower != 'none';
  }

  String _titleCase(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _conceptAt(
    List<String> concepts,
    int index, {
    required String fallback,
  }) {
    if (index < 0 || index >= concepts.length) return fallback;
    final value = concepts[index].trim();
    return value.isEmpty ? fallback : value;
  }

  List<String> _comparisonPair(List<String> concepts) {
    const preferredPairs = [
      ['Solid', 'Liquid'],
      ['Liquid', 'Gas'],
      ['Mass', 'Volume'],
      ['Matter', 'Non-matter'],
    ];
    final lowerConcepts = concepts
        .map((concept) => concept.toLowerCase())
        .toSet();
    for (final pair in preferredPairs) {
      final hasFirst = lowerConcepts.contains(pair.first.toLowerCase());
      final hasSecond = pair.last == 'Non-matter'
          ? concepts.any((concept) => concept.toLowerCase() == 'matter')
          : lowerConcepts.contains(pair.last.toLowerCase());
      if (hasFirst && hasSecond) return pair;
    }
    return [
      _conceptAt(concepts, 0, fallback: 'the main idea'),
      _conceptAt(concepts, 1, fallback: 'a related idea'),
    ];
  }
}

class LessonKitDepthTarget {
  const LessonKitDepthTarget({
    required this.label,
    required this.minSourceConcepts,
    required this.minLikelyMisconceptions,
    required this.minTeacherMoves,
    required this.minChecks,
    required this.minObjectives,
    required this.minBlackboardNotes,
    required this.minOralQuiz,
    required this.minHomework,
    required this.minGlossary,
    required this.minSimpleExplanationChars,
    required this.minTotalChars,
  });

  factory LessonKitDepthTarget.forMinutes(int minutes) {
    if (minutes >= 75) {
      return const LessonKitDepthTarget(
        label: 'extended',
        minSourceConcepts: 6,
        minLikelyMisconceptions: 4,
        minTeacherMoves: 9,
        minChecks: 8,
        minObjectives: 4,
        minBlackboardNotes: 9,
        minOralQuiz: 8,
        minHomework: 4,
        minGlossary: 5,
        minSimpleExplanationChars: 900,
        minTotalChars: 4200,
      );
    }
    if (minutes >= 50) {
      return const LessonKitDepthTarget(
        label: 'standard',
        minSourceConcepts: 5,
        minLikelyMisconceptions: 3,
        minTeacherMoves: 6,
        minChecks: 5,
        minObjectives: 3,
        minBlackboardNotes: 6,
        minOralQuiz: 6,
        minHomework: 3,
        minGlossary: 4,
        minSimpleExplanationChars: 650,
        minTotalChars: 3000,
      );
    }
    return const LessonKitDepthTarget(
      label: 'compact',
      minSourceConcepts: 3,
      minLikelyMisconceptions: 2,
      minTeacherMoves: 4,
      minChecks: 4,
      minObjectives: 2,
      minBlackboardNotes: 4,
      minOralQuiz: 4,
      minHomework: 2,
      minGlossary: 3,
      minSimpleExplanationChars: 450,
      minTotalChars: 1900,
    );
  }

  factory LessonKitDepthTarget.forSource({
    required LessonContextModel context,
    required TeachingPackContext teachingPack,
  }) {
    if (!teachingPack.hasTextSource) {
      return LessonKitDepthTarget.forMinutes(context.classDurationMinutes);
    }

    final sourceWords = teachingPack.sourceWordCount;
    final conceptHintCount = teachingPack.sourceConceptHints
        .where((hint) => hint.contains('"'))
        .length;
    final richEnoughForStandard = sourceWords >= 180 && conceptHintCount >= 4;
    final richEnoughForExtended = sourceWords >= 520 && conceptHintCount >= 6;

    if (context.classDurationMinutes >= 75 && richEnoughForExtended) {
      return LessonKitDepthTarget.forMinutes(75);
    }
    if (context.classDurationMinutes >= 50 && richEnoughForStandard) {
      return LessonKitDepthTarget.forMinutes(50);
    }
    return LessonKitDepthTarget.forMinutes(35);
  }

  final String label;
  final int minSourceConcepts;
  final int minLikelyMisconceptions;
  final int minTeacherMoves;
  final int minChecks;
  final int minObjectives;
  final int minBlackboardNotes;
  final int minOralQuiz;
  final int minHomework;
  final int minGlossary;
  final int minSimpleExplanationChars;
  final int minTotalChars;

  bool isSatisfied(LessonKitModel kit) {
    return kit.sourceConcepts.length >= minSourceConcepts &&
        kit.likelyMisconceptions.length >= minLikelyMisconceptions &&
        kit.teacherMoves.length >= minTeacherMoves &&
        kit.checksForUnderstanding.length >= minChecks &&
        kit.learningObjectives.length >= minObjectives &&
        kit.blackboardNotes.length >= minBlackboardNotes &&
        kit.oralQuiz.length >= minOralQuiz &&
        kit.homework.length >= minHomework &&
        kit.glossary.length >= minGlossary &&
        _hasLessonFlow(kit.teacherMoves) &&
        kit.simpleExplanation.trim().length >= minSimpleExplanationChars &&
        score(kit) >= minTotalChars;
  }

  bool _hasLessonFlow(List<String> teacherMoves) {
    final joined = teacherMoves.join(' ').toLowerCase();
    final hasTimedStep = RegExp(
      r'\b\d{1,2}\s*-\s*\d{1,2}\s*min',
    ).hasMatch(joined);
    final hasStartAndClose =
        joined.contains('starter') && joined.contains('close');
    return hasTimedStep || hasStartAndClose;
  }

  int score(LessonKitModel kit) {
    final quizText = kit.oralQuiz
        .map((q) => '${q.question} ${q.expectedAnswer ?? ''}')
        .join(' ');
    final glossaryText = kit.glossary
        .map((g) => '${g.term} ${g.meaning} ${g.example ?? ''}')
        .join(' ');
    return [
      kit.lessonTitle,
      kit.sourceConcepts.join(' '),
      kit.likelyMisconceptions.join(' '),
      kit.teacherMoves.join(' '),
      kit.checksForUnderstanding.join(' '),
      kit.learningObjectives.join(' '),
      kit.simpleExplanation,
      kit.blackboardNotes.join(' '),
      kit.localExample,
      quizText,
      kit.groupActivity,
      kit.homework.join(' '),
      glossaryText,
      kit.easyVersion,
    ].join(' ').trim().length;
  }

  String promptBlock(int minutes) {
    final stepDetail = label == 'extended'
        ? 'Include minute ranges such as "0-10 min" and cover introduction, '
              'guided practice, student practice, review, and exit check.'
        : label == 'compact'
        ? 'Keep this source-grounded; use extra class time for practice and checks, not invented facts.'
        : 'Cover introduction, explanation, practice, and checking.';
    final explanationShape = label == 'extended'
        ? '5-7 short paragraphs'
        : label == 'standard'
        ? '3-5 short paragraphs'
        : '2-3 short paragraphs';

    return '''
Lesson depth target for the uploaded source ($label).
Selected class duration: $minutes minutes. Let the uploaded content control
lesson depth. If the source is short, do not invent extra textbook facts; use
extra class time for practice, examples, checks, and homework review.

- simple_explanation: at least $minSimpleExplanationChars characters, written as $explanationShape.
- learning_objectives: at least $minObjectives specific objectives.
- source_concepts: at least $minSourceConcepts factual ideas or terms visible in the source.
- likely_misconceptions: at least $minLikelyMisconceptions student confusions to check before practice.
- teacher_moves: at least $minTeacherMoves complete blackboard or oral steps. $stepDetail
- checks_for_understanding: at least $minChecks quick oral checks with the expected student response embedded.
- blackboard_notes: at least $minBlackboardNotes board-ready lines in teaching order.
- oral_quiz: at least $minOralQuiz questions with expected_answer.
- homework: at least $minHomework useful tasks, not just "read the chapter".
- glossary: at least $minGlossary terms when the source provides enough vocabulary.
- group_activity and local_example: make both concrete enough for a teacher to use immediately.
''';
  }
}
