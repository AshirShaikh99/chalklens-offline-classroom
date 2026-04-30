import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/model/gemma_generation_settings.dart';

/// Session settings used by the current testing build.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.modelSettings = GemmaGenerationSettings.defaults,
  });

  final ThemeMode themeMode;
  final GemmaGenerationSettings modelSettings;

  AppSettings copyWith({
    ThemeMode? themeMode,
    GemmaGenerationSettings? modelSettings,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      modelSettings: modelSettings ?? this.modelSettings,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setThemeMode(ThemeMode m) => state = state.copyWith(themeMode: m);

  void setTemperature(double value) {
    _setModel(
      state.modelSettings.copyWith(temperature: _roundDouble(value, 1)),
    );
  }

  void setTopK(int value) {
    _setModel(state.modelSettings.copyWith(topK: value));
  }

  void setTopP(double value) {
    _setModel(state.modelSettings.copyWith(topP: _roundDouble(value, 2)));
  }

  void setRandomSeed(int value) {
    _setModel(state.modelSettings.copyWith(randomSeed: value));
  }

  void setThinkingMode(bool value) {
    _setModel(state.modelSettings.copyWith(thinkingMode: value));
  }

  void resetModelSettings() {
    _setModel(GemmaGenerationSettings.defaults);
  }

  void _setModel(GemmaGenerationSettings settings) {
    state = state.copyWith(modelSettings: settings);
  }

  double _roundDouble(double value, int fractionDigits) {
    return double.parse(value.toStringAsFixed(fractionDigits));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
