import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/lesson_kit_datasource.dart';
import '../../data/repositories/lesson_kit_repository_impl.dart';
import '../../domain/entities/lesson_context.dart';
import '../../domain/entities/lesson_generation_progress.dart';
import '../../domain/entities/lesson_kit.dart';
import '../../domain/repositories/lesson_kit_repository.dart';
import '../../domain/usecases/generate_lesson_kit.dart';

/// Datasource boundary. Production wiring lives in `main.dart`; tests can
/// override this with a fake without loading the on-device model plugin.
final lessonKitDatasourceProvider = Provider<LessonKitDatasource>((ref) {
  throw UnimplementedError('lessonKitDatasourceProvider must be overridden.');
});

/// Repository wires the datasource into the domain contract.
final lessonKitRepositoryProvider = Provider<LessonKitRepository>(
  (ref) => LessonKitRepositoryImpl(
    datasource: ref.watch(lessonKitDatasourceProvider),
  ),
);

/// The use case the presentation layer actually depends on. Screens never
/// reach into repositories or datasources directly.
final generateLessonKitProvider = Provider<GenerateLessonKit>(
  (ref) => GenerateLessonKit(ref.watch(lessonKitRepositoryProvider)),
);

/// Holds the most recently generated LessonKit (or null if none yet).
final lessonKitGenerationProvider =
    AsyncNotifierProvider<LessonKitGenerationNotifier, LessonKit?>(
      LessonKitGenerationNotifier.new,
    );

final lessonGenerationProgressProvider =
    NotifierProvider<
      LessonGenerationProgressNotifier,
      LessonGenerationProgress
    >(LessonGenerationProgressNotifier.new);

class LessonGenerationProgressNotifier
    extends Notifier<LessonGenerationProgress> {
  @override
  LessonGenerationProgress build() => const LessonGenerationProgress.idle();

  void start() {
    state = const LessonGenerationProgress(
      phase: LessonGenerationPhase.readingSource,
      progress: 0.06,
    );
  }

  void update(LessonGenerationProgress progress) {
    state = progress;
  }

  void reset() {
    state = const LessonGenerationProgress.idle();
  }
}

class LessonKitGenerationNotifier extends AsyncNotifier<LessonKit?> {
  @override
  LessonKit? build() => null;

  Future<void> generate({
    required LessonContext context,
    String? passage,
    Uint8List? imageBytes,
  }) async {
    final progress = ref.read(lessonGenerationProgressProvider.notifier);
    progress.start();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(generateLessonKitProvider);
      return useCase(
        GenerateLessonKitParams(
          context: context,
          passage: passage,
          imageBytes: imageBytes,
          onProgress: progress.update,
        ),
      );
    });
  }

  /// Drops the current kit (used when the teacher leaves the LessonKit
  /// page so the next Scan starts on a clean slate).
  void clear() {
    ref.read(lessonGenerationProgressProvider.notifier).reset();
    state = const AsyncValue.data(null);
  }

  /// Pushes a previously-saved kit into the active state so the
  /// LessonKit page can render it. Used by Saved Lessons → tap.
  void loadFromSaved(LessonKit kit) {
    ref.read(lessonGenerationProgressProvider.notifier).reset();
    state = AsyncValue.data(kit);
  }
}
