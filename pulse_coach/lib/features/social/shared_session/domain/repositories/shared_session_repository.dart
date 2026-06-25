import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session.dart';

abstract class SharedSessionRepository {
  Future<Either<Failure, SharedSession>> createSharedSession({
    required String hostUserId,
  });

  Future<Either<Failure, String>> refreshJoinCode({
    required String sessionId,
  });

  Future<Either<Failure, Unit>> deleteSharedSession({
    required String sessionId,
  });
}
