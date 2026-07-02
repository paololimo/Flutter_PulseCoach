import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/ai/safety/group_constraint_resolver.dart';
import 'package:pulse_coach/ai/safety/participant_profile.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart' as ai_state;
import 'package:pulse_coach/core/cloud/realtime_gateway.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/utils/location_service.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/get_social_profile_use_case.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/delete_shared_session_use_case.dart';
import 'package:pulse_coach/features/social/shared_session/domain/usecases/refresh_join_code_use_case.dart';

import 'shared_session_event.dart';
import 'shared_session_state.dart';

@injectable
class SharedSessionBloc extends Bloc<SharedSessionEvent, SharedSessionState> {
  final RealtimeGateway _gateway;
  final DeleteSharedSessionUseCase _deleteUseCase;
  final RefreshJoinCodeUseCase _refreshUseCase;
  final LocationService _locationService;
  final AppDatabase _db;
  final GetSocialProfileUseCase _getSocialProfileUseCase;

  // Set in _onStartTapped (host) or from broadcast echo; used when sessionEnded fires.
  String? _armKey;

  StreamSubscription<dynamic>? _broadcastSub;
  StreamSubscription<dynamic>? _presenceSub;

  bool _joined = false;

  String? _myUserId;
  String? _myDisplayHandle;
  bool _isHost = false;

  // Set on join; used for cancel/refresh operations
  String? _sessionId;

  // Ephemeral city-level coordinates — never persisted (NFR33); cleared in close()
  double? _myLat;
  double? _myLon;

  SharedSessionBloc(
    this._gateway,
    this._deleteUseCase,
    this._refreshUseCase,
    this._locationService,
    this._db,
    this._getSocialProfileUseCase, // NEW — resolves own handle when null (E20R-1)
  ) : super(const SharedSessionState.initial()) {
    on<SharedSessionJoined>(_onJoined);
    on<SessionStartTapped>(_onStartTapped);
    on<HostStepAdvanced>(_onHostStepAdvanced);
    on<SessionEndRequested>(_onSessionEndRequested);
    on<PresenceStateReceived>(_onPresenceReceived);
    on<BroadcastEventReceived>(_onBroadcastReceived);
    on<SharedSessionJoinCodeRefreshed>(_onJoinCodeRefreshed);
    on<SharedSessionCancelled>(_onCancelled);
  }

  Future<void> _onJoined(
      SharedSessionJoined event, Emitter<SharedSessionState> emit) async {
    emit(const SharedSessionState.loading());
    _myUserId = event.userId;
    _myDisplayHandle = event.displayHandle;
    _isHost = event.isHost;
    _sessionId = event.sessionId;
    try {
      await _gateway.joinChannel(event.sessionId);
      _joined = true;

      // Track presence immediately without coordinates so lobby entry is never
      // blocked on GPS (NFR33: momentary, non-blocking). The city-level position
      // is resolved in the background and re-tracked when available.
      await _gateway.trackPresence(
        userId: event.userId,
        displayHandle: event.displayHandle,
        isHost: event.isHost,
      );
      _broadcastSub = _gateway.broadcastEvents.listen(
        (e) => add(BroadcastEventReceived(e)),
      );
      _presenceSub = _gateway.presenceUpdates.listen(
        (s) => add(PresenceStateReceived(s)),
      );
      emit(SharedSessionState.lobby(
        participants: const [],
        isHost: event.isHost,
        steps: event.steps,
        joinCode: event.joinCode,
      ));

      unawaited(_resolveCoLocation(event));
      unawaited(_resolveOwnHandle(event));
    } catch (e) {
      emit(SharedSessionState.error(
        failure: RealtimeFailure('channel_join_failed: $e'),
      ));
    }
  }

