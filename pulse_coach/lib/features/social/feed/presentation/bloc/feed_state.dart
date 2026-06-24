import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';

part 'feed_state.freezed.dart';

@freezed
abstract class FeedState with _$FeedState {
  const factory FeedState.initial() = _Initial;
  const factory FeedState.loading() = _Loading;
  const factory FeedState.loaded({
    required List<FeedEntry> entries,
    /// Set of feedEntryIds currently animating a reaction (per-card animation control)
    @Default(<String>{}) Set<String> reactingIds,
  }) = _Loaded;
  const factory FeedState.error({required Failure failure}) = _Error;
}
