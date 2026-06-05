import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeCubit', () {
    late SharedPreferences prefs;

    Future<void> createPrefs(Map<String, Object> initialValues) async {
      SharedPreferences.setMockInitialValues(initialValues);
      prefs = await SharedPreferences.getInstance();
    }

    test('14.1-CUBIT-001: empty prefs starts with ThemeMode.dark', () async {
      await createPrefs({});

      expect(ThemeCubit(prefs).state, ThemeMode.dark);
    });

    test('14.1-CUBIT-002: saved light starts with ThemeMode.light', () async {
      await createPrefs({'theme_mode': 'light'});

      expect(ThemeCubit(prefs).state, ThemeMode.light);
    });

    test('14.1-CUBIT-003: saved system starts with ThemeMode.system', () async {
      await createPrefs({'theme_mode': 'system'});

      expect(ThemeCubit(prefs).state, ThemeMode.system);
    });

    blocTest<ThemeCubit, ThemeMode>(
      '14.1-CUBIT-004: setTheme(light) emits and persists light',
      setUp: () => createPrefs({}),
      build: () => ThemeCubit(prefs),
      act: (cubit) => cubit.setTheme(ThemeMode.light),
      expect: () => [ThemeMode.light],
      verify: (_) => expect(prefs.getString('theme_mode'), 'light'),
    );

    blocTest<ThemeCubit, ThemeMode>(
      '14.1-CUBIT-005: setTheme(system) emits and persists system',
      setUp: () => createPrefs({}),
      build: () => ThemeCubit(prefs),
      act: (cubit) => cubit.setTheme(ThemeMode.system),
      expect: () => [ThemeMode.system],
      verify: (_) => expect(prefs.getString('theme_mode'), 'system'),
    );

    blocTest<ThemeCubit, ThemeMode>(
      '14.1-CUBIT-006: setTheme(dark) emits and persists dark',
      setUp: () => createPrefs({'theme_mode': 'light'}),
      build: () => ThemeCubit(prefs),
      act: (cubit) => cubit.setTheme(ThemeMode.dark),
      expect: () => [ThemeMode.dark],
      verify: (_) => expect(prefs.getString('theme_mode'), 'dark'),
    );
  });
}