  // One-shot city-level position for co-location, fetched off the lobby-entry
  // path (NFR33: non-blocking). On success, re-tracks Presence with the
  // coordinates so followers can resolve `coLocated` from the next Presence
  // update. Bails out — leaving coords cleared (AC9) — if the bloc was torn
  // down or left the channel while awaiting GPS.
  Future<void> _resolveCoLocation(SharedSessionJoined event) async {
    final posResult = await _locationService.getCityLevelCoordinates();
    if (isClosed || !_joined) return;
    final coords =
        posResult.fold<(double, double)?>((_) => null, (c) => c);
    if (coords == null) return;
    _myLat = coords.$1;
    _myLon = coords.$2;
    await _gateway.trackPresence(
      userId: event.userId,
      // Use the shared field, not event.displayHandle (review P1): _onJoined
      // runs this and _resolveOwnHandle concurrently. If _resolveOwnHandle has
      // already resolved a handle that the nav arg lacked (the E20R-1 case),
      // event.displayHandle is still null here — re-tracking with it would
      // clobber the resolved handle back to null and revert the lobby row to
      // the "unknown" fallback.
      displayHandle: _myDisplayHandle,
      isHost: _isHost,
      lat: _myLat,
      lon: _myLon,
    );
  }

  // Resolves the current user's own @handle when the nav arg didn't carry one
  // (SocialProfileBloc hadn't finished loading at create/join time — E20R-1).
  // Runs off the lobby-entry path so entry is never blocked (AC4), mirroring
  // _resolveCoLocation's non-blocking pattern.
  Future<void> _resolveOwnHandle(SharedSessionJoined event) async {
    if (event.displayHandle != null) return;
    final result = await _getSocialProfileUseCase.call();
    if (isClosed || !_joined) return;
    final handle = result.fold((_) => null, (profile) => profile.displayHandle);
    if (handle == null) return;
    _myDisplayHandle = handle;
    await _gateway.trackPresence(
      userId: event.userId,
      displayHandle: handle,
      isHost: _isHost,
      lat: _myLat,
      lon: _myLon,
    );
  }

  Future<void> _onStartTapped(
      SessionStartTapped event, Emitter<SharedSessionState> emit) async {
    final lobbyState = state.mapOrNull(lobby: (s) => s);
    if (lobbyState == null || !lobbyState.isHost) return;
    if (lobbyState.participants.length < 2) return;

    // Derive group plan from host's behavioral state via GroupConstraintResolver.
    // Only the host's profile is used (followers' profiles are not available
    // over the wire in v2.4b; documented MVP limitation).
    const sessionType = 'mobility';
    int intensity;
    int durationMinutes;
    try {
      final stateRow = await _db.behavioralStateDao.getLatestState();
      final behavioralState = _parseBehavioralState(stateRow?.currentState);
      // Fail-safe (FR24): an unrecognized/corrupt state string caps to LOW
      // rather than defaulting to no cap.
      final safetyCapIntensity = behavioralState == null
          ? SessionIntensity.low
          : _safetyCapFrom(behavioralState);

      final hostProfile = ParticipantProfile(
        safetyCapIntensity: safetyCapIntensity,
        fitnessLevel: 'medium',
        movementExclusions: const {},
        availableTimeMinutes: 20,
      );

      final constraint = const GroupConstraintResolver().resolve([hostProfile]);
      intensity = _intensityFromCeiling(constraint.intensityCeiling);
      durationMinutes = constraint.durationMinutes;
    } catch (_) {
      // Fail-safe (FR24): if we cannot confirm the host's behavioral state,
      // fall back to the most protective LOW intensity rather than medium —
      // social pressure must never override the recovery-empathy promise.
      intensity = 3;
      durationMinutes = 20;
    }

    final armKey = '${sessionType}_${_intensityName(intensity)}';
    // Set before broadcast so host echo path (armKey ??= ...) is a no-op.
    _armKey = armKey;

    try {
      await _gateway.sendBroadcast(
        event: 'session_started',
        payload: {
          'session_type': sessionType,
          'intensity': intensity,
          'duration_minutes': durationMinutes,
          'arm_key': armKey,
        },
      );
    } catch (e) {
      emit(SharedSessionState.error(
        failure: RealtimeFailure('session_start_broadcast_failed: $e'),
      ));
    }
  }

