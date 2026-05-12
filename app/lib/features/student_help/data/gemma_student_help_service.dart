import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../core/constants/languages.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/model/gemma_generation_settings.dart';
import '../../../core/model/gemma_model_installer.dart';
import '../../../core/model/reasoning_trace_sanitizer.dart';
import '../../lesson_kit/domain/entities/lesson_kit.dart';
import '../domain/student_help_service.dart';

class GemmaStudentHelpService implements StudentHelpService {
  GemmaStudentHelpService({
    GemmaModelInstaller? installer,
    GemmaGenerationSettings Function()? settingsReader,
  }) : _installer = installer ?? GemmaModelInstaller(),
       _settingsReader = settingsReader;

  final GemmaModelInstaller _installer;
  final GemmaGenerationSettings Function()? _settingsReader;

  static const Duration _streamTimeout = Duration(minutes: 3);

  @override
  Future<String> answer({
    required String question,
    required AppLanguage language,
    Uint8List? audioBytes,
    LessonKit? lessonKit,
    StudentHelpThinkingCallback? onThinking,
  }) {
    return _installer.withGemmaSession(() => _runAnswer(
          question: question,
          language: language,
          audioBytes: audioBytes,
          lessonKit: lessonKit,
          onThinking: onThinking,
        ));
  }

  Future<String> _runAnswer({
    required String question,
    required AppLanguage language,
    Uint8List? audioBytes,
    LessonKit? lessonKit,
    StudentHelpThinkingCallback? onThinking,
  }) async {
    await _installer.ensureInstalled();
    final settings =
        _settingsReader?.call() ?? GemmaGenerationSettings.defaults;
    final hasAudio = audioBytes != null && audioBytes.isNotEmpty;

    final model = await _openModel(hasAudio: hasAudio);

    try {
      final systemPrompt = _systemPrompt(language);
      final chat = await model.createChat(
        systemInstruction: systemPrompt,
        temperature: settings.temperature,
        randomSeed: settings.randomSeed,
        topK: settings.topK,
        topP: settings.topP,
        tokenBuffer: 128,
        isThinking: settings.thinkingMode,
        supportAudio: hasAudio,
      );

      final prompt = _questionPrompt(
        question: question,
        lessonKit: lessonKit,
        hasAudio: hasAudio,
      );
      final reasoningFilter = ReasoningTraceFilter(
        promptEchoes: _promptEchoCandidates(
          systemPrompt: systemPrompt,
          userPrompt: prompt,
        ),
      );
      await chat.addQueryChunk(
        hasAudio
            ? Message.withAudio(
                text: prompt,
                audioBytes: audioBytes,
                isUser: true,
              )
            : Message.text(text: prompt, isUser: true),
      );

      final response = await _consumeStream(
        chat.generateChatResponseAsync(),
        reasoningFilter: reasoningFilter,
        onThinking: onThinking,
      );

      final trimmed = response.trim();
      if (trimmed.isEmpty) {
        return 'I could not generate an answer. Please ask again in simpler words.';
      }
      return trimmed;
    } catch (e) {
      if (hasAudio && _isAudioUnsupportedError(e)) {
        throw ModelUnavailableException(
          'I recorded the voice question, but this Gemma runtime did not '
          'accept the audio input. Please try again after the updated Gemma '
          'runtime is installed, or type the question for now.',
          cause: e,
        );
      }
      rethrow;
    } finally {
      try {
        await model.close();
      } catch (closeErr) {
        debugPrint(
          '[GemmaStudentHelpService] model close failed: $closeErr',
        );
      }
    }
  }

