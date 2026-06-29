// [20.5-BLOC-001..008] SharedSessionBloc — group plan generation and arm key wiring
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/cloud/realtime_gateway.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/utils/location_service.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/delete_shared_session_use_case.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/refresh_join_code_use_case.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';

@GenerateNiceMocks([
  MockSpec<RealtimeGateway>(),
  MockSpec<DeleteSharedSessionUseCase>(),
  MockSpec<RefreshJoinCodeUseCase>(),
  MockSpec<LocationService>(),
])
import 'shared_session_20_5_bloc_test.mocks.dart';

const _kSteps = [
  ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 60),
  ExerciseStep(title: 'Cardio', instruction: 'Run', durationSeconds: 120),
];

const _twoParticipants = [
  ParticipantPresence(userId: 'host-uid', displayHandle: 'alice'),
  ParticipantPresence(userId: 'follower-uid', displayHandle: 'bob'),
];

SharedSessionJoined _hostJoin() => const SharedSessionJoined(
      sessionId: 'sess-1',
      isHost: true,
      userId: 'host-uid',
      displayHandle: 'alice',
      steps: _kSteps,
    );

void main() {
  late MockRealtimeGateway mockGateway;
  late MockDeleteSharedSessionUseCase mockDelete;
  late MockRefreshJoinCodeUseCase mockRefresh;
  late MockLocationService mockLocation;
  late StreamController<BroadcastEvent> broadcastController;
  late StreamController<PresenceState> presenceController;
  late AppDatabase db;

  SharedSessionBloc buildBloc() => SharedSessionBloc(
        mockGateway,
        mockDelete,
        mockRefresh,
        mockLocation,
        db,
      );

  setUp(() async {
    mockGateway = MockRealtimeGateway();
    mockDelete = MockDeleteSharedSessionUseCase();
    mockRefresh = MockRefreshJoinCodeUseCase();
    mockLocation = MockLocationService();
    broadcastController = StreamController<BroadcastEvent>.broadcast();
    presenceController = StreamController<PresenceState>.broadcast();

    when(mockLocation.getCityLevelCoordinates())
        .thenAnswer((_) async => const Left(LocationFailure('disabled')));
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
    when(mockDelete.call(sessionId: anyNamed('sessionId')))
        .thenAnswer((_) async => const Right(unit));

    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await broadcastController.close();
    await presenceController.close();
    await db.close();
  });

  // Helper: put the bloc in lobby state with 2 participants (host path).
  Future<void> arrangeHostLobbyWith2Participants(
      SharedSessionBloc bloc) async {
    bloc.add(_hostJoin());
    await Future<void>.delayed(Duration.zero);
    presenceController.add(const PresenceState(participants: _twoParticipants));
    await Future<void>.delayed(Duration.zero);
  }

  group('SharedSessionBloc group plan generation and arm key wiring (20.5)', () {
    test('[20.5-BLOC-001] AtRisk host → broadcast payload intensity ≤ 3, armKey ends in _low',
        () async {
      // Insert atRisk behavioral state into in-memory DB.
      await db.into(db.behavioralState).insert(
            BehavioralStateCompanion.insert(
              currentState: 'atRisk',
              recordedAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );

      final bloc = buildBloc();
      await arrangeHostLobbyWith2Participants(bloc);
      bloc.add(const SessionStartTapped());
      await Future<void>.delayed(Duration.zero);

      final captured = verify(mockGateway.sendBroadcast(
        event: 'session_started',
        payload: captureAnyNamed('payload'),
      )).captured;

      expect(captured, hasLength(1));
      final payload = captured.first as Map<String, dynamic>;
      expect(payload['intensity'] as int, lessThanOrEqualTo(3));
      expect((payload['arm_key'] as String).endsWith('_low'), isTrue);

      await bloc.close();
    });

    test('[20.5-BLOC-002] Active host → broadcast payload intensity 4-7, armKey ends in _medium',
        () async {
      // No behavioral state row → defaults to active.
      final bloc = buildBloc();
      await arrangeHostLobbyWith2Participants(bloc);
      bloc.add(const SessionStartTapped());
      await Future<void>.delayed(Duration.zero);

      final captured = verify(mockGateway.sendBroadcast(
        event: 'session_started',
        payload: captureAnyNamed('payload'),
      )).captured;

      expect(captured, hasLength(1));
      final payload = captured.first as Map<String, dynamic>;
      final intensity = payload['intensity'] as int;
      expect(intensity, greaterThanOrEqualTo(4));
      expect(intensity, lessThanOrEqualTo(7));
      expect((payload['arm_key'] as String).endsWith('_medium'), isTrue);

      await bloc.close();
    });

    blocTest<SharedSessionBloc, SharedSessionState>(
      '[20.5-BLOC-003] sessionStarted broadcast with plan params → inSession carries them',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted(
          sessionType: 'mobility',
          intensity: 3,
          durationMinutes: 20,
          armKey: 'mobility_low',
        ));
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
          sessionType: 'mobility',
          intensity: 3,
          durationMinutes: 20,
        ),
      ],
    );

    test('[20.5-BLOC-005] Recovering host → broadcast intensity 4-7, armKey ends in _medium',
        () async {
      await db.into(db.behavioralState).insert(
            BehavioralStateCompanion.insert(
              currentState: 'recovering',
              recordedAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );

      final bloc = buildBloc();
      await arrangeHostLobbyWith2Participants(bloc);
      bloc.add(const SessionStartTapped());
      await Future<void>.delayed(Duration.zero);

      final captured = verify(mockGateway.sendBroadcast(
        event: 'session_started',
        payload: captureAnyNamed('payload'),
      )).captured;

      expect(captured, hasLength(1));
      final payload = captured.first as Map<String, dynamic>;
      final intensity = payload['intensity'] as int;
      expect(intensity, greaterThanOrEqualTo(4));
      expect(intensity, lessThanOrEqualTo(7));
      expect((payload['arm_key'] as String).endsWith('_medium'), isTrue);

      await bloc.close();
    });

    test('[20.5-BLOC-006] Fatigued host → broadcast intensity 4-7, armKey ends in _medium',
        () async {
      await db.into(db.behavioralState).insert(
            BehavioralStateCompanion.insert(
              currentState: 'fatigued',
              recordedAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );

      final bloc = buildBloc();
      await arrangeHostLobbyWith2Participants(bloc);
      bloc.add(const SessionStartTapped());
      await Future<void>.delayed(Duration.zero);

      final captured = verify(mockGateway.sendBroadcast(
        event: 'session_started',
        payload: captureAnyNamed('payload'),
      )).captured;

      expect(captured, hasLength(1));
      final payload = captured.first as Map<String, dynamic>;
      final intensity = payload['intensity'] as int;
      expect(intensity, greaterThanOrEqualTo(4));
      expect(intensity, lessThanOrEqualTo(7));
      expect((payload['arm_key'] as String).endsWith('_medium'), isTrue);

      await bloc.close();
    });

    test(
        '[20.5-BLOC-007] DB error during _onStartTapped → fail-safe LOW intensity (FR24)',
        () async {
      // Reach lobby first (DB still intact).
      final bloc = buildBloc();
      await arrangeHostLobbyWith2Participants(bloc);

      // Drop the behavioral_state table to force a SQL error inside _onStartTapped.
      await db.customStatement('DROP TABLE IF EXISTS behavioral_state');

      bloc.add(const SessionStartTapped());
      await Future<void>.delayed(Duration.zero);

      final captured = verify(mockGateway.sendBroadcast(
        event: 'session_started',
        payload: captureAnyNamed('payload'),
      )).captured;

      expect(captured, hasLength(1));
      final payload = captured.first as Map<String, dynamic>;
      expect(payload['intensity'] as int, equals(3));
      expect(payload['arm_key'] as String, equals('mobility_low'));
      expect(payload['duration_minutes'] as int, equals(20));

      await bloc.close();
    });

    test(
        '[20.5-BLOC-008] Unrecognized behavioral state string → safety cap LOW → armKey ends in _low',
        () async {
      // Insert a corrupt/unknown state string — _parseBehavioralState returns null
      // → safetyCapIntensity = SessionIntensity.low → intensity 3 → _low armKey.
      await db.into(db.behavioralState).insert(
            BehavioralStateCompanion.insert(
              currentState: 'zombie',
              recordedAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );

      final bloc = buildBloc();
      await arrangeHostLobbyWith2Participants(bloc);
      bloc.add(const SessionStartTapped());
      await Future<void>.delayed(Duration.zero);

      final captured = verify(mockGateway.sendBroadcast(
        event: 'session_started',
        payload: captureAnyNamed('payload'),
      )).captured;

      expect(captured, hasLength(1));
      final payload = captured.first as Map<String, dynamic>;
      expect(payload['intensity'] as int, equals(3));
      expect((payload['arm_key'] as String).endsWith('_low'), isTrue);

      await bloc.close();
    });

    blocTest<SharedSessionBloc, SharedSessionState>(
      '[20.5-BLOC-004] sessionEnded after sessionStarted with armKey → sessionEnded(armKey: mobility_low)',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionStarted(
          sessionType: 'mobility',
          intensity: 3,
          durationMinutes: 20,
          armKey: 'mobility_low',
        ));
        await Future<void>.delayed(Duration.zero);
        broadcastController.add(const BroadcastEvent.sessionEnded());
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
          sessionType: 'mobility',
          intensity: 3,
          durationMinutes: 20,
        ),
        const SharedSessionState.sessionEnded(armKey: 'mobility_low'),
      ],
    );
  });
}
