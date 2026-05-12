import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/model/gemma_generation_settings.dart';
import '../../../../core/model/gemma_model_installer.dart';
import '../../../../core/model/reasoning_trace_sanitizer.dart';
import '../../domain/entities/lesson_generation_progress.dart';
import '../models/lesson_context_model.dart';
import '../models/lesson_kit_model.dart';
import 'json_repair.dart';
import 'lesson_kit_datasource.dart';
import 'local_teaching_pack.dart';

/// Real on-device datasource backed by Gemma 4 E2B LiteRT-LM.
class GemmaLessonKitDatasource implements LessonKitDatasource {
  GemmaLessonKitDatasource({
    GemmaModelInstaller? installer,
    GemmaGenerationSettings Function()? settingsReader,
    LocalTeachingPack? teachingPack,
  }) : _installer = installer ?? GemmaModelInstaller(),
       _settingsReader = settingsReader,
       _teachingPack = teachingPack ?? const LocalTeachingPack();

  final GemmaModelInstaller _installer;
  final GemmaGenerationSettings Function()? _settingsReader;
  final LocalTeachingPack _teachingPack;

  static const Duration _streamTimeout = Duration(minutes: 5);
  static const Duration _firstTokenTimeout = Duration(minutes: 2);
  static const Duration _modelOpenAttemptTimeout = Duration(seconds: 60);
  static const Duration _chatSetupTimeout = Duration(seconds: 30);
  static const Duration _promptSubmitTimeout = Duration(seconds: 30);

  // Heuristic mapping from token count to overall progress. Anchors at
  // _streamProgressFloor when the first token arrives and approaches
  // _streamProgressFloor + _streamProgressSpan as we cross
  // _streamProgressTokenSpan tokens.
  static const double _streamProgressFloor = 0.28;
  static const double _streamProgressSpan = 0.6;
  static const int _streamProgressTokenSpan = 700;

  @override
  Future<LessonKitModel> generate({
    required LessonContextModel context,
    String? passage,
    Uint8List? imageBytes,
    LessonGenerationProgressCallback? onProgress,
    Future<void>? cancelSignal,
  }) {
    if ((passage == null || passage.trim().isEmpty) && imageBytes == null) {
      return Future.error(
        const ModelOutputException(
          'Either passage text or an image is required.',
        ),
      );
    }
    return _installer.withGemmaSession(
      () => _runGeneration(
        context: context,
        passage: passage,
        imageBytes: imageBytes,
        onProgress: onProgress,
        cancelSignal: cancelSignal,
      ),
    );
  }

