import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/repositories/social_profile_repository.dart';

@injectable
class UpdateHandleUseCase {
  final SocialProfileRepository _repository;
  const UpdateHandleUseCase(this._repository);

  Future<Either<SocialFailure, SocialProfile>> call(String handle) =>
      _repository.updateHandle(handle);
}
