import 'dart:math' show max;

import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

abstract class SessionStepGenerator {
  /// Returns a 3-step list: warm-up (20%), main phase (60%), cool-down (20%).
  /// Each phase is at least 60 seconds. Remainder goes to the main phase.
  static List<ExerciseStep> generate(
    PlannedSession? session,
    AppLocalizations l10n,
  ) {
    final totalSeconds = (session?.durationMinutes ?? 5) * 60;
    const phaseMin = 60;
    final warmup = max(phaseMin, totalSeconds ~/ 5);
    final cooldown = max(phaseMin, totalSeconds ~/ 5);
    final main = max(phaseMin, totalSeconds - warmup - cooldown);

    final sessionType = session?.sessionType ?? 'mobility';
    final mainTitle = _mainTitle(sessionType, l10n);
    final mainInstruction = _mainInstruction(sessionType, l10n);

    return [
      ExerciseStep(
        title: l10n.inSessionWarmupTitle,
        instruction: l10n.inSessionWarmupInstruction,
        durationSeconds: warmup,
      ),
      ExerciseStep(
        title: mainTitle,
        instruction: mainInstruction,
        durationSeconds: main,
      ),
      ExerciseStep(
        title: l10n.inSessionCooldownTitle,
        instruction: l10n.inSessionCooldownInstruction,
        durationSeconds: cooldown,
      ),
    ];
  }

  static String _mainTitle(String sessionType, AppLocalizations l10n) =>
      switch (sessionType) {
        'cardio' => l10n.sessionNameCardio,
        'breathing' => l10n.sessionNameBreathing,
        _ => l10n.sessionNameMobility,
      };

  static String _mainInstruction(String sessionType, AppLocalizations l10n) =>
      switch (sessionType) {
        'cardio' => l10n.inSessionMainCardioInstruction,
        'breathing' => l10n.inSessionMainBreathingInstruction,
        _ => l10n.inSessionMainMobilityInstruction,
      };
}
