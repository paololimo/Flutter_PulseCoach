import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';

abstract class EntitlementRepository {
  /// Refreshes from RevenueCat and returns the resolved three-tier value.
  Future<SubscriptionTier> currentTier();
  Future<void> invalidateCache();

  Future<Either<Failure, List<ProOffer>>> getOfferings();
  Future<Either<Failure, SubscriptionTier>> purchasePro(String packageId);
  Future<Either<Failure, SubscriptionTier>> restorePurchases();
}
