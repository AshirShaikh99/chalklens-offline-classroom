import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local_saved_lessons_datasource.dart';
import '../../data/datasources/saved_lessons_datasource.dart';
import '../../data/repositories/saved_lessons_repository_impl.dart';
import '../../domain/entities/saved_lesson.dart';
import '../../domain/repositories/saved_lessons_repository.dart';

final savedLessonsDatasourceProvider = Provider<SavedLessonsDatasource>(
  (ref) => LocalSavedLessonsDatasource(),
);

final savedLessonsRepositoryProvider = Provider<SavedLessonsRepository>(
  (ref) => SavedLessonsRepositoryImpl(
    datasource: ref.watch(savedLessonsDatasourceProvider),
  ),
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
  Future<List<SavedLesson>> build() {
    return ref.watch(savedLessonsRepositoryProvider).all();
  }

  Future<void> save(SavedLesson lesson) async {
    await ref.read(savedLessonsRepositoryProvider).save(lesson);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await ref.read(savedLessonsRepositoryProvider).delete(id);
    ref.invalidateSelf();
  }
}
