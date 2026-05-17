// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PulseCoach';

  @override
  String get stateLabelActive => 'Ready';

  @override
  String get stateLabelFatigued => 'Under load';

  @override
  String get stateLabelAtRisk => 'At risk';

  @override
  String get stateLabelRecovering => 'Recovering';

  @override
  String get staticCopyActive => 'Ready for today\'s plan.';

  @override
  String get staticCopyFatigued => 'Today we lighten the load to recover.';

  @override
  String get staticCopyAtRisk => 'Let\'s restart gently. Short, easy sessions.';

  @override
  String get staticCopyRecovering =>
      'Let\'s build the rhythm, one step at a time.';

  @override
  String get transitionActiveAtRisk =>
      'We missed you. Let\'s restart light - 5 minutes is enough today.';

  @override
  String get transitionActiveFatigued =>
      'You pushed hard. Today we lighten up: short session.';

  @override
  String get transitionFatiguedAtRisk =>
      'Your body is asking for a longer pause. Let\'s resume gently.';

  @override
  String get transitionRecoveringFatigued =>
      'We are getting back, but the last effort was intense. Let\'s return to an easy session.';

  @override
  String get transitionAtRiskRecovering =>
      'You are getting back into rhythm. Let\'s keep it calm.';

  @override
  String get transitionFatiguedRecovering =>
      'You are getting back into rhythm. Let\'s keep it calm.';

  @override
  String get transitionRecoveringActive =>
      'You are back in shape! Let\'s resume the full plan.';

  @override
  String get comingUpHeader => 'COMING UP';

  @override
  String get errorLoadingPlan => 'Unable to load the plan.';

  @override
  String get allDoneTitle => 'Great work!';

  @override
  String get allDoneBody => 'All sessions are complete for today.';

  @override
  String heroCardSemanticPreamble(String displayName, String durationLabel) {
    return 'Next session: $displayName, $durationLabel';
  }

  @override
  String get heroCardSemanticCta => 'Tap to start.';

  @override
  String get regenSemanticLabel => 'Regenerate workout plan';

  @override
  String get regenTooltip => 'Regenerate';

  @override
  String get startSessionButton => 'Start session';

  @override
  String completedCardSemanticLabel(String displayName, String durationLabel) {
    return 'Completed: $displayName, $durationLabel.';
  }

  @override
  String compactCardSemanticLabel(String displayName, String durationLabel) {
    return 'Next session: $displayName, $durationLabel. Tap to select as the next session.';
  }

  @override
  String completionRingSemanticLabel(String completed, String total) {
    return 'Daily progress: $completed of $total sessions completed';
  }

  @override
  String get sessionNameMobility => 'Mobility';

  @override
  String get sessionNameCardio => 'Cardio';

  @override
  String get sessionNameBreathing => 'Breathing';

  @override
  String get intensityLow => 'Light';

  @override
  String get intensityMedium => 'Moderate';

  @override
  String get intensityHigh => 'Intense';

  @override
  String countdownSemanticAnnounce(String count) {
    return 'Starting in $count';
  }

  @override
  String get countdownGoAnnounce => 'Go';

  @override
  String get inSessionWarmupTitle => 'Warm-up';

  @override
  String get inSessionCooldownTitle => 'Cool-down';

  @override
  String get inSessionWarmupInstruction => 'Move slowly to prepare your body.';

  @override
  String get inSessionCooldownInstruction =>
      'Slow down gradually. Breathe deeply.';

  @override
  String get inSessionMainMobilityInstruction =>
      'Perform movements smoothly and in control.';

  @override
  String get inSessionMainCardioInstruction =>
      'Keep the pace with steady breathing.';

  @override
  String get inSessionMainBreathingInstruction =>
      'Focus on deep, rhythmic breathing.';

  @override
  String get inSessionAbandonButton => 'Abandon';

  @override
  String inSessionStepLabel(String current, String total) {
    return '$current of $total';
  }
}
