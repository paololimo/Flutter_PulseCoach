import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/sync/sync_manager.dart';
import 'package:pulse_coach/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:pulse_coach/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'leaderboard_repository_impl_test.mocks.dart';

@GenerateMocks([SyncManager, LeaderboardRemoteDataSource])
void main() {
  late MockSyncManager mockSyncManager;
  late MockLeaderboardRemoteDataSource mockDataSource;
  late SharedPreferences prefs;
  late LeaderboardRepositoryImpl sut;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockSyncManager = MockSyncManager();
    mockDataSource = MockLeaderboardRemoteDataSource();
    sut = LeaderboardRepositoryImpl(mockSyncManager, prefs, mockDataSource);
  });

  test(
    '21.1-REPO-001: awardSessionPoints — enqueues with correct eventType and '
    'install-namespaced payload',
    () async {
      when(mockSyncManager.enqueue(any, any)).thenAnswer((_) async => 1);

      final result = await sut.awardSessionPoints(
        sessionLogId: 42,
        basePoints: 30,
        awardedOnUtc: DateTime.utc(2026, 7, 2, 10, 30),
      );

      expect(result.isRight(), isTrue);
      final captured = verify(
        mockSyncManager.enqueue(captureAny, captureAny),
      ).captured;
      expect(captured[0], LeaderboardRemoteDataSource.awardEventType);
      final payload = jsonDecode(captured[1] as String) as Map<String, dynamic>;
      // sessionLogId is now '{installId}:42' — a 32-hex-char per-install
      // namespace (persisted in prefs) prefixing the local Drift id, so it
      // stays globally unique across reinstalls/devices.
      final installId = prefs.getString(LeaderboardRepositoryImpl.installIdKey);
      expect(installId, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(payload['sessionLogId'], '$installId:42');
      expect(payload['basePoints'], 30);
      expect(payload['awardedOn'], '2026-07-02');
    },
  );

  test(
    '21.1-REPO-003: awardSessionPoints — install id is stable across calls '
    '(same session_log_id → same idempotency key for replay)',
    () async {
      when(mockSyncManager.enqueue(any, any)).thenAnswer((_) async => 1);

      await sut.awardSessionPoints(
        sessionLogId: 42,
        basePoints: 30,
        awardedOnUtc: DateTime.utc(2026, 7, 2, 10, 30),
      );
      await sut.awardSessionPoints(
        sessionLogId: 42,
        basePoints: 30,
        awardedOnUtc: DateTime.utc(2026, 7, 2, 10, 30),
      );

      final captured = verify(
        mockSyncManager.enqueue(any, captureAny),
      ).captured;
      final first =
          (jsonDecode(captured[0] as String) as Map)['sessionLogId'];
      final second =
          (jsonDecode(captured[1] as String) as Map)['sessionLogId'];
      expect(first, second);
    },
  );

  test(
    '21.1-REPO-002: awardSessionPoints — enqueue throws → returns Left(SocialFailure)',
    () async {
      when(mockSyncManager.enqueue(any, any)).thenThrow(Exception('offline'));

      final result = await sut.awardSessionPoints(
        sessionLogId: 42,
        basePoints: 30,
        awardedOnUtc: DateTime.utc(2026, 7, 2, 10, 30),
      );

      expect(result.isLeft(), isTrue);
    },
  );

  group('submitSharedSessionResult', () {
    test(
      '[21.3-REPO-001] submitSharedSessionResult(...) → SyncManager.enqueue '
      'called with sharedResultEventType and a JSON payload containing all '
      '4 fields',
      () async {
        when(mockSyncManager.enqueue(any, any)).thenAnswer((_) async => 1);

        final result = await sut.submitSharedSessionResult(
          sessionId: 'sess-1',
          rpe: 7,
          armKey: 'mobility_medium',
          durationMinutes: 20,
        );

        expect(result.isRight(), isTrue);
        final captured = verify(
          mockSyncManager.enqueue(captureAny, captureAny),
        ).captured;
        expect(captured[0], LeaderboardRemoteDataSource.sharedResultEventType);
        final payload =
            jsonDecode(captured[1] as String) as Map<String, dynamic>;
        expect(payload['sessionId'], 'sess-1');
        expect(payload['rpe'], 7);
        expect(payload['armKey'], 'mobility_medium');
        expect(payload['durationMinutes'], 20);
      },
    );

    test(
      '[21.3-REPO-002] SyncManager.enqueue throws → returns '
      'Left(SocialFailure)',
      () async {
        when(mockSyncManager.enqueue(any, any)).thenThrow(Exception('offline'));

        final result = await sut.submitSharedSessionResult(
          sessionId: 'sess-1',
          rpe: 7,
          armKey: 'mobility_medium',
          durationMinutes: 20,
        );

        expect(result.isLeft(), isTrue);
      },
    );
  });

  group('getFriendsLeaderboard', () {
    test(
      '[21.2-REPO-001] maps datasource rows to the unranked tuple list correctly',
      () async {
        when(mockDataSource.loadLeaderboard()).thenAnswer(
          (_) async => [
            {
              'user_id': 'u1',
              'display_handle': 'alice',
              'total_points': 30,
              'is_own': true,
            },
          ],
        );

        final result = await sut.getFriendsLeaderboard();

        expect(result.isRight(), isTrue);
        final entries = result.getOrElse(() => []);
        expect(entries.length, 1);
        expect(entries.first.userId, 'u1');
        expect(entries.first.displayHandle, 'alice');
        expect(entries.first.totalPoints, 30);
        expect(entries.first.isOwn, isTrue);
      },
    );

    test(
      '[21.2-REPO-002] one malformed row among valid ones → bad row dropped, valid rows still returned',
      () async {
        when(mockDataSource.loadLeaderboard()).thenAnswer(
          (_) async => [
            {
              'user_id': 'u1',
              'display_handle': 'alice',
              'total_points': 30,
              'is_own': true,
            },
            {
              // malformed: user_id has the wrong type, fromJson's cast throws
              'user_id': 123,
              'display_handle': 'bob',
              'total_points': 10,
              'is_own': false,
            },
          ],
        );

        final result = await sut.getFriendsLeaderboard();

        expect(result.isRight(), isTrue);
        final entries = result.getOrElse(() => []);
        expect(entries.length, 1);
        expect(entries.first.userId, 'u1');
      },
    );

    test(
      '[21.2-REPO-003] datasource throws → returns Left(SocialFailure)',
      () async {
        when(
          mockDataSource.loadLeaderboard(),
        ).thenThrow(Exception('network error'));

        final result = await sut.getFriendsLeaderboard();

        expect(result.isLeft(), isTrue);
      },
    );
  });
}
