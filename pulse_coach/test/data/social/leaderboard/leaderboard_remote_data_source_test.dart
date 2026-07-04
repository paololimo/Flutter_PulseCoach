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
