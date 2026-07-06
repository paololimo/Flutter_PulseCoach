import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/database/app_database.dart'
    show SessionLog, SessionLogsCompanion;
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';
import 'package:pulse_coach/features/weather/domain/usecases/get_weather_context.dart';

import 'today_session_cubit_test.mocks.dart';

@GenerateMocks([SessionLogsDao, GetWeatherContext])
void main() {
  late MockSessionLogsDao sessionLogsDao;
  late MockGetWeatherContext getWeatherContext;

  TodaySessionCubit buildCubit({DateTime Function()? now}) =>
      TodaySessionCubit(sessionLogsDao, getWeatherContext, now: now);

  setUp(() {
    sessionLogsDao = MockSessionLogsDao();
    getWeatherContext = MockGetWeatherContext();
    when(sessionLogsDao.getLogsForPlan(any)).thenAnswer((_) async => []);
    when(sessionLogsDao.insertLog(any)).thenAnswer((_) async => 1);
    when(sessionLogsDao.upsertCompletion(any)).thenAnswer((_) async => 1);
    when(
      sessionLogsDao.getAllLogsOrderedByDate(),
    ).thenAnswer((_) async => []);
    when(
      sessionLogsDao.watchLogsForPlan(any),
    ).thenAnswer((_) => const Stream<List<SessionLog>>.empty());
    when(getWeatherContext()).thenAnswer(
      (_) async => const Left(ServerFailure('weather_unavailable')),
    );
  });

  group('TodaySessionCubit', () {
    test('7.3-UNIT-004: initial state has no sessions or completions', () {
      final cubit = buildCubit();
      addTearDown(cubit.close);

      expect(cubit.state.heroIndex, 0);
      expect(cubit.state.completedIndices, isEmpty);
      expect(cubit.state.completedCount, 0);
      expect(cubit.state.totalSessions, 0);
    });

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-005: planLoaded resets hero and completion state',
      build: buildCubit,
      seed: () => const TodaySessionState(
        heroIndex: 2,
        completedIndices: {0, 2},
        totalSessions: 3,
      ),
      act: (cubit) => cubit.planLoaded(3, null),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.heroIndex, 'heroIndex', 0)
            .having(
              (state) => state.completedIndices,
              'completedIndices',
              isEmpty,
            )
            .having((state) => state.totalSessions, 'totalSessions', 3),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-006: swapHero selects an incomplete in-range session',
      build: buildCubit,
      seed: () => const TodaySessionState(totalSessions: 3),
      act: (cubit) => cubit.swapHero(2),
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.heroIndex,
          'heroIndex',
          2,
        ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-007: swapHero ignores negative and out-of-range indices',
      build: buildCubit,
      seed: () => const TodaySessionState(totalSessions: 3),
      act: (cubit) {
        cubit.swapHero(-1);
        cubit.swapHero(3);
      },
      expect: () => <TodaySessionState>[],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-008: swapHero ignores already completed session',
      build: buildCubit,
      seed: () => const TodaySessionState(
        heroIndex: 1,
        completedIndices: {0},
        totalSessions: 3,
      ),
      act: (cubit) => cubit.swapHero(0),
      expect: () => <TodaySessionState>[],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-009: completing swapped hero records the tapped session identity',
      build: buildCubit,
      seed: () => const TodaySessionState(heroIndex: 2, totalSessions: 3),
      act: (cubit) => cubit.markSessionCompleted(),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.completedIndices, 'completedIndices', {2})
            .having((state) => state.heroIndex, 'heroIndex', 0)
            .having((state) => state.completedCount, 'completedCount', 1),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-010: markSessionCompleted advances to next incomplete session',
      build: buildCubit,
      seed: () => const TodaySessionState(
        heroIndex: 0,
        completedIndices: {2},
        totalSessions: 3,
      ),
      act: (cubit) => cubit.markSessionCompleted(),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.completedIndices, 'completedIndices', {
              0,
              2,
            })
            .having((state) => state.heroIndex, 'heroIndex', 1),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-011: markSessionCompleted ignores duplicate completion',
      build: buildCubit,
      seed: () => const TodaySessionState(
        heroIndex: 1,
        completedIndices: {1},
        totalSessions: 3,
      ),
      act: (cubit) => cubit.markSessionCompleted(),
      expect: () => <TodaySessionState>[],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '7.3-UNIT-012: markSessionCompleted ignores zero-session plans',
      build: buildCubit,
      act: (cubit) => cubit.markSessionCompleted(),
      expect: () => <TodaySessionState>[],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '8.0-UNIT-001: planLoaded with null planId emits empty state without querying DAO',
      build: buildCubit,
      seed: () => const TodaySessionState(
        heroIndex: 2,
        completedIndices: {0, 2},
        totalSessions: 3,
      ),
      act: (cubit) => cubit.planLoaded(3, null),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.heroIndex, 'heroIndex', 0)
            .having(
              (state) => state.completedIndices,
              'completedIndices',
              isEmpty,
            )
            .having((state) => state.totalSessions, 'totalSessions', 3),
      ],
      verify: (_) {
        verifyNever(sessionLogsDao.getLogsForPlan(any));
      },
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '8.0-UNIT-002: planLoaded with valid planId queries DAO and restores completedIndices',
      build: () {
        when(sessionLogsDao.getLogsForPlan(20)).thenAnswer(
          (_) async => [
            _log(planId: 20, sessionIndex: 0),
            _log(planId: 20, sessionIndex: 2),
          ],
        );
        return buildCubit();
      },
      act: (cubit) => cubit.planLoaded(3, 20),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.heroIndex, 'heroIndex', 1)
            .having((state) => state.completedIndices, 'completedIndices', {
              0,
              2,
            })
            .having((state) => state.totalSessions, 'totalSessions', 3),
      ],
      verify: (_) {
        verify(sessionLogsDao.getLogsForPlan(20)).called(1);
      },
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '8.0-UNIT-003: planLoaded with planId change replaces (not merges) completions when same session count',
      build: () {
        when(
          sessionLogsDao.getLogsForPlan(20),
        ).thenAnswer((_) async => [_log(planId: 20, sessionIndex: 0)]);
        // New plan's DAO returns a DIFFERENT non-empty set — proves the cubit
        // discards the prior in-memory completions instead of merging them.
        when(
          sessionLogsDao.getLogsForPlan(21),
        ).thenAnswer((_) async => [_log(planId: 21, sessionIndex: 2)]);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.planLoaded(3, 20);
        await cubit.planLoaded(3, 21);
      },
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.completedIndices,
          'completedIndices',
          {0},
        ),
        isA<TodaySessionState>().having(
          (state) => state.completedIndices,
          'completedIndices',
          {2},
        ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '8.0-UNIT-004: markSessionCompleted calls insertLog with correct planId + sessionIndex',
      build: buildCubit,
      act: (cubit) async {
        await cubit.planLoaded(3, 20);
        cubit.swapHero(2);
        await cubit.markSessionCompleted();
      },
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.totalSessions,
          'totalSessions',
          3,
        ),
        isA<TodaySessionState>().having(
          (state) => state.heroIndex,
          'heroIndex',
          2,
        ),
        isA<TodaySessionState>().having(
          (state) => state.completedIndices,
          'completedIndices',
          {2},
        ),
      ],
      verify: (_) {
        final captured =
            verify(sessionLogsDao.upsertCompletion(captureAny)).captured.single
                as SessionLogsCompanion;
        expect(captured.dailyPlanId, const Value(20));
        expect(captured.sessionIndex, const Value(2));
        expect(captured.completedAt.present, isTrue);
        expect(captured.createdAt.present, isTrue);
        // Recency: completedAt must be within ±5s of now. Catches a regression
        // where a fixed/hard-coded DateTime would silently pass the prior
        // `present, isTrue` assertion.
        final completedAt = captured.completedAt.value;
        final delta = DateTime.now().difference(completedAt).abs();
        expect(
          delta.inSeconds,
          lessThanOrEqualTo(5),
          reason: 'completedAt should be close to DateTime.now()',
        );
      },
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '8.0-UNIT-005: planLoaded(validId)→planLoaded(null)→markSessionCompleted does not write to previous plan',
      build: () {
        when(sessionLogsDao.getLogsForPlan(20)).thenAnswer((_) async => []);
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.planLoaded(3, 20);
        await cubit.planLoaded(3, null);
        await cubit.markSessionCompleted();
      },
      verify: (_) {
        // After planLoaded(null), the previous planId (20) must not be
        // reused. No insert should happen because the cubit treats null as
        // "skip persistence".
        verifyNever(sessionLogsDao.upsertCompletion(any));
      },
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '8.0-UNIT-006: markSessionCompleted on already-completed session does not insert duplicate',
      build: buildCubit,
      seed: () => const TodaySessionState(
        heroIndex: 1,
        completedIndices: {1},
        totalSessions: 3,
      ),
      act: (cubit) => cubit.markSessionCompleted(),
      expect: () => <TodaySessionState>[],
      verify: (_) {
        verifyNever(sessionLogsDao.upsertCompletion(any));
      },
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '8.0-UNIT-007: planLoaded with all sessions complete picks last index (not a completed one)',
      build: () {
        when(sessionLogsDao.getLogsForPlan(30)).thenAnswer(
          (_) async => [
            _log(planId: 30, sessionIndex: 0),
            _log(planId: 30, sessionIndex: 1),
            _log(planId: 30, sessionIndex: 2),
          ],
        );
        return buildCubit();
      },
      act: (cubit) => cubit.planLoaded(3, 30),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.completedIndices, 'completedIndices', {
              0,
              1,
              2,
            })
            .having((state) => state.completedCount, 'completedCount', 3)
            .having(
              (state) => state.heroIndex,
              'heroIndex',
              // Last index, not 0 — the UI uses allDone to switch off the
              // hero card, but the value must not point at a completed slot.
              2,
            ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '10.0-CUBIT-003: completion DAO failure emits persistenceError and still completes',
      build: () {
        when(
          sessionLogsDao.upsertCompletion(any),
        ).thenThrow(StateError('disk full'));
        return buildCubit();
      },
      seed: () => const TodaySessionState(heroIndex: 0, totalSessions: 3),
      act: (cubit) async {
        await cubit.planLoaded(3, 40);
        await cubit.markSessionCompleted();
      },
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.completedIndices,
          'completedIndices',
          isEmpty,
        ),
        isA<TodaySessionState>()
            .having((state) => state.completedIndices, 'completedIndices', {0})
            .having((state) => state.heroIndex, 'heroIndex', 1)
            .having(
              (state) => state.persistenceError,
              'persistenceError',
              const ServerFailure('session_log_upsert_failed'),
            ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '8.5-UNIT-001: regression — abandoned logs are NOT counted as completed',
      build: () {
        when(sessionLogsDao.getLogsForPlan(60)).thenAnswer(
          (_) async => [
            _log(planId: 60, sessionIndex: 0, abandoned: true),
            _log(planId: 60, sessionIndex: 1),
          ],
        );
        return buildCubit();
      },
      act: (cubit) => cubit.planLoaded(3, 60),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.completedIndices, 'completedIndices', {1})
            .having((state) => state.completedCount, 'completedCount', 1),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '8.0-UNIT-009: planLoaded drops stale logs whose sessionIndex >= totalSessions',
      build: () {
        when(sessionLogsDao.getLogsForPlan(50)).thenAnswer(
          (_) async => [
            _log(planId: 50, sessionIndex: 0),
            _log(planId: 50, sessionIndex: 5),
            _log(planId: 50, sessionIndex: 1),
          ],
        );
        return buildCubit();
      },
      // Regenerate landed and the new plan has only 2 sessions instead of 6.
      act: (cubit) => cubit.planLoaded(2, 50),
      expect: () => [
        isA<TodaySessionState>()
            .having((state) => state.totalSessions, 'totalSessions', 2)
            .having((state) => state.completedIndices, 'completedIndices', {
              0,
              1,
            })
            .having((state) => state.completedCount, 'completedCount', 2),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '22.2-CUBIT-001: planLoaded with weather Right emits that weatherContext',
      build: () {
        when(getWeatherContext()).thenAnswer((_) async => Right(_weather()));
        return buildCubit();
      },
      act: (cubit) => cubit.planLoaded(3, 20),
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.weatherContext?.temperature,
          'weatherContext.temperature',
          _weather().temperature,
        ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '22.2-CUBIT-002: planLoaded with weather Left emits null weatherContext',
      build: () {
        when(getWeatherContext()).thenAnswer(
          (_) async => const Left(ServerFailure('weather_unavailable')),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.planLoaded(3, 20),
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.weatherContext,
          'weatherContext',
          isNull,
        ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '22.2-CUBIT-003: planLoaded with null planId never calls GetWeatherContext',
      build: buildCubit,
      act: (cubit) => cubit.planLoaded(3, null),
      verify: (_) {
        verifyNever(getWeatherContext());
      },
    );

    final fixedNow = DateTime(2026, 7, 6, 9, 30);

    blocTest<TodaySessionCubit, TodaySessionState>(
      '22.3-CUBIT-001: logs on 3 distinct days within the last 30 → '
      'activeDaysCount == 3',
      build: () {
        when(sessionLogsDao.getAllLogsOrderedByDate()).thenAnswer(
          (_) async => [
            _logAt(planId: 20, sessionIndex: 0, completedAt: fixedNow),
            _logAt(
              planId: 20,
              sessionIndex: 1,
              completedAt: DateTime(2026, 7, 1, 8),
            ),
            _logAt(
              planId: 20,
              sessionIndex: 2,
              completedAt: DateTime(2026, 6, 10, 18),
            ),
          ],
        );
        return buildCubit(now: () => fixedNow);
      },
      act: (cubit) => cubit.planLoaded(3, 20),
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.activeDaysCount,
          'activeDaysCount',
          3,
        ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '22.3-CUBIT-002: two logs on the same calendar day count once',
      build: () {
        when(sessionLogsDao.getAllLogsOrderedByDate()).thenAnswer(
          (_) async => [
            _logAt(
              planId: 20,
              sessionIndex: 0,
              completedAt: DateTime(2026, 7, 6, 8),
            ),
            _logAt(
              planId: 20,
              sessionIndex: 1,
              completedAt: DateTime(2026, 7, 6, 20),
            ),
          ],
        );
        return buildCubit(now: () => fixedNow);
      },
      act: (cubit) => cubit.planLoaded(3, 20),
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.activeDaysCount,
          'activeDaysCount',
          1,
        ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '22.3-CUBIT-003: a log 29 days before now is included; 30 days '
      'before is excluded (trailing-30-day boundary)',
      build: () {
        when(sessionLogsDao.getAllLogsOrderedByDate()).thenAnswer(
          (_) async => [
            _logAt(
              planId: 20,
              sessionIndex: 0,
              completedAt: DateTime(2026, 6, 7, 10),
            ),
            _logAt(
              planId: 20,
              sessionIndex: 1,
              completedAt: DateTime(2026, 6, 6, 10),
            ),
          ],
        );
        return buildCubit(now: () => fixedNow);
      },
      act: (cubit) => cubit.planLoaded(3, 20),
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.activeDaysCount,
          'activeDaysCount',
          1,
        ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '22.3-CUBIT-004: an abandoned log does not count toward activeDaysCount',
      build: () {
        when(sessionLogsDao.getAllLogsOrderedByDate()).thenAnswer(
          (_) async => [
            _logAt(
              planId: 20,
              sessionIndex: 0,
              completedAt: fixedNow,
              abandoned: true,
            ),
          ],
        );
        return buildCubit(now: () => fixedNow);
      },
      act: (cubit) => cubit.planLoaded(3, 20),
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.activeDaysCount,
          'activeDaysCount',
          0,
        ),
      ],
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '22.3-CUBIT-005: planLoaded(n, null) never calls '
      'getAllLogsOrderedByDate; activeDaysCount stays 0',
      build: buildCubit,
      act: (cubit) => cubit.planLoaded(3, null),
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.activeDaysCount,
          'activeDaysCount',
          0,
        ),
      ],
      verify: (_) {
        verifyNever(sessionLogsDao.getAllLogsOrderedByDate());
      },
    );

    blocTest<TodaySessionCubit, TodaySessionState>(
      '22.3-CUBIT-006: a live logs-stream update recomputes activeDaysCount',
      build: () {
        final controller = StreamController<List<SessionLog>>();
        addTearDown(controller.close);
        when(
          sessionLogsDao.watchLogsForPlan(20),
        ).thenAnswer((_) => controller.stream);
        _liveLogsController = controller;
        return buildCubit(now: () => fixedNow);
      },
      act: (cubit) async {
        await cubit.planLoaded(3, 20);
        // The cubit's subscription applies `.skip(1)`, so the first event
        // is dropped — it exists only to satisfy that skip.
        _liveLogsController.add(const []);
        when(sessionLogsDao.getAllLogsOrderedByDate()).thenAnswer(
          (_) async => [
            _logAt(planId: 20, sessionIndex: 0, completedAt: fixedNow),
          ],
        );
        _liveLogsController.add([_log(planId: 20, sessionIndex: 0)]);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        isA<TodaySessionState>().having(
          (state) => state.activeDaysCount,
          'activeDaysCount',
          0,
        ),
        isA<TodaySessionState>().having(
          (state) => state.activeDaysCount,
          'activeDaysCount',
          1,
        ),
      ],
    );
  });
}

late StreamController<List<SessionLog>> _liveLogsController;

WeatherContext _weather() => WeatherContext(
  temperature: 15.0,
  precipitationProbability: 10.0,
  aqiValue: 40,
  cachedAt: DateTime.utc(2026, 7, 6),
);

SessionLog _log({
  required int planId,
  required int sessionIndex,
  bool abandoned = false,
}) {
  final now = DateTime.utc(2026, 5, 16, 9);
  return SessionLog(
    id: sessionIndex + 1,
    dailyPlanId: planId,
    sessionIndex: sessionIndex,
    completedAt: now,
    createdAt: now,
    abandoned: abandoned,
  );
}

SessionLog _logAt({
  required int planId,
  required int sessionIndex,
  required DateTime completedAt,
  bool abandoned = false,
}) {
  return SessionLog(
    id: sessionIndex + 1,
    dailyPlanId: planId,
    sessionIndex: sessionIndex,
    completedAt: completedAt,
    createdAt: completedAt,
    abandoned: abandoned,
  );
}
