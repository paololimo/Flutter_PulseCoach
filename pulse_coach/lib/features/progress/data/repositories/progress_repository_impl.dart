import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/progress/data/datasources/progress_local_data_source.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';

@LazySingleton(as: ProgressRepository)
class ProgressRepositoryImpl implements ProgressRepository {
  const ProgressRepositoryImpl(this._dataSource);

  final ProgressLocalDataSource _dataSource;

  @override
  Future<Either<Failure, List<SessionHistoryEntry>>> getSessionHistory() async {
    try {
      final entries = await _dataSource.getSessionHistory();
      return Right(entries);
    } catch (e, st) {
      AppLogger.error(
        'getSessionHistory failed',
        name: 'ProgressRepositoryImpl',
        error: e,
        stackTrace: st,
      );
      return const Left(CacheFailure('progress_history_load_failed'));
    }
  }

  @override
  Future<Either<Failure, ProgressStats>> getProgressStats() async {
    try {
      final stats = await _dataSource.getProgressStats();
      return Right(stats);
    } catch (e, st) {
      AppLogger.error(
        'getProgressStats failed',
        name: 'ProgressRepositoryImpl',
        error: e,
        stackTrace: st,
      );
      return const Left(CacheFailure('progress_stats_load_failed'));
    }
  }
}
