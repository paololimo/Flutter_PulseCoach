enum VisibilityTier {
  private,
  friendsOnly;

  String toSupabaseValue() => switch (this) {
        VisibilityTier.private => 'private',
        VisibilityTier.friendsOnly => 'friends_only',
      };

  static VisibilityTier fromSupabaseValue(String value) => switch (value) {
        'friends_only' => VisibilityTier.friendsOnly,
        _ => VisibilityTier.private,
      };
}
