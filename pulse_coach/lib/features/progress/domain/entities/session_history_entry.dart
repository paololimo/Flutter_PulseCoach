import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_history_entry.freezed.dart';

/// Flattened view of one session_logs row, enriched with plan data and RPE.
///
/// Constructed by ProgressLocalDataSource from session_logs + daily_plans
/// (planJson) + rpe_feedback joins. Read-only; never persisted.
@freezed
abstract class SessionHistoryEntry with _$SessionHistoryEntry {
  const factory SessionHistoryEntry({
    required int sessionLogId,
    required DateTime completedAt,

    /// 'mobility' | 'cardio' | 'breathing' from PlannedSession.sessionType.
    required String sessionType,
    required int durationMinutes,
    required bool abandoned,

    /// Null when user did not submit RPE for this session.
    int? rpeValue,

    /// Elapsed seconds at abandon time; null for completed sessions.
    int? elapsedSeconds,
  }) = _SessionHistoryEntry;
}