  Future<void> _onHostStepAdvanced(
      HostStepAdvanced event, Emitter<SharedSessionState> emit) async {
    final inSessionState = state.mapOrNull(inSession: (s) => s);
    if (inSessionState == null || !inSessionState.isHost) return;
    try {
      await _gateway.sendBroadcast(
        event: 'step_advanced',
        payload: {
          'step_index': event.stepIndex,
          'elapsed_seconds': event.elapsedSeconds,
        },
      );
    } catch (e) {
      // Non-fatal: broadcast failure for step doesn't end the session.
    }
  }

  Future<void> _onSessionEndRequested(
      SessionEndRequested event, Emitter<SharedSessionState> emit) async {
    final inSessionState = state.mapOrNull(inSession: (s) => s);
    if (inSessionState == null || !inSessionState.isHost) return;
    try {
      await _gateway.sendBroadcast(event: 'session_ended', payload: {});
    } catch (e) {
      // Non-fatal: followers detect the host dropped via Presence (AC3).
    }
  }

  Future<void> _onJoinCodeRefreshed(
      SharedSessionJoinCodeRefreshed event,
      Emitter<SharedSessionState> emit) async {
    // Refresh is only meaningful from the lobby; ignore it from any other state
    // so the DB code is never rotated while no one is showing it.
    final inLobby = state.mapOrNull(lobby: (_) => true) ?? false;
    if (!inLobby) return;
    final sid = _sessionId;
    if (sid == null) return;
    final result = await _refreshUseCase.call(sessionId: sid);
    result.fold(
      (_) {
        // Keep the existing code visible and bump a one-shot tick so the page
        // can surface a "refresh failed" SnackBar without leaving the lobby.
        state.mapOrNull(
          lobby: (s) =>
              emit(s.copyWith(refreshErrorTick: s.refreshErrorTick + 1)),
        );
      },
      (newCode) {
        state.mapOrNull(
          lobby: (s) => emit(s.copyWith(joinCode: newCode)),
        );
      },
    );
  }

  Future<void> _onCancelled(
      SharedSessionCancelled event, Emitter<SharedSessionState> emit) async {
    // Cancel is valid before/at the lobby only. Once in-session, teardown is
    // owned by SessionEndRequested (which broadcasts session_ended); deleting
    // the row here would strand followers without an end signal.
    final inSession = state.mapOrNull(inSession: (_) => true) ?? false;
    if (inSession) return;
    final sid = _sessionId;
    if (sid != null) {
      await _deleteUseCase.call(sessionId: sid);
    }
    if (_joined) {
      _joined = false;
      unawaited(_gateway.leaveChannel());
    }
    emit(const SharedSessionState.cancelled());
  }

  void _onPresenceReceived(
      PresenceStateReceived event, Emitter<SharedSessionState> emit) {
    state.mapOrNull(
      lobby: (s) {
        bool? coLocated = s.coLocated;
        if (!_isHost && _myLat != null && _myLon != null) {
          final host = event.presenceState.participants
              .where((p) => p.isHost && p.lat != null && p.lon != null)
              .firstOrNull;
          if (host != null) {
            final distanceM = Geolocator.distanceBetween(
              _myLat!,
              _myLon!,
              host.lat!,
              host.lon!,
            );
            coLocated = distanceM <= 100.0;
          } else {
            // Host left presence or re-tracked without coordinates: the cue is
            // no longer valid, so fall back to inconclusive instead of keeping
            // a stale `true`.
            coLocated = null;
          }
        }
        emit(s.copyWith(
          participants: event.presenceState.participants,
          coLocated: coLocated,
        ));
      },
      inSession: (s) {
        final prev = s.participants;
        final next = event.presenceState.participants;

        final dropped = prev
            .where((p) => !next.any((n) => n.userId == p.userId))
            .toList();
        final droppedHandle = dropped.isNotEmpty
            ? (dropped.first.displayHandle ?? dropped.first.userId)
            : null;

        if (!_isHost && next.isNotEmpty && !next.any((p) => p.isHost)) {
          final sortedIds = next.map((p) => p.userId).toList()..sort();
          if (sortedIds.first == _myUserId) {
            _isHost = true;
            unawaited(_gateway.trackPresence(
              userId: _myUserId!,
              displayHandle: _myDisplayHandle,
              isHost: true,
            ));
          }
        }

        emit(s.copyWith(
          participants: next,
          isHost: _isHost,
          droppedHandle: droppedHandle,
        ));
      },
    );
  }