  Future<String> _consumeStream(
    Stream<dynamic> stream, {
    required ReasoningTraceFilter reasoningFilter,
    required StudentHelpThinkingCallback? onThinking,
  }) {
    final completer = Completer<String>();
    final buffer = StringBuffer();
    late StreamSubscription<dynamic> sub;
    Timer? watchdog;

    void finish(Object? error, [StackTrace? st]) {
      if (completer.isCompleted) return;
      watchdog?.cancel();
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
            'Student-help generation stalled and was aborted.',
          ),
        );
      });
    }

    sub = stream.listen(
      (chunk) {
        resetWatchdog();
        if (chunk is ThinkingResponse) {
          final visibleThinking = reasoningFilter.add(chunk.content);
          if (visibleThinking.trim().isNotEmpty) {
            onThinking?.call(visibleThinking);
          }
        } else if (chunk is TextResponse) {
          buffer.write(chunk.token);
        }
      },
      onError: (Object e, StackTrace st) => finish(e, st),
      onDone: () => finish(null),
      cancelOnError: true,
    );
    resetWatchdog();
    return completer.future;
  }

  Future<InferenceModel> _openModel({required bool hasAudio}) async {
    final attempts = <_StudentHelpModelAttempt>[
      if (hasAudio)
        const _StudentHelpModelAttempt(
          label: 'audio GPU',
          backend: PreferredBackend.gpu,
          supportAudio: true,
        ),
      if (hasAudio)
        const _StudentHelpModelAttempt(
          label: 'audio CPU',
          backend: PreferredBackend.cpu,
          supportAudio: true,
        ),
      if (!hasAudio)
        const _StudentHelpModelAttempt(
          label: 'text GPU',
          backend: PreferredBackend.gpu,
          supportAudio: false,
        ),
      if (!hasAudio)
        const _StudentHelpModelAttempt(
          label: 'text CPU',
          backend: PreferredBackend.cpu,
          supportAudio: false,
        ),
    ];

    Object? lastError;
    for (final attempt in attempts) {
      try {
        return await FlutterGemma.getActiveModel(
          maxTokens: 2048,
          preferredBackend: attempt.backend,
          supportAudio: attempt.supportAudio,
        );
      } catch (e) {
        lastError = e;
        debugPrint(
          '[GemmaStudentHelpService] model open failed '
          '(${attempt.label}): $e',
        );
      }
    }

    if (hasAudio) {
      throw ModelUnavailableException(
        'Voice questions need the Gemma 4 runtime to open with audio input. '
        'Text questions are still available.',
        cause: lastError,
      );
    }
    throw ModelUnavailableException(
      'Gemma 4 could not start for Student Help. Please try again in a moment.',
      cause: lastError,
    );
  }

  bool _isAudioUnsupportedError(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('does not support audio') ||
        text.contains('audio modality') ||
        text.contains('addaudio') ||
        text.contains('audio input') ||
        text.contains('failed to create conversation') ||
        text.contains('failed to create engine');
  }

  String _systemPrompt(AppLanguage language) =>
      '''
You are ChalkLens Student Help.
Answer a student's classroom question in ${language.label}.
Use simple, encouraging language. Do not give a long lecture.
If lesson context is provided, stay grounded in that specific lesson and use
its explanation, activities, questions, homework, and glossary before adding
outside knowledge. If context is missing, say what you can, then ask one short
follow-up question.
End with one quick check question for the student.
If the student asks by voice, understand the attached audio and reply in text.
Never say you cannot produce audio; this app needs a written classroom answer.
''';

  String _questionPrompt({
    required String question,
    required LessonKit? lessonKit,
    required bool hasAudio,
  }) {
    final lessonContext = lessonKit == null
        ? 'No active lesson kit is available.'
        : '''
Active lesson:
Title: ${lessonKit.lessonTitle}
Grade: ${lessonKit.grade}
Subject: ${lessonKit.subject}
Learning objectives: ${lessonKit.learningObjectives.join('; ')}
Source concepts: ${lessonKit.sourceConcepts.join('; ')}
Likely misconceptions: ${lessonKit.likelyMisconceptions.join('; ')}
Teacher moves: ${lessonKit.teacherMoves.join('; ')}
Checks for understanding: ${lessonKit.checksForUnderstanding.join('; ')}
Explanation: ${lessonKit.simpleExplanation}
Blackboard notes: ${lessonKit.blackboardNotes.join('; ')}
Local example: ${lessonKit.localExample}
Oral quiz: ${lessonKit.oralQuiz.map((q) => '${q.question} (${q.expectedAnswer ?? 'open response'})').join('; ')}
Group activity: ${lessonKit.groupActivity}
Homework: ${lessonKit.homework.join('; ')}
Glossary: ${lessonKit.glossary.map((term) => '${term.term}: ${term.meaning}').join('; ')}
Easy version: ${lessonKit.easyVersion}
''';

    final questionBlock = hasAudio
        ? '''
The student asked by voice. The attached audio is the source question. Infer the
spoken question, then answer it in text. If the audio is unclear, say that
briefly and ask the student to repeat it.
Teacher note: $question
'''
        : 'Student question: $question';

    return '''
$lessonContext

$questionBlock
''';
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

class _StudentHelpModelAttempt {
  const _StudentHelpModelAttempt({
    required this.label,
    required this.backend,
    required this.supportAudio,
  });

  final String label;
  final PreferredBackend backend;
  final bool supportAudio;
}
