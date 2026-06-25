import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session.dart';
import 'package:pulse_coach/features/social/shared_session/domain/repositories/shared_session_repository.dart';

@injectable
class CreateSharedSessionUseCase {
  final SharedSessionRepository _repository;
  const CreateSharedSessionUseCase(this._repository);

  Future<Either<Failure, SharedSession>> call({required String hostUserId}) =>
      _repository.createSharedSession(hostUserId: hostUserId);
}
