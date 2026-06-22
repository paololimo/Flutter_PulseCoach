import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
// SupabaseClientProvider and re-exported User come from the ARCH25 boundary.
import 'package:pulse_coach/core/cloud/supabase_client.dart';
import 'package:pulse_coach/core/cloud/entitlement_gate.dart';
import 'package:pulse_coach/features/subscription/domain/entities/feature.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';

import 'entitlement_gate_test.mocks.dart';

@GenerateMocks([SupabaseClientProvider])
void main() {
  late MockSupabaseClientProvider mockSupabase;

  final fakeUser = User(
    id: 'user-id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );

  setUp(() {
    mockSupabase = MockSupabaseClientProvider();
  });

  /// Helper: builds a gate with both test seams pre-configured.
  EntitlementGate buildGate({
    required Future<bool> Function() isPro,
    User? currentUser,
  }) {
    return EntitlementGate(mockSupabase)
      ..isProFetcher = isPro
      ..currentUserProvider = () => currentUser;
  }

  group('EntitlementGate —', () {
    test('check() defaults to accountFree before any refresh', () {
      final gate = EntitlementGate(mockSupabase);
      expect(
        gate.check(Feature.progressHistory),
        SubscriptionTier.accountFree,
      );
    });

    test('check() returns pro after refresh() with active pro entitlement', () async {
      final gate = buildGate(isPro: () async => true, currentUser: null);
      await gate.refresh();
      expect(gate.check(Feature.progressHistory), SubscriptionTier.pro);
    });

    test(
      'check() returns signedInFree after refresh() '
      'when no pro entitlement but user is signed in',
      () async {
        final gate = buildGate(isPro: () async => false, currentUser: fakeUser);
        await gate.refresh();
        expect(
          gate.check(Feature.progressHistory),
          SubscriptionTier.signedInFree,
        );
      },
    );

    test(
      'check() returns accountFree after refresh() '
      'when no pro entitlement and no session',
      () async {
        final gate = buildGate(isPro: () async => false, currentUser: null);
        await gate.refresh();
        expect(
          gate.check(Feature.progressHistory),
          SubscriptionTier.accountFree,
        );
      },
    );

    test('check() preserves cached tier when refresh() throws (NFR34)', () async {
      final gate = buildGate(isPro: () async => true, currentUser: null);
      await gate.refresh();
      expect(gate.check(Feature.progressHistory), SubscriptionTier.pro);

      // Simulate connectivity failure
      gate.isProFetcher = () async => throw Exception('network error');
      await gate.refresh();
      // Cached pro tier preserved
      expect(gate.check(Feature.progressHistory), SubscriptionTier.pro);
    });
  });
}
