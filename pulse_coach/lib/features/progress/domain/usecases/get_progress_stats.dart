import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';

@lazySingleton
class GetProgressStats {
  const GetProgressStats(this._repository);

  final ProgressRepository _repository;

  Future<Either<Failure, ProgressStats>> call() =>
      _repository.getProgressStats();
}
