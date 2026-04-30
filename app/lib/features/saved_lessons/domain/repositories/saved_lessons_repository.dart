import '../entities/saved_lesson.dart';

/// Persistence contract for saved classroom kits.
abstract class SavedLessonsRepository {
  Future<List<SavedLesson>> all();
  Future<SavedLesson?> get(String id);
  Future<void> save(SavedLesson lesson);
  Future<void> delete(String id);
}
