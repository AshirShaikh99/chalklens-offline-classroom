import 'package:flutter_gemma/flutter_gemma.dart';

import '../../../core/constants/languages.dart';
import '../../../core/model/gemma_generation_settings.dart';
import '../../../core/model/gemma_model_installer.dart';
import '../../lesson_kit/domain/entities/lesson_kit.dart';

class GemmaStudentHelpService {
  GemmaStudentHelpService({
    GemmaModelInstaller? installer,
    GemmaGenerationSettings Function()? settingsReader,
  }) : _installer = installer ?? GemmaModelInstaller(),
       _settingsReader = settingsReader;

  final GemmaModelInstaller _installer;
  final GemmaGenerationSettings Function()? _settingsReader;

  Future<String> answer({
    required String question,
    required AppLanguage language,
    LessonKit? lessonKit,
  }) async {
    await _installer.ensureInstalled();
    final settings =
        _settingsReader?.call() ?? GemmaGenerationSettings.defaults;

    final model = await FlutterGemma.getActiveModel(
      maxTokens: 768,
      preferredBackend: PreferredBackend.gpu,
    );

    final chat = await model.createChat(
      systemInstruction: _systemPrompt(language),
      temperature: settings.temperature,
      randomSeed: settings.randomSeed,
      topK: settings.topK,
      topP: settings.topP,
      isThinking: settings.thinkingMode,
    );

    try {
      await chat.addQueryChunk(
        Message.text(
          text: _questionPrompt(question: question, lessonKit: lessonKit),
          isUser: true,
        ),
      );

      final buffer = StringBuffer();
      await for (final chunk in chat.generateChatResponseAsync()) {
        if (chunk is TextResponse) buffer.write(chunk.token);
      }

      final response = buffer.toString().trim();
      if (response.isEmpty) {
        return 'I could not generate an answer. Please ask again in simpler words.';
      }
      return response;
    } finally {
      await model.close();
    }
  }

  String _systemPrompt(AppLanguage language) =>
      '''
You are ChalkLens Student Help.
Answer a student's classroom question in ${language.label}.
Use simple, encouraging language. Do not give a long lecture.
If lesson context is provided, answer from that lesson. If context is missing,
say what you can, then ask one short follow-up question.
End with one quick check question for the student.
''';

  String _questionPrompt({
    required String question,
    required LessonKit? lessonKit,
  }) {
    final lessonContext = lessonKit == null
        ? 'No active lesson kit is available.'
        : '''
Active lesson:
Title: ${lessonKit.lessonTitle}
Grade: ${lessonKit.grade}
Subject: ${lessonKit.subject}
Explanation: ${lessonKit.simpleExplanation}
Blackboard notes: ${lessonKit.blackboardNotes.join('; ')}
Local example: ${lessonKit.localExample}
Easy version: ${lessonKit.easyVersion}
''';

    return '''
$lessonContext

Student question: $question
''';
  }
}
