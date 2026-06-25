// [19.1-GW-009..015] RealtimeGateway lifecycle + stream-guard tests
// Covers 19.1-AC1: channel open/close lifecycle and pre/post-join stream state.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show
        ChannelResponse,
        RealtimeChannel,
        RealtimeChannelConfig,
        RealtimePresenceJoinPayload,
        RealtimePresenceLeavePayload,
        RealtimePresenceSyncPayload,
        RealtimeSubscribeStatus,
        SinglePresenceState,
        SupabaseClient;

import 'package:pulse_coach/core/cloud/realtime_gateway.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart';

// ---------------------------------------------------------------------------
// Fakes — minimal stand-ins so joinChannel() runs without Supabase.initialize().
// ---------------------------------------------------------------------------

class _FakeChannel extends Fake implements RealtimeChannel {
  @override
  RealtimeChannel onBroadcast({
    required String event,
    required void Function(Map<String, dynamic> payload) callback,
  }) =>
      this;

  @override
  RealtimeChannel onPresenceSync(
          void Function(RealtimePresenceSyncPayload payload) callback) =>
      this;

  @override
  RealtimeChannel onPresenceJoin(
          void Function(RealtimePresenceJoinPayload payload) callback) =>
      this;

  @override
  RealtimeChannel onPresenceLeave(
          void Function(RealtimePresenceLeavePayload payload) callback) =>
      this;

  @override
  RealtimeChannel subscribe(
          [void Function(RealtimeSubscribeStatus, Object?)? callback,
          Duration? timeout]) =>
      this;

  @override
  Future<String> unsubscribe([Duration? timeout]) async => 'ok';

  @override
  List<SinglePresenceState> presenceState() => [];
}

class _FakeClient extends Fake implements SupabaseClient {
  final _FakeChannel _ch;
  _FakeClient(this._ch);

  @override
  RealtimeChannel channel(String name,
          {RealtimeChannelConfig opts = const RealtimeChannelConfig()}) =>
      _ch;

  @override
  Future<String> removeChannel(RealtimeChannel channel) async => 'ok';
}

class _FakeProvider extends Fake implements SupabaseClientProvider {
  final _FakeClient _client;
  _FakeProvider(this._client);

  @override
  SupabaseClient get client => _client;
}

RealtimeGateway _gateway() =>
    RealtimeGateway(_FakeProvider(_FakeClient(_FakeChannel())));

// ---------------------------------------------------------------------------

void main() {
  group('RealtimeGateway lifecycle (19.1-AC1)', () {
    test('19.1-GW-009: broadcastEvents is empty stream before joinChannel',
        () async {
      await expectLater(_gateway().broadcastEvents, emitsDone);
    });

    test('19.1-GW-010: presenceUpdates is empty stream before joinChannel',
        () async {
      await expectLater(_gateway().presenceUpdates, emitsDone);
    });

    test('19.1-GW-011: sendBroadcast throws StateError before joinChannel',
        () async {
      await expectLater(
        _gateway().sendBroadcast(event: 'test', payload: {}),
        throwsA(isA<StateError>()),
      );
    });

    test('19.1-GW-012: trackPresence throws StateError before joinChannel',
        () async {
      await expectLater(
        _gateway().trackPresence(userId: 'u1'),
        throwsA(isA<StateError>()),
      );
    });

    test(
        '19.1-GW-013: joinChannel different session ID throws shared_session_already_active',
        () async {
      final gw = _gateway();
      await gw.joinChannel('session-1');
      await expectLater(
        gw.joinChannel('session-2'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'shared_session_already_active',
          ),
        ),
      );
    });

    test('19.1-GW-014: joinChannel same session ID is idempotent (no throw)',
        () async {
      final gw = _gateway();
      await gw.joinChannel('session-1');
      await expectLater(gw.joinChannel('session-1'), completes);
    });

    test('19.1-GW-015: leaveChannel closes the in-flight broadcast stream',
        () async {
      final gw = _gateway();
      await gw.joinChannel('session-1');

      final doneCompleter = Completer<void>();
      final sub = gw.broadcastEvents.listen(
        (_) {},
        onDone: doneCompleter.complete,
      );

      await gw.leaveChannel();

      await expectLater(doneCompleter.future, completes);
      await sub.cancel();
    });
  });
}
