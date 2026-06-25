import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user-selected app locale and persists it across launches.
///
/// Mirrors ThemeCubit: emit-first for instant UI, persist in the background.
/// Supported locales are Italian (default) and English.
@lazySingleton
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this._prefs) : super(_loadSavedLocale(_prefs));

  static const _localeKey = 'app_locale';
  static const supported = [Locale('it'), Locale('en')];

  final SharedPreferences _prefs;

  static Locale _loadSavedLocale(SharedPreferences prefs) {
    return switch (prefs.getString(_localeKey)) {
      'en' => const Locale('en'),
      'it' => const Locale('it'),
      _ => const Locale('it'), // null / unknown → default to Italian
    };
  }

  void setLocale(Locale locale) {
    emit(locale);
    unawaited(_prefs.setString(_localeKey, locale.languageCode));
  }
}
