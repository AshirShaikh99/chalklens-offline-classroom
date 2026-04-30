class GemmaGenerationSettings {
  const GemmaGenerationSettings({
    this.temperature = 1.0,
    this.topK = 64,
    this.topP = 0.95,
    this.randomSeed = 1,
    this.thinkingMode = false,
  });

  static const defaults = GemmaGenerationSettings();

  final double temperature;
  final int topK;
  final double topP;
  final int randomSeed;
  final bool thinkingMode;

  GemmaGenerationSettings copyWith({
    double? temperature,
    int? topK,
    double? topP,
    int? randomSeed,
    bool? thinkingMode,
  }) {
    return GemmaGenerationSettings(
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      randomSeed: randomSeed ?? this.randomSeed,
      thinkingMode: thinkingMode ?? this.thinkingMode,
    );
  }

  String get responseProfile {
    if (temperature <= 0.4 && topK <= 32 && topP <= 0.85) {
      return 'Stable';
    }
    if (temperature >= 1.2 || topP >= 0.98 || topK >= 96) {
      return 'Exploratory';
    }
    return 'Balanced classroom';
  }

  @override
  bool operator ==(Object other) {
    return other is GemmaGenerationSettings &&
        other.temperature == temperature &&
        other.topK == topK &&
        other.topP == topP &&
        other.randomSeed == randomSeed &&
        other.thinkingMode == thinkingMode;
  }

  @override
  int get hashCode =>
      Object.hash(temperature, topK, topP, randomSeed, thinkingMode);
}
