// [18.4-REPO-001..004] ProgressComparisonRepositoryImpl tests.
// Covers _safeFromJson bad-row degradation, StateError → SocialFailure,
// and generic exception wrapping.
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/comparison/data/datasources/progress_comparison_remote_data_source.dart';
import 'package:pulse_coach/features/social/comparison/data/repositories/progress_comparison_repository_impl.dart';

import 'progress_comparison_repository_impl_test.mocks.dart';

@GenerateMocks([ProgressComparisonRemoteDataSource])
void main() {
  late MockProgressComparisonRemoteDataSource mockDataSource;
  late ProgressComparisonRepositoryImpl sut;

  final tValidRow = {
    'friend_id': 'user-xyz',
    'display_handle': 'runner42',
    'sessions_count': 3,
    'minutes_total': 90,
  };

  setUp(() {
    mockDataSource = MockProgressComparisonRemoteDataSource();
    sut = ProgressComparisonRepositoryImpl(mockDataSource);
  });

  group('getFriendsProgress', () {
    test(
      '18.4-REPO-001: success — valid rows → Right(list of ProgressComparisonEntry)',
      () async {
        when(mockDataSource.loadFriendsProgress())
            .thenAnswer((_) async => [tValidRow]);

        final result = await sut.getFriendsProgress();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (entries) {
            expect(entries.length, 1);
            expect(entries.first.displayHandle, 'runner42');
            expect(entries.first.sessionsThisWeek, 3);
            expect(entries.first.minutesThisWeek, 90);
          },
        );
      },
    );

    test(
      '18.4-REPO-002: malformed row degrades — bad row null-filtered, '
      'valid row still returned',
      () async {
        final badRow = <String, dynamic>{
          'friend_id': null, // fromJson handles null gracefully but wrong type cast might fail
          'display_handle': <String, dynamic>{}, // wrong type — throws in fromJson
          'sessions_count': 'not-a-number',
          'minutes_total': 'not-a-number',
        };
        when(mockDataSource.loadFriendsProgress())
            .thenAnswer((_) async => [badRow, tValidRow]);

        final result = await sut.getFriendsProgress();

        // _safeFromJson degrades bad row; at least the valid entry survives
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('expected Right'),
          (entries) {
            expect(entries.any((e) => e.displayHandle == 'runner42'), isTrue);
          },
        );
      },
    );

    test(
      '18.4-REPO-003: StateError (not signed in) → Left(SocialFailure with message)',
      () async {
        when(mockDataSource.loadFriendsProgress())
            .thenThrow(StateError('No authenticated session'));

        final result = await sut.getFriendsProgress();

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) {
            expect(f, isA<SocialFailure>());
            expect(f.message, contains('Not signed in'));
          },
          (_) => fail('expected Left'),
        );
      },
    );

    test('18.4-REPO-004: generic exception → Left(SocialFailure)', () async {
      when(mockDataSource.loadFriendsProgress())
          .thenThrow(Exception('RPC call failed'));

      final result = await sut.getFriendsProgress();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SocialFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });
}
