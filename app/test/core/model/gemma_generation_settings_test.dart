import 'package:chalk_lens/core/model/gemma_generation_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults match the Gemma 4 sampling baseline', () {
    expect(GemmaGenerationSettings.defaults.temperature, 1.0);
    expect(GemmaGenerationSettings.defaults.topK, 64);
    expect(GemmaGenerationSettings.defaults.topP, 0.95);
    expect(GemmaGenerationSettings.defaults.randomSeed, 1);
    expect(GemmaGenerationSettings.defaults.thinkingMode, isTrue);
  });

  test('response profile follows sampling controls', () {
    expect(
      const GemmaGenerationSettings(
        temperature: 0.3,
        topK: 24,
        topP: 0.82,
      ).responseProfile,
      'Stable',
    );
    expect(
      const GemmaGenerationSettings(
        temperature: 1.2,
        topK: 64,
        topP: 0.95,
      ).responseProfile,
      'Exploratory',
    );
    expect(
      GemmaGenerationSettings.defaults.responseProfile,
      'Balanced classroom',
    );
  });

  test('copyWith keeps unchanged fields', () {
    const base = GemmaGenerationSettings();
    final changed = base.copyWith(temperature: 0.7, thinkingMode: true);

    expect(changed.temperature, 0.7);
    expect(changed.topK, base.topK);
    expect(changed.topP, base.topP);
    expect(changed.randomSeed, base.randomSeed);
    expect(changed.thinkingMode, isTrue);
  });
}
