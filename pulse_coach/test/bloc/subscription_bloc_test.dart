import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/check_entitlement_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/purchase_pro_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/restore_purchases_use_case.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';

import 'subscription_bloc_test.mocks.dart';

@GenerateMocks([
  CheckEntitlementUseCase,
  PurchaseProUseCase,
  RestorePurchasesUseCase,
])
void main() {
  late MockCheckEntitlementUseCase mockCheckEntitlement;
  late MockPurchaseProUseCase mockPurchasePro;
  late MockRestorePurchasesUseCase mockRestorePurchases;

  setUp(() {
    mockCheckEntitlement = MockCheckEntitlementUseCase();
    mockPurchasePro = MockPurchaseProUseCase();
    mockRestorePurchases = MockRestorePurchasesUseCase();
  });

  SubscriptionBloc buildBloc() =>
      SubscriptionBloc(mockCheckEntitlement, mockPurchasePro, mockRestorePurchases);

  group('SubscriptionBloc —', () {
    test('initial state is initial()', () {
      when(mockCheckEntitlement.call())
          .thenAnswer((_) async => const Right(SubscriptionTier.accountFree));
      expect(buildBloc().state, const SubscriptionState.initial());
    });

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [loading, loaded(pro)] when entitlement returns pro',
      setUp: () {
        when(mockCheckEntitlement.call())
            .thenAnswer((_) async => const Right(SubscriptionTier.pro));
      },
      build: buildBloc,
      // The bloc self-dispatches SubscriptionCheckRequested on construction
      act: (_) {},
      expect: () => [
        const SubscriptionState.loading(),
        const SubscriptionState.loaded(tier: SubscriptionTier.pro),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [loading, loaded(signedInFree)] for a signed-in non-pro user',
      setUp: () {
        when(mockCheckEntitlement.call())
            .thenAnswer((_) async => const Right(SubscriptionTier.signedInFree));
      },
      build: buildBloc,
      act: (_) {},
      expect: () => [
        const SubscriptionState.loading(),
        const SubscriptionState.loaded(tier: SubscriptionTier.signedInFree),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [loading, loaded(accountFree)] when no session and no entitlement',
      setUp: () {
        when(mockCheckEntitlement.call())
            .thenAnswer((_) async => const Right(SubscriptionTier.accountFree));
      },
      build: buildBloc,
      act: (_) {},
      expect: () => [
        const SubscriptionState.loading(),
        const SubscriptionState.loaded(tier: SubscriptionTier.accountFree),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      'emits [loading, error] on network failure; free core unaffected',
      setUp: () {
        when(mockCheckEntitlement.call()).thenAnswer(
          (_) async => const Left(SubscriptionFailure('network error')),
        );
      },
      build: buildBloc,
      act: (_) {},
      expect: () => [
        const SubscriptionState.loading(),
        const SubscriptionState.error(
          failure: SubscriptionFailure('network error'),
        ),
      ],
    );

    // 17.4 purchase and restore tests
    blocTest<SubscriptionBloc, SubscriptionState>(
      '17.4-BLOC-001: purchaseRequested emits [loading, loaded(pro)] on success',
      setUp: () {
        when(mockCheckEntitlement.call())
            .thenAnswer((_) async => const Right(SubscriptionTier.accountFree));
        when(mockPurchasePro.call(any))
            .thenAnswer((_) async => const Right(SubscriptionTier.pro));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SubscriptionEvent.purchaseRequested(packageId: r'$rc_monthly'),
      ),
      skip: 2, // skip initial self-dispatch [loading, loaded(accountFree)]
      expect: () => [
        const SubscriptionState.loading(),
        const SubscriptionState.loaded(tier: SubscriptionTier.pro),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      '17.4-BLOC-002: purchaseRequested emits [loading, error] on SubscriptionFailure',
      setUp: () {
        when(mockCheckEntitlement.call())
            .thenAnswer((_) async => const Right(SubscriptionTier.accountFree));
        when(mockPurchasePro.call(any)).thenAnswer(
          (_) async => const Left(SubscriptionFailure('Acquisto non riuscito')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const SubscriptionEvent.purchaseRequested(packageId: r'$rc_monthly'),
      ),
      skip: 2,
      expect: () => [
        const SubscriptionState.loading(),
        const SubscriptionState.error(
          failure: SubscriptionFailure('Acquisto non riuscito'),
        ),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      '17.4-BLOC-003: restoreRequested emits [loading, loaded(tier)] on success',
      setUp: () {
        when(mockCheckEntitlement.call())
            .thenAnswer((_) async => const Right(SubscriptionTier.accountFree));
        when(mockRestorePurchases.call())
            .thenAnswer((_) async => const Right(SubscriptionTier.pro));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SubscriptionEvent.restoreRequested()),
      skip: 2,
      expect: () => [
        const SubscriptionState.loading(),
        const SubscriptionState.loaded(tier: SubscriptionTier.pro),
      ],
    );

    blocTest<SubscriptionBloc, SubscriptionState>(
      '17.4-BLOC-004: restoreRequested emits [loading, error] on SubscriptionFailure',
      setUp: () {
        when(mockCheckEntitlement.call())
            .thenAnswer((_) async => const Right(SubscriptionTier.accountFree));
        when(mockRestorePurchases.call()).thenAnswer(
          (_) async =>
              const Left(SubscriptionFailure('Ripristino non riuscito')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const SubscriptionEvent.restoreRequested()),
      skip: 2,
      expect: () => [
        const SubscriptionState.loading(),
        const SubscriptionState.error(
          failure: SubscriptionFailure('Ripristino non riuscito'),
        ),
      ],
    );
  });
}
