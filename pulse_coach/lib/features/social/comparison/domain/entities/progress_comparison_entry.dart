import 'package:freezed_annotation/freezed_annotation.dart';

part 'progress_comparison_entry.freezed.dart';

@freezed
abstract class ProgressComparisonEntry with _$ProgressComparisonEntry {
  const factory ProgressComparisonEntry({
    required String displayHandle,
    required int sessionsThisWeek,
    required int minutesThisWeek,
    @Default(false) bool isOwn,
  }) = _ProgressComparisonEntry;
}
