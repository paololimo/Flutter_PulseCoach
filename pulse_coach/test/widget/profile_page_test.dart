// [P1] ProfilePage widget tests
// Tests: loading state, 4 field labels visible, pre-selected segment, segment tap, error snackbar
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/get_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/update_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/profile_page.dart';

import 'profile_page_test.mocks.dart';

@GenerateMocks([GetProfile, UpdateProfile])
void main() {
  late MockGetProfile mockGetProfile;
  late MockUpdateProfile mockUpdateProfile;

  const tProfile = UserProfile(
    fitnessLevel: 'low',
    goal: 'cardio',
    availableTime: 'short',
    physicalConstraints: 'none',
  );

  setUp(() {
    mockGetProfile = MockGetProfile();
    mockUpdateProfile = MockUpdateProfile();
    getIt.registerFactory<ProfileCubit>(
      () => ProfileCubit(mockGetProfile, mockUpdateProfile),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildPage() {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: const ProfilePage(),
    );
  }

  group('ProfilePage widget', () {
    testWidgets(
      '[P1] 2.4-WIDGET-001: loading indicator shown while ProfileState.loading',
      (tester) async {
        // Use a Completer that never completes — avoids pending timer issues
        final completer = Completer<Either<Failure, UserProfile>>();
        when(mockGetProfile()).thenAnswer((_) => completer.future);
        await tester.pumpWidget(buildPage());
        await tester.pump(); // triggers initState postFrameCallback
        await tester.pump(); // loadProfile() → emits loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        // Complete to clean up pending future
        completer.complete(const Right(tProfile));
      },
    );

    testWidgets(
      '[P1] 2.4-WIDGET-002: all 4 field labels visible after ProfileLoaded',
      (tester) async {
        when(mockGetProfile()).thenAnswer((_) async => const Right(tProfile));
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();
        expect(find.text('Fitness Level'), findsOneWidget);
        expect(find.text('Primary Goal'), findsOneWidget);
        expect(find.text('Available Time'), findsOneWidget);
        expect(find.text('Physical Constraints'), findsOneWidget);
      },
    );

    testWidgets(
      '[P1] 2.4-WIDGET-003: pre-selected segment matches loaded profile value (fitnessLevel: low → Beginner selected)',
      (tester) async {
        when(mockGetProfile()).thenAnswer((_) async => const Right(tProfile));
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Find the SegmentedButton for Fitness Level — 'Beginner' should be selected
        // We verify via the SegmentedButton's selected set by checking the widget state
        final segmentedButtons = tester.widgetList<SegmentedButton<String>>(
          find.byType(SegmentedButton<String>),
        );
        final fitnessButton = segmentedButtons.first;
        expect(fitnessButton.selected, {'low'});
      },
    );

    testWidgets(
      '[P1] 2.4-WIDGET-004: tapping a segment calls cubit.updateProfile with correct UserProfile',
      (tester) async {
        when(mockGetProfile()).thenAnswer((_) async => const Right(tProfile));
        when(mockUpdateProfile(any)).thenAnswer((_) async => const Right(null));
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();

        // Tap 'Intermediate' in Fitness Level
        await tester.tap(find.text('Intermediate'));
        await tester.pump();

        // UserProfile has no == so capture and check fields
        final captured = verify(mockUpdateProfile(captureAny)).captured;
        expect(captured.length, 1);
        final updated = captured.first as UserProfile;
        expect(updated.fitnessLevel, 'medium');
        expect(updated.goal, 'cardio');
        expect(updated.availableTime, 'short');
        expect(updated.physicalConstraints, 'none');

        // R3: verify the SegmentedButton UI reflects the new selection (optimistic setState)
        final buttons = tester
            .widgetList<SegmentedButton<String>>(
              find.byType(SegmentedButton<String>),
            )
            .toList();
        expect(buttons.first.selected, {'medium'});
      },
    );

    testWidgets(
      '[P1] 2.4-WIDGET-005: snackbar shown on ProfileError',
      (tester) async {
        when(mockGetProfile()).thenAnswer(
          (_) async => const Left(CacheFailure('Profile not found')),
        );
        await tester.pumpWidget(buildPage());
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.text('Profile not found'),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
