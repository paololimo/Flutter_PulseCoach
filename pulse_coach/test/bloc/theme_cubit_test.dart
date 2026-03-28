import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';

void main() {
  group('ThemeCubit', () {
    test('initial state is ThemeMode.dark', () {
      expect(ThemeCubit().state, ThemeMode.dark);
    });

    blocTest<ThemeCubit, ThemeMode>(
      'toggleTheme emits light when dark',
      build: () => ThemeCubit(),
      act: (c) => c.toggleTheme(),
      expect: () => [ThemeMode.light],
    );

    blocTest<ThemeCubit, ThemeMode>(
      'toggleTheme emits dark when light',
      build: () => ThemeCubit()..toggleTheme(),
      act: (c) => c.toggleTheme(),
      expect: () => [ThemeMode.dark],
    );
  });
}
