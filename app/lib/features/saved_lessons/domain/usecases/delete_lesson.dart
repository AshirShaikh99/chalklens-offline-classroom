import '../../../../core/usecases/usecase.dart';
import '../repositories/saved_lessons_repository.dart';

class DeleteLesson implements UseCase<void, String> {
  const DeleteLesson(this.repository);

  final SavedLessonsRepository repository;

  @override
  Future<void> call(String params) => repository.delete(params);
}
