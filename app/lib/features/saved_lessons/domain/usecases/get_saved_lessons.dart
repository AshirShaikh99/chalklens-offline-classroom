import '../../../../core/usecases/usecase.dart';
import '../entities/saved_lesson.dart';
import '../repositories/saved_lessons_repository.dart';

class GetSavedLessons implements UseCase<List<SavedLesson>, NoParams> {
  const GetSavedLessons(this.repository);

  final SavedLessonsRepository repository;

  @override
  Future<List<SavedLesson>> call(NoParams params) => repository.all();
}
