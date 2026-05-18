import 'package:chalk_lens/core/model/reasoning_trace_sanitizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReasoningTraceFilter', () {
    test('holds a chunked prompt echo and then emits actual reasoning', () {
      const prompt = '''
Active lesson:
Title: Water cycle
Grade: Grade 5

Student question: Where does rain come from?
''';
      final filter = ReasoningTraceFilter(promptEchoes: const [prompt]);

      expect(filter.add('Active lesson:\nTitle: Water'), isEmpty);
      expect(
        filter.add(
          ' cycle\nGrade: Grade 5\n\nStudent question: Where does rain come from?',
        ),
        isEmpty,
      );

      expect(
        filter.add('\nI should answer using evaporation and condensation.'),
        'I should answer using evaporation and condensation.',
      );
    });

    test('strips system-wrapped prompt echoes', () {
      const systemPrompt = 'You are ChalkLens Student Help.';
      const userPrompt = 'Student question: How do plants make food?';
      const wrappedPrompt = '[System: $systemPrompt]\n\n$userPrompt';
      final filter = ReasoningTraceFilter(
        promptEchoes: const [systemPrompt, userPrompt, wrappedPrompt],
      );

      expect(filter.add('[System: You are ChalkLens Student Help.]'), isEmpty);
      expect(
        filter.add('\n\nStudent question: How do plants make food?'),
        isEmpty,
      );
      expect(
        filter.add(
          '\nUse photosynthesis vocabulary, then ask a check question.',
        ),
        'Use photosynthesis vocabulary, then ask a check question.',
      );
    });

    test('keeps real reasoning that references the active lesson', () {
      final filter = ReasoningTraceFilter(
        promptEchoes: const ['Student question: How do plants make food?'],
      );

      expect(
        filter.add('Use the active lesson and keep the answer short.'),
        'Use the active lesson and keep the answer short.',
      );
    });
  });

  group('InlineReasoningSplitter', () {
    test('separates inline think tags from answer text', () {
      final splitter = InlineReasoningSplitter();

      final split = splitter.add(
        '<think>Check the lesson source first.</think>{"lesson_title":"Plants"}',
      );

      expect(split.reasoning, 'Check the lesson source first.');
      expect(split.text, '{"lesson_title":"Plants"}');
      expect(splitter.flush().isEmpty, isTrue);
    });

    test('holds partial marker tokens until the marker is complete', () {
      final splitter = InlineReasoningSplitter();

      expect(splitter.add('<thi').isEmpty, isTrue);
      expect(
        splitter.add('nk>Plan carefully</thi').reasoning,
        'Plan carefully',
      );
      final split = splitter.add('nk>Final answer');

      expect(split.reasoning, isEmpty);
      expect(split.text, 'Final answer');
    });

    test('supports Gemma channel markers', () {
      final splitter = InlineReasoningSplitter();

      final split = splitter.add(
        '<|channel>thought\nUse the glossary.<channel|>Student answer',
      );

      expect(split.reasoning, 'Use the glossary.');
      expect(split.text, 'Student answer');
    });
  });
}
