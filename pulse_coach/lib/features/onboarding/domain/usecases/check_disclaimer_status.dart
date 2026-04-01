import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';

@injectable
class CheckDisclaimerStatus {
  CheckDisclaimerStatus(this._repository);
  final OnboardingRepository _repository;

  Future<Either<Failure, bool>> call() => _repository.isDisclaimerAccepted();
}
