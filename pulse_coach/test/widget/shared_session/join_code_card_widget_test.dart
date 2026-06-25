// [20.1-WIDGET-001..003] JoinCodeCard widget tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/widgets/join_code_card.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget buildJoinCodeCard({
  String joinCode = 'ABC123',
  VoidCallback? onRefresh,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('it'),
    home: Scaffold(
      body: JoinCodeCard(
        joinCode: joinCode,
        onRefresh: onRefresh ?? () {},
      ),
    ),
  );
}

void main() {
  group('JoinCodeCard Widget (20.1)', () {
    testWidgets(
      '20.1-WIDGET-001: renders join code text and QR (AC2)',
      (tester) async {
        await tester.pumpWidget(buildJoinCodeCard());
        await tester.pump();
        expect(find.text('ABC123'), findsOneWidget);
        expect(find.byType(QrImageView), findsOneWidget);
        expect(find.text('Aggiorna codice'), findsOneWidget);
      },
    );

    testWidgets(
      '20.1-WIDGET-002: "Aggiorna codice" button calls onRefresh (AC3)',
      (tester) async {
        var refreshCalled = false;
        await tester.pumpWidget(
          buildJoinCodeCard(onRefresh: () => refreshCalled = true),
        );
        await tester.pump();
        await tester.tap(find.text('Aggiorna codice'));
        await tester.pump();
        expect(refreshCalled, isTrue);
      },
    );

    testWidgets(
      '20.1-WIDGET-003: 360×640 viewport renders without overflow (E18R-1)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildJoinCodeCard());
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
