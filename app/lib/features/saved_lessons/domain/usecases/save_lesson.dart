import '../../../../core/usecases/usecase.dart';
import '../entities/saved_lesson.dart';
import '../repositories/saved_lessons_repository.dart';

class SaveLesson implements UseCase<void, SavedLesson> {
  const SaveLesson(this.repository);

  final SavedLessonsRepository repository;

  @override
  Future<void> call(SavedLesson params) => repository.save(params);
}
