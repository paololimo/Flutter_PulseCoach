import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

/// Navigation contract for the /session/active route.
///
/// Carries session data plus persistence context so InSessionPage can write the
/// SessionLog on completion without reaching into Today's cubit.
class SessionStartArgs {
  final PlannedSession? session;
  final int? planId;
  final int sessionIndex;
  // Story 22.5: non-null when deep-linking back into an already-running,
  // backgrounded session — resumes at the exact frozen step/second instead
  // of starting fresh.
  final int? resumeStepIndex;
  final int? resumeSecondsRemaining;
  final int? resumeElapsedSeconds;

  const SessionStartArgs({
    this.session,
    this.planId,
    this.sessionIndex = 0,
    this.resumeStepIndex,
    this.resumeSecondsRemaining,
    this.resumeElapsedSeconds,
  });
}
