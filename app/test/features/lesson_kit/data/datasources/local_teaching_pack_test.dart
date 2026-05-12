import 'package:chalk_lens/core/constants/languages.dart';
import 'package:chalk_lens/features/lesson_kit/data/datasources/local_teaching_pack.dart';
import 'package:chalk_lens/features/lesson_kit/data/models/lesson_context_model.dart';
import 'package:chalk_lens/features/lesson_kit/domain/entities/student_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds an offline prompt block from source text and class context', () {
    const pack = LocalTeachingPack();

    final context = LessonContextModel(
      grade: 'Grade 5',
      subject: 'Science',
      language: AppLanguage.english,
      classDurationMinutes: 35,
      studentLevel: StudentLevel.standard,
    );

    final result = pack.build(
      context: context,
      passage:
          'Evaporation happens when heat changes liquid water into water vapor. '
          'Condensation happens when vapor cools.',
    );

    final prompt = result.toPromptBlock();

    expect(prompt, contains('OFFLINE TEACHING PACK'));
    expect(prompt, contains('Retrieved locally for Grade 5 Science'));
    expect(prompt, contains('Check whether "evaporation"'));
    expect(prompt, contains('Observation activity'));
    expect(prompt, contains('Misconception checks'));
  });

  test('keeps image-only grounding explicit when no passage is pasted', () {
    const pack = LocalTeachingPack();

    final context = LessonContextModel(
      grade: 'Grade 3',
      subject: 'Math',
      language: AppLanguage.english,
      classDurationMinutes: 25,
      studentLevel: StudentLevel.easy,
    );

    final result = pack.build(context: context);

    expect(
      result.sourceConceptHints.single,
      'Image-only source: extract concepts from the visible textbook page.',
    );
    expect(
      result.pedagogyRules,
      contains('Keep sentences short for students who need extra support.'),
    );
    expect(result.activityTemplates.join(' '), contains('stones'));
  });
}
