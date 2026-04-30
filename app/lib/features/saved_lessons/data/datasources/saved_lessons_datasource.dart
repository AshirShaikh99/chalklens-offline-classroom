import '../models/saved_lesson_model.dart';

/// Persistence-layer contract for saved lessons. Implementations own how
/// records are stored.
///
/// Throws [StorageException] on read/write failure.
abstract class SavedLessonsDatasource {
  Future<List<SavedLessonModel>> all();
  Future<SavedLessonModel?> get(String id);
  Future<void> save(SavedLessonModel model);
  Future<void> delete(String id);
}
