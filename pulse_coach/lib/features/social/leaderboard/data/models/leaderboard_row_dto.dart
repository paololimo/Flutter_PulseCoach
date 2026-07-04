class LeaderboardRowDto {
  final String userId;
  final String displayHandle;
  final int totalPoints;
  final bool isOwn;

  const LeaderboardRowDto({
    required this.userId,
    required this.displayHandle,
    required this.totalPoints,
    required this.isOwn,
  });

  factory LeaderboardRowDto.fromJson(Map<String, dynamic> json) {
    return LeaderboardRowDto(
      userId: json['user_id'] as String? ?? '',
      displayHandle:
          json['display_handle'] as String? ??
          (json['user_id'] as String? ?? ''),
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      isOwn: json['is_own'] as bool? ?? false,
    );
  }
}
