import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';

abstract class EntitlementRepository {
  /// Refreshes from RevenueCat and returns the resolved three-tier value.
  Future<SubscriptionTier> currentTier();
  Future<void> invalidateCache();
}
