import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/model/gemma_generation_settings.dart';

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
  static const String _fileName = 'settings.json';
  bool _loaded = false;

  @override
  AppSettings build() {
    Future.microtask(_load);
    return const AppSettings();
  }

  Future<File> _file() async {
    final docs = await getApplicationDocumentsDirectory();
    return File('${docs.path}/$_fileName');
  }

  Future<void> _load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      state = AppSettings(
        themeMode: _decodeThemeMode(json['theme_mode'] as String?),
        modelSettings: GemmaGenerationSettings.fromJson(
          (json['model_settings'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        ),
      );
    } catch (e) {
      // Corrupt file: keep defaults. Don't surface to UI; settings are
      // recoverable by the user.
      if (kDebugMode) debugPrint('[Settings] load failed: $e');
    } finally {
      _loaded = true;
    }
  }

  Future<void> _persist() async {
    if (!_loaded) return;
    try {
      final file = await _file();
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      final payload = <String, dynamic>{
        'theme_mode': _encodeThemeMode(state.themeMode),
        'model_settings': state.modelSettings.toJson(),
      };
      await file.writeAsString(jsonEncode(payload));
    } catch (e) {
      if (kDebugMode) debugPrint('[Settings] persist failed: $e');
    }
  }

  void setThemeMode(ThemeMode m) {
    state = state.copyWith(themeMode: m);
    unawaited(_persist());
  }

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
    unawaited(_persist());
  }

  double _roundDouble(double value, int fractionDigits) {
    return double.parse(value.toStringAsFixed(fractionDigits));
  }

  String _encodeThemeMode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };

  ThemeMode _decodeThemeMode(String? raw) => switch (raw) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);
