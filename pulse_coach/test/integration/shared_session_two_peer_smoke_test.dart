// E19R-1 — Two-peer integration smoke for the shared-session realtime transport.
//
// WHY THIS EXISTS
// Epic 19's retro (E19R-1) and the Epic 20 GUI gate both showed that hand-mocked
// `RealtimeGateway` streams keep the unit/widget suite green even when the *real*
// Supabase channel contract is violated (the "host-echo class" of bug). Nothing in
// the 1245-test suite exercises two real peers on the live channel. This test does:
// it stands up two independent authenticated Supabase clients on the SAME channel
// (mirroring `RealtimeGateway`'s exact topic + `RealtimeChannelConfig(self: true)`
// config) and verifies presence + broadcast delivery end to end.
//
// SCOPE: transport contract only (presence handle round-trip, broadcast delivery,
// host self-echo). It does NOT cover UI defects (e.g. the lobby overflow D1 or the
// follower timer D3) — those are caught by the on-device two-device GUI gate.
//
// HOW TO RUN (requires network + the live Supabase EU project + seed users):
//   flutter test test/integration/shared_session_two_peer_smoke_test.dart \
//     --dart-define-from-file=dart-defines.json \
//     --dart-define=SMOKE_PASSWORD=<seed-user-password>
//
// The default `flutter test` run SKIPS this file (no SUPABASE_URL / SMOKE_PASSWORD),
// so it never breaks offline CI. Promote to a scheduled/gated job to run it on a
// cadence (E19R-1 follow-up).
//
// Seed users (created for manual testing, see epic-18 retro): the two emails below;
// the password is supplied via --dart-define=SMOKE_PASSWORD and is never committed.
@Tags(['integration', 'network'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _password = String.fromEnvironment('SMOKE_PASSWORD');
const _hostEmail =
    String.fromEnvironment('SMOKE_HOST_EMAIL', defaultValue: 'paolo.coach@gmail.com');
const _followerEmail = String.fromEnvironment('SMOKE_FOLLOWER_EMAIL',
    defaultValue: 'marco.rossi@gmail.com');

// Mirrors RealtimeGateway.joinChannel: same topic prefix + self-echo config.
RealtimeChannel _sharedChannel(SupabaseClient client, String sessionId) =>
    client.channel(
      'shared-session:$sessionId',
      opts: const RealtimeChannelConfig(self: true),
    );

Future<void> _subscribed(RealtimeChannel channel) {
  final completer = Completer<void>();
  channel.subscribe((status, error) {
    if (status == RealtimeSubscribeStatus.subscribed && !completer.isCompleted) {
      completer.complete();
    } else if (error != null && !completer.isCompleted) {
      completer.completeError(error);
    }
  });
  return completer.future.timeout(const Duration(seconds: 15));
}

void main() {
  final missingCreds = _url.isEmpty || _anonKey.isEmpty || _password.isEmpty;

  group('shared-session two-peer transport smoke (E19R-1)', () {
    late SupabaseClient host;
    late SupabaseClient follower;
    final sessionId = 'smoke-${DateTime.now().millisecondsSinceEpoch}';

    setUpAll(() async {
      host = SupabaseClient(_url, _anonKey);
      follower = SupabaseClient(_url, _anonKey);
      await host.auth.signInWithPassword(email: _hostEmail, password: _password);
      await follower.auth
          .signInWithPassword(email: _followerEmail, password: _password);
      // Raw SupabaseClient does not auto-propagate the user JWT to the realtime
      // socket the way supabase_flutter does — presence/broadcast on an
      // authenticated channel needs the access token set explicitly.
      host.realtime.setAuth(host.auth.currentSession!.accessToken);
      follower.realtime.setAuth(follower.auth.currentSession!.accessToken);
    });

    tearDownAll(() async {
      await host.removeAllChannels();
      await follower.removeAllChannels();
      await host.auth.signOut();
      await follower.auth.signOut();
      await host.dispose();
      await follower.dispose();
    });

    test('join → presence → start → step_advanced → session_ended', () async {
      final hostUserId = host.auth.currentUser!.id;
      final followerUserId = follower.auth.currentUser!.id;

      // Follower's broadcast inbox — assert host→follower delivery.
      final followerStarted = Completer<Map<String, dynamic>>();
      final followerStep = Completer<Map<String, dynamic>>();
      final followerEnded = Completer<void>();
      // Host's own inbox — assert the self:true echo (host authority depends on it).
      final hostStartedEcho = Completer<void>();

      final hostChannel = _sharedChannel(host, sessionId)
        // Presence callbacks must be bound BEFORE subscribe() or the channel
        // never syncs presence state (mirrors RealtimeGateway).
        ..onPresenceSync((_) {})
        ..onBroadcast(
          event: 'session_started',
          callback: (_) {
            if (!hostStartedEcho.isCompleted) hostStartedEcho.complete();
          },
        );
      final followerChannel = _sharedChannel(follower, sessionId)
        ..onPresenceSync((_) {})
        ..onBroadcast(
          event: 'session_started',
          callback: (p) {
            if (!followerStarted.isCompleted) followerStarted.complete(p);
          },
        )
        ..onBroadcast(
          event: 'step_advanced',
          callback: (p) {
            if (!followerStep.isCompleted) followerStep.complete(p);
          },
        )
        ..onBroadcast(
          event: 'session_ended',
          callback: (_) {
            if (!followerEnded.isCompleted) followerEnded.complete();
          },
        );

      await Future.wait([_subscribed(hostChannel), _subscribed(followerChannel)]);

      // Presence: host tracks as host, follower as follower.
      await hostChannel.track({
        'user_id': hostUserId,
        'display_handle': 'host_smoke',
        'is_host': true,
      });
      await followerChannel.track({
        'user_id': followerUserId,
        'display_handle': 'follower_smoke',
        'is_host': false,
      });

      // Both clients should see two presences with the handles intact.
      await _expectPresenceCount(followerChannel, 2);
      await _expectPresenceCount(hostChannel, 2);
      final handles = followerChannel
          .presenceState()
          .expand((s) => s.presences)
          .map((p) => p.payload['display_handle'])
          .toSet();
      expect(handles, containsAll(<String>['host_smoke', 'follower_smoke']),
          reason: 'presence must round-trip display_handle (D1/handle contract)');

      // session_started — follower receives, host receives its own echo (self:true).
      await hostChannel.sendBroadcastMessage(
        event: 'session_started',
        payload: {
          'session_type': 'mobility',
          'intensity': 5,
          'duration_minutes': 20,
          'arm_key': 'mobility_medium',
        },
      );
      final startedPayload =
          await followerStarted.future.timeout(const Duration(seconds: 10));
      expect(startedPayload['arm_key'], 'mobility_medium');
      await hostStartedEcho.future.timeout(const Duration(seconds: 10),
          onTimeout: () => fail(
              'host did not receive its own session_started echo — self:true '
              'config regressed (host-authority lobby→inSession breaks)'));

      // step_advanced — follower advances to the host's step + elapsed.
      await hostChannel.sendBroadcastMessage(
        event: 'step_advanced',
        payload: {'step_index': 1, 'elapsed_seconds': 240},
      );
      final stepPayload =
          await followerStep.future.timeout(const Duration(seconds: 10));
      expect((stepPayload['step_index'] as num).toInt(), 1);
      expect((stepPayload['elapsed_seconds'] as num).toInt(), 240);

      // session_ended — follower transitions to its own RPE flow.
      await hostChannel.sendBroadcastMessage(
        event: 'session_ended',
        payload: <String, dynamic>{},
      );
      await followerEnded.future.timeout(const Duration(seconds: 10));
    });
  },
      skip: missingCreds
          ? 'requires --dart-define SUPABASE_URL, SUPABASE_ANON_KEY and SMOKE_PASSWORD'
          : false);
}

Future<void> _expectPresenceCount(RealtimeChannel channel, int expected) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    final count =
        channel.presenceState().expand((s) => s.presences).length;
    if (count >= expected) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  fail('presence did not reach $expected participants within timeout');
}
