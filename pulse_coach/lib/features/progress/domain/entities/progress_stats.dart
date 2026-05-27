import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_stats.freezed.dart';

/// One ISO-week bucket for the minutes-per-week bar chart.
@freezed
abstract class WeeklyMinutes with _$WeeklyMinutes {
  const factory WeeklyMinutes({
    /// Human-readable label, e.g. '03/06' (Monday date of that week DD/MM).
    required String weekLabel,
    required int totalMinutes,
  }) = _WeeklyMinutes;
}

/// One RPE observation for the RPE trend line chart.
@freezed
abstract class RpeDataPoint with _$RpeDataPoint {
  const factory RpeDataPoint({
    required DateTime completedAt,
    required int rpeValue,
  }) = _RpeDataPoint;
}

/// Aggregated stats for the Progress charts tab.
///
/// Assembled by the progress local data source from session logs, daily plans,
/// and RPE feedback. Never persisted; pure read-side projection.
@freezed
abstract class ProgressStats with _$ProgressStats {
  const factory ProgressStats({
    /// Completed (not abandoned) sessions.
    required int completedCount,

    /// Abandoned sessions.
    required int abandonedCount,

    /// Last <= 8 ISO weeks, oldest first.
    required List<WeeklyMinutes> minutesPerWeek,

    /// Last <= 20 sessions with RPE, oldest first.
    required List<RpeDataPoint> rpeTrend,

    /// Session type counts, e.g. {'mobility': 5, 'cardio': 3}.
    required Map<String, int> sessionTypeCounts,

    /// Non-abandoned sessions completed in the current ISO week (Mon-Sun).
    required int completedThisWeek,

    /// Always 3 - the AI initial session-count cap (FR12).
    required int weeklyTarget,
  }) = _ProgressStats;
}
