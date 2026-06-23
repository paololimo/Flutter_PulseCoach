import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/social_profile_repository.dart';

@injectable
class UpdateVisibilityTierUseCase {
  final SocialProfileRepository _repository;
  const UpdateVisibilityTierUseCase(this._repository);

  Future<Either<SocialFailure, SocialProfile>> call(VisibilityTier tier) =>
      _repository.updateVisibilityTier(tier);
}
