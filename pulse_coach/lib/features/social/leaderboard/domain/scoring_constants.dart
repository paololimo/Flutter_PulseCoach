/// Points-system constants for solo session scoring (Story 21.1, FR74).
///
/// `dailyPointsCap` MUST match `v_daily_cap` in
/// supabase/migrations/0011_leaderboard.sql — the Postgres value is the
/// real enforcement point (server-side, per ARCH v2 rule #10); this
/// constant only lets the client display/reason about the same number
/// later (Story 21.2) without a second source of truth drifting apart.
class ScoringConstants {
  const ScoringConstants._();

  static const int dailyPointsCap = 200;

  /// Maps an `armKey` (`'{sessionType}_{low|medium|high}'`) to its point
  /// weight. Bucket names come from the codebase's existing intensity
  /// vocabulary (`_intensityName()` in `in_session_page.dart` /
  /// `shared_session_bloc.dart`), not epics.md's literal
  /// minimal/low/moderate wording — mapped by ordinal position to
  /// preserve the specified 1 / 1.5 / 2 progression.
  static double intensityWeightFor(String armKey) {
    if (armKey.endsWith('_low')) return 1.0;
    if (armKey.endsWith('_medium')) return 1.5;
    return 2.0; // '_high'
  }
}
