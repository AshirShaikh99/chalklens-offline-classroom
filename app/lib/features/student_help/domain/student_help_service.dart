import 'dart:typed_data';

import '../../../core/constants/languages.dart';
import '../../lesson_kit/domain/entities/lesson_kit.dart';

typedef StudentHelpThinkingCallback = void Function(String content);

abstract class StudentHelpService {
  Future<String> answer({
    required String question,
    required AppLanguage language,
    Uint8List? audioBytes,
    LessonKit? lessonKit,
    StudentHelpThinkingCallback? onThinking,
  });
}
