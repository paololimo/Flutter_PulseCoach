// [17.3-WIDGET-001..005] ProUpsellSheet widget tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/features/subscription/data/services/upsell_cooldown_service.dart';
import 'package:pulse_coach/features/subscription/presentation/widgets/pro_upsell_sheet.dart';

import 'pro_upsell_sheet_test.mocks.dart';

@GenerateMocks([UpsellCooldownService])
void main() {
  group('ProUpsellSheet', () {
    late MockUpsellCooldownService mockCooldown;

    setUp(() {
      mockCooldown = MockUpsellCooldownService();
    });

    // Router-aware scaffold: needed by tests that tap "Scopri Pro",
    // which triggers context.push(AppRouter.paywall).
    Future<void> pumpScaffoldWithRouter(WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, _) => Scaffold(
              body: TextButton(
                onPressed: () => ProUpsellSheet.show(
                  ctx,
                  cooldownOverride: mockCooldown,
                ),
                child: const Text('open'),
              ),
            ),
          ),
          GoRoute(
            path: '/paywall',
            builder: (ctx, _) => const Scaffold(body: Text('paywall')),
          ),
        ],
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    Future<void> pumpScaffold(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => ProUpsellSheet.show(
                ctx,
                cooldownOverride: mockCooldown,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
    }

    testWidgets(
      '17.3-WIDGET-001: show() displays sheet when isCoolingDown() returns false',
      (tester) async {
        when(mockCooldown.isCoolingDown()).thenReturn(false);
        await pumpScaffold(tester);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Scopri Pro'), findsOneWidget);
        expect(find.text('non ora'), findsOneWidget);
      },
    );

    testWidgets(
      '17.3-WIDGET-002: show() returns early without sheet when isCoolingDown() returns true',
      (tester) async {
        when(mockCooldown.isCoolingDown()).thenReturn(true);
        await pumpScaffold(tester);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Scopri Pro'), findsNothing);
        expect(find.text('non ora'), findsNothing);
      },
    );

    testWidgets(
      '17.3-WIDGET-003: tapping non ora calls recordDismissal() and dismisses sheet',
      (tester) async {
        when(mockCooldown.isCoolingDown()).thenReturn(false);
        await pumpScaffold(tester);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('non ora'));
        await tester.pumpAndSettle();

        verify(mockCooldown.recordDismissal()).called(1);
        expect(find.text('Scopri Pro'), findsNothing);
      },
    );

    testWidgets(
      '17.3-WIDGET-004: tapping Scopri Pro dismisses without recording cooldown',
      (tester) async {
        when(mockCooldown.isCoolingDown()).thenReturn(false);
        // Use router-aware scaffold: Scopri Pro now calls context.push(/paywall).
        await pumpScaffoldWithRouter(tester);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Scopri Pro'));
        await tester.pumpAndSettle();

        verifyNever(mockCooldown.recordDismissal());
        expect(find.text('Scopri Pro'), findsNothing);
      },
    );

    testWidgets(
      '17.3-WIDGET-005: dismissing via the barrier records the cooldown',
      (tester) async {
        when(mockCooldown.isCoolingDown()).thenReturn(false);
        await pumpScaffold(tester);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Tap the scrim above the sheet to dismiss without using a button.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        verify(mockCooldown.recordDismissal()).called(1);
        expect(find.text('Scopri Pro'), findsNothing);
      },
    );
  });
}
