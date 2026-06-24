import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_entry.freezed.dart';

@freezed
abstract class FeedEntry with _$FeedEntry {
  const factory FeedEntry({
    required String id,
    required String ownerHandle,
    required String ownerId,
    required String sessionType,
    required int durationMinutes,
    required DateTime completedAt,
    required DateTime createdAt,
    // reactions count intentionally NOT stored — never displayed (UX-DR27/31)
  }) = _FeedEntry;
}
