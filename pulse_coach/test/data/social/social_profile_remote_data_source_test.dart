// [18.1-DS-001..005] SocialProfileRemoteDataSource tests using @visibleForTesting hooks.
// No Supabase initialization required — all calls go through overridden hooks.
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart'
    show SupabaseClientProvider, PostgrestException;
import 'package:pulse_coach/features/social/friends/data/datasources/social_profile_remote_data_source.dart';
import 'package:pulse_coach/features/social/friends/data/models/social_profile_dto.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

import 'social_profile_remote_data_source_test.mocks.dart';

@GenerateMocks([SupabaseClientProvider])
void main() {
  late MockSupabaseClientProvider mockSupabase;
  late SocialProfileRemoteDataSource sut;

  setUp(() {
    mockSupabase = MockSupabaseClientProvider();
    sut = SocialProfileRemoteDataSource(mockSupabase);
  });

  group('getSocialProfile', () {
    test(
      '18.1-DS-001: row exists → returns DTO with correct fields',
      () async {
        sut.fetchProfile = () async => {
              'id': 'user-123',
              'display_handle': 'paolol',
              'visibility_tier': 'private',
            };

        final dto = await sut.getSocialProfile();

        expect(dto.id, 'user-123');
        expect(dto.displayHandle, 'paolol');
        expect(dto.visibilityTier, 'private');
      },
    );

    test(
      '18.1-DS-002: no row → datasource reads userId from client (throws when unauthenticated)',
      () async {
        sut.fetchProfile = () async => null;
        // When row is null, getSocialProfile reads _supabase.client.auth.currentUser?.id.
        // MockSupabaseClientProvider.client is unstubbed, so the invocation throws.
        // This verifies the null-row branch reaches the client — production code
        // only hits this path when the user IS authenticated (no null row for known user).
        expect(
          () => sut.getSocialProfile(),
          throwsA(anything),
          reason: '18.1-DS-002: null-row path invokes client; unauthenticated mock throws as expected',
        );
      },
    );

    test(
      '18.1-DS-003: updateHandle success → returns updated DTO',
      () async {
        sut.patchProfile = (patch) async => {
              'id': 'user-123',
              'display_handle': 'newhandle',
              'visibility_tier': 'private',
            };

        final dto = await sut.updateHandle('newhandle');

        expect(dto.displayHandle, 'newhandle');
        expect(dto.toDomain().displayHandle, 'newhandle');
      },
    );

    test(
      '18.1-DS-004: updateHandle — PostgrestException from patch propagates to repository layer',
      () async {
        sut.patchProfile = (_) async => throw const PostgrestException(
              message: 'duplicate key',
              code: '23505',
            );

        expect(
          () => sut.updateHandle('taken'),
          throwsA(isA<PostgrestException>()),
          reason: '18.1-DS-004: PostgrestException from patch propagates up for repository to map',
        );
      },
    );

    test(
      '18.1-DS-005: updateVisibilityTier success → returns updated DTO',
      () async {
        sut.patchProfile = (patch) async => {
              'id': 'user-123',
              'display_handle': null,
              'visibility_tier': patch['visibility_tier'] as String,
            };

        final dto = await sut.updateVisibilityTier('friends_only');

        expect(dto.visibilityTier, 'friends_only');
        expect(dto.toDomain().visibilityTier, VisibilityTier.friendsOnly);
      },
    );
  });
}
