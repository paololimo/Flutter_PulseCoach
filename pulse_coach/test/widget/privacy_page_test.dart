import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/settings/presentation/pages/privacy_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

void main() {
  group('PrivacyPage', () {
    Future<void> pumpPrivacyPage(WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrivacyPage(),
        ),
      );
    }

    testWidgets('14.2-WIDGET-001: renders the on-device data section heading', (
      tester,
    ) async {
      await pumpPrivacyPage(tester);

      expect(find.text('Dati solo sul dispositivo'), findsOneWidget);
    });

    testWidgets('14.2-WIDGET-002: renders the Health API section heading', (
      tester,
    ) async {
      await pumpPrivacyPage(tester);

      expect(find.text('API Salute'), findsOneWidget);
    });

    testWidgets('14.2-WIDGET-003: renders the location section heading', (
      tester,
    ) async {
      await pumpPrivacyPage(tester);

      expect(find.text('Posizione'), findsOneWidget);
    });

    testWidgets(
      '14.2-WIDGET-004: renders the GDPR compliance section heading',
      (tester) async {
        await pumpPrivacyPage(tester);

        expect(find.text('Conformità GDPR'), findsOneWidget);
      },
    );

    testWidgets(
      '14.2-WIDGET-005: AppBar title matches privacyPageTitle l10n key',
      (tester) async {
        await pumpPrivacyPage(tester);

        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.text('Privacy'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('14.2-WIDGET-006: renders each section body text', (
      tester,
    ) async {
      await pumpPrivacyPage(tester);

      expect(
        find.text(
          'Tutti i dati personali e di allenamento sono conservati '
          'esclusivamente sul tuo dispositivo. PulseCoach non trasmette dati '
          'a server esterni per la personalizzazione.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'PulseCoach può leggere la frequenza cardiaca e il conteggio dei '
          'passi dalle API Salute del dispositivo (HealthKit / Health '
          'Connect), se il permesso è concesso. Questi dati non lasciano mai '
          'il dispositivo.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'PulseCoach usa solo la posizione a livello di città (coordinate '
          'approssimate) per ottenere informazioni meteo. Non vengono '
          'memorizzate o trasmesse coordinate GPS precise.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'I dati biometrici sono classificati come dati sensibili ai sensi '
          "dell'Art. 9 del GDPR. PulseCoach li elabora localmente con il tuo "
          'esplicito consenso e non li condivide con terze parti.',
        ),
        findsOneWidget,
      );
    });
  });
}