  Future<LessonKitModel> _runGeneration({
    required LessonContextModel context,
    String? passage,
    Uint8List? imageBytes,
    LessonGenerationProgressCallback? onProgress,
    Future<void>? cancelSignal,
  }) async {
    onProgress?.call(
      const LessonGenerationProgress(
        phase: LessonGenerationPhase.readingSource,
        progress: 0.08,
      ),
    );
    await _installer.ensureInstalled();
    final settings =
        _settingsReader?.call() ?? GemmaGenerationSettings.defaults;
    final teachingPack = _teachingPack.build(
      context: context,
      passage: passage,
    );

    final useImage = imageBytes != null;
    onProgress?.call(
      const LessonGenerationProgress(
        phase: LessonGenerationPhase.startingModel,
        progress: 0.18,
      ),
    );
    final opened = await _openModel(
      useImage: useImage,
      cancelSignal: cancelSignal,
    );
    final model = opened.model;

    try {
      final systemPrompt = _systemPromptFor(context, teachingPack);
      final userPrompt = opened.useImage
          ? passage == null || passage.trim().isEmpty
                ? _userPromptForImage(context)
                : '${_userPromptForImage(context)}\n\nKnown text from page:\n$passage'
          : '${_userPromptForText(context)}\n\nPassage:\n$passage';
      final reasoningFilter = ReasoningTraceFilter(
        promptEchoes: _promptEchoCandidates(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
        ),
      );
      final chat = await _withCancel(
        model
            .createChat(
              systemInstruction: systemPrompt,
              temperature: settings.temperature,
              randomSeed: settings.randomSeed,
              topK: settings.topK,
              topP: settings.topP,
              isThinking: settings.thinkingMode,
              supportImage: opened.supportImage,
            )
            .timeout(
              _chatSetupTimeout,
              onTimeout: () => throw const ModelUnavailableException(
                'Gemma opened, but the lesson chat did not become ready. '
                'Try again; if it repeats, open Model setup and verify the '
                'offline model file.',
              ),
            ),
        cancelSignal,
      );

      if (opened.useImage) {
        await _withCancel(
          chat
              .addQueryChunk(
                Message.withImage(
                  text: userPrompt,
                  imageBytes: imageBytes!,
                  isUser: true,
                ),
              )
              .timeout(
                _promptSubmitTimeout,
                onTimeout: () => throw const ModelUnavailableException(
                  'Gemma opened, but the scanned page could not be sent to '
                  'the local model. Try again with typed text if image mode '
                  'keeps failing on this device.',
                ),
              ),
          cancelSignal,
        );
      } else {
        await _withCancel(
          chat
              .addQueryChunk(Message.text(text: userPrompt, isUser: true))
              .timeout(
                _promptSubmitTimeout,
                onTimeout: () => throw const ModelUnavailableException(
                  'Gemma opened, but the lesson prompt could not be sent to '
                  'the local model. Please try again.',
                ),
              ),
          cancelSignal,
        );
      }

      onProgress?.call(
        const LessonGenerationProgress(
          phase: LessonGenerationPhase.namingLesson,
          progress: 0.28,
        ),
      );
      final raw = await _consumeStream(
        chat.generateChatResponseAsync(),
        reasoningFilter: reasoningFilter,
        onProgress: onProgress,
        cancelSignal: cancelSignal,
      );

      onProgress?.call(
        LessonGenerationProgress(
          phase: LessonGenerationPhase.checkingKit,
          progress: 0.94,
        ),
      );
      final kit = _withTeachingPackFallbacks(
        _parseLessonKit(raw),
        teachingPack,
      );
      onProgress?.call(
        const LessonGenerationProgress(
          phase: LessonGenerationPhase.complete,
          progress: 1,
        ),
      );
      return kit;
    } finally {
      try {
        await model.close();
      } catch (closeErr) {
        debugPrint('[GemmaLessonKitDatasource] model close failed: $closeErr');
      }
    }
  }

  Future<T> _withCancel<T>(Future<T> future, Future<void>? cancelSignal) {
    if (cancelSignal == null) return future;
    return Future.any<T>([
      future,
      cancelSignal.then<T>((_) => throw const GenerationCancelled()),
    ]);
  }

  /// Listen-based stream consumer so we can cancel the subscription if the
  /// caller's [cancelSignal] fires (e.g. page popped) without leaving an
  /// orphaned Gemma generation chasing tokens against a closed model.
  Future<String> _consumeStream(
    Stream<dynamic> stream, {
    required ReasoningTraceFilter reasoningFilter,
    required LessonGenerationProgressCallback? onProgress,
    required Future<void>? cancelSignal,
  }) {
    final completer = Completer<String>();
    final buffer = StringBuffer();
    var generatedTokens = 0;
    var generatedCharacters = 0;
    var reasoningCharacters = 0;
    var reasoningPreview = '';
    var lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);
    var sawFirstToken = false;

    late StreamSubscription<dynamic> sub;
    Timer? watchdog;
    Timer? firstTokenTimer;

    void finish(Object? error, [StackTrace? st]) {
      if (completer.isCompleted) return;
      watchdog?.cancel();
      firstTokenTimer?.cancel();
      sub.cancel();
      if (error != null) {
        completer.completeError(error, st);
      } else {
        completer.complete(buffer.toString());
      }
    }

