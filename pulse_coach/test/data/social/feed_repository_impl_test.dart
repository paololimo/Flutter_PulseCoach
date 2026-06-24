// [18.3-REPO-001..008] FeedRepositoryImpl tests.
// Covers _rowToDto nested profile parsing, bad-row degradation,
// AuthFailureException → SocialFailure mapping, and error wrapping.
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/feed/data/datasources/feed_remote_data_source.dart';
import 'package:pulse_coach/features/social/feed/data/repositories/feed_repository_impl.dart';

import 'feed_repository_impl_test.mocks.dart';

@GenerateMocks([FeedRemoteDataSource])
void main() {
  late MockFeedRemoteDataSource mockDataSource;
  late FeedRepositoryImpl sut;

  final tValidRow = {
    'id': 'feed-entry-1',
    'owner_id': 'user-abc',
    'session_type': 'cardio',
    'duration_minutes': 30,
    'completed_at': '2026-06-20T10:00:00.000Z',
    'created_at': '2026-06-20T10:00:00.001Z',
    'profiles': {'display_handle': 'paolol'},
  };

  setUp(() {
    mockDataSource = MockFeedRemoteDataSource();
    sut = FeedRepositoryImpl(mockDataSource);
  });

  group('getFeed', () {
    test(
      '18.3-REPO-001: success — valid row with nested profile handle '
      '→ Right(list with FeedEntry)',
      () async {
        when(mockDataSource.loadFeed())
            .thenAnswer((_) async => [tValidRow]);

        final result = await sut.getFeed();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (entries) {
            expect(entries.length, 1);
            expect(entries.first.ownerHandle, 'paolol');
            expect(entries.first.sessionType, 'cardio');
            expect(entries.first.durationMinutes, 30);
          },
        );
      },
    );

    test(
      '18.3-REPO-002: malformed row degrades — bad row excluded, '
      'valid row still returned',
      () async {
        final badRow = <String, dynamic>{
          'id': 123, // wrong type — will throw in _rowToDto
          'owner_id': 'user-abc',
        };
        when(mockDataSource.loadFeed())
            .thenAnswer((_) async => [badRow, tValidRow]);

        final result = await sut.getFeed();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (entries) {
            // bad row degraded to null and filtered; valid row remains
            expect(entries.length, 1);
            expect(entries.first.ownerHandle, 'paolol');
          },
        );
      },
    );

    test('18.3-REPO-003: exception → Left(SocialFailure)', () async {
      when(mockDataSource.loadFeed())
          .thenThrow(Exception('network timeout'));

      final result = await sut.getFeed();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SocialFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('shareFeedEntry', () {
    test('18.3-REPO-004: success → Right(unit)', () async {
      when(mockDataSource.currentUserId).thenReturn('user-abc');
      when(mockDataSource.share(
        ownerId: anyNamed('ownerId'),
        sessionType: anyNamed('sessionType'),
        durationMinutes: anyNamed('durationMinutes'),
        completedAt: anyNamed('completedAt'),
      )).thenAnswer((_) async {});

      final result = await sut.shareFeedEntry(
        sessionType: 'mobility',
        durationMinutes: 20,
        completedAt: DateTime(2026, 6, 24),
      );

      expect(result.isRight(), isTrue);
    });

    test(
      '18.3-REPO-005: AuthFailureException → Left(SocialFailure(Not signed in))',
      () async {
        when(mockDataSource.currentUserId)
            .thenThrow(const AuthFailureException());

        final result = await sut.shareFeedEntry(
          sessionType: 'mobility',
          durationMinutes: 20,
          completedAt: DateTime(2026, 6, 24),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) {
            expect(f, isA<SocialFailure>());
            expect(f.message, 'Not signed in');
          },
          (_) => fail('expected Left'),
        );
      },
    );

    test('18.3-REPO-006: generic exception → Left(SocialFailure)', () async {
      when(mockDataSource.currentUserId).thenReturn('user-abc');
      when(mockDataSource.share(
        ownerId: anyNamed('ownerId'),
        sessionType: anyNamed('sessionType'),
        durationMinutes: anyNamed('durationMinutes'),
        completedAt: anyNamed('completedAt'),
      )).thenThrow(Exception('server error'));

      final result = await sut.shareFeedEntry(
        sessionType: 'mobility',
        durationMinutes: 20,
        completedAt: DateTime(2026, 6, 24),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SocialFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('reactToEntry', () {
    test('18.3-REPO-007: success → Right(unit)', () async {
      when(mockDataSource.incrementReaction('entry-1'))
          .thenAnswer((_) async {});

      final result = await sut.reactToEntry('entry-1');

      expect(result.isRight(), isTrue);
    });

    test('18.3-REPO-008: exception → Left(SocialFailure)', () async {
      when(mockDataSource.incrementReaction(any))
          .thenThrow(Exception('rate limited'));

      final result = await sut.reactToEntry('entry-1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SocialFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });
}
