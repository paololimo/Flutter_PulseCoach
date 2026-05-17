import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
import 'package:pulse_coach/features/session/presentation/utils/live_hr_service.dart';

class _FakeLiveHrService implements LiveHrService {
  int? _nextValue;
  int fetchCount = 0;

  void setNextValue(int? value) => _nextValue = value;

  @override
  Future<void> init() async {}

  @override
  Future<int?> fetchLiveHr() async {
    fetchCount++;
    return _nextValue;
  }
}

const _steps = [
  ExerciseStep(title: 'Warm-up', instruction: 'Prep', durationSeconds: 60),
  ExerciseStep(title: 'Main', instruction: 'Go', durationSeconds: 60),
];

void main() {
  group('InSessionCubit live HR (Story 8.4)', () {
    testWidgets(
      '8.4-CUBIT-001: state.liveHr updates when service returns a value',
      (tester) async {
        final hr = _FakeLiveHrService()..setNextValue(72);
        final cubit = InSessionCubit(steps: _steps, liveHrService: hr)..start();

        await tester.pump();

        expect(cubit.state.liveHr, 72);
        await cubit.close();
      },
    );

    testWidgets(
      '8.4-CUBIT-002: state.liveHr retains last known value when service returns null',
      (tester) async {
        final hr = _FakeLiveHrService()..setNextValue(68);
        final cubit = InSessionCubit(steps: _steps, liveHrService: hr)..start();

        await tester.pump();
        expect(cubit.state.liveHr, 68);

        hr.setNextValue(null);
        await tester.pump(const Duration(seconds: 5));
        await tester.pump();

        expect(cubit.state.liveHr, 68);
        await cubit.close();
      },
    );

    testWidgets(
      '8.4-CUBIT-003: state.liveHr is null when no service is injected',
      (tester) async {
        final cubit = InSessionCubit(steps: _steps)..start();

        await tester.pump();

        expect(cubit.state.liveHr, isNull);
        await cubit.close();
      },
    );

    testWidgets(
      '8.4-CUBIT-004: state.liveHr is null when service always returns null',
      (tester) async {
        final hr = _FakeLiveHrService()..setNextValue(null);
        final cubit = InSessionCubit(steps: _steps, liveHrService: hr)..start();

        await tester.pump();
        await tester.pump(const Duration(seconds: 5));
        await tester.pump();

        expect(cubit.state.liveHr, isNull);
        await cubit.close();
      },
    );

    testWidgets('8.4-CUBIT-005: liveHr updates on each poll', (tester) async {
      final hr = _FakeLiveHrService()..setNextValue(70);
      final cubit = InSessionCubit(steps: _steps, liveHrService: hr)..start();

      await tester.pump();
      expect(cubit.state.liveHr, 70);

      hr.setNextValue(85);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();

      expect(cubit.state.liveHr, 85);
      await cubit.close();
    });

    testWidgets('8.4-CUBIT-006: HR timer is cancelled on close', (
      tester,
    ) async {
      final hr = _FakeLiveHrService()..setNextValue(72);
      final cubit = InSessionCubit(steps: _steps, liveHrService: hr)..start();

      await tester.pump();
      final countAfterStart = hr.fetchCount;

      await cubit.close();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(hr.fetchCount, countAfterStart);
    });

    testWidgets('8.4-CUBIT-007: HR timer is cancelled on abandon', (
      tester,
    ) async {
      final hr = _FakeLiveHrService()..setNextValue(72);
      final cubit = InSessionCubit(steps: _steps, liveHrService: hr)..start();

      await tester.pump();
      final countAfterStart = hr.fetchCount;

      cubit.abandon();
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(hr.fetchCount, countAfterStart);
      expect(cubit.state.isAbandoned, isTrue);
      await cubit.close();
    });

    testWidgets(
      '8.4-CUBIT-008: null hapticService still works with liveHrService',
      (tester) async {
        final hr = _FakeLiveHrService()..setNextValue(77);
        final cubit = InSessionCubit(steps: _steps, liveHrService: hr)..start();

        await tester.pump();

        expect(cubit.state.liveHr, 77);
        expect(cubit.state.currentStepIndex, 0);
        await cubit.close();
      },
    );

    testWidgets(
      '8.4-CUBIT-009: start() is idempotent — second call does not double timers',
      (tester) async {
        final hr = _FakeLiveHrService()..setNextValue(72);
        final cubit = InSessionCubit(steps: _steps, liveHrService: hr);
        cubit.start();
        cubit.start();

        await tester.pump();
        final firstCount = hr.fetchCount;
        await tester.pump(const Duration(seconds: 5));
        await tester.pump();

        // Exactly one poll per 5s — would be 2x if start() leaked a timer.
        expect(hr.fetchCount, firstCount + 1);
        await cubit.close();
      },
    );

    testWidgets(
      '8.4-CUBIT-010: HR polling stops after 6 consecutive null reads',
      (tester) async {
        final hr = _FakeLiveHrService()..setNextValue(null);
        final cubit = InSessionCubit(steps: _steps, liveHrService: hr)..start();

        // Initial fetch + 5 timer ticks = 6 null polls total.
        await tester.pump();
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(seconds: 5));
          await tester.pump();
        }
        final countAfterCap = hr.fetchCount;

        // No further polls after cap is reached.
        await tester.pump(const Duration(seconds: 30));
        await tester.pump();

        expect(hr.fetchCount, countAfterCap);
        expect(cubit.state.liveHr, isNull);
        await cubit.close();
      },
    );

    testWidgets(
      '8.4-CUBIT-011: lastHrAtEpochMs is set when liveHr is emitted',
      (tester) async {
        final hr = _FakeLiveHrService()..setNextValue(72);
        final cubit = InSessionCubit(steps: _steps, liveHrService: hr)..start();

        await tester.pump();

        expect(cubit.state.liveHr, 72);
        expect(cubit.state.lastHrAtEpochMs, isNotNull);
        await cubit.close();
      },
    );
  });
}
