import 'package:flutter/material.dart';
import 'package:pulse_coach/ai/explainability/explanation_key.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Color sessionAccentColor(String sessionType, PulseCoachTheme theme) {
  switch (sessionType) {
    case 'cardio':
      return const Color(0xFFF0A1B0);
    case 'mobility':
      return theme.primaryColor;
    case 'breathing':
      return theme.secondary;
    default:
      return theme.onSurfaceVariant;
  }
}

String sessionDisplayName(String sessionType, AppLocalizations l10n) {
  switch (sessionType) {
    case 'mobility':
      return l10n.sessionNameMobility;
    case 'cardio':
      return l10n.sessionNameCardio;
    case 'breathing':
      return l10n.sessionNameBreathing;
    default:
      return sessionType;
  }
}

IconData sessionIcon(String sessionType) {
  switch (sessionType) {
    case 'mobility':
      return Icons.self_improvement;
    case 'cardio':
      return Icons.favorite_border;
    case 'breathing':
      return Icons.air;
    default:
      return Icons.fitness_center;
  }
}

String intensityLabel(int intensity, AppLocalizations l10n) {
  if (intensity >= 1 && intensity <= 3) return l10n.intensityLow;
  if (intensity >= 4 && intensity <= 7) return l10n.intensityMedium;
  if (intensity >= 8 && intensity <= 10) return l10n.intensityHigh;
  return l10n.intensityMedium;
}

/// Resolves a stored `PlannedSession.explanation` value to localized text.
///
/// The AI isolate now stores a locale-independent [ExplanationKey] name
/// (E7.5-T1). If [stored] is a known key, it is resolved via [l10n];
/// otherwise the raw string is returned unchanged so legacy plans (which
/// stored a baked Italian string) still render.
String explanationText(String stored, AppLocalizations l10n) {
  switch (ExplanationKey.tryParse(stored)) {
    case ExplanationKey.recovering:
      return l10n.explRecovering;
    case ExplanationKey.atRiskMissed:
      return l10n.explAtRiskMissed;
    case ExplanationKey.atRiskHighLoad:
      return l10n.explAtRiskHighLoad;
    case ExplanationKey.fatigued:
      return l10n.explFatigued;
    case ExplanationKey.elevatedRestingHr:
      return l10n.explElevatedRestingHr;
    case ExplanationKey.lowSteps:
      return l10n.explLowSteps;
    case ExplanationKey.optimalRestingHr:
      return l10n.explOptimalRestingHr;
    case ExplanationKey.consistentWeek:
      return l10n.explConsistentWeek;
    case ExplanationKey.intenseEffort:
      return l10n.explIntenseEffort;
    case ExplanationKey.comfortZone:
      return l10n.explComfortZone;
    case ExplanationKey.greatStreak:
      return l10n.explGreatStreak;
    case ExplanationKey.welcomeBack:
      return l10n.explWelcomeBack;
    case ExplanationKey.breathingFallback:
      return l10n.explBreathingFallback;
    case ExplanationKey.mobilityFallback:
      return l10n.explMobilityFallback;
    case ExplanationKey.genericFallback:
      return l10n.explGenericFallback;
    case null:
      return stored;
  }
}
