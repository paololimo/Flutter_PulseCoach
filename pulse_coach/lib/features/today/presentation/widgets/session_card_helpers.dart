import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

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

String sessionDisplayName(String sessionType) {
  switch (sessionType) {
    case 'mobility':
      return 'Mobilità';
    case 'cardio':
      return 'Cardio';
    case 'breathing':
      return 'Respirazione';
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

String intensityLabel(int intensity) {
  if (intensity >= 1 && intensity <= 3) return 'Leggera';
  if (intensity >= 4 && intensity <= 7) return 'Moderata';
  if (intensity >= 8 && intensity <= 10) return 'Intensa';
  return 'Moderata';
}
