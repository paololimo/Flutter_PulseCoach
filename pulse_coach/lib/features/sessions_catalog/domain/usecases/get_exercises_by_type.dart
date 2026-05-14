import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/repositories/exercise_repository.dart';

@injectable
class GetExercisesByType {
  GetExercisesByType(this._repository);

  final ExerciseRepository _repository;

  Future<Either<Failure, List<Exercise>>> call(String sessionType) =>
      _repository.getExercisesByType(sessionType);
}
