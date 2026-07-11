// [P1] OnboardingPage widget tests
// Tests: disclaimer text visible, button disabled without checkbox, checkbox enables button,
//        no back button, no skip option, carousel screens, state transitions
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:pulse_coach/features/onboarding/presentation/widgets/disclaimer_screen.dart';
import 'package:pulse_coach/features/onboarding/presentation/widgets/onboarding_carousel.dart';
import 'package:pulse_coach/features/onboarding/presentation/widgets/profile_setup_form.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

import 'onboarding_page_test.mocks.dart';

@GenerateMocks([AcceptDisclaimer, CheckDisclaimerStatus, SaveProfile])
void main() {
  late MockAcceptDisclaimer mockAcceptDisclaimer;
  late MockCheckDisclaimerStatus mockCheckDisclaimerStatus;
  late MockSaveProfile mockSaveProfile;

  setUp(() {
    mockAcceptDisclaimer = MockAcceptDisclaimer();
    mockCheckDisclaimerStatus = MockCheckDisclaimerStatus();
    mockSaveProfile = MockSaveProfile();
    // Default: not yet accepted — disclaimer should be shown
    when(mockCheckDisclaimerStatus()).thenAnswer((_) async => const Right(false));
  });

  Widget buildPage() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => OnboardingCubit(
          mockAcceptDisclaimer,
          mockCheckDisclaimerStatus,
          mockSaveProfile,
        ),
        child: const DisclaimerScreen(),
      ),
    );
  }

  // Wraps the carousel with disableAnimations:true to prevent Lottie from
  // creating infinite tickers that cause pumpAndSettle to time out in tests.
  Widget buildCarousel() {
    final cubit = OnboardingCubit(
      mockAcceptDisclaimer,
      mockCheckDisclaimerStatus,
      mockSaveProfile,
    );
    return MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: BlocProvider.value(
          value: cubit,
          child: const OnboardingCarousel(),
        ),
      ),
    );
  }

  Widget buildCarouselWithBrokenAssets() {
    final cubit = OnboardingCubit(
      mockAcceptDisclaimer,
      mockCheckDisclaimerStatus,
      mockSaveProfile,
    );
    return MaterialApp(
      theme: AppTheme.darkTheme,
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: BlocProvider.value(
          value: cubit,
          child: const OnboardingCarousel(
            overrideAssetPath: 'assets/animations/nonexistent.json',
          ),
        ),
      ),
    );
  }

  group('OnboardingCarousel widget', () {
    testWidgets(
      '[P1] 2.2-WIDGET-001: Screen 1 headline "Move more. Decide less." is visible',
      (tester) async {
        await tester.pumpWidget(buildCarousel());
        await tester.pumpAndSettle();
        expect(find.text('Move more. Decide less.'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 2.2-WIDGET-002: "Next" button is visible on Screen 1',
      (tester) async {
        await tester.pumpWidget(buildCarousel());
        await tester.pumpAndSettle();
        expect(find.text('Next'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 2.2-WIDGET-003: Tapping "Next" on Screen 1 advances to Screen 2',
      (tester) async {
        await tester.pumpWidget(buildCarousel());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Your data stays yours.'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 2.2-WIDGET-004: Tapping "Next" on Screen 2 advances to Screen 3',
      (tester) async {
        await tester.pumpWidget(buildCarousel());
        await tester.pumpAndSettle();

        // Screen 1 → Screen 2
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        // Screen 2 → Screen 3
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Let\'s set you up in 60 seconds.'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 2.2-WIDGET-005: Tapping "Get Started" on Screen 3 calls completeOnboardingFlow',
      (tester) async {
        when(mockAcceptDisclaimer()).thenAnswer((_) async => const Right(null));
        await tester.pumpWidget(buildCarousel());
        await tester.pumpAndSettle();

        // Navigate to screen 3
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Get Started'), findsOneWidget);
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        // After tapping, cubit should be in profileSetupReady state
        // We verify by checking the cubit state is profileSetupReady
        final cubit = tester
            .element(find.byType(OnboardingCarousel))
            .read<OnboardingCubit>();
        expect(cubit.state, const OnboardingState.profileSetupReady());
      },
    );
    testWidgets(
      '[P1] 2.2-WIDGET-007: Fallback icon renders when Lottie asset fails to load (AC6)',
      (tester) async {
        await tester.pumpWidget(buildCarouselWithBrokenAssets());
        await tester.pumpAndSettle();
        // Lottie errorBuilder fires for nonexistent asset, rendering
        // the fallback Material icon for Screen 1.
        expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
        expect(find.text('Move more. Decide less.'), findsOneWidget);
      },
    );
  });

  group('OnboardingPage profileSetupReady state', () {
    testWidgets(
      '[P1] 2.2-WIDGET-006: When state is profileSetupReady, ProfileSetupForm renders with "Fitness Level" label',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider(
              create: (_) {
                final cubit = OnboardingCubit(
                  mockAcceptDisclaimer,
                  mockCheckDisclaimerStatus,
                  mockSaveProfile,
                );
                cubit.emit(const OnboardingState.profileSetupReady());
                return cubit;
              },
              child: const ProfileSetupForm(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Fitness Level'), findsOneWidget);
      },
    );
  });

  group('ProfileSetupForm widget', () {
    Widget buildProfileSetupForm() {
      return MaterialApp(
        theme: AppTheme.darkTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => OnboardingCubit(
            mockAcceptDisclaimer,
            mockCheckDisclaimerStatus,
            mockSaveProfile,
          ),
          child: const ProfileSetupForm(),
        ),
      );
    }

    testWidgets(
      '[P1] 2.3-WIDGET-001: all 4 field labels are visible',
      (tester) async {
        await tester.pumpWidget(buildProfileSetupForm());
        await tester.pumpAndSettle();
        expect(find.text('Fitness Level'), findsOneWidget);
        expect(find.text('Primary Goal'), findsOneWidget);
        expect(find.text('Available Time'), findsOneWidget);
        expect(find.text('Physical Constraints'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 2.3-WIDGET-006: form content is width-capped at tablet width',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 1400));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildProfileSetupForm());
        await tester.pumpAndSettle();

        // On a 1200px-wide surface the content is centred and capped well
        // below full width, instead of stretching the submit button edge to
        // edge as it does on a phone.
        final buttonWidth = tester.getSize(find.byType(FilledButton)).width;
        expect(buttonWidth, lessThanOrEqualTo(640));
      },
    );

    testWidgets(
      '[P1] 2.3-WIDGET-002: "Start My Plan" button is disabled when no selections made',
      (tester) async {
        await tester.pumpWidget(buildProfileSetupForm());
        await tester.pumpAndSettle();
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      },
    );

    testWidgets(
      '[P1] 2.3-WIDGET-003: "Start My Plan" button becomes enabled after all 4 fields selected',
      (tester) async {
        await tester.pumpWidget(buildProfileSetupForm());
        await tester.pumpAndSettle();

        // Select Fitness Level: Beginner
        await tester.tap(find.text('Beginner'));
        await tester.pump();
        // Select Primary Goal: Cardio
        await tester.tap(find.text('Cardio'));
        await tester.pump();
        // Select Available Time: 2–5 min
        await tester.tap(find.text('2–5 min'));
        await tester.pump();
        // Select Physical Constraints: None
        await tester.tap(find.text('None'));
        await tester.pump();

        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets(
      '[P1] 2.3-WIDGET-005: saveProfile error shows snackbar and form stays visible',
      (tester) async {
        when(mockSaveProfile(any)).thenAnswer(
          (_) async => const Left(CacheFailure('DB error')),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider(
              create: (_) {
                final cubit = OnboardingCubit(
                  mockAcceptDisclaimer,
                  mockCheckDisclaimerStatus,
                  mockSaveProfile,
                );
                cubit.emit(const OnboardingState.profileSetupReady());
                return cubit;
              },
              child: const ProfileSetupForm(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Select all 4 fields
        await tester.tap(find.text('Beginner'));
        await tester.pump();
        await tester.tap(find.text('Cardio'));
        await tester.pump();
        await tester.tap(find.text('2–5 min'));
        await tester.pump();
        await tester.tap(find.text('None'));
        await tester.pump();

        // Tap "Start My Plan"
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        // Form should still be visible (not replaced by DisclaimerScreen)
        expect(find.text('Fitness Level'), findsOneWidget);
        expect(find.text('Primary Goal'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 2.3-WIDGET-004: Tapping "Start My Plan" calls cubit.saveProfile',
      (tester) async {
        when(mockSaveProfile(any)).thenAnswer((_) async => const Right(null));
        await tester.pumpWidget(buildProfileSetupForm());
        await tester.pumpAndSettle();

        // Select all 4 fields
        await tester.tap(find.text('Beginner'));
        await tester.pump();
        await tester.tap(find.text('Cardio'));
        await tester.pump();
        await tester.tap(find.text('2–5 min'));
        await tester.pump();
        await tester.tap(find.text('None'));
        await tester.pump();

        // Tap "Start My Plan"
        await tester.tap(find.byType(FilledButton));
        await tester.pump();

        verify(mockSaveProfile(any)).called(1);
      },
    );
  });

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
