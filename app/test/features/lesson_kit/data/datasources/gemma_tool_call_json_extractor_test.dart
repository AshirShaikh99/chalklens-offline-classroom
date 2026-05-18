import 'dart:convert';

import 'package:chalk_lens/features/lesson_kit/data/datasources/gemma_tool_call_json_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const extractor = GemmaToolCallJsonExtractor(toolName: 'submit_lesson_kit');

  group('GemmaToolCallJsonExtractor', () {
    test('extracts direct lesson_kit_json function argument', () {
      final result = extractor.fromFunctionArgs({
        'lesson_kit_json': '{"lesson_title":"Fractions"}',
      });

      expect(result, '{"lesson_title":"Fractions"}');
    });

    test('extracts direct lesson kit function arguments', () {
      final result = extractor.fromFunctionArgs({
        'lesson_title': 'Fractions',
        'grade': 'Class 5',
        'source_concepts': ['Equal parts', '<|"|>Numerator<|"|>'],
      });

      expect(jsonDecode(result!) as Map<String, dynamic>, {
        'lesson_title': 'Fractions',
        'grade': 'Class 5',
        'source_concepts': ['Equal parts', 'Numerator'],
      });
    });

    test('extracts lesson_kit_json map argument', () {
      final result = extractor.fromFunctionArgs({
        'lesson_kit_json': {
          'lesson_title': 'Plants',
          'grade': '<|"|>Class 3<|"|>',
        },
      });

      expect(jsonDecode(result!) as Map<String, dynamic>, {
        'lesson_title': 'Plants',
        'grade': 'Class 3',
      });
    });

    test('extracts native Gemma 4 tool call text', () {
      const raw = '''
<|channel|>analysis
Thinking about the page.
<|tool_call>call:submit_lesson_kit{
  lesson_title:<|"|>Evaporation<|"|>,
  grade:<|"|>Grade 5<|"|>,
  source_concepts:[<|"|>Liquid water changes into vapor<|"|>,<|"|>Heat gives energy<|"|>],
  oral_quiz:[{question:<|"|>What is evaporation?<|"|>,expected_answer:<|"|>Liquid water changing to vapor.<|"|>}],
  confidence:0.82
}<tool_call|><|tool_response>
''';

      final result = extractor.fromText(raw);

      expect(jsonDecode(result!) as Map<String, dynamic>, {
        'lesson_title': 'Evaporation',
        'grade': 'Grade 5',
        'source_concepts': [
          'Liquid water changes into vapor',
          'Heat gives energy',
        ],
        'oral_quiz': [
          {
            'question': 'What is evaporation?',
            'expected_answer': 'Liquid water changing to vapor.',
          },
        ],
        'confidence': 0.82,
      });
    });

    test('ignores native Gemma 4 calls for a different tool', () {
      const raw =
          '<|tool_call>call:other_tool{lesson_title:<|"|>Wrong<|"|>}<tool_call|>';

      expect(extractor.fromText(raw), isNull);
    });

    test('extracts OpenAI-style string arguments from raw SDK response', () {
      final arguments = jsonEncode({
        'lesson_kit_json': '{"lesson_title":"Water","grade":"Class 4"}',
      });
      final raw = jsonEncode({
        'role': 'assistant',
        'tool_calls': [
          {
            'type': 'function',
            'function': {'name': 'submit_lesson_kit', 'arguments': arguments},
          },
        ],
      });

      final result = extractor.fromSdkRawResponse(raw);

      expect(result, '{"lesson_title":"Water","grade":"Class 4"}');
    });

    test('extracts map arguments from raw SDK response', () {
      final raw = jsonEncode({
        'tool_calls': [
          {
            'name': 'submit_lesson_kit',
            'arguments': {
              'lesson_kit': {'lesson_title': 'Plants', 'grade': 'Class 3'},
            },
          },
        ],
      });

      final result = extractor.fromSdkRawResponse(raw);

      expect(jsonDecode(result!) as Map<String, dynamic>, {
        'lesson_title': 'Plants',
        'grade': 'Class 3',
      });
    });

    test('ignores other tool calls', () {
      final raw = jsonEncode({
        'tool_calls': [
          {
            'name': 'other_tool',
            'arguments': {'lesson_kit_json': '{"lesson_title":"Wrong"}'},
          },
        ],
      });

      expect(extractor.fromSdkRawResponse(raw), isNull);
    });
  });
}
