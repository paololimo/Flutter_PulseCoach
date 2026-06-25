import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/domain/repositories/shared_session_repository.dart';

@injectable
class RefreshJoinCodeUseCase {
  final SharedSessionRepository _repository;
  const RefreshJoinCodeUseCase(this._repository);

  Future<Either<Failure, String>> call({required String sessionId}) =>
      _repository.refreshJoinCode(sessionId: sessionId);
}
