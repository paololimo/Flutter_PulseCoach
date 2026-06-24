// [18.4-DS-001..003] ProgressComparisonRemoteDataSource tests using @visibleForTesting hooks.
// No Supabase initialization required — all calls go through overridden hooks.
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider;
import 'package:pulse_coach/features/social/comparison/data/datasources/progress_comparison_remote_data_source.dart';

import 'progress_comparison_remote_data_source_test.mocks.dart';

@GenerateMocks([SupabaseClientProvider])
void main() {
  late MockSupabaseClientProvider mockSupabase;
  late ProgressComparisonRemoteDataSource sut;

  setUp(() {
    mockSupabase = MockSupabaseClientProvider();
    sut = ProgressComparisonRemoteDataSource(mockSupabase);
  });

  group('loadFriendsProgress', () {
    test(
      '18.4-DS-001: loadFriendsProgress — returns list of rows from RPC',
      () async {
        final fakeRows = [
          {
            'friend_id': 'user-abc',
            'display_handle': 'alice',
            'sessions_count': 2,
            'minutes_total': 35,
          },
          {
            'friend_id': 'user-def',
            'display_handle': 'bob',
            'sessions_count': 1,
            'minutes_total': 20,
          },
        ];
        sut.fetchFriendsProgress = () async => fakeRows;

        final rows = await sut.loadFriendsProgress();

        expect(rows.length, 2);
        expect(rows[0]['friend_id'], 'user-abc');
        expect(rows[0]['display_handle'], 'alice');
        expect(rows[1]['sessions_count'], 1);
      },
    );

    test(
      '18.4-DS-002: loadFriendsProgress — returns empty list when RPC returns []',
      () async {
        sut.fetchFriendsProgress = () async => [];

        final rows = await sut.loadFriendsProgress();

        expect(rows, isEmpty);
      },
    );

    test(
      '18.4-DS-003: _uid guard — StateError thrown by seam propagates through loadFriendsProgress',
      () async {
        // The _uid guard inside _defaultFetchFriendsProgress throws StateError
        // when currentUser is null. Here we simulate that path via the seam.
        sut.fetchFriendsProgress =
            () async => throw StateError('No authenticated session');

        await expectLater(
          sut.loadFriendsProgress(),
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
