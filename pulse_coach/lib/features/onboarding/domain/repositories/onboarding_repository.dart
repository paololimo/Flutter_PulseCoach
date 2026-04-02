import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, void>> acceptDisclaimer();
  Future<Either<Failure, bool>> isDisclaimerAccepted();
  Future<Either<Failure, void>> saveProfile(UserProfile profile);
  Future<Either<Failure, UserProfile>> getProfile();
  Future<Either<Failure, void>> updateProfile(UserProfile profile);
}
