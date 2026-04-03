import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/health_data.dart';
import 'package:pulse_coach/features/session/domain/repositories/health_repository.dart';

/// Fetches HR + steps from Health API and persists to behavioral_state table.
/// Returns [HealthData] on success, [SensorFailure] on permission denial or error.
/// On failure, returns Left — caller should continue with RPE-only mode (do NOT surface error to user).
@injectable
class GetHealthData {
  GetHealthData(this._repository);
  final HealthRepository _repository;

  Future<Either<Failure, HealthData>> call() async {
    final result = await _repository.fetchHealthData();
    return result.fold(
      (failure) => Left(failure),
      (data) async {
        // Store to behavioral_state regardless of null fields (RPE-only mode is valid)
        await _repository.saveHealthData(data);
        return Right(data);
      },
    );
  }
}
