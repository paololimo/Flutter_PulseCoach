import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';

part 'progress_comparison_state.freezed.dart';

@freezed
abstract class ProgressComparisonState with _$ProgressComparisonState {
  const factory ProgressComparisonState.initial() = _Initial;
  const factory ProgressComparisonState.loading() = _Loading;
  const factory ProgressComparisonState.loaded({
    required ProgressComparisonEntry ownEntry,
    required List<ProgressComparisonEntry> friendEntries,
  }) = _Loaded;
  const factory ProgressComparisonState.error({required Failure failure}) =
      _Error;
}
