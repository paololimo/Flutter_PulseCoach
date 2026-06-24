// [18.1-CUBIT-001..003] VisibilityCubit tests.
// Verifies initial state and select() emissions.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/visibility_cubit.dart';

void main() {
  group('VisibilityCubit', () {
    test('18.1-CUBIT-001: initial state is private', () {
      final cubit = VisibilityCubit();
      expect(cubit.state, VisibilityTier.private);
      cubit.close();
    });

    blocTest<VisibilityCubit, VisibilityTier>(
      '18.1-CUBIT-002: select(friendsOnly) emits friendsOnly',
      build: VisibilityCubit.new,
      act: (cubit) => cubit.select(VisibilityTier.friendsOnly),
      expect: () => [VisibilityTier.friendsOnly],
    );

    blocTest<VisibilityCubit, VisibilityTier>(
      '18.1-CUBIT-003: select(private) from friendsOnly emits private',
      build: VisibilityCubit.new,
      seed: () => VisibilityTier.friendsOnly,
      act: (cubit) => cubit.select(VisibilityTier.private),
      expect: () => [VisibilityTier.private],
    );
  });
}
