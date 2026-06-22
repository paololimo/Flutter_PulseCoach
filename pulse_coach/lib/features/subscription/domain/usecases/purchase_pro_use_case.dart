import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/repositories/entitlement_repository.dart';

@injectable
class PurchaseProUseCase {
  final EntitlementRepository _repository;
  PurchaseProUseCase(this._repository);

  Future<Either<Failure, SubscriptionTier>> call(String packageId) =>
      _repository.purchasePro(packageId);
}
