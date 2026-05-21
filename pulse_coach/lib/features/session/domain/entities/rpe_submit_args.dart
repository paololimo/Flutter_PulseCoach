/// Navigation contract for the /session/rpe route.
///
/// Carries everything RpePage needs to persist RPE without touching upstream
/// Cubits.
class RpeSubmitArgs {
  final int? planId;
  final int sessionIndex;
  final bool abandoned;
  final String armKey;
  final int? sessionLogId;

  const RpeSubmitArgs({
    this.planId,
    required this.sessionIndex,
    required this.abandoned,
    required this.armKey,
    this.sessionLogId,
  });
}
