import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
import 'package:pulse_coach/features/social/comparison/domain/repositories/progress_comparison_repository.dart';

@injectable
class GetFriendsComparisonUseCase {
  final ProgressComparisonRepository _repository;
  const GetFriendsComparisonUseCase(this._repository);

  Future<Either<SocialFailure, List<ProgressComparisonEntry>>> call() =>
      _repository.getFriendsProgress();
}
