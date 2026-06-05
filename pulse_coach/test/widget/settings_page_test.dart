import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/pages/settings_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsPage', () {
    late SharedPreferences prefs;
    late ThemeCubit themeCubit;

    Future<void> pumpSettingsPage(
      WidgetTester tester, {
      Map<String, Object> initialValues = const {},
    }) async {
      SharedPreferences.setMockInitialValues(initialValues);
      prefs = await SharedPreferences.getInstance();
      themeCubit = ThemeCubit(prefs);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(value: themeCubit, child: const SettingsPage()),
        ),
      );
    }

    testWidgets(
      '14.1-WIDGET-001: renders 3 theme segment labels',
      (tester) async {
        await pumpSettingsPage(tester);

        expect(find.text('Scuro'), findsOneWidget);
        expect(find.text('Chiaro'), findsOneWidget);
        expect(find.text('Sistema'), findsOneWidget);
      },
    );

    testWidgets(
      '14.1-WIDGET-002: tapping Chiaro sets ThemeMode.light',
      (tester) async {
        await pumpSettingsPage(tester);

        await tester.tap(find.text('Chiaro'));
        await tester.pump();

        expect(themeCubit.state, ThemeMode.light);
        expect(prefs.getString('theme_mode'), 'light');
      },
    );

    testWidgets(
      '14.1-WIDGET-003: selected theme is reflected in SegmentedButton',
      (tester) async {
        await pumpSettingsPage(tester, initialValues: {'theme_mode': 'system'});

        final segmentedButton = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        );
        expect(segmentedButton.selected, {ThemeMode.system});
      },
    );
  });
}