    void resetWatchdog() {
      watchdog?.cancel();
      watchdog = Timer(_streamTimeout, () {
        finish(
          const ModelOutputException(
            'Gemma generation stalled and was aborted.',
          ),
        );
      });
    }

    cancelSignal?.then((_) => finish(const GenerationCancelled()));

    sub = stream.listen(
      (chunk) {
        resetWatchdog();
        if (chunk is ThinkingResponse) {
          final visibleThinking = reasoningFilter.add(chunk.content);
          if (visibleThinking.trim().isEmpty) return;
          reasoningCharacters = reasoningFilter.visibleText.length;
          reasoningPreview = _appendReasoningPreview(
            current: reasoningPreview,
            chunk: visibleThinking,
          );
          final now = DateTime.now();
          if (now.difference(lastProgressAt) >
              const Duration(milliseconds: 160)) {
            lastProgressAt = now;
            onProgress?.call(
              LessonGenerationProgress(
                phase: LessonGenerationPhase.namingLesson,
                progress: 0.3,
                generatedTokens: generatedTokens,
                generatedCharacters: generatedCharacters,
                reasoningCharacters: reasoningCharacters,
                reasoningPreview: reasoningPreview,
              ),
            );
          }
        } else if (chunk is TextResponse) {
          final token = chunk.token;
          if (token.isEmpty) return;
          if (!sawFirstToken) {
            sawFirstToken = true;
            firstTokenTimer?.cancel();
          }
          buffer.write(token);
          generatedTokens += 1;
          generatedCharacters += token.length;
          final now = DateTime.now();
          if (generatedTokens == 1 ||
              now.difference(lastProgressAt) >
                  const Duration(milliseconds: 120)) {
            lastProgressAt = now;
            onProgress?.call(
              _progressForOutput(
                raw: buffer.toString(),
                generatedTokens: generatedTokens,
                generatedCharacters: generatedCharacters,
                reasoningCharacters: reasoningCharacters,
                reasoningPreview: reasoningPreview,
              ),
            );
          }
        }
      },
      onError: (Object e, StackTrace st) => finish(e, st),
      onDone: () => finish(null),
      cancelOnError: true,
    );

    resetWatchdog();
    firstTokenTimer = Timer(_firstTokenTimeout, () {
      if (!sawFirstToken) {
        finish(
          const ModelOutputException(
            'Gemma did not produce any output before the first-token timeout.',
          ),
        );
      }
    });

