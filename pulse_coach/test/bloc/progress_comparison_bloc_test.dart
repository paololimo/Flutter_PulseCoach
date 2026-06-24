// [18.4-BLOC-001..004] ProgressComparisonBloc tests
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';
import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
import 'package:pulse_coach/features/social/comparison/domain/repositories/progress_comparison_repository.dart';
import 'package:pulse_coach/features/social/comparison/domain/usecases/get_friends_comparison_use_case.dart';
import 'package:pulse_coach/features/social/comparison/domain/usecases/get_own_weekly_summary_use_case.dart';
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_bloc.dart';
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_event.dart';
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_state.dart';

import 'progress_comparison_bloc_test.mocks.dart';

@GenerateMocks([ProgressComparisonRepository, ProgressRepository])
void main() {
  late MockProgressComparisonRepository mockComparisonRepo;
  late MockProgressRepository mockProgressRepo;
  late GetFriendsComparisonUseCase getFriends;
  late GetOwnWeeklySummaryUseCase getOwn;

  const tOwnHandle = 'paolol';
  const tFailure = SocialFailure('network error');

  const tFriendEntry = ProgressComparisonEntry(
    displayHandle: 'alice',
    sessionsThisWeek: 2,
    minutesThisWeek: 35,
  );

  const tStats = ProgressStats(
    completedCount: 5,
    abandonedCount: 1,
    minutesPerWeek: [],
    rpeTrend: [],
    sessionTypeCounts: {},
    completedThisWeek: 2,
    weeklyTarget: 3,
  );

  setUp(() {
    mockComparisonRepo = MockProgressComparisonRepository();
    mockProgressRepo = MockProgressRepository();
    getFriends = GetFriendsComparisonUseCase(mockComparisonRepo);
    getOwn = GetOwnWeeklySummaryUseCase(mockProgressRepo);
  });

  ProgressComparisonBloc buildBloc() =>
      ProgressComparisonBloc(getFriends, getOwn);

  group('ProgressComparisonLoaded', () {
    blocTest<ProgressComparisonBloc, ProgressComparisonState>(
      '18.4-BLOC-001: ProgressComparisonLoaded → [loading, loaded(ownEntry, friendEntries)]'
      ' ownEntry.isOwn = true, friendEntries[0].isOwn = false',
      build: () {
        when(mockComparisonRepo.getFriendsProgress())
            .thenAnswer((_) async => const Right<SocialFailure, List<ProgressComparisonEntry>>([tFriendEntry]));
        when(mockProgressRepo.getProgressStats())
            .thenAnswer((_) async => const Right<Failure, ProgressStats>(tStats));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProgressComparisonLoaded(tOwnHandle)),
      expect: () => [
        const ProgressComparisonState.loading(),
        const ProgressComparisonState.loaded(
          ownEntry: ProgressComparisonEntry(
            displayHandle: tOwnHandle,
            sessionsThisWeek: 2,
            minutesThisWeek: 0, // no weekly minutes bucket matching this week
            isOwn: true,
          ),
          friendEntries: [tFriendEntry],
        ),
      ],
    );

    blocTest<ProgressComparisonBloc, ProgressComparisonState>(
      '18.4-BLOC-002: ProgressComparisonLoaded — getFriendsProgress error → [loading, error]',
      build: () {
        when(mockComparisonRepo.getFriendsProgress())
            .thenAnswer((_) async => const Left(tFailure));
        when(mockProgressRepo.getProgressStats())
            .thenAnswer((_) async => const Right<Failure, ProgressStats>(tStats));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProgressComparisonLoaded(tOwnHandle)),
      expect: () => [
        const ProgressComparisonState.loading(),
        const ProgressComparisonState.error(failure: tFailure),
      ],
    );

    blocTest<ProgressComparisonBloc, ProgressComparisonState>(
      '18.4-BLOC-003: ProgressComparisonLoaded — getOwnWeeklySummary error → [loading, error]',
      build: () {
        when(mockComparisonRepo.getFriendsProgress())
            .thenAnswer((_) async => const Right<SocialFailure, List<ProgressComparisonEntry>>([tFriendEntry]));
        when(mockProgressRepo.getProgressStats()).thenAnswer(
          (_) async => const Left(CacheFailure('db error')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProgressComparisonLoaded(tOwnHandle)),
      expect: () => [
        const ProgressComparisonState.loading(),
        const ProgressComparisonState.error(
            failure: CacheFailure('db error')),
      ],
    );

    blocTest<ProgressComparisonBloc, ProgressComparisonState>(
      '18.4-BLOC-004: ProgressComparisonLoaded — empty friend list → [loading, loaded(ownEntry, [])]',
      build: () {
        when(mockComparisonRepo.getFriendsProgress())
            .thenAnswer((_) async => const Right([]));
        when(mockProgressRepo.getProgressStats())
            .thenAnswer((_) async => const Right<Failure, ProgressStats>(tStats));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProgressComparisonLoaded(tOwnHandle)),
      expect: () => [
        const ProgressComparisonState.loading(),
        const ProgressComparisonState.loaded(
          ownEntry: ProgressComparisonEntry(
            displayHandle: tOwnHandle,
            sessionsThisWeek: 2,
            minutesThisWeek: 0,
            isOwn: true,
          ),
          friendEntries: [],
        ),
      ],
    );
  });
}
