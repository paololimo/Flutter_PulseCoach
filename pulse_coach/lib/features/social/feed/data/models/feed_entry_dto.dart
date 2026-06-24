import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';

part 'feed_entry_dto.freezed.dart';
part 'feed_entry_dto.g.dart';

@freezed
abstract class FeedEntryDto with _$FeedEntryDto {
  const factory FeedEntryDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'session_type') required String sessionType,
    @JsonKey(name: 'duration_minutes') required int durationMinutes,
    @JsonKey(name: 'completed_at') required String completedAt,
    @JsonKey(name: 'created_at') required String createdAt,
    // joined from profiles; nullable for resilience
    @JsonKey(name: 'display_handle') String? displayHandle,
  }) = _FeedEntryDto;

  factory FeedEntryDto.fromJson(Map<String, dynamic> json) =>
      _$FeedEntryDtoFromJson(json);
}

extension FeedEntryDtoMapper on FeedEntryDto {
  FeedEntry toDomain() => FeedEntry(
        id: id,
        ownerHandle: displayHandle ?? ownerId,
        ownerId: ownerId,
        sessionType: sessionType,
        durationMinutes: durationMinutes,
        completedAt: DateTime.parse(completedAt),
        createdAt: DateTime.parse(createdAt),
      );
}
