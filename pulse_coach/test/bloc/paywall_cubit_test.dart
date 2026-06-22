// [17.4-PAYWALL-001..003] PaywallCubit tests
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/get_offerings_use_case.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/paywall_cubit.dart';

import 'paywall_cubit_test.mocks.dart';

@GenerateMocks([GetOfferingsUseCase])
void main() {
  late MockGetOfferingsUseCase mockGetOfferings;

  setUp(() {
    mockGetOfferings = MockGetOfferingsUseCase();
  });

  PaywallCubit buildCubit() => PaywallCubit(mockGetOfferings);

  const testOffer = ProOffer(
    packageId: r'$rc_monthly',
    priceString: '€ 4,99',
    period: 'mensile',
  );

  group('PaywallCubit —', () {
    test('17.4-PAYWALL-003: initial state is loading()', () {
      when(mockGetOfferings.call())
          .thenAnswer((_) async => const Right([testOffer]));
      expect(buildCubit().state, const PaywallState.loading());
    });

    blocTest<PaywallCubit, PaywallState>(
      '17.4-PAYWALL-001: loadOfferings() emits [loading, loaded] when use case returns offers',
      setUp: () {
        when(mockGetOfferings.call())
            .thenAnswer((_) async => const Right([testOffer]));
      },
      build: buildCubit,
      act: (cubit) => cubit.loadOfferings(),
      expect: () => [
        const PaywallState.loading(),
        const PaywallState.loaded(offers: [testOffer]),
      ],
    );

    blocTest<PaywallCubit, PaywallState>(
      '17.4-PAYWALL-002: loadOfferings() emits [loading, error] on SubscriptionFailure',
      setUp: () {
        when(mockGetOfferings.call()).thenAnswer(
          (_) async => const Left(SubscriptionFailure('network error')),
        );
      },
      build: buildCubit,
      act: (cubit) => cubit.loadOfferings(),
      expect: () => [
        const PaywallState.loading(),
        const PaywallState.error(message: 'network error'),
      ],
    );
  });
}
