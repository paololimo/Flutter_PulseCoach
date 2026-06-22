import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/entitlement_gate.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/repositories/entitlement_repository.dart';

@Injectable(as: EntitlementRepository)
class EntitlementRepositoryImpl implements EntitlementRepository {
  final EntitlementGate _gate;

  EntitlementRepositoryImpl(this._gate);

  @override
  Future<SubscriptionTier> currentTier() async {
    // The gate is the single source of truth: refresh() does one RevenueCat
    // fetch and resolves all three tiers from (auth session + pro entitlement).
    await _gate.refresh();
    return _gate.currentTier;
  }

  @override
  Future<void> invalidateCache() async {
    await _gate.refresh();
  }
}
