import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/realtime_gateway.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';

import 'shared_session_event.dart';
import 'shared_session_state.dart';

@injectable
class SharedSessionBloc extends Bloc<SharedSessionEvent, SharedSessionState> {
  final RealtimeGateway _gateway;

  StreamSubscription<dynamic>? _broadcastSub;
  StreamSubscription<dynamic>? _presenceSub;

  // True only once this bloc has successfully taken the gateway channel.
  bool _joined = false;

  String? _myUserId;
  String? _myDisplayHandle;
  bool _isHost = false;

  SharedSessionBloc(this._gateway) : super(const SharedSessionState.initial()) {
    on<SharedSessionJoined>(_onJoined);
    on<SessionStartTapped>(_onStartTapped);
    on<HostStepAdvanced>(_onHostStepAdvanced);
    on<SessionEndRequested>(_onSessionEndRequested);
    on<PresenceStateReceived>(_onPresenceReceived);
    on<BroadcastEventReceived>(_onBroadcastReceived);
  }

  Future<void> _onJoined(
      SharedSessionJoined event, Emitter<SharedSessionState> emit) async {
    emit(const SharedSessionState.loading());
    _myUserId = event.userId;
    _myDisplayHandle = event.displayHandle;
    _isHost = event.isHost;
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

  void _onPresenceReceived(
      PresenceStateReceived event, Emitter<SharedSessionState> emit) {
    state.mapOrNull(
      lobby: (s) =>
          emit(s.copyWith(participants: event.presenceState.participants)),
      inSession: (s) {
        final prev = s.participants;
        final next = event.presenceState.participants;

        // AC1: detect dropped participants for the inline note
        final dropped = prev
            .where((p) => !next.any((n) => n.userId == p.userId))
            .toList();
        final droppedHandle = dropped.isNotEmpty
            ? (dropped.first.displayHandle ?? dropped.first.userId)
            : null;

        // AC3 + hardening: elect a new host whenever no participant is flagged
        // host. This covers a plain host-drop AND the reconnect case where the
        // dropped host was never in `prev` (a follower that snapped to inSession
        // with empty participants). The lexicographically-first remaining userId
        // wins and re-tracks presence with isHost:true, so peers learn the new
        // host — which keeps a subsequent transfer detectable if the promoted
        // host later drops too.
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
            // AC1: clear droppedHandle on step advance (note is transient)
            emit(s.copyWith(
                stepIndex: idx, elapsedSeconds: elapsed, droppedHandle: null));
          },
          // AC2: reconnect path — follower missed session_started or re-joined mid-session
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
        // AC4: terminal state — leaves channel and emits sessionEnded()
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
