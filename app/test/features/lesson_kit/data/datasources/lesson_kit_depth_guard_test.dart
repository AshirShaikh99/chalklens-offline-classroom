import 'package:chalk_lens/core/constants/languages.dart';
import 'package:chalk_lens/features/lesson_kit/data/datasources/lesson_kit_depth_guard.dart';
import 'package:chalk_lens/features/lesson_kit/data/datasources/local_teaching_pack.dart';
import 'package:chalk_lens/features/lesson_kit/data/models/glossary_term_model.dart';
import 'package:chalk_lens/features/lesson_kit/data/models/lesson_context_model.dart';
import 'package:chalk_lens/features/lesson_kit/data/models/lesson_kit_model.dart';
import 'package:chalk_lens/features/lesson_kit/data/models/quiz_question_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const context = LessonContextModel(
    grade: 'Class 7',
    subject: 'Science',
    language: AppLanguage.english,
    classDurationMinutes: 50,
  );

  test('expands a tiny salvaged kit to match source depth', () {
    const guard = LessonKitDepthGuard();
    final teachingPack = const LocalTeachingPack().build(
      context: context,
      passage: '''
Matter has mass and occupies space. Solids have definite shape and volume.
Liquids have definite volume but take the shape of their container.
Gases do not have definite shape or definite volume.
''',
    );
    const shortKit = LessonKitModel(
      lessonTitle: 'Science lesson',
      grade: 'Class 7',
      subject: 'Science',
      language: AppLanguage.english,
      sourceConcepts: ['Matter', 'Definite', 'Properties', 'Liquid'],
      likelyMisconceptions: [
        'Check whether students confuse observation with explanation.',
      ],
      teacherMoves: [
        'Use one blackboard-friendly sequence for a 50-minute class.',
      ],
      checksForUnderstanding: [
        'Ask one student to explain Matter in their own words.',
      ],
      simpleExplanation: 'Science lesson',
    );
    final logs = <String>[];

    final expanded = guard.expandIfTooShort(
      kit: shortKit,
      context: context,
      teachingPack: teachingPack,
      log: logs.add,
    );
    final target = LessonKitDepthTarget.forSource(
      context: context,
      teachingPack: teachingPack,
    );

    expect(target.label, 'compact');
    expect(target.isSatisfied(expanded), isTrue);
    expect(expanded.lessonTitle, 'Introduction to Matter');
    expect(expanded.sourceConcepts, isNot(contains('Definite')));
    expect(expanded.sourceConcepts, isNot(contains('Example')));
    expect(expanded.simpleExplanation.length, greaterThanOrEqualTo(450));
    expect(expanded.teacherMoves.length, greaterThanOrEqualTo(4));
    expect(expanded.teacherMoves.first, startsWith('0-5 min'));
    expect(expanded.oralQuiz.length, greaterThanOrEqualTo(4));
    expect(expanded.homework.length, greaterThanOrEqualTo(2));
    expect(expanded.glossary.length, greaterThanOrEqualTo(3));
    expect(expanded.teacherMoves.join(' '), isNot(contains('50-minute class')));
    expect(logs.single, contains('too short for the uploaded content'));
  });

  test('turns a rich matter source into a clear start to end lesson flow', () {
    const guard = LessonKitDepthGuard();
    final teachingPack = const LocalTeachingPack().build(
      context: context,
      passage: List.filled(8, '''
Matter has mass and occupies space. Mass is the amount of matter in an object.
Volume is the space occupied by matter. Solids have definite shape and volume.
Liquids have definite volume but take the shape of their container. Gases do
not have definite shape or definite volume. Particles are close in solids,
can slide in liquids, and move freely in gases.
''').join(' '),
    );
    const shortKit = LessonKitModel(
      lessonTitle: 'Science lesson',
      grade: 'Class 7',
      subject: 'Science',
      language: AppLanguage.english,
      sourceConcepts: [
        'Matter',
        'Definite',
        'Properties',
        'Liquid',
        'Volume',
        'Water',
        'Example',
        'Particles',
      ],
      teacherMoves: [
        'Use one blackboard-friendly sequence for a 50-minute class.',
        'Start from a concrete example before naming the formal idea.',
        'Observation activity using classroom objects or the environment.',
      ],
      simpleExplanation: 'Science lesson',
    );

    final expanded = guard.expandIfTooShort(
      kit: shortKit,
      context: context,
      teachingPack: teachingPack,
    );
    final teacherMoves = expanded.teacherMoves.join(' ');
    final allText = [
      ...expanded.teacherMoves,
      ...expanded.checksForUnderstanding,
      ...expanded.blackboardNotes,
      ...expanded.oralQuiz.map((question) => question.question),
    ].join(' ');

    expect(
      LessonKitDepthTarget.forSource(
        context: context,
        teachingPack: teachingPack,
      ).label,
      'standard',
    );
    expect(expanded.sourceConcepts.take(6), [
      'Matter',
      'Mass',
      'Volume',
      'Solid',
      'Liquid',
      'Gas',
    ]);
    expect(teacherMoves, contains('0-5 min Starter'));
    expect(teacherMoves, contains('43-50 min Close'));
    expect(teacherMoves, isNot(contains('blackboard-friendly sequence')));
    expect(allText, isNot(contains('Matter and Definite')));
    expect(allText, isNot(contains('Matter vs Definite')));
    expect(expanded.simpleExplanation, contains('Matter is anything'));
  });

  test('keeps a sufficiently deep kit unchanged', () {
    const guard = LessonKitDepthGuard();
    final teachingPack = const LocalTeachingPack().build(
      context: context,
      passage: 'Matter mass volume solid liquid gas',
    );
    final deepKit = LessonKitModel(
      lessonTitle: 'Introduction to Matter',
      grade: 'Class 7',
      subject: 'Science',
      language: AppLanguage.english,
      sourceConcepts: const ['Matter', 'Mass', 'Volume', 'Solid', 'Liquid'],
      likelyMisconceptions: const [
        'Students may think only solids are matter.',
        'Students may confuse mass and volume.',
        'Students may forget air is matter.',
      ],
      teacherMoves: const [
        '0-5 min: Show classroom examples.',
        '5-10 min: Write key words.',
        '10-18 min: Explain the definition.',
        '18-28 min: Compare examples.',
        '28-40 min: Ask oral checks.',
        '40-50 min: Summarize and assign homework.',
      ],
      checksForUnderstanding: const [
        'What is matter? expected: has mass and occupies space.',
        'Is air matter? expected: yes.',
        'What is mass? expected: amount of matter.',
        'What is volume? expected: space occupied.',
        'Name a liquid. expected: water or milk.',
      ],
      learningObjectives: const [
        'Define matter.',
        'Identify examples of matter.',
        'Compare states of matter.',
      ],
      simpleExplanation: List.filled(
        30,
        'Matter has mass and occupies space, so students compare examples before copying the definition.',
      ).join(' '),
      blackboardNotes: const [
        'Matter: mass and volume',
        'Mass: amount of matter',
        'Volume: space occupied',
        'Solid: fixed shape',
        'Liquid: container shape',
        'Gas: fills container',
      ],
      oralQuiz: const [
        QuizQuestionModel(question: 'What is matter?'),
        QuizQuestionModel(question: 'What is mass?'),
        QuizQuestionModel(question: 'What is volume?'),
        QuizQuestionModel(question: 'Give one solid.'),
        QuizQuestionModel(question: 'Give one liquid.'),
        QuizQuestionModel(question: 'Give one gas.'),
      ],
      groupActivity:
          'Students compare a book, water, and air in a balloon using a board table and then explain one difference aloud.',
      homework: const [
        'Define matter.',
        'Give three examples.',
        'Compare solid and liquid.',
      ],
      glossary: const [
        GlossaryTermModel(term: 'Matter', meaning: 'Has mass and space.'),
        GlossaryTermModel(term: 'Mass', meaning: 'Amount of matter.'),
        GlossaryTermModel(term: 'Volume', meaning: 'Space occupied.'),
        GlossaryTermModel(term: 'Liquid', meaning: 'Takes container shape.'),
      ],
      easyVersion:
          'Matter is anything with mass and space. Use examples, compare them, and explain the difference in your own words.',
    );

    final expanded = guard.expandIfTooShort(
      kit: deepKit,
      context: context,
      teachingPack: teachingPack,
    );

    expect(identical(expanded, deepKit), isTrue);
  });

  test('repairs a drifted class 1 short a kit back to phonics', () {
    const guard = LessonKitDepthGuard();
    const englishContext = LessonContextModel(
      grade: 'Class 1',
      subject: 'English',
      language: AppLanguage.english,
      classDurationMinutes: 50,
    );
    final teachingPack = const LocalTeachingPack().build(
      context: englishContext,
      passage:
          'Class 1 English. Lesson: The Short A Sound. The short a sound is '
          'heard in words like cat, mat, hat, bag, fan, and apple. Word Bank: '
          'cat mat hat bag fan jam cap map apple. Simple Sentences: A cat is '
          'on the mat. Quick Questions: Which sound do you hear in cat?',
    );
    final driftedKit = LessonKitModel(
      lessonTitle: 'Introduction to Sound',
      grade: 'Class 1',
      subject: 'English',
      language: AppLanguage.english,
      sourceConcepts: const [
        'Sound',
        'Short',
        'Sentence',
        'Apple',
        'Simple',
        'Students',
        'Words',
        'Picture',
      ],
      likelyMisconceptions: const [
        'Check whether students can explain Sound in their own words.',
        'Check whether students confuse two related key words from the lesson.',
      ],
      teacherMoves: const [
        '0-5 min: Hold up a familiar classroom example and ask what students notice.',
        '5-10 min: Write the lesson title and key words on the board.',
        '10-18 min: Read the source idea aloud in short parts.',
        '18-28 min: Compare Sound and Short using a two-column board table.',
        '28-36 min: Run a predict-observe-explain moment.',
      ],
      checksForUnderstanding: const [
        'Explain Sound in your own words.',
        'Give one local example of Sound.',
        'How is Sound different from Short?',
        'What word from the board is most important today?',
      ],
      learningObjectives: const [
        'Students can define Sound.',
        'Students can give one example.',
      ],
      simpleExplanation: '''
Introduction to Sound begins with Sound, but it should be taught as a sequence, not as one short definition. The teacher first shows a concrete example, asks students what they observe, and then connects those observations to the textbook words: Sound, Short, Sentence, Apple, Simple, Students.

Use one familiar object, situation, or sentence from the classroom so students meet the idea before they copy the formal words. The middle of the lesson should help students compare ideas, sort examples, explain differences, and correct everyday meanings that do not match the science or textbook meaning.

By the end, students should be able to define Sound, give a local example, answer quick oral questions, and copy a clean set of board notes. The final minutes should be used for an exit question and homework so the teacher can see whether students can use the key ideas without help.
''',
      blackboardNotes: const [
        'Introduction to Sound',
        'Today\'s question: What does Sound mean?',
        'Key words: Sound, Short, Sentence, Apple, Simple, Students',
        'Compare: Sound vs Short',
      ],
      localExample:
          'Use one object, place, or routine from the classroom and ask students to connect it to Sound and Short.',
      oralQuiz: const [
        QuizQuestionModel(question: 'What does Sound mean in this lesson?'),
        QuizQuestionModel(question: 'Give one example of Sound.'),
        QuizQuestionModel(question: 'How is Sound different from Short?'),
        QuizQuestionModel(question: 'What was one observation?'),
      ],
      groupActivity:
          'In pairs, students choose one local example for Sound, explain it, then compare with another pair.',
      homework: const [
        'Write the meaning of Sound in your own words.',
        'Choose three key words and use each in a sentence.',
      ],
      glossary: const [
        GlossaryTermModel(term: 'Sound', meaning: 'A key term.'),
        GlossaryTermModel(term: 'Short', meaning: 'A key term.'),
        GlossaryTermModel(term: 'Sentence', meaning: 'A key term.'),
      ],
      easyVersion:
          'Sound is the main idea of the lesson. First look at an example, then explain the idea.',
    );
    final logs = <String>[];

    final expanded = guard.expandIfTooShort(
      kit: driftedKit,
      context: englishContext,
      teachingPack: teachingPack,
      log: logs.add,
    );

    expect(expanded.lessonTitle, 'The Short A Sound');
    expect(expanded.sourceConcepts.take(5), [
      'Short a sound',
      '/a/',
      'Short a words',
      'Cat',
      'Mat',
    ]);
    expect(expanded.sourceConcepts, isNot(contains('Sound')));
    expect(expanded.simpleExplanation, contains('English phonics lesson'));
    expect(expanded.simpleExplanation, contains('cat, mat, hat'));
    expect(expanded.teacherMoves.first, contains('cat, mat, hat'));
    expect(expanded.teacherMoves, hasLength(7));
    expect(
      expanded.teacherMoves.where((move) => move.startsWith('0-5 min')),
      hasLength(1),
    );
    expect(expanded.teacherMoves.join(' '), isNot(contains('local example')));
    expect(
      expanded.checksForUnderstanding.first,
      contains('Which sound do you hear in cat?'),
    );
    expect(expanded.checksForUnderstanding, hasLength(6));
    expect(
      expanded.checksForUnderstanding.join(' '),
      isNot(contains('How is Short A Sound connected')),
    );
    expect(
      expanded.likelyMisconceptions.join(' '),
      isNot(contains('grammar labels')),
    );
    expect(expanded.blackboardNotes, contains('Sound: /a/'));
    expect(expanded.homework.first, contains('Write five short a words'));
    expect(expanded.glossary.first.meaning, contains('/a/ vowel sound'));
    expect(
      expanded.easyVersion,
      'Short a is the /a/ sound in words like cat, mat, hat, bag, and fan. '
      'Say the sound, read the word slowly, then use one word in a simple sentence.',
    );
    expect(logs.single, contains('drifted from the uploaded phonics source'));
  });

  test('repairs a complete but ungrounded kit using pdf key terms', () {
    const guard = LessonKitDepthGuard();
    const englishContext = LessonContextModel(
      grade: 'Class 2',
      subject: 'English',
      language: AppLanguage.english,
      classDurationMinutes: 50,
    );
    final teachingPack = const LocalTeachingPack().build(
      context: englishContext,
      passage:
          'Lesson: Naming Words. Naming words are names of people, places, '
          'animals, and things. Word Bank: boy school dog book. '
          'Sentence: The boy reads a book.',
    );
    final ungroundedKit = LessonKitModel(
      lessonTitle: 'Introduction to Sound',
      grade: 'Class 2',
      subject: 'English',
      language: AppLanguage.english,
      sourceConcepts: const ['Sound', 'Short', 'Sentence', 'Apple', 'Simple'],
      likelyMisconceptions: const [
        'Students may confuse sound with short.',
        'Students may not use Sound in a new sentence.',
        'Students may repeat the textbook words.',
      ],
      teacherMoves: const [
        '0-5 min: Show a classroom object.',
        '5-10 min: Write key words on the board.',
        '10-18 min: Read the source idea aloud.',
        '18-28 min: Compare Sound and Short.',
        '28-40 min: Ask oral checks.',
        '40-50 min: Give homework.',
      ],
      checksForUnderstanding: const [
        'Explain Sound in your own words.',
        'Give one local example of Sound.',
        'How is Sound different from Short?',
        'Use Sound in a sentence.',
        'What mistake should we avoid?',
      ],
      learningObjectives: const [
        'Define Sound.',
        'Give an example of Sound.',
        'Use Sound in a sentence.',
      ],
      simpleExplanation: List.filled(
        25,
        'Sound is the main idea, so students observe a familiar example, explain it, and copy board notes.',
      ).join(' '),
      blackboardNotes: const [
        'Introduction to Sound',
        'Sound: write the textbook meaning.',
        'Compare: Sound vs Short',
        'Exit check: explain Sound.',
      ],
      localExample:
          'Use one classroom object and ask students to connect it to Sound.',
      oralQuiz: const [
        QuizQuestionModel(question: 'What does Sound mean?'),
        QuizQuestionModel(question: 'Give one example of Sound.'),
        QuizQuestionModel(question: 'How is Sound different from Short?'),
        QuizQuestionModel(question: 'Use Sound in a sentence.'),
        QuizQuestionModel(question: 'What mistake should we avoid?'),
      ],
      groupActivity:
          'Students choose one local example for Sound and explain it in pairs.',
      homework: const [
        'Write the meaning of Sound.',
        'Use three key words in sentences.',
        'Draw one example of Sound.',
      ],
      glossary: const [
        GlossaryTermModel(term: 'Sound', meaning: 'A key term.'),
        GlossaryTermModel(term: 'Short', meaning: 'A key term.'),
        GlossaryTermModel(term: 'Sentence', meaning: 'A key term.'),
        GlossaryTermModel(term: 'Apple', meaning: 'A key term.'),
      ],
      easyVersion: 'Sound is the main idea. Give a meaning and one example.',
    );
    final logs = <String>[];

    final expanded = guard.expandIfTooShort(
      kit: ungroundedKit,
      context: englishContext,
      teachingPack: teachingPack,
      log: logs.add,
    );

    expect(expanded.lessonTitle, 'Introduction to Naming Words');
    expect(expanded.sourceConcepts.take(5), [
      'Naming Words',
      'Boy',
      'School',
      'Dog',
      'Book',
    ]);
    expect(expanded.sourceConcepts, isNot(contains('Sound')));
    expect(expanded.simpleExplanation, contains('Naming Words'));
    expect(expanded.blackboardNotes.first, 'Introduction to Naming Words');
    expect(expanded.teacherMoves.join(' '), isNot(contains('Sound and Short')));
    expect(
      expanded.checksForUnderstanding.join(' '),
      isNot(contains('Explain Sound')),
    );
    expect(expanded.homework.join(' '), isNot(contains('Sound')));
    expect(
      expanded.glossary.map((term) => term.term),
      isNot(contains('Sound')),
    );
    expect(logs.single, contains('drifted from the uploaded source text'));
  });
}
