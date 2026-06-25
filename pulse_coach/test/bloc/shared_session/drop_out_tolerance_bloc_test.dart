// [19.3-BLOC-001..012] Drop-out tolerance and reconnect bloc tests
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';

// Re-use the MockRealtimeGateway from story 19.2 test
import 'shared_session_bloc_test.mocks.dart';

const _kSteps = [
  ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 60),
  ExerciseStep(title: 'Cardio', instruction: 'Run', durationSeconds: 120),
];

// Participants
const _alice =
    ParticipantPresence(userId: 'alice-uid', displayHandle: 'alice', isHost: true);
const _bob =
    ParticipantPresence(userId: 'bob-uid', displayHandle: 'bob', isHost: false);
const _carol =
    ParticipantPresence(userId: 'carol-uid', displayHandle: 'carol', isHost: false);

SharedSessionJoined _hostJoin() => const SharedSessionJoined(
      sessionId: 'sess-1',
      isHost: true,
      userId: 'alice-uid',
      displayHandle: 'alice',
      steps: _kSteps,
    );

SharedSessionJoined _followerJoin(
        {String userId = 'bob-uid', String? handle = 'bob'}) =>
    SharedSessionJoined(
      sessionId: 'sess-1',
      isHost: false,
      userId: userId,
      displayHandle: handle,
      steps: _kSteps,
    );

