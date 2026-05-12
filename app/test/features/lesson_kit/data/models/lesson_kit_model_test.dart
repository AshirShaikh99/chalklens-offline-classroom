import 'package:chalk_lens/core/constants/languages.dart';
import 'package:chalk_lens/features/lesson_kit/data/models/lesson_kit_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses innovation grounding fields from Gemma JSON', () {
    final model = LessonKitModel.fromJson({
      'lesson_title': 'Water Cycle',
      'grade': 'Grade 5',
      'subject': 'Science',
      'language': 'en',
      'source_concepts': ['evaporation', 'condensation'],
      'likely_misconceptions': ['Clouds are smoke'],
      'teacher_moves': ['Start with wet clothes drying in sunlight'],
      'checks_for_understanding': ['Where does water vapor go?'],
      'learning_objectives': ['Explain evaporation'],
      'simple_explanation': 'Water moves between land, air, and clouds.',
      'blackboard_notes': ['Heat changes water into vapor'],
      'local_example': 'Wet clothes dry faster in sunlight.',
      'oral_quiz': [
        {
          'question': 'What is evaporation?',
          'expected_answer': 'Liquid water changing into vapor',
        },
      ],
      'group_activity': 'Draw the water cycle.',
      'homework': ['Find one example of evaporation at home.'],
      'glossary': [
        {'term': 'Evaporation', 'meaning': 'Liquid water changes into vapor.'},
      ],
      'easy_version': 'Water can go up into air as vapor.',
      'confidence': 0.86,
    });

    expect(model.language, AppLanguage.english);
    expect(model.sourceConcepts, ['evaporation', 'condensation']);
    expect(model.likelyMisconceptions, ['Clouds are smoke']);
    expect(model.teacherMoves, ['Start with wet clothes drying in sunlight']);
    expect(model.checksForUnderstanding, ['Where does water vapor go?']);

    final entity = model.toEntity();
    expect(entity.sourceConcepts, model.sourceConcepts);
    expect(entity.checksForUnderstanding, model.checksForUnderstanding);
  });
}
