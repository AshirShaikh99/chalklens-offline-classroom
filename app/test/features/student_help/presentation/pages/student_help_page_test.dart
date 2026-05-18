import 'package:chalk_lens/core/constants/languages.dart';
import 'package:chalk_lens/core/theme/app_theme.dart';
import 'package:chalk_lens/features/lesson_kit/domain/entities/lesson_context.dart';
import 'package:chalk_lens/features/lesson_kit/domain/entities/lesson_kit.dart';
import 'package:chalk_lens/features/lesson_kit/presentation/providers/lesson_kit_providers.dart';
import 'package:chalk_lens/features/saved_lessons/domain/entities/saved_lesson.dart';
import 'package:chalk_lens/features/saved_lessons/domain/repositories/saved_lessons_repository.dart';
import 'package:chalk_lens/features/saved_lessons/presentation/providers/saved_lessons_providers.dart';
import 'package:chalk_lens/features/student_help/domain/student_help_service.dart';
import 'package:chalk_lens/features/student_help/presentation/pages/student_help_page.dart';
import 'package:chalk_lens/features/student_help/presentation/providers/student_help_providers.dart';
import 'package:flutter/foundation.dart';
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
        overrides: [
          studentHelpServiceProvider.overrideWithValue(service),
          savedLessonsRepositoryProvider.overrideWithValue(
            _FakeSavedLessonsRepository(),
          ),
        ],
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
    expect(
      find.textContaining(
        'I need a selected lesson before I can answer safely',
      ),
      findsOneWidget,
    );
  });

  testWidgets('lesson question uses the student help service', (tester) async {
    final service = _FakeStudentHelpService(answerText: 'Plants use sunlight.');
    final container = ProviderContainer(
      overrides: [
        studentHelpServiceProvider.overrideWithValue(service),
        savedLessonsRepositoryProvider.overrideWithValue(
          _FakeSavedLessonsRepository(),
        ),
      ],
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

  testWidgets('greeting with a lesson uses the student help service', (
    tester,
  ) async {
    final service = _FakeStudentHelpService(answerText: 'Hello from Gemma.');
    final container = ProviderContainer(
      overrides: [
        studentHelpServiceProvider.overrideWithValue(service),
        savedLessonsRepositoryProvider.overrideWithValue(
          _FakeSavedLessonsRepository(),
        ),
      ],
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

    await tester.enterText(find.byType(TextField), 'hi');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(service.callCount, 1);
    expect(service.lastQuestion, 'hi');
    expect(find.text('Hello from Gemma.'), findsOneWidget);
  });

  testWidgets('lesson question can use a saved lesson without active state', (
    tester,
  ) async {
    final service = _FakeStudentHelpService(answerText: 'Use the saved kit.');
    final repository = _FakeSavedLessonsRepository([
      _savedLesson(id: 'plants', kit: _kit),
    ]);
    final container = ProviderContainer(
      overrides: [
        studentHelpServiceProvider.overrideWithValue(service),
        savedLessonsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StudentHelpPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'What do plants need?');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(service.callCount, 1);
    expect(service.lastLessonKit, _kit);
    expect(find.text('Use the saved kit.'), findsOneWidget);
  });

  testWidgets('student can choose a specific saved lesson context', (
    tester,
  ) async {
    final waterKit = _kit.copyWith(
      lessonTitle: 'Water cycle',
      simpleExplanation: 'Water moves between clouds, land, and rivers.',
    );
    final service = _FakeStudentHelpService(answerText: 'Water answer.');
    final repository = _FakeSavedLessonsRepository([
      _savedLesson(id: 'plants', kit: _kit),
      _savedLesson(id: 'water', kit: waterKit),
    ]);
    final container = ProviderContainer(
      overrides: [
        studentHelpServiceProvider.overrideWithValue(service),
        savedLessonsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const StudentHelpPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose lesson context'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Water cycle').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      'Where does rain come from?',
    );
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();

    expect(service.callCount, 1);
    expect(service.lastLessonKit, waterKit);
    expect(find.text('Water answer.'), findsOneWidget);
  });

  testWidgets('lesson question shows returned reasoning trace', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final service = _FakeStudentHelpService(
        answerText: 'Plants make food from light.',
        thinkingText: 'Use the active lesson and keep the answer short.',
      );
      final container = ProviderContainer(
        overrides: [
          studentHelpServiceProvider.overrideWithValue(service),
          savedLessonsRepositoryProvider.overrideWithValue(
            _FakeSavedLessonsRepository(),
          ),
        ],
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

      await tester.enterText(
        find.byType(TextField),
        'How do plants make food?',
      );
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(find.text('Reasoning trace'), findsOneWidget);
      expect(find.textContaining('Use the active lesson'), findsOneWidget);
      expect(find.text('Plants make food from light.'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('hides voice input on macOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentHelpServiceProvider.overrideWithValue(
              _FakeStudentHelpService(),
            ),
            savedLessonsRepositoryProvider.overrideWithValue(
              _FakeSavedLessonsRepository(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const StudentHelpPage(),
          ),
        ),
      );

      expect(find.byTooltip('Voice input'), findsNothing);
      expect(find.text('Reasoning'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

const _kit = LessonKit(
  lessonTitle: 'Plants',
  grade: 'Grade 5',
  subject: 'Science',
  language: AppLanguage.english,
  simpleExplanation: 'Plants need sunlight, air, and water to grow.',
);

SavedLesson _savedLesson({required String id, required LessonKit kit}) {
  return SavedLesson(
    id: id,
    kit: kit,
    context: LessonContext(
      grade: kit.grade,
      subject: kit.subject,
      language: kit.language,
    ),
    savedAt: DateTime(2026),
  );
}

class _FakeStudentHelpService implements StudentHelpService {
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
    Uint8List? audioBytes,
    LessonKit? lessonKit,
    bool? thinkingModeOverride,
    StudentHelpThinkingCallback? onThinking,
  }) async {
    callCount += 1;
    lastQuestion = question;
    lastLessonKit = lessonKit;
    if (thinkingText != null) onThinking?.call(thinkingText!);
    return answerText;
  }
}

class _FakeSavedLessonsRepository implements SavedLessonsRepository {
  _FakeSavedLessonsRepository([List<SavedLesson> lessons = const []])
    : _lessons = List<SavedLesson>.of(lessons);

  final List<SavedLesson> _lessons;

  @override
  Future<List<SavedLesson>> all() async => List<SavedLesson>.of(_lessons);

  @override
  Future<SavedLesson?> get(String id) async {
    for (final lesson in _lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }

  @override
  Future<void> save(SavedLesson lesson) async {
    _lessons.removeWhere((existing) => existing.id == lesson.id);
    _lessons.add(lesson);
  }

  @override
  Future<void> delete(String id) async {
    _lessons.removeWhere((lesson) => lesson.id == id);
  }
}
