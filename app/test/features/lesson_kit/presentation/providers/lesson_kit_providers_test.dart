import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chalk_lens/core/constants/languages.dart';
import 'package:chalk_lens/core/theme/app_theme.dart';
import 'package:chalk_lens/features/lesson_kit/domain/entities/lesson_context.dart';
import 'package:chalk_lens/features/lesson_kit/domain/entities/lesson_generation_progress.dart';
import 'package:chalk_lens/features/lesson_kit/domain/entities/lesson_kit.dart';
import 'package:chalk_lens/features/lesson_kit/domain/repositories/lesson_kit_repository.dart';
import 'package:chalk_lens/features/lesson_kit/presentation/pages/lesson_kit_page.dart';
import 'package:chalk_lens/features/lesson_kit/presentation/providers/lesson_kit_providers.dart';

void main() {
  test(
    'first generation stays loading until the lesson kit is ready',
    () async {
      final repository = _DelayedLessonKitRepository();
      final container = ProviderContainer(
        overrides: [lessonKitRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final states = <AsyncValue<LessonKit?>>[];
      final subscription = container.listen(
        lessonKitGenerationProvider,
        (_, next) => states.add(next),
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final generation = container
          .read(lessonKitGenerationProvider.notifier)
          .generate(
            context: _context,
            imageBytes: Uint8List.fromList(const [1, 2, 3]),
          );

      expect(repository.callCount, 1);
      expect(container.read(lessonKitGenerationProvider).isLoading, isTrue);

      await Future<void>.delayed(Duration.zero);

      expect(container.read(lessonKitGenerationProvider).isLoading, isTrue);
      expect(
        states
            .skip(1)
            .where(
              (state) =>
                  !state.isLoading && state.hasValue && state.value == null,
            ),
        isEmpty,
      );

      repository.complete(_kit);
      await generation;

      final generated = container.read(lessonKitGenerationProvider);
      expect(generated.hasValue, isTrue);
      expect(generated.value, _kit);
    },
  );

  test('clear ignores a stale in-flight generation result', () async {
    final repository = _DelayedLessonKitRepository();
    final container = ProviderContainer(
      overrides: [lessonKitRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final generation = container
        .read(lessonKitGenerationProvider.notifier)
        .generate(
          context: _context,
          imageBytes: Uint8List.fromList(const [1, 2, 3]),
        );

    expect(container.read(lessonKitGenerationProvider).isLoading, isTrue);

    container.read(lessonKitGenerationProvider.notifier).clear();
    expect(container.read(lessonKitGenerationProvider).value, isNull);

    repository.complete(_kit);
    await generation;

    final generated = container.read(lessonKitGenerationProvider);
    expect(generated.hasValue, isTrue);
    expect(generated.value, isNull);
  });

  testWidgets('lesson page shows loading for the first generation', (
    tester,
  ) async {
    final repository = _DelayedLessonKitRepository();
    final container = ProviderContainer(
      overrides: [lessonKitRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    unawaited(
      container
          .read(lessonKitGenerationProvider.notifier)
          .generate(
            context: _context,
            imageBytes: Uint8List.fromList(const [1, 2, 3]),
          ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const LessonKitPage(),
        ),
      ),
    );

    expect(find.text('Generating lesson kit'), findsOneWidget);
    expect(find.text('Drafting the explanation'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.text('24 tokens'), findsOneWidget);
    expect(find.text('No lesson kit yet'), findsNothing);
  });
}

const _context = LessonContext(
  grade: 'Grade 5',
  subject: 'Science',
  language: AppLanguage.english,
);

const _kit = LessonKit(
  lessonTitle: 'Plants',
  grade: 'Grade 5',
  subject: 'Science',
  language: AppLanguage.english,
  simpleExplanation: 'Plants need sunlight, air, and water to grow.',
);

class _DelayedLessonKitRepository implements LessonKitRepository {
  final Completer<LessonKit> _completer = Completer<LessonKit>();
  int callCount = 0;

  @override
  Future<LessonKit> generate({
    required LessonContext context,
    String? passage,
    Uint8List? imageBytes,
    LessonGenerationProgressCallback? onProgress,
    Future<void>? cancelSignal,
  }) {
    callCount += 1;
    onProgress?.call(
      const LessonGenerationProgress(
        phase: LessonGenerationPhase.draftingExplanation,
        progress: 0.48,
        generatedTokens: 24,
        generatedCharacters: 180,
      ),
    );
    return _completer.future;
  }

  void complete(LessonKit kit) => _completer.complete(kit);
}
