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
  // Guards teardown so a bloc that never joined (or failed to join) does not
  // leave a channel owned by another bloc instance.
  bool _joined = false;

  SharedSessionBloc(this._gateway) : super(const SharedSessionState.initial()) {
    on<SharedSessionJoined>(_onJoined);
    on<SessionStartTapped>(_onStartTapped);
    on<HostStepAdvanced>(_onHostStepAdvanced);
    on<PresenceStateReceived>(_onPresenceReceived);
    on<BroadcastEventReceived>(_onBroadcastReceived);
  }

  Future<void> _onJoined(
      SharedSessionJoined event, Emitter<SharedSessionState> emit) async {
    emit(const SharedSessionState.loading());
    try {
      await _gateway.joinChannel(event.sessionId);
      _joined = true;
      await _gateway.trackPresence(
        userId: event.userId,
        displayHandle: event.displayHandle,
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
      // The host's local session continues; followers experience a sync gap
      // that will be corrected on the next step_advanced broadcast.
      // Story 19.3 (drop-out tolerance) handles persistent broadcast failure.
    }
  }

  void _onPresenceReceived(
      PresenceStateReceived event, Emitter<SharedSessionState> emit) {
    state.mapOrNull(
      lobby: (s) =>
          emit(s.copyWith(participants: event.presenceState.participants)),
      inSession: (s) => null,
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
          )),
        );
      case StepAdvanced(stepIndex: final idx, elapsedSeconds: final elapsed):
        state.mapOrNull(
          inSession: (s) {
            if (s.isHost) return;
            emit(s.copyWith(stepIndex: idx, elapsedSeconds: elapsed));
          },
        );
      case SessionEnded():
        if (_joined) {
          _joined = false;
          unawaited(_gateway.leaveChannel());
        }
        emit(const SharedSessionState.initial());
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
