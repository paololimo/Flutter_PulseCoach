import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/supabase_client.dart' show PostgrestException;
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/data/datasources/social_profile_remote_data_source.dart';
import 'package:pulse_coach/features/social/friends/data/models/social_profile_dto.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/social_profile_repository.dart';

@Injectable(as: SocialProfileRepository)
class SocialProfileRepositoryImpl implements SocialProfileRepository {
  final SocialProfileRemoteDataSource _dataSource;
  const SocialProfileRepositoryImpl(this._dataSource);

  @override
  Future<Either<SocialFailure, SocialProfile>> getSocialProfile() async {
    try {
      final dto = await _dataSource.getSocialProfile();
      return Right(dto.toDomain());
    } catch (e) {
      return Left(SocialFailure('Failed to load profile: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, SocialProfile>> updateHandle(
      String handle) async {
    try {
      final dto = await _dataSource.updateHandle(handle);
      return Right(dto.toDomain());
    } on PostgrestException catch (e) {
      if (e.code == '23505') return const Left(SocialHandleTakenFailure());
      return Left(SocialFailure('Handle update failed: ${e.message}'));
    } catch (e) {
      return Left(SocialFailure('Handle update failed: $e'));
    }
  }

  @override
  Future<Either<SocialFailure, SocialProfile>> updateVisibilityTier(
      VisibilityTier tier) async {
    try {
      final dto = await _dataSource.updateVisibilityTier(tier.toSupabaseValue());
      return Right(dto.toDomain());
    } catch (e) {
      return Left(SocialFailure('Visibility update failed: $e'));
    }
  }
}
