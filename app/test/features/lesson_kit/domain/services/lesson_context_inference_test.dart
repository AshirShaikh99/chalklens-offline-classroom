import 'package:chalk_lens/core/constants/languages.dart';
import 'package:chalk_lens/features/lesson_kit/domain/services/lesson_context_inference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('infers class and subject from a source header', () {
    final context = LessonContextInference.fromSource(
      sourceText: '''
Class 7 Science
Lesson: Particles in Matter
Matter is anything that has mass and occupies space.
''',
    );

    expect(context.grade, 'Class 7');
    expect(context.subject, 'Science');
    expect(context.language, AppLanguage.english);
    expect(context.classDurationMinutes, 50);
  });

  test('infers grade style and math subject from topic vocabulary', () {
    final context = LessonContextInference.fromSource(
      sourceText: '''
Grade 5
Equivalent Fractions
A fraction has a numerator and denominator.
Calculate which fractions are equal.
''',
    );

    expect(context.grade, 'Grade 5');
    expect(context.subject, 'Math');
  });

  test('uses neutral fallbacks when the page has no context clues', () {
    final context = LessonContextInference.fromSource(
      sourceText: 'Read the passage carefully and answer the questions.',
    );

    expect(context.grade, 'Class from source');
    expect(context.subject, 'Subject from source');
  });
}
