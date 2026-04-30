import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/local_saved_lessons_datasource.dart';
import '../../data/datasources/saved_lessons_datasource.dart';
import '../../data/repositories/saved_lessons_repository_impl.dart';
import '../../domain/entities/saved_lesson.dart';
import '../../domain/repositories/saved_lessons_repository.dart';
import '../../domain/usecases/delete_lesson.dart';
import '../../domain/usecases/get_saved_lessons.dart';
import '../../domain/usecases/save_lesson.dart';

final savedLessonsDatasourceProvider = Provider<SavedLessonsDatasource>(
  (ref) => LocalSavedLessonsDatasource(),
);

final savedLessonsRepositoryProvider = Provider<SavedLessonsRepository>(
  (ref) => SavedLessonsRepositoryImpl(
    datasource: ref.watch(savedLessonsDatasourceProvider),
  ),
);

final getSavedLessonsProvider = Provider<GetSavedLessons>(
  (ref) => GetSavedLessons(ref.watch(savedLessonsRepositoryProvider)),
);

final saveLessonProvider = Provider<SaveLesson>(
  (ref) => SaveLesson(ref.watch(savedLessonsRepositoryProvider)),
);

final deleteLessonProvider = Provider<DeleteLesson>(
  (ref) => DeleteLesson(ref.watch(savedLessonsRepositoryProvider)),
);

/// Loads the saved-lessons list. Calling [SavedLessonsNotifier.save] or
/// [SavedLessonsNotifier.delete] invalidates the provider so subscribers
/// refetch.
final savedLessonsProvider =
    AsyncNotifierProvider<SavedLessonsNotifier, List<SavedLesson>>(
      SavedLessonsNotifier.new,
    );

class SavedLessonsNotifier extends AsyncNotifier<List<SavedLesson>> {
  @override
  Future<List<SavedLesson>> build() async {
    final useCase = ref.read(getSavedLessonsProvider);
    return useCase(const NoParams());
  }

  Future<void> save(SavedLesson lesson) async {
    await ref.read(saveLessonProvider).call(lesson);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(deleteLessonProvider).call(id);
    ref.invalidateSelf();
  }
}
