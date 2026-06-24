import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';

/// Plain Dart class — no freezed needed (read-only projection, no copyWith required).
class FriendProgressDto {
  final String friendId;
  final String displayHandle;
  final int sessionsThisWeek;
  final int minutesThisWeek;

  const FriendProgressDto({
    required this.friendId,
    required this.displayHandle,
    required this.sessionsThisWeek,
    required this.minutesThisWeek,
  });

  factory FriendProgressDto.fromJson(Map<String, dynamic> json) {
    return FriendProgressDto(
      friendId: json['friend_id'] as String? ?? '',
      displayHandle: json['display_handle'] as String? ??
          (json['friend_id'] as String? ?? ''),
      sessionsThisWeek: (json['sessions_count'] as num?)?.toInt() ?? 0,
      minutesThisWeek: (json['minutes_total'] as num?)?.toInt() ?? 0,
    );
  }

  ProgressComparisonEntry toDomain() => ProgressComparisonEntry(
        displayHandle: displayHandle,
        sessionsThisWeek: sessionsThisWeek,
        minutesThisWeek: minutesThisWeek,
        // isOwn defaults to false
      );
}
