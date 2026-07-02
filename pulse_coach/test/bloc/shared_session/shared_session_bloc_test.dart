// [19.2-BLOC-001..012] SharedSessionBloc unit tests
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:drift/native.dart';
import 'package:pulse_coach/core/cloud/realtime_gateway.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';

@GenerateNiceMocks([MockSpec<RealtimeGateway>()])
import 'shared_session_bloc_test.mocks.dart';
import 'shared_session_cancel_refresh_bloc_test.mocks.dart';
import 'shared_session_bloc_co_location_test.mocks.dart';

const _kSteps = [
  ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 60),
  ExerciseStep(title: 'Cardio', instruction: 'Run', durationSeconds: 120),
];

SharedSessionJoined _hostJoin({String sessionId = 'sess-1'}) =>
    SharedSessionJoined(
      sessionId: sessionId,
      isHost: true,
      userId: 'host-uid',
      displayHandle: 'alice',
      steps: _kSteps,
    );

SharedSessionJoined _followerJoin({String sessionId = 'sess-1'}) =>
    SharedSessionJoined(
      sessionId: sessionId,
      isHost: false,
      userId: 'follower-uid',
      displayHandle: 'bob',
      steps: _kSteps,
    );

void main() {
  late MockRealtimeGateway mockGateway;
  late MockDeleteSharedSessionUseCase mockDelete;
  late MockRefreshJoinCodeUseCase mockRefresh;
  late MockLocationService mockLocation;
  late MockGetSocialProfileUseCase mockGetSocialProfile;
  late StreamController<BroadcastEvent> broadcastController;
  late StreamController<PresenceState> presenceController;
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
    broadcastController = StreamController<BroadcastEvent>.broadcast();
    presenceController = StreamController<PresenceState>.broadcast();
    when(mockGateway.broadcastEvents)
        .thenAnswer((_) => broadcastController.stream);
    when(mockGateway.presenceUpdates)
        .thenAnswer((_) => presenceController.stream);
    when(mockGateway.joinChannel(any)).thenAnswer((_) async {});
    when(mockGateway.trackPresence(
            userId: anyNamed('userId'),
            displayHandle: anyNamed('displayHandle'),
            isHost: anyNamed('isHost'),
            lat: anyNamed('lat'),
            lon: anyNamed('lon')))
        .thenAnswer((_) async {});
    when(mockGateway.leaveChannel()).thenAnswer((_) async {});
    when(mockGateway.sendBroadcast(
            event: anyNamed('event'), payload: anyNamed('payload')))
        .thenAnswer((_) async {});
    when(mockGateway.untrackPresence()).thenAnswer((_) async {});
    when(mockDelete.call(sessionId: anyNamed('sessionId')))
        .thenAnswer((_) async => const Right(unit));
    when(mockRefresh.call(sessionId: anyNamed('sessionId')))
        .thenAnswer((_) async => const Right('NEW'));
  });

  tearDown(() async {
    broadcastController.close();
    presenceController.close();
    await db.close();
  });

  group('SharedSessionBloc (19.2)', () {
    test('19.2-BLOC-001: initial state is SharedSessionState.initial', () {
      final bloc = SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile);
      expect(bloc.state, const SharedSessionState.initial());
      bloc.close();
    });

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-002: SharedSessionJoined → loading → lobby',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) => bloc.add(_hostJoin()),
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
          participants: [],
          isHost: true,
          steps: _kSteps,
        ),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-003: joinChannel failure → error state',
      build: () {
        when(mockGateway.joinChannel(any))
            .thenThrow(Exception('ws failure'));
        return SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile);
      },
      act: (bloc) => bloc.add(_hostJoin()),
      expect: () => [
        const SharedSessionState.loading(),
        predicate<SharedSessionState>(
          (s) => s.mapOrNull(error: (e) => e.failure is RealtimeFailure) == true,
          'is error state with RealtimeFailure',
        ),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-004: PresenceState update → lobby.participants updated',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        presenceController.add(const PresenceState(participants: [
          ParticipantPresence(userId: 'host-uid', displayHandle: 'alice'),
          ParticipantPresence(userId: 'follower-uid', displayHandle: 'bob'),
        ]));
      },
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
            participants: [], isHost: true, steps: _kSteps),
        const SharedSessionState.lobby(
          participants: [
            ParticipantPresence(userId: 'host-uid', displayHandle: 'alice'),
            ParticipantPresence(
                userId: 'follower-uid', displayHandle: 'bob'),
          ],
          isHost: true,
          steps: _kSteps,
        ),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-005: SessionStartTapped with <2 participants → no broadcast',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SessionStartTapped());
      },
      verify: (_) {
        verifyNever(mockGateway.sendBroadcast(
          event: 'session_started',
          payload: anyNamed('payload'),
        ));
      },
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-006: follower cannot dispatch session_started (AC1)',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_followerJoin());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SessionStartTapped());
      },
      verify: (_) {
        verifyNever(mockGateway.sendBroadcast(
          event: 'session_started',
          payload: anyNamed('payload'),
        ));
      },
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-007: BroadcastEvent.sessionStarted → all move to inSession (AC4)',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
      },
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
            participants: [], isHost: true, steps: _kSteps),
        const SharedSessionState.inSession(
          stepIndex: 0,
          elapsedSeconds: 0,
          isHost: true,
          steps: [],
        ),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-008: follower receives stepAdvanced → inSession state updated (AC2)',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_followerJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(
            const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 62));
      },
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
            participants: [], isHost: false, steps: _kSteps),
        const SharedSessionState.inSession(
            stepIndex: 0, elapsedSeconds: 0, isHost: false, steps: []),
        const SharedSessionState.inSession(
            stepIndex: 1, elapsedSeconds: 62, isHost: false, steps: []),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-009: host ignores echo of own step_advanced broadcast (AC1)',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(
            const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 65));
      },
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
            participants: [], isHost: true, steps: _kSteps),
        // Only inSession(0,0) from sessionStarted — the echo of stepAdvanced is ignored
        const SharedSessionState.inSession(
            stepIndex: 0, elapsedSeconds: 0, isHost: true, steps: []),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-010: HostStepAdvanced → sendBroadcast called with correct payload (AC1)',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const HostStepAdvanced(stepIndex: 1, elapsedSeconds: 63));
      },
      verify: (_) {
        verify(mockGateway.sendBroadcast(
          event: 'step_advanced',
          payload: {'step_index': 1, 'elapsed_seconds': 63},
        )).called(1);
      },
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-011: follower cannot call sendBroadcast for step_advanced (AC1)',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_followerJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        // Follower dispatches HostStepAdvanced — guard must block sendBroadcast
        bloc.add(const HostStepAdvanced(stepIndex: 1, elapsedSeconds: 63));
      },
      verify: (_) {
        verifyNever(mockGateway.sendBroadcast(
          event: 'step_advanced',
          payload: anyNamed('payload'),
        ));
      },
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.2-BLOC-012: close() calls leaveChannel() (AC6)',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        await bloc.close();
      },
      verify: (_) {
        verify(mockGateway.leaveChannel()).called(greaterThanOrEqualTo(1));
      },
    );
  });

  group('SharedSessionBloc session end (20.4)', () {
    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.4-BLOC-001: SessionEndRequested from host → sendBroadcast called with session_ended',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SessionEndRequested());
      },
      verify: (_) {
        verify(mockGateway.sendBroadcast(
          event: 'session_ended',
          payload: {},
        )).called(1);
      },
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.4-BLOC-002: SessionEndRequested from follower → sendBroadcast NOT called',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_followerJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SessionEndRequested());
      },
      verify: (_) {
        verifyNever(mockGateway.sendBroadcast(
          event: 'session_ended',
          payload: anyNamed('payload'),
        ));
      },
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.4-BLOC-003: BroadcastEvent.sessionEnded received → SharedSessionState.sessionEnded emitted',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionEnded());
      },
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
            participants: [], isHost: true, steps: _kSteps),
        const SharedSessionState.inSession(
            stepIndex: 0, elapsedSeconds: 0, isHost: true, steps: []),
        const SharedSessionState.sessionEnded(),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.4-BLOC-004: session_ended broadcast → leaveChannel() called',
      build: () => SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionEnded());
      },
      verify: (_) {
        verify(mockGateway.leaveChannel()).called(greaterThanOrEqualTo(1));
      },
    );
  });

  group('SharedSessionBloc — resolve own handle (21.0)', () {
    test(
      '21.0-BLOC-001: SharedSessionJoined(displayHandle: null) → '
      'GetSocialProfileUseCase.call() invoked; on Right(profile with '
      'displayHandle: alice) → gateway.trackPresence called again with '
      'displayHandle: alice, isHost matching event.isHost',
      () async {
        when(mockGetSocialProfile.call()).thenAnswer(
          (_) async => const Right(SocialProfile(
            userId: 'host-uid',
            displayHandle: 'alice',
            visibilityTier: VisibilityTier.friendsOnly,
          )),
        );
        final bloc = SharedSessionBloc(
          mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile);

        bloc.add(const SharedSessionJoined(sessionId: 'sess-1', isHost: true, userId: 'host-uid', displayHandle: null, steps: _kSteps));
        await Future<void>.delayed(Duration.zero);

        verify(mockGetSocialProfile.call()).called(1);
        verify(mockGateway.trackPresence(
          userId: 'host-uid',
          displayHandle: 'alice',
          isHost: true,
          lat: anyNamed('lat'),
          lon: anyNamed('lon'),
        )).called(1);

        await bloc.close();
      },
    );

    test(
      '21.0-BLOC-002: SharedSessionJoined(displayHandle: bob) (already '
      'resolved) → GetSocialProfileUseCase.call() is NEVER invoked',
      () async {
        final bloc = SharedSessionBloc(
          mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile);

        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);

        verifyNever(mockGetSocialProfile.call());

        await bloc.close();
      },
    );

    test(
      '21.0-BLOC-003: SharedSessionJoined(displayHandle: null), '
      'GetSocialProfileUseCase.call() returns Left(failure) → no error '
      'state emitted; lobby state remains from the initial emission',
      () async {
        when(mockGetSocialProfile.call()).thenAnswer(
          (_) async => const Left(SocialFailure('network')),
        );
        final bloc = SharedSessionBloc(
          mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile);

        bloc.add(const SharedSessionJoined(sessionId: 'sess-1', isHost: true, userId: 'host-uid', displayHandle: null, steps: _kSteps));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state, isA<SharedSessionState>());
        expect(
          bloc.state.mapOrNull(lobby: (s) => s.isHost),
          isTrue,
          reason: 'lobby state remains from the initial emission',
        );
        verify(mockGetSocialProfile.call()).called(1);
        verifyNever(mockGateway.trackPresence(
          userId: anyNamed('userId'),
          displayHandle: 'alice',
          isHost: anyNamed('isHost'),
          lat: anyNamed('lat'),
          lon: anyNamed('lon'),
        ));

        await bloc.close();
      },
    );

    test(
      '21.0-BLOC-004: bloc closed before GetSocialProfileUseCase.call() '
      'resolves → trackPresence is NOT called again (isClosed guard)',
      () async {
        final completer = Completer<Either<SocialFailure, SocialProfile>>();
        when(mockGetSocialProfile.call()).thenAnswer((_) => completer.future);
        final bloc = SharedSessionBloc(
          mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile);

        bloc.add(const SharedSessionJoined(sessionId: 'sess-1', isHost: true, userId: 'host-uid', displayHandle: null, steps: _kSteps));
        await Future<void>.delayed(Duration.zero);
        await bloc.close();

        completer.complete(const Right(SocialProfile(
          userId: 'host-uid',
          displayHandle: 'alice',
          visibilityTier: VisibilityTier.friendsOnly,
        )));
        await Future<void>.delayed(Duration.zero);

        verifyNever(mockGateway.trackPresence(
          userId: anyNamed('userId'),
          displayHandle: 'alice',
          isHost: anyNamed('isHost'),
          lat: anyNamed('lat'),
          lon: anyNamed('lon'),
        ));
      },
    );

    test(
      '21.0-BLOC-005: co-location resolving AFTER own-handle resolution '
      're-tracks presence with the resolved handle, not the null nav arg '
      '(review P1 regression)',
      () async {
        // displayHandle: null nav arg → _resolveOwnHandle resolves 'alice'
        // first; then co-location resolves. The bug: _resolveCoLocation used
        // event.displayHandle (still null) and clobbered 'alice' back to null.
        when(mockGetSocialProfile.call()).thenAnswer(
          (_) async => const Right(SocialProfile(
            userId: 'host-uid',
            displayHandle: 'alice',
            visibilityTier: VisibilityTier.friendsOnly,
          )),
        );
        final coordsCompleter =
            Completer<Either<Failure, (double, double)>>();
        when(mockLocation.getCityLevelCoordinates())
            .thenAnswer((_) => coordsCompleter.future);
        final bloc = SharedSessionBloc(
          mockGateway, mockDelete, mockRefresh, mockLocation, db, mockGetSocialProfile);

        bloc.add(const SharedSessionJoined(sessionId: 'sess-1', isHost: true, userId: 'host-uid', displayHandle: null, steps: _kSteps));
        await Future<void>.delayed(Duration.zero); // let the handle resolve first
        coordsCompleter.complete(const Right((45.0, 9.0)));
        await Future<void>.delayed(Duration.zero);

        // Co-location re-track carries the already-resolved handle.
        verify(mockGateway.trackPresence(
          userId: 'host-uid',
          displayHandle: 'alice',
          isHost: true,
          lat: 45.0,
          lon: 9.0,
        )).called(1);
        // The bug would have re-tracked with a null handle once coords arrived.
        verifyNever(mockGateway.trackPresence(
          userId: anyNamed('userId'),
          displayHandle: null,
          isHost: anyNamed('isHost'),
          lat: 45.0,
          lon: anyNamed('lon'),
        ));

        await bloc.close();
      },
    );
  });
}
