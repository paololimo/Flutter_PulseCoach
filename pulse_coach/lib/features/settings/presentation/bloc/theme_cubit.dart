import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._prefs) : super(_loadSavedTheme(_prefs));

  static const _themeModeKey = 'theme_mode';

  final SharedPreferences _prefs;

  static ThemeMode _loadSavedTheme(SharedPreferences prefs) {
    return switch (prefs.getString(_themeModeKey)) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.dark, // null / unknown → default to dark
    };
  }

  void setTheme(ThemeMode mode) {
    // Emit first for instant UI; persist in the background (in-memory cache
    // updates synchronously, so init read-back is unaffected by the async flush).
    emit(mode);
    unawaited(_prefs.setString(_themeModeKey, mode.name));
  }
}
