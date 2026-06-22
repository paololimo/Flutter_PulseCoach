import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart';
import 'package:pulse_coach/features/subscription/domain/entities/feature.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
// User is re-exported by supabase_client.dart — no direct supabase_flutter import needed.

// ARCH25 boundary: this file may only read auth state via SupabaseClientProvider
// and MUST NOT import package:pulse_coach/features/auth/... directly.

@singleton
class EntitlementGate {
  final SupabaseClientProvider _supabase;
  SubscriptionTier _cachedTier = SubscriptionTier.accountFree;

  EntitlementGate(this._supabase) {
    isProFetcher = () async {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey('pro');
    };
    currentUserProvider = () => _supabase.client.auth.currentUser;
  }

  /// Overridable in tests to avoid real Purchases SDK calls.
  @visibleForTesting
  late Future<bool> Function() isProFetcher;

  /// Overridable in tests to avoid depending on a live Supabase session.
  @visibleForTesting
  late User? Function() currentUserProvider;

  /// Synchronous tier read — returns the last cached value.
  /// Defaults to [SubscriptionTier.accountFree] until the first [refresh()].
  SubscriptionTier check(Feature feature) => _cachedTier;

  /// The current cached tier, independent of any [Feature].
  /// Defaults to [SubscriptionTier.accountFree] until the first [refresh()].
  SubscriptionTier get currentTier => _cachedTier;

  /// Fetches the latest entitlement state from RevenueCat and updates the
  /// cached tier. On error, the previous cached tier is preserved (NFR34).
  Future<void> refresh() async {
    try {
      final isPro = await isProFetcher();
      final user = currentUserProvider();
      if (isPro) {
        _cachedTier = SubscriptionTier.pro;
      } else if (user != null) {
        _cachedTier = SubscriptionTier.signedInFree;
      } else {
        _cachedTier = SubscriptionTier.accountFree;
      }
    } catch (e) {
      // Preserve cached tier on connectivity failure (NFR34); log for
      // diagnostics so a misconfigured SDK or seam bug is not silent.
      debugPrint('EntitlementGate.refresh failed: $e — preserving cached tier');
    }
  }
}
