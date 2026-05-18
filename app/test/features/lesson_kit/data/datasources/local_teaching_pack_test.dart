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

  test('recognizes short a phonics terms from class 1 English text', () {
    const pack = LocalTeachingPack();

    final context = LessonContextModel(
      grade: 'Class 1',
      subject: 'English',
      language: AppLanguage.english,
      classDurationMinutes: 50,
      studentLevel: StudentLevel.standard,
    );

    final result = pack.build(
      context: context,
      passage:
          'Lesson: The Short A Sound. The short a sound is heard in words '
          'like cat, mat, hat, bag, fan, and apple. Word Bank: cat mat hat '
          'bag fan jam cap map apple. Simple Sentences: A cat is on the mat.',
    );

    expect(
      result.sourceConceptHints,
      contains('Check whether "short a sound" is a key source concept.'),
    );
    expect(
      result.sourceConceptHints,
      contains('Check whether "/a/" is a key source concept.'),
    );
    expect(
      result.sourceConceptHints,
      contains('Check whether "cat" is a key source concept.'),
    );
    expect(
      result.sourceConceptHints,
      contains('Check whether "mat" is a key source concept.'),
    );
    expect(
      result.sourceConceptHints,
      isNot(contains('Check whether "students" is a key source concept.')),
    );
  });
}
