import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/domain/usecases/generate_daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/usecases/regenerate_daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';

import 'daily_plan_bloc_test.mocks.dart';

@GenerateMocks([GenerateDailyPlan, RegenerateDailyPlan])
void main() {
  late MockGenerateDailyPlan mockGenerate;
  late MockRegenerateDailyPlan mockRegenerate;

  final tPlan = DailyPlan(
    planDate: '2026-04-29',
    sessions: const [
      PlannedSession(
        sessionType: 'cardio',
        intensity: 6,
        durationMinutes: 10,
        isIndoor: false,
      ),
    ],
    generatedAt: DateTime.utc(2026, 4, 29, 8, 0),
  );
  const tFailure = CacheFailure('DB error');

  setUp(() {
    mockGenerate = MockGenerateDailyPlan();
    mockRegenerate = MockRegenerateDailyPlan();
  });

  DailyPlanBloc _bloc() => DailyPlanBloc(mockGenerate, mockRegenerate);

  group('DailyPlanBloc', () {
    test('5.5-UNIT-027: initial state is DailyPlanInitial', () {
      expect(_bloc().state, const DailyPlanState.initial());
    });

    blocTest<DailyPlanBloc, DailyPlanState>(
      '5.5-UNIT-028: DailyPlanGenerateRequested → [loading, loaded] on success',
      build: () {
        when(mockGenerate.call()).thenAnswer((_) async => Right(tPlan));
        return _bloc();
      },
      act: (bloc) => bloc.add(DailyPlanGenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        DailyPlanState.loaded(plan: tPlan),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '5.5-UNIT-029: DailyPlanGenerateRequested → [loading, error] on failure',
      build: () {
        when(mockGenerate.call()).thenAnswer((_) async => const Left(tFailure));
        return _bloc();
      },
      act: (bloc) => bloc.add(DailyPlanGenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        const DailyPlanState.error(failure: tFailure),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '5.5-UNIT-030: DailyPlanRegenerateRequested → [loading, loaded] on success',
      build: () {
        when(mockRegenerate.call()).thenAnswer((_) async => Right(tPlan));
        return _bloc();
      },
      act: (bloc) => bloc.add(DailyPlanRegenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        DailyPlanState.loaded(plan: tPlan),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '5.5-UNIT-031: DailyPlanRegenerateRequested → [loading, error] on failure',
      build: () {
        when(mockRegenerate.call())
            .thenAnswer((_) async => const Left(tFailure));
        return _bloc();
      },
      act: (bloc) => bloc.add(DailyPlanRegenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        const DailyPlanState.error(failure: tFailure),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '5.5-UNIT-032: DailyPlanGenerateRequested dispatched twice → use case invoked twice, two loaded emissions',
      build: () {
        when(mockGenerate.call()).thenAnswer((_) async => Right(tPlan));
        return _bloc();
      },
      act: (bloc) async {
        bloc.add(DailyPlanGenerateRequested());
        // Drain the event queue so the first handler completes before the
        // second event is enqueued. Using pumpEventQueue is deterministic
        // across CI machines, unlike a fixed-duration sleep.
        await Future<void>.delayed(Duration.zero);
        await pumpEventQueue();
        bloc.add(DailyPlanGenerateRequested());
      },
      expect: () => [
        const DailyPlanState.loading(),
        DailyPlanState.loaded(plan: tPlan),
        const DailyPlanState.loading(),
        DailyPlanState.loaded(plan: tPlan),
      ],
      verify: (_) => verify(mockGenerate.call()).called(2),
    );
  });
}
