import '../../domain/entities/saved_lesson.dart';
import '../../domain/repositories/saved_lessons_repository.dart';
import '../datasources/saved_lessons_datasource.dart';
import '../models/saved_lesson_model.dart';

/// Bridges the domain SavedLessonsRepository contract to the datasource.
/// Maps DTOs at the boundary so the domain layer never sees JSON.
class SavedLessonsRepositoryImpl implements SavedLessonsRepository {
  const SavedLessonsRepositoryImpl({required this.datasource});

  final SavedLessonsDatasource datasource;

  @override
  Future<List<SavedLesson>> all() async {
    final models = await datasource.all();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<SavedLesson?> get(String id) async {
    final model = await datasource.get(id);
    return model?.toEntity();
  }

  @override
  Future<void> save(SavedLesson lesson) async {
    await datasource.save(SavedLessonModel.fromEntity(lesson));
  }

  @override
  Future<void> delete(String id) async {
    await datasource.delete(id);
  }
}
