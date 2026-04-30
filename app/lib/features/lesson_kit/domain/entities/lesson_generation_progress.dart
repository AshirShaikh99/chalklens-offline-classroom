enum LessonGenerationPhase {
  idle,
  readingSource,
  startingModel,
  namingLesson,
  writingObjectives,
  draftingExplanation,
  preparingBoardNotes,
  makingActivities,
  makingQuestions,
  addingHomework,
  buildingGlossary,
  checkingKit,
  complete,
}

typedef LessonGenerationProgressCallback =
    void Function(LessonGenerationProgress progress);

class LessonGenerationProgress {
  const LessonGenerationProgress({
    required this.phase,
    required this.progress,
    this.generatedTokens = 0,
    this.generatedCharacters = 0,
  });

  const LessonGenerationProgress.idle()
    : phase = LessonGenerationPhase.idle,
      progress = 0,
      generatedTokens = 0,
      generatedCharacters = 0;

  final LessonGenerationPhase phase;
  final double progress;
  final int generatedTokens;
  final int generatedCharacters;

  LessonGenerationProgress copyWith({
    LessonGenerationPhase? phase,
    double? progress,
    int? generatedTokens,
    int? generatedCharacters,
  }) {
    return LessonGenerationProgress(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      generatedTokens: generatedTokens ?? this.generatedTokens,
      generatedCharacters: generatedCharacters ?? this.generatedCharacters,
    );
  }

  bool get hasGeneratedText => generatedTokens > 0 || generatedCharacters > 0;
}