/// Bring the bloc to inSession state with given participants.
Future<void> _bringToInSession(
  SharedSessionBloc bloc,
  StreamController<BroadcastEvent> bc,
  StreamController<PresenceState> pc, {
  List<ParticipantPresence> participants = const [_alice, _bob],
  bool asHost = true,
}) async {
  bloc.add(asHost ? _hostJoin() : _followerJoin());
  await Future<void>.delayed(Duration.zero);
  bc.add(const BroadcastEvent.sessionStarted());
  await Future<void>.delayed(Duration.zero);
  if (participants.isNotEmpty) {
    pc.add(PresenceState(participants: participants));
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late MockRealtimeGateway mockGateway;
  late StreamController<BroadcastEvent> broadcastController;
  late StreamController<PresenceState> presenceController;

  setUp(() {
    mockGateway = MockRealtimeGateway();
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
    )).thenAnswer((_) async {});
    when(mockGateway.leaveChannel()).thenAnswer((_) async {});
    when(mockGateway.sendBroadcast(
      event: anyNamed('event'),
      payload: anyNamed('payload'),
    )).thenAnswer((_) async {});
    when(mockGateway.untrackPresence()).thenAnswer((_) async {});
  });

  tearDown(() {
    broadcastController.close();
    presenceController.close();
  });

  group('SharedSessionBloc — Drop-Out Tolerance (19.3)', () {
    // AC1: follower drops → droppedHandle set in inSession
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-001: follower drop-out → droppedHandle set in inSession state (AC1)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        await _bringToInSession(bloc, broadcastController, presenceController);
        // Bob drops out
        presenceController.add(const PresenceState(participants: [_alice]));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
            participants: [], isHost: true, steps: _kSteps),
        const SharedSessionState.inSession(
            stepIndex: 0,
            elapsedSeconds: 0,
            isHost: true,
            steps: _kSteps,
            participants: []),
        const SharedSessionState.inSession(
            stepIndex: 0,
            elapsedSeconds: 0,
            isHost: true,
            steps: _kSteps,
            participants: [_alice, _bob]),
        // bob drops → droppedHandle = 'bob'
        const SharedSessionState.inSession(
          stepIndex: 0,
          elapsedSeconds: 0,
          isHost: true,
          steps: _kSteps,
          participants: [_alice],
          droppedHandle: 'bob',
        ),
      ],
    );

    // AC1: droppedHandle clears on next step_advanced
    // Uses carol (non-host) dropping so no leadership transfer occurs and
    // bob (follower) still processes the next step_advanced broadcast.
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-002: droppedHandle clears on next step_advanced (AC1)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        bloc.add(_followerJoin(userId: 'bob-uid', handle: 'bob'));
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        presenceController
            .add(const PresenceState(participants: [_alice, _bob, _carol]));
        await Future<void>.delayed(Duration.zero);
        // Carol (non-host) drops → droppedHandle = 'carol'; no leadership transfer
        presenceController
            .add(const PresenceState(participants: [_alice, _bob]));
        await Future<void>.delayed(Duration.zero);
        // Next step_advanced from alice (still host) should clear droppedHandle
        broadcastController.add(
            const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 65));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
            participants: [], isHost: false, steps: _kSteps),
        const SharedSessionState.inSession(
            stepIndex: 0,
            elapsedSeconds: 0,
            isHost: false,
            steps: _kSteps,
            participants: []),
        const SharedSessionState.inSession(
            stepIndex: 0,
            elapsedSeconds: 0,
            isHost: false,
            steps: _kSteps,
            participants: [_alice, _bob, _carol]),
        // carol drops → droppedHandle = 'carol' (intermediate emission asserted
        // so a regression that never sets the note cannot pass silently)
        const SharedSessionState.inSession(
            stepIndex: 0,
            elapsedSeconds: 0,
            isHost: false,
            steps: _kSteps,
            participants: [_alice, _bob],
            droppedHandle: 'carol'),
        // next step_advanced clears the note
        const SharedSessionState.inSession(
            stepIndex: 1,
            elapsedSeconds: 65,
            isHost: false,
            steps: _kSteps,
            participants: [_alice, _bob]),
      ],
      verify: (bloc) {
        final inSession = bloc.state.mapOrNull(inSession: (s) => s);
        expect(inSession, isNotNull);
        expect(inSession!.droppedHandle, isNull);
        expect(inSession.stepIndex, 1);
      },
    );

    // AC3: host drops → follower with alphabetically-first userId becomes new host
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-003: host drop → new host elected (alphabetically first userId) (AC3)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        // bob-uid is the follower; alice-uid (host) and carol-uid also present
        bloc.add(_followerJoin(userId: 'bob-uid', handle: 'bob'));
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        presenceController
            .add(const PresenceState(participants: [_alice, _bob, _carol]));
        await Future<void>.delayed(Duration.zero);
        // Alice (host) drops; remaining: bob-uid, carol-uid
        // alphabetically: bob-uid < carol-uid → bob becomes new host
        presenceController
            .add(const PresenceState(participants: [_bob, _carol]));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        final inSession = bloc.state.mapOrNull(inSession: (s) => s);
        expect(inSession, isNotNull);
        expect(inSession!.isHost, true);
      },
    );

    // AC3: host drops → non-first follower does NOT become host
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-004: host drops → carol (alphabetically second) does NOT become host (AC3)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        bloc.add(_followerJoin(userId: 'carol-uid', handle: 'carol'));
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        presenceController
            .add(const PresenceState(participants: [_alice, _bob, _carol]));
        await Future<void>.delayed(Duration.zero);
        // Alice drops; sorted remaining: [bob-uid, carol-uid] → bob-uid is first
        presenceController
            .add(const PresenceState(participants: [_bob, _carol]));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        final inSession = bloc.state.mapOrNull(inSession: (s) => s);
        expect(inSession, isNotNull);
        expect(inSession!.isHost, false);
      },
    );

    // AC3: HostStepAdvanced now works after leadership transfer
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-005: promoted-host can call sendBroadcast after transfer (AC3)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        bloc.add(_followerJoin(userId: 'bob-uid', handle: 'bob'));
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted());
        await Future<void>.delayed(Duration.zero);
        presenceController
            .add(const PresenceState(participants: [_alice, _bob]));
        await Future<void>.delayed(Duration.zero);
        // Alice drops → bob becomes new host
        presenceController.add(const PresenceState(participants: [_bob]));
        await Future<void>.delayed(Duration.zero);
        // Bob dispatches HostStepAdvanced as new host
        bloc.add(const HostStepAdvanced(stepIndex: 1, elapsedSeconds: 62));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verify(mockGateway.sendBroadcast(
          event: 'step_advanced',
          payload: {'step_index': 1, 'elapsed_seconds': 62},
        )).called(1);
      },
    );

    // AC2: follower reconnect — missed session_started → snaps via step_advanced
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-006: follower missed session_started → StepAdvanced while in lobby snaps to inSession (AC2)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        bloc.add(_followerJoin());
        await Future<void>.delayed(Duration.zero);
        // Follower stays in lobby (session_started was missed)
        // Next step_advanced arrives → should snap to inSession
        broadcastController.add(
            const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 90));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
            participants: [], isHost: false, steps: _kSteps),
        // Snap to inSession from lobby
        const SharedSessionState.inSession(
          stepIndex: 1,
          elapsedSeconds: 90,
          isHost: false,
          steps: _kSteps,
          participants: [],
        ),
      ],
    );

    // AC2: host does NOT snap to inSession via step_advanced from lobby
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-007: host in lobby does NOT transition via StepAdvanced (AC2 guard)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        // Host should not transition via the lobby→inSession reconnect path
        broadcastController.add(
            const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 90));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
            participants: [], isHost: true, steps: _kSteps),
        // No additional state — host stays in lobby
      ],
    );

    // AC4: SessionEnded broadcast → sessionEnded() state + leaveChannel
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-008: BroadcastEvent.sessionEnded → sessionEnded() state (AC4)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        await _bringToInSession(bloc, broadcastController, presenceController);
        broadcastController.add(const BroadcastEvent.sessionEnded());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        expect(bloc.state, const SharedSessionState.sessionEnded());
        verify(mockGateway.leaveChannel()).called(1);
      },
    );

    // AC4: SessionEndRequested by host → sends session_ended broadcast
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-009: SessionEndRequested by host → sendBroadcast session_ended (AC4)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        await _bringToInSession(bloc, broadcastController, presenceController);
        bloc.add(const SessionEndRequested());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verify(mockGateway.sendBroadcast(
          event: 'session_ended',
          payload: {},
        )).called(1);
      },
    );

    // AC4: SessionEndRequested by non-host → no-op
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-010: SessionEndRequested by follower → no sendBroadcast (AC4)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        await _bringToInSession(
          bloc,
          broadcastController,
          presenceController,
          asHost: false,
        );
        bloc.add(const SessionEndRequested());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verifyNever(mockGateway.sendBroadcast(
          event: 'session_ended',
          payload: anyNamed('payload'),
        ));
      },
    );

    // AC1: trackPresence called with isHost flag
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-011: trackPresence called with isHost=true for host (AC1/AC3)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
      },
      verify: (_) {
        verify(mockGateway.trackPresence(
          userId: 'alice-uid',
          displayHandle: 'alice',
          isHost: true,
        )).called(1);
      },
    );

    // AC3 hardening: a reconnect follower that entered inSession with empty
    // participants (host never in `prev`) still elects a host when presence
    // shows no host flagged, and re-tracks presence so peers learn the new host.
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-013: reconnect follower with no host in presence elects + re-tracks (AC3 hardening)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        bloc.add(_followerJoin(userId: 'bob-uid', handle: 'bob'));
        await Future<void>.delayed(Duration.zero);
        // Snap to inSession via step_advanced while in lobby (participants empty)
        broadcastController.add(
            const BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 30));
        await Future<void>.delayed(Duration.zero);
        // Presence sync arrives with NO host flagged (original host already gone)
        presenceController.add(const PresenceState(participants: [_bob]));
        await Future<void>.delayed(Duration.zero);
      },
      verify: (bloc) {
        final inSession = bloc.state.mapOrNull(inSession: (s) => s);
        expect(inSession, isNotNull);
        expect(inSession!.isHost, true);
        verify(mockGateway.trackPresence(
          userId: 'bob-uid',
          displayHandle: 'bob',
          isHost: true,
        )).called(1);
      },
    );

    // regression: presence update in lobby still works
    blocTest<SharedSessionBloc, SharedSessionState>(
      '19.3-BLOC-012: presence update in lobby still updates lobby.participants (regression)',
      build: () => SharedSessionBloc(mockGateway),
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        presenceController.add(const PresenceState(participants: [_alice]));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SharedSessionState.loading(),
        const SharedSessionState.lobby(
            participants: [], isHost: true, steps: _kSteps),
        const SharedSessionState.lobby(
            participants: [_alice], isHost: true, steps: _kSteps),
      ],
    );
  });
}
