import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/repositories/entitlement_repository.dart';

@injectable
class CheckEntitlementUseCase {
  final EntitlementRepository _repository;
  CheckEntitlementUseCase(this._repository);

  Future<Either<Failure, SubscriptionTier>> call() async {
    try {
      final tier = await _repository.currentTier();
      return Right(tier);
    } catch (e) {
      return Left(SubscriptionFailure(e.toString()));
    }
  }
}
