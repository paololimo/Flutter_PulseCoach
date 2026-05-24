import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';

/// Read-only contract for the progress feature.
///
/// Story 10.1 uses only [getSessionHistory]. Story 10.2+ will add
/// getProgressStats here.
abstract class ProgressRepository {
  Future<Either<Failure, List<SessionHistoryEntry>>> getSessionHistory();
}
