import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/model/gemma_generation_settings.dart';
import '../../../../core/model/gemma_model_installer.dart';
import '../../domain/entities/lesson_generation_progress.dart';
import '../models/lesson_context_model.dart';
import '../models/lesson_kit_model.dart';
import 'json_repair.dart';
import 'lesson_kit_datasource.dart';

/// Real on-device datasource backed by Gemma 4 E2B LiteRT-LM.
class GemmaLessonKitDatasource implements LessonKitDatasource {
  GemmaLessonKitDatasource({
    GemmaModelInstaller? installer,
    GemmaGenerationSettings Function()? settingsReader,
  }) : _installer = installer ?? GemmaModelInstaller(),
       _settingsReader = settingsReader;

  final GemmaModelInstaller _installer;
  final GemmaGenerationSettings Function()? _settingsReader;

  @override
  Future<LessonKitModel> generate({
    required LessonContextModel context,
    String? passage,
    Uint8List? imageBytes,
    LessonGenerationProgressCallback? onProgress,
  }) async {
    if ((passage == null || passage.trim().isEmpty) && imageBytes == null) {
      throw const ModelOutputException(
        'Either passage text or an image is required.',
      );
    }

    onProgress?.call(
      const LessonGenerationProgress(
        phase: LessonGenerationPhase.readingSource,
        progress: 0.08,
      ),
    );
    await _installer.ensureInstalled();
    final settings =
        _settingsReader?.call() ?? GemmaGenerationSettings.defaults;

    final useImage = imageBytes != null;
    onProgress?.call(
      const LessonGenerationProgress(
        phase: LessonGenerationPhase.startingModel,
        progress: 0.18,
      ),
    );
    final model = await FlutterGemma.getActiveModel(
      maxTokens: 4096,
      preferredBackend: PreferredBackend.gpu,
      supportImage: useImage,
      maxNumImages: useImage ? 1 : null,
    );

    final chat = await model.createChat(
      systemInstruction: _systemPromptFor(context),
      temperature: settings.temperature,
      randomSeed: settings.randomSeed,
      topK: settings.topK,
      topP: settings.topP,
      isThinking: settings.thinkingMode,
      supportImage: useImage,
    );

    try {
      if (useImage) {
        await chat.addQueryChunk(
          Message.withImage(
            text: passage == null || passage.trim().isEmpty
                ? _userPromptForImage(context)
                : '${_userPromptForImage(context)}\n\nKnown text from page:\n$passage',
            imageBytes: imageBytes,
            isUser: true,
          ),
        );
      } else {
        await chat.addQueryChunk(
          Message.text(
            text: '${_userPromptForText(context)}\n\nPassage:\n$passage',
            isUser: true,
          ),
        );
      }

      final buffer = StringBuffer();
      var generatedTokens = 0;
      var generatedCharacters = 0;
      var reasoningCharacters = 0;
      var reasoningPreview = '';
      var lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);

      onProgress?.call(
        const LessonGenerationProgress(
          phase: LessonGenerationPhase.namingLesson,
          progress: 0.28,
        ),
      );
      final stream = chat.generateChatResponseAsync();
      await for (final chunk in stream) {
        if (chunk is ThinkingResponse) {
          if (chunk.content.trim().isEmpty) continue;
          reasoningCharacters += chunk.content.length;
          reasoningPreview = _appendReasoningPreview(
            current: reasoningPreview,
            chunk: chunk.content,
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
          if (token.isEmpty) continue;
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
      }

      final raw = buffer.toString();
      onProgress?.call(
        LessonGenerationProgress(
          phase: LessonGenerationPhase.checkingKit,
          progress: 0.94,
          generatedTokens: generatedTokens,
          generatedCharacters: generatedCharacters,
          reasoningCharacters: reasoningCharacters,
          reasoningPreview: reasoningPreview,
        ),
      );
      final kit = _parseLessonKit(raw);
      onProgress?.call(
        LessonGenerationProgress(
          phase: LessonGenerationPhase.complete,
          progress: 1,
          generatedTokens: generatedTokens,
          generatedCharacters: generatedCharacters,
          reasoningCharacters: reasoningCharacters,
          reasoningPreview: reasoningPreview,
        ),
      );
      return kit;
    } finally {
      await model.close();
    }
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
    final streamProgress = 0.28 + math.min(generatedTokens / 700, 1) * 0.6;

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

  String _systemPromptFor(LessonContextModel context) {
    final langLabel = context.language.label;
    final native = context.language.native;
    return '''
You are ChalkLens, an offline classroom co-pilot for low-resource teachers.
Given a textbook passage or page image, return a complete classroom kit as
STRICT JSON matching the schema below. Use only information present in the
input — do NOT invent textbook facts. If a field has no good answer from the
input, write "N/A" or an empty array as appropriate.

Output ONLY the JSON object — no prose, no markdown fences, no commentary.

Target language for ALL textual fields: $langLabel ($native).
Grade: ${context.grade}. Subject: ${context.subject}.
Class duration: ~${context.classDurationMinutes} minutes.
Student level: ${context.studentLevel.name}.

JSON schema:
{
  "lesson_title": string,
  "grade": string,
  "subject": string,
  "language": "${context.language.code}",
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
}
