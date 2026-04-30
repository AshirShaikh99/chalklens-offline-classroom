import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chalk_lens/core/model/gemma_generation_settings.dart';
import 'package:chalk_lens/features/settings/presentation/providers/settings_provider.dart';

void main() {
  test('model settings default to the Gemma 4 sampling baseline', () {
    expect(GemmaGenerationSettings.defaults.temperature, 1.0);
    expect(GemmaGenerationSettings.defaults.topK, 64);
    expect(GemmaGenerationSettings.defaults.topP, 0.95);
    expect(GemmaGenerationSettings.defaults.randomSeed, 1);
    expect(GemmaGenerationSettings.defaults.thinkingMode, isTrue);
  });

  test('app defaults to the dark theme', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
  });

  test('settings notifier updates and resets model behavior', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(settingsProvider.notifier);
    notifier.setTemperature(0.36);
    notifier.setTopK(24);
    notifier.setTopP(0.82);
    notifier.setRandomSeed(12);
    notifier.setThinkingMode(true);

    final changed = container.read(settingsProvider).modelSettings;
    expect(changed.temperature, 0.4);
    expect(changed.topK, 24);
    expect(changed.topP, 0.82);
    expect(changed.randomSeed, 12);
    expect(changed.thinkingMode, isTrue);
    expect(changed.responseProfile, 'Stable');

    notifier.resetModelSettings();

    expect(
      container.read(settingsProvider).modelSettings,
      GemmaGenerationSettings.defaults,
    );
  });
}
