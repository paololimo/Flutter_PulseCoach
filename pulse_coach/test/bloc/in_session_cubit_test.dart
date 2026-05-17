import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';

const _steps = [
  ExerciseStep(title: 'Warm-up', instruction: 'Prep', durationSeconds: 3),
  ExerciseStep(title: 'Main', instruction: 'Go', durationSeconds: 2),
  ExerciseStep(title: 'Cool-down', instruction: 'Rest', durationSeconds: 2),
];

InSessionCubit _cubit() => InSessionCubit(steps: _steps);

void main() {
  group('InSessionCubit', () {
    testWidgets('8.2-CUBIT-001: initial state', (tester) async {
      final cubit = _cubit();

      expect(cubit.state.currentStepIndex, 0);
      expect(cubit.state.secondsRemaining, _steps[0].durationSeconds);
      expect(cubit.state.isComplete, isFalse);

      await cubit.close();
    });

    testWidgets('8.2-CUBIT-002: tick decrements secondsRemaining', (
      tester,
    ) async {
      final cubit = _cubit()..start();

      await tester.pump(const Duration(seconds: 1));

      expect(cubit.state.secondsRemaining, _steps[0].durationSeconds - 1);
      await cubit.close();
    });

    testWidgets('8.2-CUBIT-003: step advances after timer shows 00:00', (
      tester,
    ) async {
      final cubit = _cubit()..start();

      // duration N ticks reach secondsRemaining=0 (the 00:00 frame); the
      // (N+1)-th tick advances to the next step. See 8.2-CUBIT-007 for the
      // explicit 00:00 frame assertion.
      await tester.pump(Duration(seconds: _steps[0].durationSeconds + 1));

      expect(cubit.state.currentStepIndex, 1);
      expect(cubit.state.secondsRemaining, _steps[1].durationSeconds);
      await cubit.close();
    });

    testWidgets('8.2-CUBIT-004: all steps complete emits isComplete', (
      tester,
    ) async {
      final cubit = _cubit()..start();
      // Each step now consumes durationSeconds + 1 ticks (the extra tick is
      // the visible 00:00 frame before advancing).
      final totalSeconds = _steps.fold<int>(
        0,
        (sum, step) => sum + step.durationSeconds + 1,
      );

      await tester.pump(Duration(seconds: totalSeconds));
      await tester.pump();

      expect(cubit.state.isComplete, isTrue);
      await cubit.close();
    });

    testWidgets('8.2-CUBIT-007: timer renders 00:00 before advancing', (
      tester,
    ) async {
      final cubit = _cubit()..start();

      // After N ticks the first step has decremented from N→0 (the 00:00
      // frame). The next tick is what advances to step 2 — confirm we are
      // still on step 0 here.
      await tester.pump(Duration(seconds: _steps[0].durationSeconds));

      expect(cubit.state.currentStepIndex, 0);
      expect(cubit.state.secondsRemaining, 0);
      await cubit.close();
    });

    testWidgets('8.2-CUBIT-005: close cancels timer without error', (
      tester,
    ) async {
      final cubit = _cubit()..start();

      await cubit.close();
      await tester.pump(const Duration(seconds: 10));

      expect(cubit.isClosed, isTrue);
    });

    testWidgets(
      '8.2-CUBIT-006: abandon emits isAbandoned (not isComplete) and stops timer',
      (tester) async {
        final cubit = _cubit()..start();

        cubit.abandon();
        final stateAfterAbandon = cubit.state;
        await tester.pump(const Duration(seconds: 10));

        expect(cubit.state.isAbandoned, isTrue);
        // isComplete must remain false so the RPE-bound BlocListener does not
        // fire on abandon (avoids double navigation RPE + Today).
        expect(cubit.state.isComplete, isFalse);
        expect(
          cubit.state.currentStepIndex,
          stateAfterAbandon.currentStepIndex,
        );
        expect(
          cubit.state.secondsRemaining,
          stateAfterAbandon.secondsRemaining,
        );
        await cubit.close();
      },
    );
  });
}
