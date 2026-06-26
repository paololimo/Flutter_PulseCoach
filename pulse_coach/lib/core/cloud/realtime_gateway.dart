// ARCHITECTURE BOUNDARY (ARCH25): this file is one of the few locations
// permitted to import supabase_flutter directly (alongside supabase_client.dart,
// secure_local_storage.dart, and the one-time init in main.dart).
// All other layers must depend on RealtimeGateway via injection.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pulse_coach/core/cloud/supabase_client.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';

@singleton
class RealtimeGateway {
  final SupabaseClientProvider _clientProvider;

  RealtimeChannel? _channel;
  String? _activeSessionId;
  StreamController<BroadcastEvent>? _broadcastController;
  StreamController<PresenceState>? _presenceController;

  RealtimeGateway(this._clientProvider);

  Stream<BroadcastEvent> get broadcastEvents =>
      _broadcastController?.stream ?? const Stream.empty();

  Stream<PresenceState> get presenceUpdates =>
      _presenceController?.stream ?? const Stream.empty();

  Future<void> joinChannel(String sessionId) async {
    if (_channel != null) {
      // Single-active-session invariant: refuse to silently tear down a live
      // channel for a *different* session, which would deafen any consumer
      // still listening to it. Same-session re-join is allowed (idempotent).
      if (_activeSessionId != sessionId) {
        throw StateError('shared_session_already_active');
      }
      await leaveChannel();
    }
    _activeSessionId = sessionId;
    _broadcastController = StreamController<BroadcastEvent>.broadcast();
    _presenceController = StreamController<PresenceState>.broadcast();

    _channel = _clientProvider.client
        .channel(
          'shared-session:$sessionId',
          // self: true so the host receives the echo of its own broadcasts
          // (session_started / step_advanced). The host's lobby→inSession
          // transition depends on this echo (ARCH21 host authority).
          opts: const RealtimeChannelConfig(self: true),
        )
        .onBroadcast(
          event: 'step_advanced',
          callback: (payload) {
            final event = _parseBroadcast('step_advanced', payload);
            if (event != null) _broadcastController?.add(event);
          },
        )
        .onBroadcast(
          event: 'session_started',
          callback: (_) =>
              _broadcastController?.add(const BroadcastEvent.sessionStarted()),
        )
        .onBroadcast(
          event: 'session_ended',
          callback: (_) =>
              _broadcastController?.add(const BroadcastEvent.sessionEnded()),
        )
        .onPresenceSync((_) => _emitPresenceState())
        .onPresenceJoin((_) => _emitPresenceState())
        .onPresenceLeave((_) => _emitPresenceState());

    _channel!.subscribe();
  }

  Future<void> leaveChannel() async {
    final ch = _channel;
    final broadcastController = _broadcastController;
    final presenceController = _presenceController;
    // Detach references first so the gateway is left in a clean state even if
    // the async teardown throws — a subsequent joinChannel must not re-trigger
    // the re-entry guard against a half-torn-down channel.
    _channel = null;
    _activeSessionId = null;
    _broadcastController = null;
    _presenceController = null;
    try {
      await ch?.unsubscribe();
      if (ch != null) {
        await _clientProvider.client.removeChannel(ch);
      }
    } finally {
      await broadcastController?.close();
      await presenceController?.close();
    }
  }

  Future<void> sendBroadcast({
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    final channel = _channel;
    if (channel == null) {
      throw StateError('sendBroadcast called before joinChannel');
    }
    await channel.sendBroadcastMessage(event: event, payload: payload);
  }

  Future<void> trackPresence({
    required String userId,
    String? displayHandle,
    bool isHost = false,
    double? lat,
    double? lon,
  }) async {
    final channel = _channel;
    if (channel == null) {
      throw StateError('trackPresence called before joinChannel');
    }
    await channel.track({
      'user_id': userId,
      'display_handle': displayHandle,
      'is_host': isHost,
      'lat': ?lat,
      'lon': ?lon,
    });
  }

  Future<void> untrackPresence() async {
    final channel = _channel;
    if (channel == null) {
      throw StateError('untrackPresence called before joinChannel');
    }
    await channel.untrack();
  }

  void _emitPresenceState() {
    final rawState = _channel?.presenceState() ?? [];
    final participants = rawState.expand((s) => s.presences).map((p) {
      final userId = p.payload['user_id'];
      final displayHandle = p.payload['display_handle'];
      final isHost = p.payload['is_host'];
      final lat = p.payload['lat'];
      final lon = p.payload['lon'];
      return ParticipantPresence(
        userId: userId is String ? userId : '',
        displayHandle: displayHandle is String ? displayHandle : null,
        isHost: isHost is bool && isHost,
        lat: lat is num ? lat.toDouble() : null,
        lon: lon is num ? lon.toDouble() : null,
      );
    }).toList();
    _presenceController?.add(PresenceState(participants: participants));
  }

  @visibleForTesting
  static BroadcastEvent? parseBroadcast(
      String event, Map<String, dynamic> payload) {
    switch (event) {
      case 'step_advanced':
        final stepIndex = payload['step_index'];
        final elapsedSeconds = payload['elapsed_seconds'];
        if (stepIndex is num && elapsedSeconds is num) {
          return BroadcastEvent.stepAdvanced(
            stepIndex: stepIndex.toInt(),
            elapsedSeconds: elapsedSeconds.toInt(),
          );
        }
        return null;
      case 'session_started':
        return const BroadcastEvent.sessionStarted();
      case 'session_ended':
        return const BroadcastEvent.sessionEnded();
      default:
        return BroadcastEvent.unknown(rawEvent: event);
    }
  }

  BroadcastEvent? _parseBroadcast(
          String event, Map<String, dynamic> payload) =>
      parseBroadcast(event, payload);
}
