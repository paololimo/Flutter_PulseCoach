import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

abstract class SocialProfileRepository {
  Future<Either<SocialFailure, SocialProfile>> getSocialProfile();
  Future<Either<SocialFailure, SocialProfile>> updateHandle(String handle);
  Future<Either<SocialFailure, SocialProfile>> updateVisibilityTier(
      VisibilityTier tier);
}
