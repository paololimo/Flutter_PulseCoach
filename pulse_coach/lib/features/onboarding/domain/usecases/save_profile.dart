import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';

@injectable
class SaveProfile {
  SaveProfile(this._repository);
  final OnboardingRepository _repository;

  Future<Either<Failure, void>> call(UserProfile profile) =>
      _repository.saveProfile(profile);
}
