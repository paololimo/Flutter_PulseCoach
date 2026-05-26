import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_progress_stats.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_state.dart';

import 'progress_stats_cubit_test.mocks.dart';

@GenerateMocks([GetProgressStats])
void main() {
  group('ProgressStatsCubit', () {
    late MockGetProgressStats mockGetProgressStats;
    late ProgressStatsCubit cubit;

    setUp(() {
      mockGetProgressStats = MockGetProgressStats();
      cubit = ProgressStatsCubit(mockGetProgressStats);
    });

    tearDown(() async {
      await cubit.close();
    });

    test('10.2-CUBIT-001: initial state is ProgressStatsInitial', () {
      expect(cubit.state, isA<ProgressStatsInitial>());
    });

    blocTest<ProgressStatsCubit, ProgressStatsState>(
      '10.2-CUBIT-002: load() emits loading then loaded on success',
      build: () {
        when(
          mockGetProgressStats(),
        ).thenAnswer((_) async => const Right(_emptyStats));
        return ProgressStatsCubit(mockGetProgressStats);
      },
      act: (cubit) => cubit.load(),
      expect: () => [isA<ProgressStatsLoading>(), isA<ProgressStatsLoaded>()],
    );

    blocTest<ProgressStatsCubit, ProgressStatsState>(
      '10.2-CUBIT-003: load() emits loading then error on failure',
      build: () {
        when(mockGetProgressStats()).thenAnswer(
          (_) async => const Left(CacheFailure('progress_stats_load_failed')),
        );
        return ProgressStatsCubit(mockGetProgressStats);
      },
      act: (cubit) => cubit.load(),
      expect: () => [isA<ProgressStatsLoading>(), isA<ProgressStatsError>()],
    );

    test('10.2-CUBIT-004: no emit after close', () async {
      final completer = Completer<Either<Failure, ProgressStats>>();
      when(mockGetProgressStats()).thenAnswer((_) => completer.future);
      final states = <ProgressStatsState>[];
      final subscription = cubit.stream.listen(states.add);

      unawaited(cubit.load());
      await Future<void>.delayed(Duration.zero);
      await cubit.close();
      completer.complete(const Right(_emptyStats));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(states.whereType<ProgressStatsLoaded>(), isEmpty);
      expect(states.whereType<ProgressStatsError>(), isEmpty);
    });
  });
}

const _emptyStats = ProgressStats(
  completedCount: 0,
  abandonedCount: 0,
  minutesPerWeek: [],
  rpeTrend: [],
  sessionTypeCounts: {},
);
