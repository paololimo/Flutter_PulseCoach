import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, void>> acceptDisclaimer();
  Future<Either<Failure, bool>> isDisclaimerAccepted();
}
