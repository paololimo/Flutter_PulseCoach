import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session.dart';
import 'package:pulse_coach/features/social/shared_session/domain/repositories/shared_session_repository.dart';

@injectable
class JoinSharedSessionUseCase {
  final SharedSessionRepository _repository;
  const JoinSharedSessionUseCase(this._repository);

  Future<Either<Failure, SharedSession>> call({
    required String joinCode,
    required String userId,
  }) =>
      _repository.joinSharedSession(joinCode: joinCode, userId: userId);
}
