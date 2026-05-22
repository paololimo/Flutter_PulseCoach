import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_transition_key.dart';
import 'package:pulse_coach/core/database/app_database.dart' as db_models;
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
  late db_models.AppDatabase db;

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
    db = db_models.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  DailyPlanBloc bloc() => DailyPlanBloc(mockGenerate, mockRegenerate, db);

  group('DailyPlanBloc', () {
    test('5.5-UNIT-027: initial state is DailyPlanInitial', () {
      expect(bloc().state, const DailyPlanState.initial());
    });

    test('7.3-UNIT-001: loaded state defaults behavioralState to active', () {
      final loaded = DailyPlanState.loaded(plan: tPlan) as DailyPlanLoaded;

      expect(loaded.behavioralState, BehavioralState.active);
    });

    blocTest<DailyPlanBloc, DailyPlanState>(
      '5.5-UNIT-028: DailyPlanGenerateRequested → [loading, loaded] on success',
      build: () {
        when(mockGenerate.call()).thenAnswer(
          (_) async => Right(GenerateDailyPlanResult(plan: tPlan)),
        );
        return bloc();
      },
      act: (bloc) => bloc.add(DailyPlanGenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        DailyPlanState.loaded(plan: tPlan),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '7.3-UNIT-002: DailyPlanGenerateRequested emits latest behavioral state',
      setUp: () async {
        await db.behavioralStateDao.insertState(
          db_models.BehavioralStateCompanion.insert(
            currentState: 'Fatigued',
            recordedAt: DateTime.utc(2026, 4, 29, 7, 0),
            updatedAt: DateTime.utc(2026, 4, 29, 7, 0),
          ),
        );
      },
      build: () {
        when(mockGenerate.call()).thenAnswer(
          (_) async => Right(GenerateDailyPlanResult(plan: tPlan)),
        );
        return bloc();
      },
      act: (bloc) => bloc.add(DailyPlanGenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        DailyPlanState.loaded(
          plan: tPlan,
          behavioralState: BehavioralState.fatigued,
        ),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '9.3-UNIT-010: DailyPlanGenerateRequested surfaces transitionKey from use case',
      setUp: () async {
        // Latest DB state is what populates `behavioralState`; the
        // transitionKey itself is carried in the use-case result (no more
        // pre/post DB inference — closed in Story 9.3 code review).
        await db.behavioralStateDao.insertState(
          db_models.BehavioralStateCompanion.insert(
            currentState: 'Fatigued',
            recordedAt: DateTime.utc(2026, 4, 29, 8, 0),
            updatedAt: DateTime.utc(2026, 4, 29, 8, 0),
          ),
        );
      },
      build: () {
        when(mockGenerate.call()).thenAnswer(
          (_) async => Right(
            GenerateDailyPlanResult(
              plan: tPlan,
              transitionKey: BehavioralTransitionKey.activeToFatigued,
            ),
          ),
        );
        return bloc();
      },
      act: (bloc) => bloc.add(DailyPlanGenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        DailyPlanState.loaded(
          plan: tPlan,
          behavioralState: BehavioralState.fatigued,
          transitionKey: BehavioralTransitionKey.activeToFatigued,
        ),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '8.0-UNIT-007: DailyPlanGenerateRequested exposes persisted planDbId',
      setUp: () async {
        await db.dailyPlansDao.insertPlan(
          db_models.DailyPlansCompanion.insert(
            planDate: tPlan.planDate,
            planJson: '{"sessions":[]}',
            generatedAt: tPlan.generatedAt,
            createdAt: tPlan.generatedAt,
          ),
        );
      },
      build: () {
        when(mockGenerate.call()).thenAnswer(
          (_) async => Right(GenerateDailyPlanResult(plan: tPlan)),
        );
        return bloc();
      },
      act: (bloc) => bloc.add(DailyPlanGenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        isA<DailyPlanLoaded>()
            .having((state) => state.plan, 'plan', tPlan)
            .having((state) => state.planDbId, 'planDbId', 1),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '7.3-UNIT-003: DailyPlanGenerateRequested parses AtRisk behavioral state',
      setUp: () async {
        await db.behavioralStateDao.insertState(
          db_models.BehavioralStateCompanion.insert(
            currentState: 'AtRisk',
            recordedAt: DateTime.utc(2026, 4, 29, 7, 0),
            updatedAt: DateTime.utc(2026, 4, 29, 7, 0),
          ),
        );
      },
      build: () {
        when(mockGenerate.call()).thenAnswer(
          (_) async => Right(GenerateDailyPlanResult(plan: tPlan)),
        );
        return bloc();
      },
      act: (bloc) => bloc.add(DailyPlanGenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        DailyPlanState.loaded(
          plan: tPlan,
          behavioralState: BehavioralState.atRisk,
        ),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '5.5-UNIT-029: DailyPlanGenerateRequested → [loading, error] on failure',
      build: () {
        when(mockGenerate.call()).thenAnswer((_) async => const Left(tFailure));
        return bloc();
      },
      act: (bloc) => bloc.add(DailyPlanGenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        const DailyPlanState.error(failure: tFailure, retryAttempts: 1),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '5.5-UNIT-030: DailyPlanRegenerateRequested → [loading, loaded] on success',
      build: () {
        when(mockRegenerate.call()).thenAnswer(
          (_) async => Right(GenerateDailyPlanResult(plan: tPlan)),
        );
        return bloc();
      },
      act: (bloc) => bloc.add(DailyPlanRegenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        DailyPlanState.loaded(plan: tPlan),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '8.0-UNIT-008: DailyPlanRegenerateRequested exposes persisted planDbId',
      setUp: () async {
        await db.dailyPlansDao.insertPlan(
          db_models.DailyPlansCompanion.insert(
            planDate: tPlan.planDate,
            planJson: '{"sessions":[]}',
            generatedAt: tPlan.generatedAt,
            createdAt: tPlan.generatedAt,
            isCompleted: const Value(true),
          ),
        );
      },
      build: () {
        when(mockRegenerate.call()).thenAnswer(
          (_) async => Right(GenerateDailyPlanResult(plan: tPlan)),
        );
        return bloc();
      },
      act: (bloc) => bloc.add(DailyPlanRegenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        isA<DailyPlanLoaded>()
            .having((state) => state.plan, 'plan', tPlan)
            .having((state) => state.planDbId, 'planDbId', 1),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '5.5-UNIT-031: DailyPlanRegenerateRequested → [loading, error] on failure',
      build: () {
        when(
          mockRegenerate.call(),
        ).thenAnswer((_) async => const Left(tFailure));
        return bloc();
      },
      act: (bloc) => bloc.add(DailyPlanRegenerateRequested()),
      expect: () => [
        const DailyPlanState.loading(),
        const DailyPlanState.error(failure: tFailure, retryAttempts: 1),
      ],
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '6.5-EQ-BLOC-004: two consecutive failures produce distinct error emissions (retry counter increments)',
      build: () {
        when(mockGenerate.call()).thenAnswer((_) async => const Left(tFailure));
        return bloc();
      },
      act: (bloc) async {
        bloc.add(DailyPlanGenerateRequested());
        await Future<void>.delayed(Duration.zero);
        await pumpEventQueue();
        bloc.add(DailyPlanGenerateRequested());
      },
      expect: () => [
        const DailyPlanState.loading(),
        const DailyPlanState.error(failure: tFailure, retryAttempts: 1),
        const DailyPlanState.loading(),
        const DailyPlanState.error(failure: tFailure, retryAttempts: 2),
      ],
      verify: (_) => verify(mockGenerate.call()).called(2),
    );

    blocTest<DailyPlanBloc, DailyPlanState>(
      '5.5-UNIT-032: DailyPlanGenerateRequested dispatched twice → use case invoked twice, two loaded emissions',
      build: () {
        when(mockGenerate.call()).thenAnswer(
          (_) async => Right(GenerateDailyPlanResult(plan: tPlan)),
        );
        return bloc();
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
