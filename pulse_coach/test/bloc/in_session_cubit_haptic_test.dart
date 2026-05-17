import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
import 'package:pulse_coach/features/session/presentation/utils/haptic_service.dart';

class _FakeHapticService implements HapticService {
  int callCount = 0;

  @override
  void stepTransition() => callCount++;
}

const _steps = [
  ExerciseStep(title: 'Warm-up', instruction: 'Prep', durationSeconds: 2),
  ExerciseStep(title: 'Main', instruction: 'Go', durationSeconds: 2),
  ExerciseStep(title: 'Cool-down', instruction: 'Rest', durationSeconds: 2),
];

void main() {
  group('InSessionCubit - haptic feedback (Story 8.3)', () {
    testWidgets(
      '8.3-CUBIT-001: haptic fires on step transition (step 0 to step 1)',
      (tester) async {
        final haptic = _FakeHapticService();
        final cubit = InSessionCubit(steps: _steps, hapticService: haptic)
          ..start();

        await tester.pump(const Duration(seconds: 3));

        expect(cubit.state.currentStepIndex, 1);
        expect(haptic.callCount, 1);

        await cubit.close();
      },
    );

    testWidgets(
      '8.3-CUBIT-002: haptic fires on final-step to complete transition',
      (tester) async {
        final haptic = _FakeHapticService();
        final cubit = InSessionCubit(steps: _steps, hapticService: haptic)
          ..start();

        await tester.pump(const Duration(seconds: 9));
        await tester.pump();

        expect(cubit.state.isComplete, isTrue);
        expect(haptic.callCount, 3);

        await cubit.close();
      },
    );

    testWidgets('8.3-CUBIT-003: null hapticService has no crash', (
      tester,
    ) async {
      final cubit = InSessionCubit(steps: _steps)..start();

      await tester.pump(const Duration(seconds: 3));

      expect(cubit.state.currentStepIndex, 1);

      await cubit.close();
    });

    testWidgets(
      '8.3-CUBIT-004: haptic fires exactly once per step transition for N-step session',
      (tester) async {
        final haptic = _FakeHapticService();
        final cubit = InSessionCubit(steps: _steps, hapticService: haptic)
          ..start();

        await tester.pump(const Duration(seconds: 3));
        expect(haptic.callCount, 1);

        await tester.pump(const Duration(seconds: 3));
        expect(haptic.callCount, 2);

        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(haptic.callCount, 3);
        expect(cubit.state.isComplete, isTrue);

        await cubit.close();
      },
    );

    testWidgets('8.3-CUBIT-005: haptic does not fire on start', (tester) async {
      final haptic = _FakeHapticService();
      final cubit = InSessionCubit(steps: _steps, hapticService: haptic)
        ..start();

      await tester.pump(const Duration(seconds: 1));

      expect(haptic.callCount, 0);

      await cubit.close();
    });

    testWidgets(
      '8.3-CUBIT-006: abandon after one transition does not fire an extra haptic',
      (tester) async {
        final haptic = _FakeHapticService();
        final cubit = InSessionCubit(steps: _steps, hapticService: haptic)
          ..start();

        // Advance past step 0 so a real transition (and haptic) has fired.
        await tester.pump(const Duration(seconds: 3));
        expect(cubit.state.currentStepIndex, 1);
        expect(haptic.callCount, 1);

        // Abandon must not trigger an additional haptic.
        cubit.abandon();

        expect(cubit.state.isAbandoned, isTrue);
        expect(haptic.callCount, 1);

        await cubit.close();
      },
    );
  });
}
