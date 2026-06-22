import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/check_entitlement_use_case.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';

import 'subscription_bloc_test.mocks.dart';

@GenerateMocks([CheckEntitlementUseCase])
void main() {
  late MockCheckEntitlementUseCase mockCheckEntitlement;

  setUp(() {
    mockCheckEntitlement = MockCheckEntitlementUseCase();
  });

  SubscriptionBloc buildBloc() => SubscriptionBloc(mockCheckEntitlement);

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
          (_) async =>
              const Left(SubscriptionFailure('network error')),
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
  });
}
