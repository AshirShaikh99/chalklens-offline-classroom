import 'package:chalk_lens/core/constants/languages.dart';
import 'package:chalk_lens/features/lesson_kit/data/datasources/lesson_kit_recovery_builder.dart';
import 'package:chalk_lens/features/lesson_kit/data/datasources/local_teaching_pack.dart';
import 'package:chalk_lens/features/lesson_kit/data/models/lesson_context_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const context = LessonContextModel(
    grade: 'Class 7',
    subject: 'Science',
    language: AppLanguage.english,
    classDurationMinutes: 50,
  );

  test('recovers a classroom kit when Gemma emits malformed lesson JSON', () {
    const passage = '''
Matter has mass and occupies space. Solids have definite shape and volume.
Liquids have definite volume but take the shape of their container. Gases
have neither definite shape nor definite volume. Mass and volume are physical
properties of matter.
''';
    final teachingPack = const LocalTeachingPack().build(
      context: context,
      passage: passage,
    );
    const rawOutput = '''
{
  "lesson_title": "Introduction to Matter",
  "source_concepts": [
    "Matter",
    "Mass",
    "Volume",
    "Solid",
    "Liquid",
    "Gas"
  ],
  "simple_explanation": "Matter is anything that has mass and takes up space.",
  "blackboard_notes": [
    "Matter: Has Mass & Volume",
    "Examples: Solids, Liquids, Gases"Not Matter: Light, Sound, Heat"
    "States of Matter:"
    Solids: Definite Shape & Volume"
  ],
''';

    final kit = const LessonKitRecoveryBuilder().build(
      context: context,
      teachingPack: teachingPack,
      rawOutput: rawOutput,
    );

    expect(kit.lessonTitle, 'Introduction to Matter');
    expect(kit.sourceConcepts, containsAll(['Matter', 'Mass', 'Volume']));
    expect(kit.simpleExplanation, contains('mass'));
    expect(kit.teacherMoves.first, startsWith('0-'));
    expect(kit.teacherMoves, hasLength(greaterThanOrEqualTo(6)));
    expect(kit.blackboardNotes, contains(contains('Today')));
    expect(kit.oralQuiz, hasLength(greaterThanOrEqualTo(5)));
    expect(kit.homework, hasLength(greaterThanOrEqualTo(3)));
  });
}
