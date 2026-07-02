import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';

abstract class LeaderboardRepository {
  Future<Either<Failure, Unit>> awardSessionPoints({
    required int sessionLogId,
    required int basePoints,
    required DateTime awardedOnUtc,
  });
}
