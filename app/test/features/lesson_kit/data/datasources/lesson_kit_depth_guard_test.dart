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
}
