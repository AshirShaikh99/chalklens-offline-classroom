import 'package:chalk_lens/core/constants/languages.dart';
import 'package:chalk_lens/core/theme/app_theme.dart';
import 'package:chalk_lens/features/lesson_kit/domain/entities/lesson_kit.dart';
import 'package:chalk_lens/features/lesson_kit/presentation/providers/lesson_kit_providers.dart';
import 'package:chalk_lens/features/student_help/data/gemma_student_help_service.dart';
import 'package:chalk_lens/features/student_help/presentation/pages/student_help_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('greeting without an active lesson does not call Gemma', (
    tester,
  ) async {
    final service = _FakeStudentHelpService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [studentHelpServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StudentHelpPage(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(service.callCount, 0);
    expect(find.textContaining('I need a lesson kit first'), findsOneWidget);
  });

  testWidgets('lesson question uses the student help service', (tester) async {
    final service = _FakeStudentHelpService(answerText: 'Plants use sunlight.');
    final container = ProviderContainer(
      overrides: [studentHelpServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    container.read(lessonKitGenerationProvider.notifier).loadFromSaved(_kit);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StudentHelpPage(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Why do plants need light?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(service.callCount, 1);
    expect(service.lastQuestion, 'Why do plants need light?');
    expect(service.lastLessonKit, _kit);
    expect(find.text('Plants use sunlight.'), findsOneWidget);
  });

  testWidgets('lesson question shows returned reasoning trace', (tester) async {
    final service = _FakeStudentHelpService(
      answerText: 'Plants make food from light.',
      thinkingText: 'Use the active lesson and keep the answer short.',
    );
    final container = ProviderContainer(
      overrides: [studentHelpServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    container.read(lessonKitGenerationProvider.notifier).loadFromSaved(_kit);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StudentHelpPage(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'How do plants make food?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(find.text('Reasoning trace'), findsOneWidget);
    expect(find.textContaining('Use the active lesson'), findsOneWidget);
    expect(find.text('Plants make food from light.'), findsOneWidget);
  });
}

const _kit = LessonKit(
  lessonTitle: 'Plants',
  grade: 'Grade 5',
  subject: 'Science',
  language: AppLanguage.english,
  simpleExplanation: 'Plants need sunlight, air, and water to grow.',
);

class _FakeStudentHelpService extends GemmaStudentHelpService {
  _FakeStudentHelpService({this.answerText = 'Fake answer', this.thinkingText});

  final String answerText;
  final String? thinkingText;
  int callCount = 0;
  String? lastQuestion;
  LessonKit? lastLessonKit;

  @override
  Future<String> answer({
    required String question,
    required AppLanguage language,
    LessonKit? lessonKit,
    StudentHelpThinkingCallback? onThinking,
  }) async {
    callCount += 1;
    lastQuestion = question;
    lastLessonKit = lessonKit;
    if (thinkingText != null) onThinking?.call(thinkingText!);
    return answerText;
  }
}
