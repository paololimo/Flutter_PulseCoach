import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';

abstract class ProgressComparisonRepository {
  Future<Either<SocialFailure, List<ProgressComparisonEntry>>> getFriendsProgress();
}
