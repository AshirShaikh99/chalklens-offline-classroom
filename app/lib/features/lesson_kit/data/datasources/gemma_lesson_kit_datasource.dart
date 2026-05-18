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
import 'gemma_tool_call_json_extractor.dart';
import 'json_repair.dart';
import 'lesson_kit_depth_guard.dart';
import 'lesson_kit_datasource.dart';
import 'lesson_kit_json_normalizer.dart';
import 'lesson_kit_recovery_builder.dart';
import 'local_teaching_pack.dart';

/// Real on-device datasource backed by the configured LiteRT-LM model.
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
  static const String _lessonKitToolName = 'submit_lesson_kit';
  static const int _richLessonMaxTokens = 3072;
  static const int _standardLessonMaxTokens = 2048;
  static const int _maxPromptPassageChars = 3500;
  static const LessonKitDepthGuard _depthGuard = LessonKitDepthGuard();
  static const LessonKitRecoveryBuilder _recoveryBuilder =
      LessonKitRecoveryBuilder();
  static const GemmaToolCallJsonExtractor _toolCallJsonExtractor =
      GemmaToolCallJsonExtractor(toolName: _lessonKitToolName);

  // Heuristic mapping from token count to overall progress. Anchors at
  // _streamProgressFloor when the first token arrives and approaches
  // _streamProgressFloor + _streamProgressSpan as we cross
  // _streamProgressTokenSpan tokens.
  static const double _streamProgressFloor = 0.28;
  static const double _streamProgressSpan = 0.6;
  static const int _streamProgressTokenSpan = 2200;

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
    final promptPassage = _promptSafePassage(passage);
    final teachingPack = _teachingPack.build(
      context: context,
      passage: promptPassage,
    );

    final hasPromptPassage =
        promptPassage != null && promptPassage.trim().isNotEmpty;
    final useImage = imageBytes != null && !hasPromptPassage;
    if (imageBytes != null && !useImage) {
      debugPrint(
        '[GemmaLessonKitDatasource] using pasted text instead of image mode '
        'for generation stability.',
      );
    }
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
          ? _userPromptForImage(context)
          : '${_userPromptForText(context)}\n\nPassage:\n$promptPassage';

      final raw = await _generateRawLessonKit(
        model: model,
        opened: opened,
        settings: settings,
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        imageBytes: useImage ? imageBytes : null,
        onProgress: onProgress,
        cancelSignal: cancelSignal,
      );

      onProgress?.call(
        LessonGenerationProgress(
          phase: LessonGenerationPhase.checkingKit,
          progress: 0.94,
        ),
      );
      LessonKitModel parsedKit;
      try {
        parsedKit = _parseLessonKitWithoutNativeRetry(
          raw: raw,
          context: context,
        );
      } on ModelOutputException catch (e) {
        debugPrint(
          '[GemmaLessonKitDatasource] lesson JSON parse failed; '
          'recovering from source text and local teaching pack: $e',
        );
        parsedKit = _recoveryBuilder.build(
          context: context,
          teachingPack: teachingPack,
          rawOutput: raw,
        );
      }
      final kitWithTeachingPack = _withTeachingPackFallbacks(
        parsedKit,
        teachingPack,
      );
      final kit = _depthGuard.expandIfTooShort(
        kit: kitWithTeachingPack,
        context: context,
        teachingPack: teachingPack,
        log: debugPrint,
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

  Future<String> _generateRawLessonKit({
    required InferenceModel model,
    required _OpenedGemmaModel opened,
    required GemmaGenerationSettings settings,
    required String systemPrompt,
    required String userPrompt,
    required Uint8List? imageBytes,
    required LessonGenerationProgressCallback? onProgress,
    required Future<void>? cancelSignal,
  }) async {
    final structuredSettings = _structuredLessonSettings(settings);
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
            temperature: structuredSettings.temperature,
            randomSeed: structuredSettings.randomSeed,
            topK: structuredSettings.topK,
            topP: structuredSettings.topP,
            isThinking: structuredSettings.thinkingMode,
            supportImage: opened.supportImage,
            tools: const [],
            supportsFunctionCalls: false,
            modelType: _installer.modelType,
            toolChoice: ToolChoice.none,
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

    try {
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
          phase: LessonGenerationPhase.draftingExplanation,
          progress: 0.34,
        ),
      );
      return await _consumeStream(
        chat.generateChatResponseAsync(),
        chat: chat,
        reasoningFilter: reasoningFilter,
        onProgress: onProgress,
        cancelSignal: cancelSignal,
        requireFirstOutput: false,
      );
    } finally {
      try {
        await chat.close();
      } catch (closeErr) {
        debugPrint('[GemmaLessonKitDatasource] chat close failed: $closeErr');
      }
    }
  }

  GemmaGenerationSettings _structuredLessonSettings(
    GemmaGenerationSettings settings,
  ) {
    return settings.copyWith(
      temperature: math.min(settings.temperature, 0.6).toDouble(),
      topK: math.min(settings.topK, 64).toInt(),
      topP: math.min(settings.topP, 0.9).toDouble(),
      thinkingMode: false,
    );
  }

  LessonKitModel _parseLessonKitWithoutNativeRetry({
    required String raw,
    required LessonContextModel context,
  }) => _parseLessonKit(raw, context: context);

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
    required InferenceChat chat,
    required ReasoningTraceFilter reasoningFilter,
    required LessonGenerationProgressCallback? onProgress,
    required Future<void>? cancelSignal,
    bool requireFirstOutput = true,
  }) {
    final completer = Completer<String>();
    final buffer = StringBuffer();
    final inlineReasoningSplitter = InlineReasoningSplitter();
    String? functionCallJson;
    final streamStartedAt = DateTime.now();
    var generatedTokens = 0;
    var generatedCharacters = 0;
    var reasoningCharacters = 0;
    var reasoningPreview = '';
    var lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);
    var sawFirstOutput = false;

    late StreamSubscription<dynamic> sub;
    Timer? watchdog;
    Timer? firstTokenTimer;
    Timer? waitingProgressTimer;

    void finish(Object? error, [StackTrace? st]) {
      if (completer.isCompleted) return;
      watchdog?.cancel();
      firstTokenTimer?.cancel();
      waitingProgressTimer?.cancel();
      sub.cancel();
      if (error != null) {
        completer.completeError(error, st);
      } else {
        completer.complete(
          functionCallJson ??
              _jsonFromSdkRawResponse(chat) ??
              _toolCallJsonExtractor.fromText(buffer.toString()) ??
              buffer.toString(),
        );
      }
    }

    void emitWaitingProgress() {
      if (sawFirstOutput || completer.isCompleted) return;
      final elapsedSeconds = DateTime.now()
          .difference(streamStartedAt)
          .inSeconds;
      final progressValue = (0.34 + math.min(elapsedSeconds / 180, 1) * 0.28)
          .clamp(0.34, 0.62)
          .toDouble();
      final phase = elapsedSeconds >= 70
          ? LessonGenerationPhase.makingActivities
          : LessonGenerationPhase.draftingExplanation;
      onProgress?.call(
        LessonGenerationProgress(
          phase: phase,
          progress: progressValue,
          generatedTokens: generatedTokens,
          generatedCharacters: generatedCharacters,
          reasoningCharacters: reasoningCharacters,
          reasoningPreview: reasoningPreview,
        ),
      );
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

    void markFirstOutput() {
      if (sawFirstOutput) return;
      sawFirstOutput = true;
      firstTokenTimer?.cancel();
    }

    void handleReasoning(String reasoning) {
      if (reasoning.isEmpty) return;
      markFirstOutput();
      final visibleThinking = reasoningFilter.add(reasoning);
      if (visibleThinking.trim().isEmpty) return;
      reasoningCharacters = reasoningFilter.visibleText.length;
      reasoningPreview = _appendReasoningPreview(
        current: reasoningPreview,
        chunk: visibleThinking,
      );
      final now = DateTime.now();
      if (now.difference(lastProgressAt) > const Duration(milliseconds: 160)) {
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
    }

    void handleText(String text) {
      if (text.isEmpty) return;
      markFirstOutput();
      buffer.write(text);
      generatedTokens += _estimatedTokenCount(text);
      generatedCharacters += text.length;
      final now = DateTime.now();
      if (generatedTokens == 1 ||
          now.difference(lastProgressAt) > const Duration(milliseconds: 120)) {
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

    cancelSignal?.then((_) => finish(const GenerationCancelled()));

    sub = stream.listen(
      (chunk) {
        resetWatchdog();
        if (chunk is ThinkingResponse) {
          handleReasoning(chunk.content);
        } else if (chunk is TextResponse) {
          final split = inlineReasoningSplitter.add(chunk.token);
          handleReasoning(split.reasoning);
          handleText(split.text);
        } else if (chunk is FunctionCallResponse) {
          markFirstOutput();
          final extracted = _toolCallJsonExtractor.fromFunctionArgs(chunk.args);
          if (extracted != null && extracted != functionCallJson) {
            functionCallJson = extracted;
            generatedCharacters = math.max(
              generatedCharacters,
              extracted.length,
            );
            generatedTokens = math.max(
              generatedTokens,
              _estimatedTokenCount(extracted),
            );
            onProgress?.call(
              _progressForOutput(
                raw: extracted,
                generatedTokens: generatedTokens,
                generatedCharacters: generatedCharacters,
                reasoningCharacters: reasoningCharacters,
                reasoningPreview: reasoningPreview,
              ),
            );
          }
        } else if (chunk is ParallelFunctionCallResponse) {
          markFirstOutput();
          if (chunk.calls.isEmpty) return;
          final lessonCall = chunk.calls.firstWhere(
            (call) => call.name == _lessonKitToolName,
            orElse: () => chunk.calls.first,
          );
          final extracted = _toolCallJsonExtractor.fromFunctionArgs(
            lessonCall.args,
          );
          if (extracted != null && extracted != functionCallJson) {
            functionCallJson = extracted;
            generatedCharacters = math.max(
              generatedCharacters,
              extracted.length,
            );
            generatedTokens = math.max(
              generatedTokens,
              _estimatedTokenCount(extracted),
            );
            onProgress?.call(
              _progressForOutput(
                raw: extracted,
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
      onDone: () {
        final split = inlineReasoningSplitter.flush();
        handleReasoning(split.reasoning);
        handleText(split.text);
        finish(null);
      },
      cancelOnError: true,
    );

    resetWatchdog();
    waitingProgressTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => emitWaitingProgress(),
    );
    if (requireFirstOutput) {
      firstTokenTimer = Timer(_firstTokenTimeout, () {
        if (!sawFirstOutput) {
          finish(
            const ModelOutputException(
              'Gemma did not produce any output before the first-token timeout.',
            ),
          );
        }
      });
    }

    return completer.future;
  }

  int _estimatedTokenCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return math.max(1, (trimmed.runes.length / 4).ceil());
  }

  String? _jsonFromSdkRawResponse(InferenceChat chat) {
    final session = chat.session;
    if (session is! RawSdkResponseSession) return null;
    final raw = session.lastRawResponse;
    if (raw == null || raw.trim().isEmpty) return null;
    return _toolCallJsonExtractor.fromText(raw);
  }

  Future<_OpenedGemmaModel> _openModel({
    required bool useImage,
    required Future<void>? cancelSignal,
  }) async {
    // Image flow is GPU-only: flutter_gemma 0.14+ runs LiteRT-LM vision
    // through the Metal delegate on iPhone, and CPU image mode is unusable
    // there (no Metal scratch reuse, ~10x slower decode). Image attempts
    // prefer a 3072-token context and fall back to 2048 because a full
    // lesson-kit JSON can exceed 2k tokens, while larger contexts are too
    // crash-prone on device for this teacher flow. If pasted text is
    // available, the caller uses text-only mode because the native multimodal
    // prefill path has been the crash-prone path on iPhone release builds.
    //
    // Text-only flow keeps a GPU→CPU fallback because no vision capability
    // is at stake; CPU text decode is acceptable.
    final attempts = useImage
        ? const <_ModelOpenAttempt>[
            _ModelOpenAttempt(
              label: 'image GPU rich',
              backend: PreferredBackend.gpu,
              maxTokens: _richLessonMaxTokens,
              supportImage: true,
            ),
            _ModelOpenAttempt(
              label: 'image GPU standard',
              backend: PreferredBackend.gpu,
              maxTokens: _standardLessonMaxTokens,
              supportImage: true,
            ),
          ]
        : const <_ModelOpenAttempt>[
            _ModelOpenAttempt(
              label: 'text GPU rich',
              backend: PreferredBackend.gpu,
              maxTokens: _richLessonMaxTokens,
              supportImage: false,
            ),
            _ModelOpenAttempt(
              label: 'text GPU standard',
              backend: PreferredBackend.gpu,
              maxTokens: _standardLessonMaxTokens,
              supportImage: false,
            ),
            _ModelOpenAttempt(
              label: 'text CPU standard',
              backend: PreferredBackend.cpu,
              maxTokens: _standardLessonMaxTokens,
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
              'this device. Open Model setup and re-import or download '
              '${_installer.modelDisplayName} again.$imageHint'
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

  LessonKitModel _parseLessonKit(
    String raw, {
    required LessonContextModel context,
  }) {
    final toolJson = _toolCallJsonExtractor.fromText(raw);
    final parseInput = toolJson ?? raw;
    final candidates = JsonRepair.extractObjects(parseInput);
    final objects = candidates.isEmpty
        ? [JsonRepair.extractObject(parseInput)]
        : candidates;
    Object? firstDecodeError;
    Object? firstSchemaError;

    for (final candidate in objects) {
      final decoded = _tryDecodeMap(candidate);
      Map<String, dynamic>? json = decoded.value;
      if (json == null) {
        firstDecodeError ??= decoded.error;
        // Last-chance: run a best-effort repair pass (close truncated
        // strings/structures, strip trailing commas and JS comments,
        // escape raw control chars). Idempotent on already-valid JSON.
        final repaired = JsonRepair.repair(candidate);
        if (repaired != candidate) {
          final retry = _tryDecodeMap(repaired);
          json = retry.value;
        }
      }
      if (json == null) continue;

      try {
        final normalized = LessonKitJsonNormalizer.normalize(
          json,
          context: context,
        );
        return LessonKitModel.fromJson(normalized);
      } catch (e) {
        firstSchemaError ??= e;
      }
    }

    if (firstSchemaError != null) {
      throw ModelOutputException(
        'JSON parsed but did not match the LessonKit schema.',
        cause: firstSchemaError,
      );
    }

    if (firstDecodeError != null) {
      throw ModelOutputException(
        'The offline model returned text that could not be parsed as JSON.',
        cause: firstDecodeError,
      );
    }

    throw ModelOutputException(
      'The offline model returned text that could not be parsed as JSON.',
    );
  }

  _DecodeAttempt _tryDecodeMap(String candidate) {
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is! Map) {
        return _DecodeAttempt.failure(
          const FormatException('JSON root was not an object.'),
        );
      }
      return _DecodeAttempt.success(decoded.cast<String, dynamic>());
    } catch (e) {
      return _DecodeAttempt.failure(e);
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
      teacherMoves: teacherMoves,
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

  Map<String, dynamic> _lessonKitJsonSchema(LessonContextModel context) {
    const stringArray = {
      'type': 'array',
      'items': {'type': 'string'},
    };
    const quizQuestion = {
      'type': 'object',
      'properties': {
        'question': {'type': 'string'},
        'expected_answer': {'type': 'string'},
      },
      'required': ['question'],
    };
    const glossaryTerm = {
      'type': 'object',
      'properties': {
        'term': {'type': 'string'},
        'meaning': {'type': 'string'},
        'example': {'type': 'string'},
      },
      'required': ['term', 'meaning'],
    };

    return {
      'type': 'object',
      'properties': {
        'lesson_title': {'type': 'string'},
        'grade': {'type': 'string'},
        'subject': {'type': 'string'},
        'language': {
          'type': 'string',
          'enum': [context.language.code],
        },
        'source_concepts': stringArray,
        'likely_misconceptions': stringArray,
        'teacher_moves': stringArray,
        'checks_for_understanding': stringArray,
        'learning_objectives': stringArray,
        'simple_explanation': {'type': 'string'},
        'blackboard_notes': stringArray,
        'local_example': {'type': 'string'},
        'oral_quiz': {'type': 'array', 'items': quizQuestion},
        'group_activity': {'type': 'string'},
        'homework': stringArray,
        'glossary': {'type': 'array', 'items': glossaryTerm},
        'easy_version': {'type': 'string'},
        'confidence': {'type': 'number'},
      },
      'required': [
        'lesson_title',
        'grade',
        'subject',
        'language',
        'source_concepts',
        'likely_misconceptions',
        'teacher_moves',
        'checks_for_understanding',
        'learning_objectives',
        'simple_explanation',
        'blackboard_notes',
        'local_example',
        'oral_quiz',
        'group_activity',
        'homework',
        'glossary',
        'easy_version',
        'confidence',
      ],
    };
  }

  String _systemPromptFor(
    LessonContextModel context,
    TeachingPackContext teachingPack,
  ) {
    final langLabel = context.language.label;
    final native = context.language.native;
    final lessonKitSchema = jsonEncode(_lessonKitJsonSchema(context));
    final depthTarget = LessonKitDepthTarget.forSource(
      context: context,
      teachingPack: teachingPack,
    );
    return '''
You are ChalkLens, an offline classroom co-pilot for low-resource teachers.
Given a textbook passage or page image, return a complete classroom kit as
STRICT JSON matching the schema below. Use only information present in the
input — do NOT invent textbook facts. Fill every field with classroom-usable
detail sized to the class duration; use "N/A" only when the source truly gives
no basis for an item.

Output ONLY one JSON object matching the schema below. Do not use markdown
fences, comments, reasoning, or any text outside the JSON object.

Target language for ALL textual fields: $langLabel ($native).
Inferred class context: ${context.grade}.
Inferred subject context: ${context.subject}.
These inferred values are hints from the uploaded source. If the page text or
image explicitly says a different class, subject, topic, or lesson title, follow
the uploaded source and put the source values in the JSON.
Class duration: ~${context.classDurationMinutes} minutes.
Student level: ${context.studentLevel.name}.

${teachingPack.toPromptBlock()}

${depthTarget.promptBlock(context.classDurationMinutes)}

JSON schema:
$lessonKitSchema
''';
  }

  String _userPromptForImage(LessonContextModel context) =>
      'Here is a textbook page image. Read the page carefully, infer the '
      'class, subject, and lesson topic from the visible source, and produce '
      'the classroom kit as JSON matching the schema in your instructions.';

  String _userPromptForText(LessonContextModel context) =>
      'Generate the classroom kit for the passage below as JSON matching the '
      'schema in your instructions. Infer the class, subject, and lesson topic '
      'from the passage when they are present.';

  String? _promptSafePassage(String? passage) {
    final text = passage?.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text == null || text.isEmpty) return null;
    if (text.length <= _maxPromptPassageChars) return text;

    const marker =
        '[Passage trimmed for device stability. Use only the visible text above and below.]';
    final headLength = (_maxPromptPassageChars * 0.72).floor();
    final tailLength = _maxPromptPassageChars - headLength;
    final head = text.substring(0, headLength).trimRight();
    final tail = text.substring(text.length - tailLength).trimLeft();
    return '$head\n\n$marker\n\n$tail';
  }

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

class _DecodeAttempt {
  const _DecodeAttempt._(this.value, this.error);

  factory _DecodeAttempt.success(Map<String, dynamic> value) =>
      _DecodeAttempt._(value, null);

  factory _DecodeAttempt.failure(Object error) => _DecodeAttempt._(null, error);

  final Map<String, dynamic>? value;
  final Object? error;
}
