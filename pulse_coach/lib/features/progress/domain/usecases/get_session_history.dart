import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';

@lazySingleton
class GetSessionHistory {
  const GetSessionHistory(this._repository);

  final ProgressRepository _repository;

  Future<Either<Failure, List<SessionHistoryEntry>>> call() =>
      _repository.getSessionHistory();
}
