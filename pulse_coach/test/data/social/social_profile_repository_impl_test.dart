// [18.1-REPO-001..007] SocialProfileRepositoryImpl error-mapping tests.
// Exercises the PostgrestException code '23505' → SocialHandleTakenFailure
// mapping end-to-end from the data source, plus generic failure wrapping.
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/data/datasources/social_profile_remote_data_source.dart';
import 'package:pulse_coach/features/social/friends/data/models/social_profile_dto.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/data/repositories/social_profile_repository_impl.dart';

import 'social_profile_repository_impl_test.mocks.dart';

@GenerateMocks([SocialProfileRemoteDataSource])
void main() {
  late MockSocialProfileRemoteDataSource mockDataSource;
  late SocialProfileRepositoryImpl sut;

  const tDto = SocialProfileDto(
    id: 'user-123',
    displayHandle: 'paolol',
    visibilityTier: 'private',
  );

  setUp(() {
    mockDataSource = MockSocialProfileRemoteDataSource();
    sut = SocialProfileRepositoryImpl(mockDataSource);
  });

  group('getSocialProfile', () {
    test('18.1-REPO-001: success → Right(SocialProfile)', () async {
      when(mockDataSource.getSocialProfile()).thenAnswer((_) async => tDto);

      final result = await sut.getSocialProfile();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected Right'),
        (profile) => expect(profile.displayHandle, 'paolol'),
      );
    });

    test('18.1-REPO-002: throw → Left(SocialFailure)', () async {
      when(mockDataSource.getSocialProfile())
          .thenThrow(Exception('network down'));

      final result = await sut.getSocialProfile();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SocialFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('updateHandle', () {
    test('18.1-REPO-003: success → Right(SocialProfile)', () async {
      when(mockDataSource.updateHandle('paolol'))
          .thenAnswer((_) async => tDto);

      final result = await sut.updateHandle('paolol');

      expect(result.isRight(), isTrue);
    });

    test(
      '18.1-REPO-004: PostgrestException 23505 → Left(SocialHandleTakenFailure)',
      () async {
        when(mockDataSource.updateHandle('taken')).thenThrow(
          const PostgrestException(message: 'duplicate key', code: '23505'),
        );

        final result = await sut.updateHandle('taken');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) => expect(f, isA<SocialHandleTakenFailure>()),
          (_) => fail('expected Left'),
        );
      },
    );

    test(
      '18.1-REPO-005: non-23505 PostgrestException → Left(SocialFailure, not taken)',
      () async {
        when(mockDataSource.updateHandle('bad')).thenThrow(
          const PostgrestException(message: 'boom', code: '42P01'),
        );

        final result = await sut.updateHandle('bad');

        expect(result.isLeft(), isTrue);
        result.fold(
          (f) {
            expect(f, isA<SocialFailure>());
            expect(f, isNot(isA<SocialHandleTakenFailure>()));
          },
          (_) => fail('expected Left'),
        );
      },
    );

    test('18.1-REPO-006: generic exception → Left(SocialFailure)', () async {
      when(mockDataSource.updateHandle('x')).thenThrow(Exception('weird'));

      final result = await sut.updateHandle('x');

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SocialFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('updateVisibilityTier', () {
    test('18.1-REPO-007: throw → Left(SocialFailure)', () async {
      when(mockDataSource.updateVisibilityTier(any))
          .thenThrow(Exception('network down'));

      final result = await sut.updateVisibilityTier(VisibilityTier.friendsOnly);

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SocialFailure>()),
        (_) => fail('expected Left'),
      );
    });
  });
}
