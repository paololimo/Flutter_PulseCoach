import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';

void main() {
  group('TodaySessionCubit', () {
    test('7.3-UNIT-004: initial state has no sessions or completions', () {
      final cubit = TodaySessionCubit();
      addTearDown(cubit.close);

      expect(cubit.state.heroIndex, 0);
      expect(cubit.state.completedIndices, isEmpty);
      expect(cubit.state.completedCount, 0);
      expect(cubit.state.totalSessions, 0);
    });

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-005: planLoaded resets hero and completion state',
      build: TodaySessionCubit.new,
      seed: () => const TodaySessionState(
        heroIndex: 2,
        completedIndices: {0, 2},
        totalSessions: 3,
      ),
      act: (cubit) => cubit.planLoaded(3),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.heroIndex, 'heroIndex', 0)
            .having(
              (state) => state.completedIndices,
              'completedIndices',
              isEmpty,
            )
            .having((state) => state.totalSessions, 'totalSessions', 3),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-006: swapHero selects an incomplete in-range session',
      build: TodaySessionCubit.new,
      seed: () => const TodaySessionState(totalSessions: 3),
      act: (cubit) => cubit.swapHero(2),
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.heroIndex,
          'heroIndex',
          2,
        ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-007: swapHero ignores negative and out-of-range indices',
      build: TodaySessionCubit.new,
      seed: () => const TodaySessionState(totalSessions: 3),
      act: (cubit) {
        cubit.swapHero(-1);
        cubit.swapHero(3);
      },
      expect: () => <TodaySessionState>[],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-008: swapHero ignores already completed session',
      build: TodaySessionCubit.new,
      seed: () => const TodaySessionState(
        heroIndex: 1,
        completedIndices: {0},
        totalSessions: 3,
      ),
      act: (cubit) => cubit.swapHero(0),
      expect: () => <TodaySessionState>[],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-009: completing swapped hero records the tapped session identity',
      build: TodaySessionCubit.new,
      seed: () => const TodaySessionState(heroIndex: 2, totalSessions: 3),
      act: (cubit) => cubit.markSessionCompleted(),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.completedIndices, 'completedIndices', {2})
            .having((state) => state.heroIndex, 'heroIndex', 0)
            .having((state) => state.completedCount, 'completedCount', 1),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-010: markSessionCompleted advances to next incomplete session',
      build: TodaySessionCubit.new,
      seed: () => const TodaySessionState(
        heroIndex: 0,
        completedIndices: {2},
        totalSessions: 3,
      ),
      act: (cubit) => cubit.markSessionCompleted(),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.completedIndices, 'completedIndices', {
              0,
              2,
            })
            .having((state) => state.heroIndex, 'heroIndex', 1),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-011: markSessionCompleted ignores duplicate completion',
      build: TodaySessionCubit.new,
      seed: () => const TodaySessionState(
        heroIndex: 1,
        completedIndices: {1},
        totalSessions: 3,
      ),
      act: (cubit) => cubit.markSessionCompleted(),
      expect: () => <TodaySessionState>[],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-012: markSessionCompleted ignores zero-session plans',
      build: TodaySessionCubit.new,
      act: (cubit) => cubit.markSessionCompleted(),
      expect: () => <TodaySessionState>[],
    );
  });
}
