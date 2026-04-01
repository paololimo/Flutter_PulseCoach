// [P1] OnboardingPage widget tests
// Tests: disclaimer text visible, button disabled without checkbox, checkbox enables button,
//        no back button, no skip option
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/widgets/disclaimer_screen.dart';

import 'onboarding_page_test.mocks.dart';

@GenerateMocks([AcceptDisclaimer, CheckDisclaimerStatus])
void main() {
  late MockAcceptDisclaimer mockAcceptDisclaimer;
  late MockCheckDisclaimerStatus mockCheckDisclaimerStatus;

  setUp(() {
    mockAcceptDisclaimer = MockAcceptDisclaimer();
    mockCheckDisclaimerStatus = MockCheckDisclaimerStatus();
    // Default: not yet accepted — disclaimer should be shown
    when(mockCheckDisclaimerStatus()).thenAnswer((_) async => const Right(false));
  });

  Widget buildPage() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: BlocProvider(
        create: (_) =>
            OnboardingCubit(mockAcceptDisclaimer, mockCheckDisclaimerStatus),
        child: const DisclaimerScreen(),
      ),
    );
  }

  group('DisclaimerScreen widget', () {
    testWidgets(
      '[P1] 2.1-WIDGET-001: disclaimer text is visible',
      (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();
        expect(find.text('Your data stays yours.'), findsOneWidget);
        expect(
          find.textContaining('not a medical device'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      '[P1] 2.1-WIDGET-002: Continue button is disabled when checkbox is unchecked',
      (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      '[P1] 2.1-WIDGET-003: checking checkbox enables Continue button',
      (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Checkbox is unchecked initially — button disabled
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );

        // Tap checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Button should now be enabled
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
      },
    );

    testWidgets(
      '[P1] 2.1-WIDGET-004: tapping Continue triggers cubit acceptDisclaimer',
      (tester) async {
        when(mockAcceptDisclaimer()).thenAnswer(
          (_) async => const Right(null),
        );
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Check the checkbox
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Tap Continue
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        verify(mockAcceptDisclaimer()).called(1);
      },
    );

    testWidgets(
      '[P1] 2.1-WIDGET-005: no back button and no skip option',
      (tester) async {
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // No AppBar (no leading back button)
        expect(find.byType(AppBar), findsNothing);
        // No skip/close
        expect(find.text('Skip'), findsNothing);
        expect(find.text('Close'), findsNothing);
        expect(find.text('Dismiss'), findsNothing);
        // PopScope(canPop: false) is present
        expect(find.byType(PopScope), findsOneWidget);
      },
    );
  });
}
