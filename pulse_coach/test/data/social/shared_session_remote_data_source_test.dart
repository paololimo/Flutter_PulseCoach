// [E21R-D2] Regression lock for the Story 21.5 D2 fix: a shared-session HOST
// must be registered as a session_participants row at creation time, otherwise
// score_shared_session / sweep_unscored_shared_sessions (which key off
// session_participants) never score the host and they earn ZERO points for a
// completed shared session.
//
// The Supabase fluent client is not unit-testable without a brittle chain mock,
// so createSharedSession/joinSharedSession delegate their two write operations
// to @visibleForTesting seams. These tests override the seams to assert the
// host-participant invariant directly — no live backend, no fragile mock.
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart';
import 'package:pulse_coach/features/social/shared_session/data/datasources/shared_session_remote_data_source.dart';

class _FakeSupabaseClientProvider implements SupabaseClientProvider {
  // The seams are overridden in every test, so .client is never touched.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Supabase client must not be reached in a seam test');
}

void main() {
  late SharedSessionRemoteDataSource sut;
  late List<({String sessionId, String userId})> upserts;

  setUp(() {
    sut = SharedSessionRemoteDataSource(_FakeSupabaseClientProvider());
    upserts = [];
    sut.upsertParticipant = (sessionId, userId) async {
      upserts.add((sessionId: sessionId, userId: userId));
    };
  });

  group('createSharedSession host-participant registration (D2)', () {
    test(
      'E21R-D2-001: createSharedSession upserts a participant row for the host',
      () async {
        sut.insertSharedSession = (hostUserId, code) async => {
          'id': 'sess-42',
          'host_user_id': hostUserId,
          'join_code': code,
          'status': 'waiting',
          'created_at': '2026-07-07T10:00:00.000Z',
        };

        final dto = await sut.createSharedSession(hostUserId: 'host-abc');

        expect(dto.id, 'sess-42');
        expect(dto.hostUserId, 'host-abc');
        // The invariant: the host is registered as a participant of the new
        // session, keyed by the session id from the insert.
        expect(
          upserts,
          contains((sessionId: 'sess-42', userId: 'host-abc')),
          reason:
              'host must be a session_participants row or scoring skips them (D2)',
        );
      },
    );

    test(
      'E21R-D2-002: host participant uses the created session id, not a stale one',
      () async {
        sut.insertSharedSession = (hostUserId, code) async => {
          'id': 'sess-99',
          'host_user_id': hostUserId,
          'join_code': code,
          'status': 'waiting',
          'created_at': '2026-07-07T10:00:00.000Z',
        };

        await sut.createSharedSession(hostUserId: 'host-xyz');

        expect(upserts.single.sessionId, 'sess-99');
        expect(upserts.single.userId, 'host-xyz');
      },
    );
  });
}
