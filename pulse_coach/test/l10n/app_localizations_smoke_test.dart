import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

void main() {
  testWidgets('AppLocalizations resolves appTitle in Italian', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final title = AppLocalizations.of(context)!.appTitle;
            return Text(title);
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PulseCoach'), findsOneWidget);
  });
}
