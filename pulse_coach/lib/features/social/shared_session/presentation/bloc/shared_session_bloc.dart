import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/realtime_gateway.dart';
import 'package:pulse_coach/core/error/failures.dart';
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

  StreamSubscription<dynamic>? _broadcastSub;
  StreamSubscription<dynamic>? _presenceSub;

  bool _joined = false;

  String? _myUserId;
  String? _myDisplayHandle;
  bool _isHost = false;

  // Set on join; used for cancel/refresh operations
  String? _sessionId;

  SharedSessionBloc(
    this._gateway,
    this._deleteUseCase,
    this._refreshUseCase,
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
    } catch (e) {
      emit(SharedSessionState.error(
        failure: RealtimeFailure('channel_join_failed: $e'),
      ));
    }
  }

  Future<void> _onStartTapped(
      SessionStartTapped event, Emitter<SharedSessionState> emit) async {
    final lobbyState = state.mapOrNull(lobby: (s) => s);
    if (lobbyState == null || !lobbyState.isHost) return;
    if (lobbyState.participants.length < 2) return;
    try {
      await _gateway.sendBroadcast(event: 'session_started', payload: {});
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
      lobby: (s) =>
          emit(s.copyWith(participants: event.presenceState.participants)),
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
      case SessionStarted():
        state.mapOrNull(
          lobby: (s) => emit(SharedSessionState.inSession(
            stepIndex: 0,
            elapsedSeconds: 0,
            isHost: s.isHost,
            steps: s.steps,
            participants: s.participants,
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
        emit(const SharedSessionState.sessionEnded());
      case UnknownBroadcast():
        break;
    }
  }

  @override
  Future<void> close() async {
    await _broadcastSub?.cancel();
    await _presenceSub?.cancel();
    if (_joined) await _gateway.leaveChannel();
    return super.close();
  }
}
