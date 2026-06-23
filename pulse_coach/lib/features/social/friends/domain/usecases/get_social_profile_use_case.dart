import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/social_profile_repository.dart';

@injectable
class GetSocialProfileUseCase {
  final SocialProfileRepository _repository;
  const GetSocialProfileUseCase(this._repository);

  Future<Either<SocialFailure, SocialProfile>> call() =>
      _repository.getSocialProfile();
}
