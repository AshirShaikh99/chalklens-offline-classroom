import 'dart:async';
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
///
/// Not autoDispose: scan_page kicks off generation via `ref.read` without
/// holding a subscription, then navigates to /lesson. With autoDispose the
/// provider would be torn down between the two pages — cancelling the
/// in-flight generation. Cancel-on-back is handled explicitly in
/// `LessonKitPage.onBack` via `notifier.clear()`.
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
  GenerateLessonKitParams? _lastParams;
  Completer<void>? _activeCancel;
  int _generationId = 0;

  @override
  LessonKit? build() {
    ref.onDispose(() {
      // Page popped or provider invalidated. Signal any active generation
      // to abort so it doesn't continue chasing tokens against a torn-down
      // model session.
      final cancel = _activeCancel;
      if (cancel != null && !cancel.isCompleted) cancel.complete();
    });
    return null;
  }

  Future<void> generate({
    required LessonContext context,
    String? passage,
    Uint8List? imageBytes,
  }) async {
    // Cancel any prior in-flight call before starting a new one.
    final prior = _activeCancel;
    if (prior != null && !prior.isCompleted) prior.complete();

    final cancel = Completer<void>();
    _activeCancel = cancel;
    final generationId = ++_generationId;
    final progress = ref.read(lessonGenerationProgressProvider.notifier);
    progress.start();
    final params = GenerateLessonKitParams(
      context: context,
      passage: passage,
      imageBytes: imageBytes,
      onProgress: progress.update,
      cancelSignal: cancel.future,
    );
    _lastParams = params;
    state = const AsyncValue.loading();
    final nextState = await AsyncValue.guard(() async {
      final useCase = ref.read(generateLessonKitProvider);
      return useCase(params);
    });
    if (_generationId != generationId || _activeCancel != cancel) return;
    _activeCancel = null;
    state = nextState;
  }

  /// Re-runs the most recent generation request, if one exists. Used by
  /// the in-place "Regenerate" affordance on the error state when the model
  /// produced un-parseable JSON.
  Future<void> regenerate() async {
    final last = _lastParams;
    if (last == null) return;
    await generate(
      context: last.context,
      passage: last.passage,
      imageBytes: last.imageBytes,
    );
  }

  bool get canRegenerate => _lastParams != null;

  /// Drops the current kit (used when the teacher leaves the LessonKit
  /// page so the next Scan starts on a clean slate).
  void clear() {
    _generationId += 1;
    final prior = _activeCancel;
    if (prior != null && !prior.isCompleted) prior.complete();
    _activeCancel = null;
    ref.read(lessonGenerationProgressProvider.notifier).reset();
    state = const AsyncValue.data(null);
  }

  /// Pushes a previously-saved kit into the active state so the
  /// LessonKit page can render it. Used by Saved Lessons → tap.
  void loadFromSaved(LessonKit kit) {
    _generationId += 1;
    final prior = _activeCancel;
    if (prior != null && !prior.isCompleted) prior.complete();
    _activeCancel = null;
    ref.read(lessonGenerationProgressProvider.notifier).reset();
    state = AsyncValue.data(kit);
  }
}
