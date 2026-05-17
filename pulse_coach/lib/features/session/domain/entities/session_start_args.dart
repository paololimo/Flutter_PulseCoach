import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

/// Navigation contract for the /session/active route.
///
/// Carries session data plus persistence context so InSessionPage can write the
/// SessionLog on completion without reaching into Today's cubit.
class SessionStartArgs {
  final PlannedSession? session;
  final int? planId;
  final int sessionIndex;

  const SessionStartArgs({this.session, this.planId, this.sessionIndex = 0});
}
