import 'package:flutter/material.dart';

class PulseCoachTheme extends ThemeExtension<PulseCoachTheme> {
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color primaryColor;
  final Color secondary;
  final Color tertiary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color error;

  const PulseCoachTheme({
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.primaryColor,
    required this.secondary,
    required this.tertiary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.error,
  });

  static const dark = PulseCoachTheme(
    surface: Color(0xFF0F1119),
    surfaceContainer: Color(0xFF171B26),
    surfaceContainerHigh: Color(0xFF1E2333),
    primaryColor: Color(0xFF7DD3C0),
    secondary: Color(0xFFA78BDA),
    tertiary: Color(0xFFE8C87A),
    onSurface: Color(0xFFE2E4EA),
    onSurfaceVariant: Color(0xFF9498A6),
    error: Color(0xFFF28B82),
  );

  static const light = PulseCoachTheme(
    surface: Color(0xFFF8FFFE),
    surfaceContainer: Color(0xFFEEF6F4),
    surfaceContainerHigh: Color(0xFFE1F0ED),
    primaryColor: Color(0xFF7DD3C0),
    secondary: Color(0xFFA78BDA),
    tertiary: Color(0xFFE8C87A),
    onSurface: Color(0xFF1A1C1E),
    onSurfaceVariant: Color(0xFF42474E),
    error: Color(0xFFBA1A1A),
  );

  @override
  PulseCoachTheme copyWith({
    Color? surface,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? primaryColor,
    Color? secondary,
    Color? tertiary,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? error,
  }) {
    return PulseCoachTheme(
      surface: surface ?? this.surface,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
      primaryColor: primaryColor ?? this.primaryColor,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      error: error ?? this.error,
    );
  }

  @override
  PulseCoachTheme lerp(PulseCoachTheme? other, double t) {
    if (other == null) return this;
    return PulseCoachTheme(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainer: Color.lerp(surfaceContainer, other.surfaceContainer, t)!,
      surfaceContainerHigh:
          Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