  void _onBroadcastReceived(
      BroadcastEventReceived event, Emitter<SharedSessionState> emit) {
    final broadcast = event.broadcastEvent;
    switch (broadcast) {
      case SessionStarted(
        sessionType: final sessionType,
        intensity: final intensity,
        durationMinutes: final durationMinutes,
        armKey: final broadcastArmKey,
      ):
        // Follower path: armKey comes from broadcast. Host already set _armKey
        // in _onStartTapped, so ??= is a no-op for the host echo.
        _armKey ??= broadcastArmKey;
        state.mapOrNull(
          lobby: (s) => emit(SharedSessionState.inSession(
            stepIndex: 0,
            elapsedSeconds: 0,
            isHost: s.isHost,
            steps: const [], // Page generates steps from plan params (UX-DR29)
            participants: s.participants,
            sessionType: sessionType,
            intensity: intensity,
            durationMinutes: durationMinutes,
          )),
        );
      case StepAdvanced(stepIndex: final idx, elapsedSeconds: final elapsed):
        state.mapOrNull(
          inSession: (s) {
            if (s.isHost) return;
            emit(s.copyWith(
                stepIndex: idx, elapsedSeconds: elapsed, droppedHandle: null));
          },
          lobby: (s) {
            if (!s.isHost) {
              emit(SharedSessionState.inSession(
                stepIndex: idx,
                elapsedSeconds: elapsed,
                isHost: false,
                steps: s.steps,
                participants: s.participants,
              ));
            }
          },
        );
      case SessionEnded():
        if (_joined) {
          _joined = false;
          unawaited(_gateway.leaveChannel());
        }
        emit(SharedSessionState.sessionEnded(
          armKey: _armKey ?? 'mobility_medium',
        ));
      case UnknownBroadcast():
        break;
    }
  }

  // Maps behavioral state to the per-user safety intensity cap per FR24.
  // Exhaustive switch — compiler catches new BehavioralState values.
  SessionIntensity? _safetyCapFrom(ai_state.BehavioralState state) =>
      switch (state) {
        ai_state.BehavioralState.atRisk => SessionIntensity.low,
        ai_state.BehavioralState.recovering => SessionIntensity.medium,
        ai_state.BehavioralState.fatigued => SessionIntensity.medium,
        ai_state.BehavioralState.active => null,
      };

  // Returns null for an unrecognized non-null state string so the caller can
  // fail safe (FR24). A null input (no state recorded yet) is the legitimate
  // first-run default and maps to `active`.
  ai_state.BehavioralState? _parseBehavioralState(String? raw) {
    if (raw == null) return ai_state.BehavioralState.active;
    return switch (raw.toLowerCase()) {
      'atrisk' => ai_state.BehavioralState.atRisk,
      'recovering' => ai_state.BehavioralState.recovering,
      'fatigued' => ai_state.BehavioralState.fatigued,
      'active' => ai_state.BehavioralState.active,
      _ => null,
    };
  }

  // Maps SessionIntensity ceiling to a concrete intensity int value.
  // null = no cap → medium (5). Ranges: low 1-3, medium 4-7, high 8-10.
  int _intensityFromCeiling(SessionIntensity? ceiling) => switch (ceiling) {
        SessionIntensity.low => 3,
        SessionIntensity.medium => 5,
        SessionIntensity.high => 8,
        null => 5,
      };

  String _intensityName(int intensity) {
    if (intensity <= 3) return 'low';
    if (intensity <= 7) return 'medium';
    return 'high';
  }

  @override
  Future<void> close() async {
    _myLat = null;
    _myLon = null;
    await _broadcastSub?.cancel();
    await _presenceSub?.cancel();
    if (_joined) await _gateway.leaveChannel();
    return super.close();
  }
}
