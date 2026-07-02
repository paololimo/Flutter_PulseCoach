import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/sync/sync_manager.dart';
import 'package:pulse_coach/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import 'package:pulse_coach/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'leaderboard_repository_impl_test.mocks.dart';

@GenerateMocks([SyncManager])
void main() {
  late MockSyncManager mockSyncManager;
  late SharedPreferences prefs;
  late LeaderboardRepositoryImpl sut;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockSyncManager = MockSyncManager();
    sut = LeaderboardRepositoryImpl(mockSyncManager, prefs);
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
}
