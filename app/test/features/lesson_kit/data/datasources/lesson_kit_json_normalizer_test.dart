import 'package:chalk_lens/core/constants/languages.dart';
import 'package:chalk_lens/features/lesson_kit/data/datasources/lesson_kit_json_normalizer.dart';
import 'package:chalk_lens/features/lesson_kit/data/models/lesson_context_model.dart';
import 'package:chalk_lens/features/lesson_kit/data/models/lesson_kit_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const context = LessonContextModel(
    grade: 'Grade 5',
    subject: 'Science',
    language: AppLanguage.english,
    classDurationMinutes: 50,
  );

  test('normalizes loose Gemma JSON into LessonKit schema', () {
    final normalized = LessonKitJsonNormalizer.normalize({
      'lessonTitle': 'Water Cycle',
      'class': 'Class 5',
      'language': 'English',
      'keyIdeas': 'Evaporation\nCondensation',
      'objectives': ['Explain evaporation', 42],
      'simpleExplanation': {'text': 'Water moves through the air.'},
      'blackboardNotes': '1. Draw sun\n2. Draw clouds',
      'quiz': [
        {'q': 'What heats water?', 'answer': 'The sun'},
        'What forms clouds?',
      ],
      'terms': [
        'Evaporation: liquid water becomes vapor',
        {'word': 'Condensation', 'definition': 'Vapor becomes drops'},
      ],
      'confidence': '85%',
    }, context: context);

    final kit = LessonKitModel.fromJson(normalized);

    expect(kit.lessonTitle, 'Water Cycle');
    expect(kit.grade, 'Class 5');
    expect(kit.language, AppLanguage.english);
    expect(kit.sourceConcepts, ['Evaporation', 'Condensation']);
    expect(kit.learningObjectives, ['Explain evaporation', '42']);
    expect(kit.blackboardNotes, ['Draw sun', 'Draw clouds']);
    expect(kit.oralQuiz.first.expectedAnswer, 'The sun');
    expect(kit.oralQuiz.last.question, 'What forms clouds?');
    expect(kit.glossary.first.term, 'Evaporation');
    expect(kit.confidence, 0.85);
  });

  test('fills required fields from context when model omits them', () {
    final normalized = LessonKitJsonNormalizer.normalize({
      'concepts': ['Plants need sunlight'],
    }, context: context);

    final kit = LessonKitModel.fromJson(normalized);

    expect(kit.lessonTitle, 'Science lesson');
    expect(kit.grade, 'Grade 5');
    expect(kit.subject, 'Science');
    expect(kit.language, AppLanguage.english);
    expect(kit.simpleExplanation, contains('Plants need sunlight'));
  });
}
