import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

/// Read-only contract for the progress feature.
///
abstract class ProgressRepository {
  Future<Either<Failure, List<SessionHistoryEntry>>> getSessionHistory();

  Future<Either<Failure, ProgressStats>> getProgressStats();
}
