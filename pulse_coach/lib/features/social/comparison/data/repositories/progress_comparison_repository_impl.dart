import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/comparison/data/datasources/progress_comparison_remote_data_source.dart';
import 'package:pulse_coach/features/social/comparison/data/models/friend_progress_dto.dart';
import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
import 'package:pulse_coach/features/social/comparison/domain/repositories/progress_comparison_repository.dart';

@Injectable(as: ProgressComparisonRepository)
class ProgressComparisonRepositoryImpl implements ProgressComparisonRepository {
  final ProgressComparisonRemoteDataSource _dataSource;
  const ProgressComparisonRepositoryImpl(this._dataSource);

  @override
  Future<Either<SocialFailure, List<ProgressComparisonEntry>>>
      getFriendsProgress() async {
    try {
      final rows = await _dataSource.loadFriendsProgress();
      final entries = rows
          .map(_safeFromJson)
          .whereType<ProgressComparisonEntry>()
          .toList();
      return Right(entries);
    } on StateError catch (e) {
      return Left(SocialFailure('Not signed in: ${e.message}'));
    } catch (e) {
      return Left(SocialFailure('Failed to load comparison: $e'));
    }
  }

  ProgressComparisonEntry? _safeFromJson(Map<String, dynamic> row) {
    try {
      return FriendProgressDto.fromJson(row).toDomain();
    } catch (_) {
      return null; // degrade single bad row rather than crashing the full list
    }
  }
}
