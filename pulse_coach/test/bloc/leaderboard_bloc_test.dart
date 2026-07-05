import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/database/app_database.dart' as db_models;
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/leaderboard/data/rank_freeze_store.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/usecases/get_friends_leaderboard_use_case.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_event.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_state.dart';

import 'leaderboard_bloc_test.mocks.dart';

@GenerateMocks([GetFriendsLeaderboardUseCase, RankFreezeStore])
void main() {
  late MockGetFriendsLeaderboardUseCase mockUseCase;
  late MockRankFreezeStore mockFreezeStore;
  late db_models.AppDatabase db;

  const tRaw = Right<
    Failure,
    List<
      ({String userId, String displayHandle, int totalPoints, bool isOwn})
    >
  >([
    (userId: 'a', displayHandle: 'alice', totalPoints: 100, isOwn: false),
    (userId: 'b', displayHandle: 'bob', totalPoints: 80, isOwn: false),
    (userId: 'me', displayHandle: 'zzz', totalPoints: 60, isOwn: true),
    (userId: 'd', displayHandle: 'dave', totalPoints: 10, isOwn: false),
  ]);

  setUp(() {
    mockUseCase = MockGetFriendsLeaderboardUseCase();
    mockFreezeStore = MockRankFreezeStore();
    db = db_models.AppDatabase.forTesting(NativeDatabase.memory());
    when(mockUseCase.call()).thenAnswer((_) async => tRaw);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertState(String state) => db.behavioralStateDao.insertState(
    db_models.BehavioralStateCompanion.insert(
      currentState: state,
      recordedAt: DateTime.utc(2026, 7, 4, 8, 0),
      updatedAt: DateTime.utc(2026, 7, 4, 8, 0),
    ),
  );

  LeaderboardBloc bloc() => LeaderboardBloc(mockUseCase, mockFreezeStore, db);

  group('LeaderboardBloc', () {
    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-001] state=Active, no stored freeze → loaded with live ranking, isFrozen: false',
      setUp: () async {
        await insertState('Active');
        when(mockFreezeStore.getFrozenRank()).thenReturn(null);
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      expect: () => [
        const LeaderboardState.loading(),
        isA<LeaderboardState>(),
      ],
      verify: (bloc) {
        final state = bloc.state as dynamic;
        final entries = state.entries as List;
        expect(entries.firstWhere((e) => e.isOwn).rank, 3);
        expect(state.isFrozen, isFalse);
        verify(mockFreezeStore.clear()).called(1);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-002] state=AtRisk, no stored freeze → captures live rank, calls freezeStore.setFrozenRank with it, isFrozen: true',
      setUp: () async {
        await insertState('AtRisk');
        when(mockFreezeStore.getFrozenRank()).thenReturn(null);
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      verify: (bloc) {
        verify(mockFreezeStore.setFrozenRank(3)).called(1);
        final state = bloc.state as dynamic;
        expect(state.isFrozen, isTrue);
        final entries = state.entries as List;
        expect(entries.firstWhere((e) => e.isOwn).rank, 3);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-003] state=AtRisk, stored freeze=2, live rank would now be 3 → own entry pinned at rank 2, isFrozen: true',
      setUp: () async {
        await insertState('AtRisk');
        when(mockFreezeStore.getFrozenRank()).thenReturn(2);
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      verify: (bloc) {
        verifyNever(mockFreezeStore.setFrozenRank(any));
        final state = bloc.state as dynamic;
        expect(state.isFrozen, isTrue);
        final entries = state.entries as List;
        expect(entries.firstWhere((e) => e.isOwn).rank, 2);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-004a] state=Recovering, no stored freeze → same freeze behavior as AtRisk',
      setUp: () async {
        await insertState('Recovering');
        when(mockFreezeStore.getFrozenRank()).thenReturn(null);
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      verify: (bloc) {
        verify(mockFreezeStore.setFrozenRank(3)).called(1);
        final state = bloc.state as dynamic;
        expect(state.isFrozen, isTrue);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-004b] state=Recovering, stored freeze=2 → own entry pinned at rank 2',
      setUp: () async {
        await insertState('Recovering');
        when(mockFreezeStore.getFrozenRank()).thenReturn(2);
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      verify: (bloc) {
        final state = bloc.state as dynamic;
        final entries = state.entries as List;
        expect(entries.firstWhere((e) => e.isOwn).rank, 2);
        expect(state.isFrozen, isTrue);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-005] previously frozen, state now Fatigued → freezeStore.clear() called, live ranking shown, isFrozen: false',
      setUp: () async {
        await insertState('Fatigued');
        when(mockFreezeStore.getFrozenRank()).thenReturn(2);
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      verify: (bloc) {
        verify(mockFreezeStore.clear()).called(1);
        final state = bloc.state as dynamic;
        expect(state.isFrozen, isFalse);
        final entries = state.entries as List;
        expect(entries.firstWhere((e) => e.isOwn).rank, 3);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-006] repository returns Left → error state',
      setUp: () async {
        await insertState('Active');
        when(
          mockUseCase.call(),
        ).thenAnswer((_) async => const Left(SocialFailure('boom')));
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      expect: () => [
        const LeaderboardState.loading(),
        const LeaderboardState.error(failure: SocialFailure('boom')),
      ],
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-007] behavioralStateDao.getLatestState() returns null → defaults to Active (unfrozen)',
      setUp: () async {
        when(mockFreezeStore.getFrozenRank()).thenReturn(2);
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      verify: (bloc) {
        verify(mockFreezeStore.clear()).called(1);
        final state = bloc.state as dynamic;
        expect(state.isFrozen, isFalse);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-008] state=AtRisk, no stored freeze, own entry absent from '
      'the live ranking (e.g. dropped from the friends list) → '
      'setFrozenRank never called, isFrozen: false',
      setUp: () async {
        await insertState('AtRisk');
        when(mockFreezeStore.getFrozenRank()).thenReturn(null);
        when(mockUseCase.call()).thenAnswer(
          (_) async => const Right([
            (userId: 'a', displayHandle: 'alice', totalPoints: 100, isOwn: false),
            (userId: 'b', displayHandle: 'bob', totalPoints: 80, isOwn: false),
          ]),
        );
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      verify: (bloc) {
        verifyNever(mockFreezeStore.setFrozenRank(any));
        final state = bloc.state as dynamic;
        expect(state.isFrozen, isFalse);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-009] state=AtRisk, stored freeze=2, own entry absent from '
      'this fetch (dropped mid-freeze) → ranking still returned, '
      'isFrozen: false (stored rank exists but is not applied to anyone)',
      setUp: () async {
        await insertState('AtRisk');
        when(mockFreezeStore.getFrozenRank()).thenReturn(2);
        when(mockUseCase.call()).thenAnswer(
          (_) async => const Right([
            (userId: 'a', displayHandle: 'alice', totalPoints: 100, isOwn: false),
            (userId: 'b', displayHandle: 'bob', totalPoints: 80, isOwn: false),
          ]),
        );
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      verify: (bloc) {
        verifyNever(mockFreezeStore.setFrozenRank(any));
        final state = bloc.state as dynamic;
        expect(state.isFrozen, isFalse);
        final entries = state.entries as List;
        expect(entries.length, 2);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.2-BLOC-010] freezeStore.clear() throws (e.g. a storage race) → '
      'caught, error state emitted instead of the bloc staying wedged on '
      'loading',
      setUp: () async {
        await insertState('Active');
        when(mockFreezeStore.getFrozenRank()).thenReturn(null);
        when(mockFreezeStore.clear()).thenThrow(Exception('storage race'));
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      verify: (bloc) {
        final isError = bloc.state.whenOrNull(error: (_) => true);
        expect(isError, isTrue);
      },
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      '[21.3-BLOC-001] state=AtRisk, stored freeze=2, own totalPoints '
      'already reflects an awarded shared-session bonus that would move '
      'the live rank to 1 → still pinned at the frozen rank 2 (a bonus '
      'awarded while protective produces no visible rank change per 21.3 '
      'AC3; scoring and rank-freeze are independent concerns)',
      setUp: () async {
        await insertState('AtRisk');
        when(mockFreezeStore.getFrozenRank()).thenReturn(2);
        when(mockUseCase.call()).thenAnswer(
          (_) async => const Right<
            Failure,
            List<
              ({
                String userId,
                String displayHandle,
                int totalPoints,
                bool isOwn,
              })
            >
          >([
            (userId: 'a', displayHandle: 'alice', totalPoints: 100, isOwn: false),
            // Own points now exceed alice's — a shared-session bonus (21.3)
            // was awarded unconditionally while AtRisk, unaware of freeze.
            (userId: 'me', displayHandle: 'zzz', totalPoints: 150, isOwn: true),
            (userId: 'b', displayHandle: 'bob', totalPoints: 80, isOwn: false),
            (userId: 'd', displayHandle: 'dave', totalPoints: 10, isOwn: false),
          ]),
        );
      },
      build: bloc,
      act: (bloc) => bloc.add(const LeaderboardLoaded()),
      verify: (bloc) {
        verifyNever(mockFreezeStore.setFrozenRank(any));
        final state = bloc.state as dynamic;
        expect(state.isFrozen, isTrue);
        final entries = state.entries as List;
        // Live rank for 150 points would be 1st; frozen rank keeps it at 2.
        expect(entries.firstWhere((e) => e.isOwn).rank, 2);
      },
    );
  });
}
