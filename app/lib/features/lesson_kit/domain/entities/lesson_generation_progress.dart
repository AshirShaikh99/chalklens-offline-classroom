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
    this.reasoningCharacters = 0,
    this.reasoningPreview = '',
  });

  const LessonGenerationProgress.idle()
    : phase = LessonGenerationPhase.idle,
      progress = 0,
      generatedTokens = 0,
      generatedCharacters = 0,
      reasoningCharacters = 0,
      reasoningPreview = '';

  final LessonGenerationPhase phase;
  final double progress;
  final int generatedTokens;
  final int generatedCharacters;
  final int reasoningCharacters;
  final String reasoningPreview;

  LessonGenerationProgress copyWith({
    LessonGenerationPhase? phase,
    double? progress,
    int? generatedTokens,
    int? generatedCharacters,
    int? reasoningCharacters,
    String? reasoningPreview,
  }) {
    return LessonGenerationProgress(
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      generatedTokens: generatedTokens ?? this.generatedTokens,
      generatedCharacters: generatedCharacters ?? this.generatedCharacters,
      reasoningCharacters: reasoningCharacters ?? this.reasoningCharacters,
      reasoningPreview: reasoningPreview ?? this.reasoningPreview,
    );
  }

  bool get hasGeneratedText => generatedTokens > 0 || generatedCharacters > 0;
  bool get hasReasoning =>
      reasoningCharacters > 0 || reasoningPreview.isNotEmpty;
}
