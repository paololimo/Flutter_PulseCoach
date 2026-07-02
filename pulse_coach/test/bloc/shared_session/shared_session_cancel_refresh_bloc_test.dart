// [20.1-BLOC-001..008] Cancel and refresh join code bloc tests
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:drift/native.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/get_social_profile_use_case.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/delete_shared_session_use_case.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/refresh_join_code_use_case.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';

import 'shared_session_bloc_test.mocks.dart';

@GenerateMocks([
  DeleteSharedSessionUseCase,
  RefreshJoinCodeUseCase,
  GetSocialProfileUseCase,
])
import 'shared_session_cancel_refresh_bloc_test.mocks.dart';
import 'shared_session_bloc_co_location_test.mocks.dart';

const _kSteps = [
  ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 60),
];

void main() {
  late MockRealtimeGateway mockGateway;
  late MockDeleteSharedSessionUseCase mockDelete;
  late MockRefreshJoinCodeUseCase mockRefresh;
  late MockLocationService mockLocation;
  late MockGetSocialProfileUseCase mockGetSocialProfile;
  late StreamController<BroadcastEvent> bc;
  late StreamController<PresenceState> pc;
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    mockGateway = MockRealtimeGateway();
    mockDelete = MockDeleteSharedSessionUseCase();
    mockRefresh = MockRefreshJoinCodeUseCase();
    mockLocation = MockLocationService();
    mockGetSocialProfile = MockGetSocialProfileUseCase();
    when(mockGetSocialProfile.call()).thenAnswer(
      (_) async => const Right(SocialProfile(
        userId: 'stub',
        displayHandle: null,
        visibilityTier: VisibilityTier.friendsOnly,
      )),
    );
    when(mockLocation.getCityLevelCoordinates())
        .thenAnswer((_) async => const Left(LocationFailure('disabled')));
    bc = StreamController<BroadcastEvent>.broadcast();
    pc = StreamController<PresenceState>.broadcast();
    when(mockGateway.broadcastEvents).thenAnswer((_) => bc.stream);
    when(mockGateway.presenceUpdates).thenAnswer((_) => pc.stream);
    when(mockGateway.joinChannel(any)).thenAnswer((_) async {});
    when(mockGateway.trackPresence(
      userId: anyNamed('userId'),
      displayHandle: anyNamed('displayHandle'),
      isHost: anyNamed('isHost'),
      lat: anyNamed('lat'),
      lon: anyNamed('lon'),
    )).thenAnswer((_) async {});
    when(mockGateway.leaveChannel()).thenAnswer((_) async {});
    when(mockDelete.call(sessionId: anyNamed('sessionId')))
        .thenAnswer((_) async => const Right(unit));
    when(mockRefresh.call(sessionId: anyNamed('sessionId')))
        .thenAnswer((_) async => const Right('XYZ789'));
  });

  tearDown(() async {
    bc.close();
    pc.close();
    await db.close();
  });

  group('SharedSessionBloc — Cancel and Refresh (20.1)', () {
    SharedSessionBloc build() => SharedSessionBloc(
        mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile);

    Future<void> joinLobby(SharedSessionBloc bloc) async {
      bloc.add(const SharedSessionJoined(
        sessionId: 'sess-1',
        isHost: true,
        userId: 'alice-uid',
        displayHandle: 'alice',
        steps: _kSteps,
        joinCode: 'ABC123',
      ));
      await Future<void>.delayed(Duration.zero);
    }

    // AC5: cancel flow
    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.1-BLOC-001: SharedSessionCancelled → deleteUseCase called + cancelled() emitted (AC5)',
      build: build,
      act: (bloc) async {
        await joinLobby(bloc);
        bloc.add(const SharedSessionCancelled());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        verify(mockDelete.call(sessionId: 'sess-1')).called(1);
        verify(mockGateway.leaveChannel()).called(1);
        expect(bloc.state, const SharedSessionState.cancelled());
      },
    );

    // AC5: cancel emits cancelled even if delete fails
    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.1-BLOC-002: cancel emits cancelled() even when deleteUseCase fails (AC5 resilience)',
      build: build,
      setUp: () {
        when(mockDelete.call(sessionId: anyNamed('sessionId')))
            .thenAnswer((_) async => const Left(ServerFailure('delete_failed')));
      },
      act: (bloc) async {
        await joinLobby(bloc);
        bloc.add(const SharedSessionCancelled());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state, const SharedSessionState.cancelled());
      },
    );

    // AC3: join code refresh
    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.1-BLOC-003: SharedSessionJoinCodeRefreshed → refreshUseCase called + lobby.joinCode updated (AC3)',
      build: build,
      act: (bloc) async {
        await joinLobby(bloc);
        bloc.add(const SharedSessionJoinCodeRefreshed());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        verify(mockRefresh.call(sessionId: 'sess-1')).called(1);
        final joinCode = bloc.state.mapOrNull(lobby: (s) => s.joinCode);
        expect(joinCode, 'XYZ789');
      },
    );

    // AC2: lobby.joinCode from initial join is set correctly
    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.1-BLOC-004: SharedSessionJoined with joinCode sets lobby.joinCode (AC2)',
      build: build,
      act: (bloc) async {
        await joinLobby(bloc);
      },
      verify: (bloc) {
        final joinCode = bloc.state.mapOrNull(lobby: (s) => s.joinCode);
        expect(joinCode, 'ABC123');
      },
    );

    // Refresh when not in lobby: no-op
    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.1-BLOC-005: refresh when not in lobby → no-op (guard)',
      build: build,
      act: (bloc) async {
        bloc.add(const SharedSessionJoinCodeRefreshed());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verifyNever(mockRefresh.call(sessionId: anyNamed('sessionId')));
      },
    );

    // Cancel before joining: still emits cancelled
    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.1-BLOC-006: cancel before joining channel → cancelled() without leaveChannel (guard)',
      build: build,
      act: (bloc) async {
        bloc.add(const SharedSessionCancelled());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        verifyNever(mockDelete.call(sessionId: anyNamed('sessionId')));
        verifyNever(mockGateway.leaveChannel());
        expect(bloc.state, const SharedSessionState.cancelled());
      },
    );

    // Existing 19.x events still work (regression)
    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.1-BLOC-007: existing SessionEndRequested still works (regression)',
      build: build,
      act: (bloc) async {
        await joinLobby(bloc);
        bc.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SessionEndRequested());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verify(mockGateway.sendBroadcast(
          event: 'session_ended',
          payload: anyNamed('payload'),
        )).called(1);
      },
    );

    // Follower cancel
    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.1-BLOC-008: follower cancel → emits cancelled() (host guard deferred to Story 20.3)',
      build: build,
      act: (bloc) async {
        bloc.add(const SharedSessionJoined(
          sessionId: 'sess-1',
          isHost: false,
          userId: 'bob-uid',
          displayHandle: 'bob',
          steps: _kSteps,
        ));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SharedSessionCancelled());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state, const SharedSessionState.cancelled());
      },
    );
  });
}
