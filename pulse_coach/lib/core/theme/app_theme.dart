import 'package:flutter/material.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';

abstract class AppTheme {
  static const _bodyFontFamily = 'Plus Jakarta Sans';

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF7DD3C0),
          brightness: Brightness.dark,
        ).copyWith(
          surface: PulseCoachTheme.dark.surface,
          surfaceContainerLow: PulseCoachTheme.dark.surface,
          surfaceContainer: PulseCoachTheme.dark.surfaceContainer,
          surfaceContainerHigh: PulseCoachTheme.dark.surfaceContainerHigh,
          primary: PulseCoachTheme.dark.primaryColor,
          secondary: PulseCoachTheme.dark.secondary,
          tertiary: PulseCoachTheme.dark.tertiary,
          onSurface: PulseCoachTheme.dark.onSurface,
          onSurfaceVariant: PulseCoachTheme.dark.onSurfaceVariant,
          error: PulseCoachTheme.dark.error,
        ),
    textTheme: ThemeData(
      brightness: Brightness.dark,
    ).textTheme.apply(fontFamily: _bodyFontFamily),
    extensions: const [PulseCoachTheme.dark],
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      elevation: 0,
    ),
  );

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7DD3C0))
        .copyWith(
          surface: PulseCoachTheme.light.surface,
          surfaceContainerLow: PulseCoachTheme.light.surface,
          surfaceContainer: PulseCoachTheme.light.surfaceContainer,
          surfaceContainerHigh: PulseCoachTheme.light.surfaceContainerHigh,
          primary: PulseCoachTheme.light.primaryColor,
          secondary: PulseCoachTheme.light.secondary,
          tertiary: PulseCoachTheme.light.tertiary,
          onSurface: PulseCoachTheme.light.onSurface,
          onSurfaceVariant: PulseCoachTheme.light.onSurfaceVariant,
          error: PulseCoachTheme.light.error,
        ),
    textTheme: ThemeData().textTheme.apply(fontFamily: _bodyFontFamily),
    extensions: const [PulseCoachTheme.light],
    cardTheme: const CardThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      elevation: 0,
    ),
  );
}
