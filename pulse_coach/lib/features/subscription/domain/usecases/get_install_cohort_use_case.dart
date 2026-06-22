import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';

@injectable
class GetInstallCohortUseCase {
  final OnboardingRepository _repository;
  GetInstallCohortUseCase(this._repository);

  Future<Either<Failure, String?>> call() => _repository.getInstallCohort();
}
