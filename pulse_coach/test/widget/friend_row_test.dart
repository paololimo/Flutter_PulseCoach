// [18.2-WIDGET-001..005] FriendRow widget tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/social/friends/presentation/widgets/friend_row.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );

void main() {
  group('FriendRow', () {
    testWidgets(
      '18.2-WIDGET-001: searchResult variant — renders @handle + "Aggiungi amico" button',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const FriendRow(
              displayHandle: 'paolotest',
              variant: FriendRowVariant.searchResult,
            ),
          ),
        );

        expect(find.text('@paolotest'), findsOneWidget);
        expect(find.text('Aggiungi amico'), findsOneWidget);
      },
    );

    testWidgets(
      '18.2-WIDGET-002: searchResult variant (requestSent=true) — shows "Richiesta inviata"',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const FriendRow(
              displayHandle: 'paolotest',
              variant: FriendRowVariant.searchResult,
              requestSent: true,
            ),
          ),
        );

        expect(find.text('Richiesta inviata'), findsOneWidget);
        expect(find.text('Aggiungi amico'), findsNothing);
      },
    );

    testWidgets(
      '18.2-WIDGET-003: receivedRequest variant — renders "Accetta" + "Rifiuta"',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const FriendRow(
              displayHandle: 'someuser',
              variant: FriendRowVariant.receivedRequest,
            ),
          ),
        );

        expect(find.text('Accetta'), findsOneWidget);
        expect(find.text('Rifiuta'), findsOneWidget);
      },
    );

    testWidgets(
      '18.2-WIDGET-004: receivedRequest "Accetta" tap dispatches onPrimaryAction',
      (tester) async {
        var called = false;
        await tester.pumpWidget(
          _wrap(
            FriendRow(
              displayHandle: 'someuser',
              variant: FriendRowVariant.receivedRequest,
              onPrimaryAction: () => called = true,
            ),
          ),
        );

        await tester.tap(find.text('Accetta'));
        await tester.pump();

        expect(called, isTrue);
      },
    );

    testWidgets(
      '18.2-WIDGET-005: friend variant — renders "Rimuovi" button',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const FriendRow(
              displayHandle: 'myfriend',
              variant: FriendRowVariant.friend,
            ),
          ),
        );

        expect(find.text('@myfriend'), findsOneWidget);
        expect(find.text('Rimuovi'), findsOneWidget);
      },
    );
  });
}
