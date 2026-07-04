import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider;
import 'package:pulse_coach/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart';

import 'leaderboard_remote_data_source_test.mocks.dart';

@GenerateMocks([SupabaseClientProvider])
void main() {
  late MockSupabaseClientProvider mockSupabase;
  late LeaderboardRemoteDataSource sut;

  setUp(() {
    mockSupabase = MockSupabaseClientProvider();
    sut = LeaderboardRemoteDataSource(mockSupabase);
  });

  group('awardPoints', () {
    test(
      '21.1-DS-001: awardPoints — callAwardRpc invoked with exact args',
      () async {
        String? capturedSessionLogId;
        int? capturedBasePoints;
        String? capturedAwardedOnIso;
        sut.callAwardRpc = (sessionLogId, basePoints, awardedOnIso) async {
          capturedSessionLogId = sessionLogId;
          capturedBasePoints = basePoints;
          capturedAwardedOnIso = awardedOnIso;
        };

        await sut.awardPoints(
          sessionLogId: '42',
          basePoints: 30,
          awardedOnIso: '2026-07-02',
        );

        expect(capturedSessionLogId, '42');
        expect(capturedBasePoints, 30);
        expect(capturedAwardedOnIso, '2026-07-02');
      },
    );
  });

  group('replayAward', () {
    test(
      '21.1-DS-002: replayAward — decodes payload, invokes callAwardRpc, returns Right(unit)',
      () async {
        String? capturedSessionLogId;
        int? capturedBasePoints;
        String? capturedAwardedOnIso;
        sut.callAwardRpc = (sessionLogId, basePoints, awardedOnIso) async {
          capturedSessionLogId = sessionLogId;
          capturedBasePoints = basePoints;
          capturedAwardedOnIso = awardedOnIso;
        };

        final result = await sut.replayAward(
          '{"sessionLogId":"42","basePoints":30,"awardedOn":"2026-07-02"}',
        );

        expect(capturedSessionLogId, '42');
        expect(capturedBasePoints, 30);
        expect(capturedAwardedOnIso, '2026-07-02');
        expect(result.isRight(), isTrue);
      },
    );

    test(
      '21.1-DS-003: replayAward — callAwardRpc throws → returns Left(ServerFailure)',
      () async {
        sut.callAwardRpc = (sessionLogId, basePoints, awardedOnIso) async {
          throw Exception('RPC failed');
        };

        final result = await sut.replayAward(
          '{"sessionLogId":"42","basePoints":30,"awardedOn":"2026-07-02"}',
        );

        expect(result.isLeft(), isTrue);
      },
    );

    test(
      '21.1-DS-004: replayAward — malformed JSON → returns Left(ServerFailure), does not throw',
      () async {
        final result = await sut.replayAward('not-json');

        expect(result.isLeft(), isTrue);
      },
    );
  });

  group('submitSharedResult', () {
    test(
      '[21.3-DS-001] submitSharedResult(...) → callSubmitSharedResultRpc '
      'invoked with the exact 4 args',
      () async {
        String? capturedSessionId;
        int? capturedRpe;
        String? capturedArmKey;
        int? capturedDurationMinutes;
        sut.callSubmitSharedResultRpc =
            (sessionId, rpe, armKey, durationMinutes) async {
          capturedSessionId = sessionId;
          capturedRpe = rpe;
          capturedArmKey = armKey;
          capturedDurationMinutes = durationMinutes;
        };

        await sut.submitSharedResult('sess-1', 7, 'mobility_medium', 20);

        expect(capturedSessionId, 'sess-1');
        expect(capturedRpe, 7);
        expect(capturedArmKey, 'mobility_medium');
        expect(capturedDurationMinutes, 20);
      },
    );

    test(
      '[21.3-DS-002] replaySubmitSharedResult(payload) → decodes JSON and '
      'calls callSubmitSharedResultRpc with the decoded fields',
      () async {
        String? capturedSessionId;
        int? capturedRpe;
        String? capturedArmKey;
        int? capturedDurationMinutes;
        sut.callSubmitSharedResultRpc =
            (sessionId, rpe, armKey, durationMinutes) async {
          capturedSessionId = sessionId;
          capturedRpe = rpe;
          capturedArmKey = armKey;
          capturedDurationMinutes = durationMinutes;
        };

        final result = await sut.replaySubmitSharedResult(
          '{"sessionId":"sess-1","rpe":7,"armKey":"mobility_medium","durationMinutes":20}',
        );

        expect(capturedSessionId, 'sess-1');
        expect(capturedRpe, 7);
        expect(capturedArmKey, 'mobility_medium');
        expect(capturedDurationMinutes, 20);
        expect(result.isRight(), isTrue);
      },
    );

    test(
      '[21.3-DS-003] replaySubmitSharedResult with malformed JSON → returns '
      'Left(ServerFailure), does not throw',
      () async {
        final result = await sut.replaySubmitSharedResult('not-json');

        expect(result.isLeft(), isTrue);
      },
    );
  });

  group('loadLeaderboard', () {
    test(
      '[21.2-DS-001] loadLeaderboard() → fetchLeaderboard invoked, returns its raw list verbatim',
      () async {
        final rawRows = [
          {
            'user_id': 'u1',
            'display_handle': 'alice',
            'total_points': 30,
            'is_own': true,
          },
        ];
        sut.fetchLeaderboard = () async => rawRows;

        final result = await sut.loadLeaderboard();

        expect(result, rawRows);
      },
    );
  });
}
