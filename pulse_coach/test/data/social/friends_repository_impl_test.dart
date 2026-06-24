// [18.2-REPO-001..008] FriendsRepositoryImpl error-mapping and DTO→domain tests.
// Covers error wrapping, searchByHandle null path, getPendingRequests row mapping,
// getFriends success, and _rowToFriendItem graceful degradation.
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/data/datasources/friends_remote_data_source.dart';
import 'package:pulse_coach/features/social/friends/data/models/social_profile_dto.dart';
import 'package:pulse_coach/features/social/friends/data/repositories/friends_repository_impl.dart';

import 'friends_repository_impl_test.mocks.dart';

@GenerateMocks([FriendsRemoteDataSource])
void main() {
  late MockFriendsRemoteDataSource mockDataSource;
  late FriendsRepositoryImpl sut;

  const tProfileDto = SocialProfileDto(
    id: 'user-abc',
    displayHandle: 'testuser',
    visibilityTier: 'private',
  );

  final tFriendRow = {
    'id': 'friendship-1',
    'requester_id': 'user-abc',
    'addressee_id': 'user-xyz',
    'profiles': {'display_handle': 'testuser'},
    'created_at': '2026-06-01T10:00:00.000Z',
  };

  setUp(() {
    mockDataSource = MockFriendsRemoteDataSource();
    sut = FriendsRepositoryImpl(mockDataSource);
  });

  group('searchByHandle', () {
    test('18.2-REPO-001: found → Right(SocialProfile)', () async {
      when(mockDataSource.findByHandle('testuser'))
          .thenAnswer((_) async => tProfileDto);

      final result = await sut.searchByHandle('testuser');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (profile) => expect(profile?.displayHandle, 'testuser'),
      );
    });

    test('18.2-REPO-002: not found → Right(null)', () async {
      when(mockDataSource.findByHandle('nobody'))
          .thenAnswer((_) async => null);

      final result = await sut.searchByHandle('nobody');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (profile) => expect(profile, isNull),
      );
    });

    test('18.2-REPO-003: exception → Left(SocialFailure)', () async {
      when(mockDataSource.findByHandle(any))
          .thenThrow(Exception('network error'));

      final result = await sut.searchByHandle('any');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SocialFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('getPendingRequests', () {
    test('18.2-REPO-004: success → maps received and sent rows', () async {
      when(mockDataSource.getPendingRequests()).thenAnswer((_) async => (
            received: [tFriendRow],
            sent: <Map<String, dynamic>>[],
          ));

      final result = await sut.getPendingRequests();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (pending) {
          expect(pending.received.length, 1);
          expect(pending.received.first.userId, 'user-abc');
          expect(pending.received.first.displayHandle, 'testuser');
          expect(pending.sent, isEmpty);
        },
      );
    });

    test('18.2-REPO-005: exception → Left(SocialFailure)', () async {
      when(mockDataSource.getPendingRequests())
          .thenThrow(Exception('server error'));

      final result = await sut.getPendingRequests();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SocialFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('getFriends', () {
    test('18.2-REPO-006: success → maps friendship rows to FriendItems', () async {
      final friendRow = {
        'id': 'friendship-2',
        'requester_id': 'me',
        'addressee_id': 'user-xyz',
        'profiles': {'display_handle': 'myfriend'},
        'created_at': '2026-06-10T08:00:00.000Z',
      };
      when(mockDataSource.getAllFriends())
          .thenAnswer((_) async => [friendRow]);

      final result = await sut.getFriends();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (friends) {
          expect(friends.length, 1);
          expect(friends.first.displayHandle, 'myfriend');
        },
      );
    });

    test('18.2-REPO-007: exception → Left(SocialFailure)', () async {
      when(mockDataSource.getAllFriends())
          .thenThrow(Exception('connection refused'));

      final result = await sut.getFriends();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SocialFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('_rowToFriendItem graceful degradation', () {
    test(
      '18.2-REPO-008: null profiles embed → displayHandle empty; '
      'malformed created_at → epoch',
      () async {
        final degradedRow = {
          'id': 'friendship-3',
          'requester_id': 'user-rls-hidden',
          'addressee_id': 'me',
          'profiles': null, // RLS hides the profile embed
          'created_at': 'not-a-valid-date',
        };
        when(mockDataSource.getPendingRequests()).thenAnswer((_) async => (
              received: [degradedRow],
              sent: <Map<String, dynamic>>[],
            ));

        final result = await sut.getPendingRequests();

        result.fold(
          (_) => fail('expected Right'),
          (pending) {
            final item = pending.received.first;
            expect(item.displayHandle, '');
            expect(
              item.createdAt,
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            );
          },
        );
      },
    );
  });
}
