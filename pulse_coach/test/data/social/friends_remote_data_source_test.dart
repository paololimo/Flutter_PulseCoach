// [18.2-DS-001..008] FriendsRemoteDataSource tests using @visibleForTesting hooks.
// No Supabase initialization required — all calls go through overridden hooks.
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider;
import 'package:pulse_coach/features/social/friends/data/datasources/friends_remote_data_source.dart';

import 'friends_remote_data_source_test.mocks.dart';

@GenerateMocks([SupabaseClientProvider])
void main() {
  late MockSupabaseClientProvider mockSupabase;
  late FriendsRemoteDataSource sut;

  setUp(() {
    mockSupabase = MockSupabaseClientProvider();
    sut = FriendsRemoteDataSource(mockSupabase);
  });

  group('findByHandle', () {
    test(
      '18.2-DS-001: profile found → returns SocialProfileDto with correct fields',
      () async {
        sut.searchByHandle = (_) async => {
              'id': 'user-abc',
              'display_handle': 'paolotest',
              'visibility_tier': 'friends_only',
            };

        final dto = await sut.findByHandle('paolotest');

        expect(dto, isNotNull);
        expect(dto!.id, 'user-abc');
        expect(dto.displayHandle, 'paolotest');
      },
    );

    test(
      '18.2-DS-002: no profile → returns null',
      () async {
        sut.searchByHandle = (_) async => null;

        final dto = await sut.findByHandle('nobody');

        expect(dto, isNull);
      },
    );
  });

  group('getPendingRequests', () {
    test(
      '18.2-DS-003: returns received + sent rows correctly',
      () async {
        sut.fetchPendingRequests = () async => {
              'received': [
                {
                  'id': 'fs-1',
                  'requester_id': 'user-x',
                  'created_at': '2026-06-01T10:00:00Z',
                  'profiles': {'display_handle': 'xhandle'},
                },
              ],
              'sent': [
                {
                  'id': 'fs-2',
                  'addressee_id': 'user-y',
                  'created_at': '2026-06-02T10:00:00Z',
                  'profiles': {'display_handle': 'yhandle'},
                },
              ],
            };

        final result = await sut.getPendingRequests();

        expect(result.received.length, 1);
        expect(result.sent.length, 1);
        expect(result.received.first['id'], 'fs-1');
        expect(result.sent.first['id'], 'fs-2');
      },
    );
  });

  group('getAllFriends', () {
    test(
      '18.2-DS-004: returns combined asRequester + asAddressee rows',
      () async {
        sut.fetchFriends = () async => [
              {
                'id': 'fs-req',
                'addressee_id': 'user-a',
                'created_at': '2026-06-01T10:00:00Z',
                'profiles': {'display_handle': 'ahandle'},
              },
              {
                'id': 'fs-addr',
                'requester_id': 'user-b',
                'created_at': '2026-06-02T10:00:00Z',
                'profiles': {'display_handle': 'bhandle'},
              },
            ];

        final rows = await sut.getAllFriends();

        expect(rows.length, 2);
      },
    );
  });

  group('addFriend', () {
    test(
      '18.2-DS-005: calls insertFriendRequest with correct addresseeId',
      () async {
        String? captured;
        sut.insertFriendRequest = (addresseeId) async {
          captured = addresseeId;
        };

        await sut.addFriend('target-user-id');

        expect(captured, 'target-user-id');
      },
    );
  });

  group('acceptFriendship', () {
    test(
      '18.2-DS-006: calls updateFriendshipStatus with accepted',
      () async {
        String? capturedId;
        String? capturedStatus;
        sut.updateFriendshipStatus = (id, status) async {
          capturedId = id;
          capturedStatus = status;
        };

        await sut.acceptFriendship('fs-123');

        expect(capturedId, 'fs-123');
        expect(capturedStatus, 'accepted');
      },
    );
  });

  group('declineFriendship', () {
    test(
      '18.2-DS-007: calls deleteFriendship with correct id',
      () async {
        String? captured;
        sut.deleteFriendship = (id) async => captured = id;

        await sut.declineFriendship('fs-456');

        expect(captured, 'fs-456');
      },
    );
  });

  group('removeFriendship', () {
    test(
      '18.2-DS-008: calls deleteFriendship with correct id',
      () async {
        String? captured;
        sut.deleteFriendship = (id) async => captured = id;

        await sut.removeFriendship('fs-789');

        expect(captured, 'fs-789');
      },
    );
  });
}