    return completer.future;
  }

  Future<_OpenedGemmaModel> _openModel({
    required bool useImage,
    required Future<void>? cancelSignal,
  }) async {
    // Image flow is GPU-only and single-attempt: flutter_gemma 0.14+ runs
    // Gemma 4 E2B vision through the Metal delegate, and CPU image mode is
    // unusable on iPhone (no Metal scratch reuse, ~10× slower decode). Image
    // attempts use 2048 tokens because the vision tower already pins
    // significant Metal buffers; the lesson-kit JSON output fits comfortably
    // under 2k tokens. We deliberately do NOT silently fall back to text-only
    // when an image is provided — losing the page would change what the
    // teacher sees without their consent.
    //
    // Text-only flow keeps a GPU→CPU fallback because no vision capability
    // is at stake; CPU text decode is acceptable.
    final attempts = useImage
        ? const <_ModelOpenAttempt>[
            _ModelOpenAttempt(
              label: 'image GPU',
              backend: PreferredBackend.gpu,
              maxTokens: 2048,
              supportImage: true,
            ),
          ]
        : const <_ModelOpenAttempt>[
            _ModelOpenAttempt(
              label: 'text GPU',
              backend: PreferredBackend.gpu,
              maxTokens: 4096,
              supportImage: false,
            ),
            _ModelOpenAttempt(
              label: 'text CPU',
              backend: PreferredBackend.cpu,
              maxTokens: 4096,
              supportImage: false,
            ),
          ];

    Object? lastError;
    for (final attempt in attempts) {
      try {
        final model = await _withCancel(
          FlutterGemma.getActiveModel(
            maxTokens: attempt.maxTokens,
            preferredBackend: attempt.backend,
            supportImage: attempt.supportImage,
            maxNumImages: attempt.supportImage ? 1 : null,
          ).timeout(
            _modelOpenAttemptTimeout,
            onTimeout: () => throw TimeoutException(
              'Timed out opening ${attempt.label} after '
              '${_modelOpenAttemptTimeout.inSeconds}s.',
            ),
          ),
          cancelSignal,
        );
        if (lastError != null) {
          debugPrint(
            '[GemmaLessonKitDatasource] opened fallback ${attempt.label}',
          );
        }
        return _OpenedGemmaModel(model: model, attempt: attempt);
      } on GenerationCancelled {
        rethrow;
      } catch (e) {
        lastError = e;
        debugPrint(
          '[GemmaLessonKitDatasource] model open failed '
          '(${attempt.label}): $e',
        );
      }
    }

    throw _friendlyModelStartFailure(lastError, useImage: useImage);
  }

  ModelUnavailableException _friendlyModelStartFailure(
    Object? error, {
    required bool useImage,
  }) {
    if (error is TimeoutException) {
      return ModelUnavailableException(
        'Gemma took too long to start on this device. Try again; if it '
        'happens repeatedly, open Model setup and verify the offline model.',
        cause: error,
      );
    }
    final imageHint = useImage
        ? ' If image mode keeps failing, paste the textbook words and try '
              'again in text-only mode.'
        : '';
    final message = _looksLikeEngineFailure(error)
        ? 'The offline model file is present, but Gemma could not start it on '
              'this device. Open Model setup and re-import or download the '
              'exact gemma-4-E2B-it.litertlm file again.$imageHint'
        : 'Could not start the offline model. Open Model setup and check the '
              'Gemma file.$imageHint';
    return ModelUnavailableException(message, cause: error);
  }

  bool _looksLikeEngineFailure(Object? error) {
    final text = error.toString().toLowerCase();
    return text.contains('failed to create engine') ||
        text.contains('model may be invalid') ||
        text.contains('failed to initialize model') ||
        text.contains('litert');
  }

  LessonGenerationProgress _progressForOutput({
    required String raw,
    required int generatedTokens,
    required int generatedCharacters,
    required int reasoningCharacters,
    required String reasoningPreview,
  }) {
    final phase = _phaseForPartialOutput(raw);
    final phaseProgress = _progressFloorForPhase(phase);
    final streamProgress =
        _streamProgressFloor +
        math.min(generatedTokens / _streamProgressTokenSpan, 1) *
            _streamProgressSpan;

    return LessonGenerationProgress(
      phase: phase,
      progress: math
          .max(phaseProgress, streamProgress)
          .clamp(0.28, 0.9)
          .toDouble(),
      generatedTokens: generatedTokens,
      generatedCharacters: generatedCharacters,
      reasoningCharacters: reasoningCharacters,
      reasoningPreview: reasoningPreview,
    );
  }

  String _appendReasoningPreview({
    required String current,
    required String chunk,
  }) {
    final normalized = chunk.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) return current;
    final joined = current.isEmpty ? normalized : '$current $normalized';
    const limit = 520;
    if (joined.length <= limit) return joined;
    return '...${joined.substring(joined.length - limit).trimLeft()}';
  }

  LessonGenerationPhase _phaseForPartialOutput(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('"glossary"')) {
      return LessonGenerationPhase.buildingGlossary;
    }
    if (lower.contains('"checks_for_understanding"') ||
        lower.contains('"teacher_moves"') ||
        lower.contains('"likely_misconceptions"') ||
        lower.contains('"source_concepts"')) {
      return LessonGenerationPhase.makingActivities;
    }
    if (lower.contains('"homework"')) {
      return LessonGenerationPhase.addingHomework;
    }
    if (lower.contains('"oral_quiz"')) {
      return LessonGenerationPhase.makingQuestions;
    }
    if (lower.contains('"group_activity"') ||
        lower.contains('"local_example"')) {
      return LessonGenerationPhase.makingActivities;
    }
    if (lower.contains('"blackboard_notes"')) {
      return LessonGenerationPhase.preparingBoardNotes;
    }
    if (lower.contains('"simple_explanation"')) {
      return LessonGenerationPhase.draftingExplanation;
    }
    if (lower.contains('"learning_objectives"')) {
      return LessonGenerationPhase.writingObjectives;
    }
    return LessonGenerationPhase.namingLesson;
  }

  double _progressFloorForPhase(LessonGenerationPhase phase) {
    return switch (phase) {
      LessonGenerationPhase.idle => 0,
      LessonGenerationPhase.readingSource => 0.08,
      LessonGenerationPhase.startingModel => 0.18,
      LessonGenerationPhase.namingLesson => 0.28,
      LessonGenerationPhase.writingObjectives => 0.38,
      LessonGenerationPhase.draftingExplanation => 0.48,
      LessonGenerationPhase.preparingBoardNotes => 0.58,
      LessonGenerationPhase.makingActivities => 0.66,
      LessonGenerationPhase.makingQuestions => 0.74,
      LessonGenerationPhase.addingHomework => 0.82,
      LessonGenerationPhase.buildingGlossary => 0.88,
      LessonGenerationPhase.checkingKit => 0.94,
      LessonGenerationPhase.complete => 1,
    };
  }

  LessonKitModel _parseLessonKit(String raw) {
    final cleaned = JsonRepair.extractObject(raw);
    Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw ModelOutputException(
        'Gemma 4 returned text that could not be parsed as JSON.',
        cause: e,
      );
    }

    try {
      return LessonKitModel.fromJson(json);
    } catch (e) {
      throw ModelOutputException(
        'JSON parsed but did not match the LessonKit schema.',
        cause: e,
      );
    }
  }

  LessonKitModel _withTeachingPackFallbacks(
    LessonKitModel kit,
    TeachingPackContext teachingPack,
  ) {
    final sourceConcepts = _usefulItems(kit.sourceConcepts);
    final likelyMisconceptions = _usefulItems(kit.likelyMisconceptions);
    final teacherMoves = _usefulItems(kit.teacherMoves);
    final checksForUnderstanding = _usefulItems(kit.checksForUnderstanding);

    final fallbackConcepts = _fallbackSourceConcepts(teachingPack);
    final finalConcepts = sourceConcepts.isEmpty
        ? fallbackConcepts
        : sourceConcepts;

    return kit.copyWith(
      sourceConcepts: finalConcepts,
      likelyMisconceptions: likelyMisconceptions.isEmpty
          ? _usefulItems(teachingPack.misconceptionChecks).take(3).toList()
          : likelyMisconceptions,
      teacherMoves: teacherMoves.isEmpty
          ? _usefulItems([
              ...teachingPack.pedagogyRules.take(2),
              ...teachingPack.activityTemplates.take(2),
            ]).toList()
          : teacherMoves,
      checksForUnderstanding: checksForUnderstanding.isEmpty
          ? _fallbackChecks(finalConcepts)
          : checksForUnderstanding,
    );
  }

  List<String> _usefulItems(Iterable<String> items) {
    return items
        .map((item) => item.trim())
        .where(
          (item) =>
              item.isNotEmpty &&
              item.toLowerCase() != 'n/a' &&
              item.toLowerCase() != 'na',
        )
        .toList();
  }

  List<String> _fallbackSourceConcepts(TeachingPackContext teachingPack) {
    final concepts = <String>[];
    for (final hint in teachingPack.sourceConceptHints) {
      final quoted = RegExp('"([^"]+)"').firstMatch(hint);
      if (quoted != null) {
        concepts.add(_titleCase(quoted.group(1)!));
      }
    }
    if (concepts.isNotEmpty) return concepts.take(4).toList();
    return const ['Main idea from the textbook source'];
  }

  List<String> _fallbackChecks(List<String> sourceConcepts) {
    final concreteConcepts = sourceConcepts
        .where((concept) => !concept.toLowerCase().contains('main idea'))
        .take(2)
        .toList();
    if (concreteConcepts.isEmpty) {
      return const [
        'Ask one student to explain the main idea in their own words.',
        'Ask the class for one local example before moving on.',
      ];
    }
    return [
      for (final concept in concreteConcepts)
        'Ask one student to explain $concept in their own words.',
      'Ask the class for one local example connected to the lesson.',
    ];
  }

  String _titleCase(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return words
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _systemPromptFor(
    LessonContextModel context,
    TeachingPackContext teachingPack,
  ) {
    final langLabel = context.language.label;
    final native = context.language.native;
    return '''
You are ChalkLens, an offline classroom co-pilot for low-resource teachers.
Given a textbook passage or page image, return a complete classroom kit as
STRICT JSON matching the schema below. Use only information present in the
input — do NOT invent textbook facts. Fill every array with short classroom
usable items; use "N/A" only when the source truly gives no basis for an item.

Output ONLY the JSON object — no prose, no markdown fences, no commentary.

Target language for ALL textual fields: $langLabel ($native).
Grade: ${context.grade}. Subject: ${context.subject}.
Class duration: ~${context.classDurationMinutes} minutes.
Student level: ${context.studentLevel.name}.

${teachingPack.toPromptBlock()}

Required teaching strategy fields:
- source_concepts: 2-5 factual ideas or terms visible in the source.
- likely_misconceptions: 2-4 student confusions to check before practice.
- teacher_moves: 2-4 blackboard/oral moves usable without internet or devices.
- checks_for_understanding: 2-4 quick oral checks a teacher can ask immediately.

JSON schema:
{
  "lesson_title": string,
  "grade": string,
  "subject": string,
  "language": "${context.language.code}",
  "source_concepts": [string, ...],
  "likely_misconceptions": [string, ...],
  "teacher_moves": [string, ...],
  "checks_for_understanding": [string, ...],
  "learning_objectives": [string, ...],
  "simple_explanation": string,
  "blackboard_notes": [string, ...],
  "local_example": string,
  "oral_quiz": [{"question": string, "expected_answer": string?}, ...],
  "group_activity": string,
  "homework": [string, ...],
  "glossary": [{"term": string, "meaning": string, "example": string?}, ...],
  "easy_version": string,
  "confidence": number between 0 and 1
}
''';
  }

  String _userPromptForImage(LessonContextModel context) =>
      'Here is a page from a ${context.subject} textbook for ${context.grade}. '
      'Read the page carefully and produce the classroom kit as JSON matching '
      'the schema in your instructions.';

  String _userPromptForText(LessonContextModel context) =>
      'Generate the classroom kit for the passage below as JSON matching the '
      'schema in your instructions.';

  List<String> _promptEchoCandidates({
    required String systemPrompt,
    required String userPrompt,
  }) {
    return [
      systemPrompt,
      userPrompt,
      '$systemPrompt\n\n$userPrompt',
      '[System: $systemPrompt]\n\n$userPrompt',
      '<start_of_turn>user\n$userPrompt<end_of_turn>\n<start_of_turn>model\n',
      '<start_of_turn>user\n[System: $systemPrompt]\n\n$userPrompt'
          '<end_of_turn>\n<start_of_turn>model\n',
    ];
  }
}

class _ModelOpenAttempt {
  const _ModelOpenAttempt({
    required this.label,
    required this.backend,
    required this.maxTokens,
    required this.supportImage,
  });

  final String label;
  final PreferredBackend backend;
  final int maxTokens;
  final bool supportImage;
}

class _OpenedGemmaModel {
  const _OpenedGemmaModel({required this.model, required this.attempt});

  final InferenceModel model;
  final _ModelOpenAttempt attempt;

  bool get useImage => attempt.supportImage;
  bool get supportImage => attempt.supportImage;
}
