/// Navigation contract for the /session/summary route.
///
/// Carries everything MiniSummaryPage needs to render the post-session recap
/// without reaching into upstream Cubits.
class MiniSummaryArgs {
  final int rpeValue;
  final String sessionType;
  final int durationMinutes;
  final bool abandoned;
  final int? planId;

  const MiniSummaryArgs({
    required this.rpeValue,
    required this.sessionType,
    required this.durationMinutes,
    required this.abandoned,
    this.planId,
  });
}
