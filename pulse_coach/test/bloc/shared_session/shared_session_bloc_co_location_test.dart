// [20.3-BLOC-001..005] SharedSessionBloc co-location tests
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/utils/location_service.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_state.dart';

import 'shared_session_bloc_test.mocks.dart';
import 'shared_session_cancel_refresh_bloc_test.mocks.dart';

@GenerateMocks([LocationService])
import 'shared_session_bloc_co_location_test.mocks.dart';

const _kSteps = [
  ExerciseStep(title: 'Warm Up', instruction: 'Breathe', durationSeconds: 60),
];

// Real coordinate pairs for Haversine distance checks:
// (45.4642, 9.1900) vs (45.4643, 9.1900) ≈ 11m → coLocated=true
// (45.4642, 9.1900) vs (45.4660, 9.1900) ≈ 200m → coLocated=false
const _hostLat = 45.4642;
const _hostLon = 9.1900;
const _followerLatNear = 45.4643;
const _followerLonNear = 9.1900;
const _followerLatFar = 45.4660;
const _followerLonFar = 9.1900;

const _hostPresence = ParticipantPresence(
  userId: 'host-uid',
  displayHandle: 'alice',
  isHost: true,
  lat: _hostLat,
  lon: _hostLon,
);

const _followerPresence = ParticipantPresence(
  userId: 'follower-uid',
  displayHandle: 'bob',
  isHost: false,
);

SharedSessionJoined _followerJoin() => const SharedSessionJoined(
      sessionId: 'sess-1',
      isHost: false,
      userId: 'follower-uid',
      displayHandle: 'bob',
      steps: _kSteps,
    );

SharedSessionJoined _hostJoin() => const SharedSessionJoined(
      sessionId: 'sess-1',
      isHost: true,
      userId: 'host-uid',
      displayHandle: 'alice',
      steps: _kSteps,
    );

Matcher _lobbyCoLocated(bool? expected) => isA<SharedSessionState>().having(
      (s) => s.mapOrNull(lobby: (l) => l.coLocated),
      'coLocated',
      expected,
    );

void main() {
  late MockRealtimeGateway mockGateway;
  late MockDeleteSharedSessionUseCase mockDelete;
  late MockRefreshJoinCodeUseCase mockRefresh;
  late MockLocationService mockLocation;
  late StreamController<BroadcastEvent> broadcastController;
  late StreamController<PresenceState> presenceController;

  setUp(() {
    mockGateway = MockRealtimeGateway();
    mockDelete = MockDeleteSharedSessionUseCase();
    mockRefresh = MockRefreshJoinCodeUseCase();
    mockLocation = MockLocationService();
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
      lon: anyNamed('lon'),
    )).thenAnswer((_) async {});
  });

  tearDown(() async {
    await broadcastController.close();
    await presenceController.close();
  });

  SharedSessionBloc buildBloc() =>
      SharedSessionBloc(mockGateway, mockDelete, mockRefresh, mockLocation);

  group('SharedSessionBloc co-location (20.3)', () {
    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.3-BLOC-001: follower within 100m → coLocated=true (AC6)',
      build: buildBloc,
      setUp: () {
        when(mockLocation.getCityLevelCoordinates()).thenAnswer(
          (_) async => const Right((_followerLatNear, _followerLonNear)),
        );
      },
      act: (bloc) async {
        bloc.add(_followerJoin());
        await Future<void>.delayed(Duration.zero);
        presenceController.add(const PresenceState(
          participants: [_hostPresence, _followerPresence],
        ));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SharedSessionState.loading(),
        _lobbyCoLocated(null),
        _lobbyCoLocated(true),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.3-BLOC-002: follower > 100m away → coLocated=false (AC6)',
      build: buildBloc,
      setUp: () {
        when(mockLocation.getCityLevelCoordinates()).thenAnswer(
          (_) async => const Right((_followerLatFar, _followerLonFar)),
        );
      },
      act: (bloc) async {
        bloc.add(_followerJoin());
        await Future<void>.delayed(Duration.zero);
        presenceController.add(const PresenceState(
          participants: [_hostPresence, _followerPresence],
        ));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SharedSessionState.loading(),
        _lobbyCoLocated(null),
        _lobbyCoLocated(false),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.3-BLOC-003: LocationService fails → coLocated stays null (AC7)',
      build: buildBloc,
      setUp: () {
        when(mockLocation.getCityLevelCoordinates()).thenAnswer(
          (_) async =>
              const Left(LocationFailure('Location services are disabled')),
        );
      },
      act: (bloc) async {
        bloc.add(_followerJoin());
        await Future<void>.delayed(Duration.zero);
        presenceController.add(const PresenceState(
          participants: [_hostPresence, _followerPresence],
        ));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SharedSessionState.loading(),
        _lobbyCoLocated(null),
        _lobbyCoLocated(null),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.3-BLOC-004: host Presence has no lat/lon → coLocated stays null (AC7)',
      build: buildBloc,
      setUp: () {
        when(mockLocation.getCityLevelCoordinates()).thenAnswer(
          (_) async => const Right((_followerLatNear, _followerLonNear)),
        );
      },
      act: (bloc) async {
        bloc.add(_followerJoin());
        await Future<void>.delayed(Duration.zero);
        presenceController.add(const PresenceState(
          participants: [
            ParticipantPresence(
              userId: 'host-uid',
              displayHandle: 'alice',
              isHost: true,
              // lat and lon intentionally null — host has no location
            ),
            _followerPresence,
          ],
        ));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SharedSessionState.loading(),
        _lobbyCoLocated(null),
        _lobbyCoLocated(null),
      ],
    );

    blocTest<SharedSessionBloc, SharedSessionState>(
      '20.3-BLOC-005: host device never sets coLocated (AC8)',
      build: buildBloc,
      setUp: () {
        when(mockLocation.getCityLevelCoordinates()).thenAnswer(
          (_) async => const Right((_hostLat, _hostLon)),
        );
      },
      act: (bloc) async {
        bloc.add(_hostJoin());
        await Future<void>.delayed(Duration.zero);
        presenceController.add(const PresenceState(
          participants: [_hostPresence, _followerPresence],
        ));
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const SharedSessionState.loading(),
        _lobbyCoLocated(null),
        // Host receives presence update but coLocated is never set (guard: !_isHost)
        _lobbyCoLocated(null),
      ],
    );
  });
}
