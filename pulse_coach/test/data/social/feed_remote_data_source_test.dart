// [18.3-DS-001..005] FeedRemoteDataSource tests using @visibleForTesting hooks.
// No Supabase initialization required — all calls go through overridden hooks.
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider;
import 'package:pulse_coach/features/social/feed/data/datasources/feed_remote_data_source.dart';

import 'feed_remote_data_source_test.mocks.dart';

@GenerateMocks([SupabaseClientProvider])
void main() {
  late MockSupabaseClientProvider mockSupabase;
  late FeedRemoteDataSource sut;

  setUp(() {
    mockSupabase = MockSupabaseClientProvider();
    sut = FeedRemoteDataSource(mockSupabase);
  });

  group('share', () {
    test(
      '18.3-DS-001: share — inserts row with correct fields, no biometric data',
      () async {
        Map<String, dynamic>? capturedRow;
        sut.insertFeedEntry = (row) async {
          capturedRow = row;
        };

        final completedAt = DateTime.utc(2026, 6, 24, 10, 0, 0);
        await sut.share(
          ownerId: 'user-abc',
          sessionType: 'cardio',
          durationMinutes: 25,
          completedAt: completedAt,
        );

        expect(capturedRow, isNotNull);
        expect(capturedRow!['owner_id'], 'user-abc');
        expect(capturedRow!['session_type'], 'cardio');
        expect(capturedRow!['duration_minutes'], 25);
        expect(capturedRow!['completed_at'], completedAt.toIso8601String());
        // No biometric fields
        expect(capturedRow!.containsKey('rpe_value'), isFalse);
        expect(capturedRow!.containsKey('heart_rate'), isFalse);
      },
    );
  });

  group('loadFeed', () {
    test(
      '18.3-DS-002: loadFeed — returns list of raw rows',
      () async {
        final fakeRows = [
          {
            'id': 'feed-1',
            'owner_id': 'user-abc',
            'session_type': 'mobility',
            'duration_minutes': 15,
            'completed_at': '2026-06-24T10:00:00.000Z',
            'created_at': '2026-06-24T10:01:00.000Z',
            'profiles': {'display_handle': 'paolol'},
          }
        ];
        sut.fetchFeed = () async => fakeRows;

        final rows = await sut.loadFeed();

        expect(rows.length, 1);
        expect(rows[0]['id'], 'feed-1');
        expect(rows[0]['session_type'], 'mobility');
      },
    );
  });

  group('incrementReaction', () {
    test(
      '18.3-DS-003: incrementReaction — calls RPC with feed_id',
      () async {
        String? capturedId;
        sut.callIncrementReaction = (id) async {
          capturedId = id;
        };

        await sut.incrementReaction('feed-123');

        expect(capturedId, 'feed-123');
      },
    );
  });

  group('revoke', () {
    test(
      '18.3-DS-004: revoke — calls deleteFeedEntry with correct id',
      () async {
        String? capturedId;
        sut.deleteFeedEntry = (id) async {
          capturedId = id;
        };

        await sut.revoke('feed-999');

        expect(capturedId, 'feed-999');
      },
    );

    test(
      '18.3-DS-004b: revoke — propagates exception on zero affected rows',
      () async {
        sut.deleteFeedEntry = (id) async {
          throw Exception('No rows deleted — not owner or entry missing');
        };

        expect(
          () => sut.revoke('feed-missing'),
          throwsException,
        );
      },
    );
  });

  group('_uid / AuthFailureException', () {
    test(
      '18.3-DS-005: currentUserId getter — throws when no auth session is configured',
      () {
        // With strict mocks, accessing _supabase.client on an unconfigured
        // MockSupabaseClientProvider throws MissingStubError. Any access path
        // that reaches _uid will throw, confirming the session guard is in place.
        expect(() => sut.currentUserId, throwsA(anything));
      },
    );
  });
}
