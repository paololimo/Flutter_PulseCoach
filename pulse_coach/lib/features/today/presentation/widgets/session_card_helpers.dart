import 'package:flutter/material.dart';
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
