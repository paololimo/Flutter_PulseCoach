import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/ai/engine/ai_engine.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart'
    as domain;
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/domain/repositories/daily_plan_repository.dart';
import 'package:pulse_coach/features/daily_plan/domain/usecases/generate_daily_plan.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:pulse_coach/features/progress/data/datasources/progress_local_data_source.dart';
import 'package:pulse_coach/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
import 'package:pulse_coach/features/session/domain/entities/health_data.dart';
import 'package:pulse_coach/features/session/domain/repositories/health_repository.dart';
import 'package:pulse_coach/features/session/domain/repositories/sensor_repository.dart';
import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
import 'package:pulse_coach/features/session/presentation/utils/live_hr_service.dart';
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_local_data_source.dart';
import 'package:pulse_coach/features/sessions_catalog/data/datasources/exercise_remote_data_source.dart';
import 'package:pulse_coach/features/sessions_catalog/data/repositories/exercise_repository_impl.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/weather/domain/repositories/weather_repository.dart';
import 'package:pulse_coach/features/weather/domain/usecases/get_weather_context.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';

import 'offline_core_features_test.mocks.dart';

@GenerateMocks([
  AiEngine,
  DailyPlanRepository,
  ExerciseRemoteDataSource,
  HealthRepository,
  OnboardingRepository,
  SensorRepository,
  WeatherRepository,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Story 13.1 offline-first core features', () {
    late AppDatabase db;
    late ExerciseLocalDataSource exerciseLocalDataSource;
    late MockDailyPlanRepository planRepository;
    late MockAiEngine aiEngine;
    late MockHealthRepository healthRepository;
    late MockSensorRepository sensorRepository;
    late MockWeatherRepository weatherRepository;
    late MockOnboardingRepository onboardingRepository;
    late MockExerciseRemoteDataSource exerciseRemoteDataSource;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      exerciseLocalDataSource = ExerciseLocalDataSource(db.exerciseCacheDao);
      planRepository = MockDailyPlanRepository();
      aiEngine = MockAiEngine();
      healthRepository = MockHealthRepository();
      sensorRepository = MockSensorRepository();
      weatherRepository = MockWeatherRepository();
      onboardingRepository = MockOnboardingRepository();
      exerciseRemoteDataSource = MockExerciseRemoteDataSource();

      when(
        planRepository.getPlanForDate(any),
      ).thenAnswer((_) async => const Right(null));
      when(
        healthRepository.fetchHealthData(),
      ).thenAnswer((_) async => const Right(HealthData(stepCount: 3200)));
      when(
        sensorRepository.fetchActivityLevel(),
      ).thenAnswer((_) async => const Left(SensorFailure('offline sensor')));
      when(
        weatherRepository.getWeatherContext(),
      ).thenAnswer((_) async => const Left(ServerFailure('offline weather')));
      when(
        onboardingRepository.getProfile(),
      ).thenAnswer((_) async => const Right(_profile));
      when(aiEngine.call(any)).thenAnswer(
        (_) async => AiEngineOutput(
          plan: _plan(),
          newBehavioralState: BehavioralState.active,
        ),
      );
      when(
        planRepository.savePlan(any),
      ).thenAnswer((_) async => const Right(null));
    });

    tearDown(() async {
      AppLogger.debugSink = null;
      await db.close();
    });

    test(
      '13.1-OFFLINE-001: plan generation succeeds with weather failure and stale exercise cache',
      () async {
        await _seedWeatherCache(db);
        await exerciseLocalDataSource.cacheExercises(
          [_cachedCardio],
          DateTime.now().toUtc().subtract(const Duration(hours: 25)),
        );
        when(
          exerciseRemoteDataSource.fetchExercisesByType('cardio'),
        ).thenThrow(const ServerException('offline exercise catalog'));
        final exerciseRepository = ExerciseRepositoryImpl(
          exerciseRemoteDataSource,
          exerciseLocalDataSource,
        );
        final generateDailyPlan = _buildGenerateDailyPlan(
          db: db,
          planRepository: planRepository,
          aiEngine: aiEngine,
          healthRepository: healthRepository,
          sensorRepository: sensorRepository,
          weatherRepository: weatherRepository,
          onboardingRepository: onboardingRepository,
          exerciseRepository: exerciseRepository,
        );

        final result = await generateDailyPlan();

        expect(result.isRight(), isTrue);
        // Prove the 25h-stale cache entry is what the recovery path actually
        // returns — not bundled fallback and not a Left. A regression returning
        // Left from _recoverFromFallbacks would be caught here.
        final staleResult = await exerciseRepository.getExercisesByType('cardio');
        expect(staleResult.isRight(), isTrue);
        staleResult.fold((_) => fail('Expected stale cache recovery'), (
          exercises,
        ) {
          expect(exercises.map((e) => e.id), contains('cached-cardio'));
        });
        verify(weatherRepository.getWeatherContext()).called(1);
        // Twice: once via plan generation enrichment, once via the direct
        // stale-cache assertion above.
        verify(exerciseRemoteDataSource.fetchExercisesByType('cardio')).called(
          2,
        );
      },
    );

    test(
      '13.1-OFFLINE-002: plan generation succeeds with no exercise cache and bundled fallback',
      () async {
        await _seedWeatherCache(db);
        when(
          exerciseRemoteDataSource.fetchExercisesByType('cardio'),
        ).thenThrow(const ServerException('offline exercise catalog'));
        final exerciseRepository = ExerciseRepositoryImpl(
          exerciseRemoteDataSource,
          exerciseLocalDataSource,
        );
        final generateDailyPlan = _buildGenerateDailyPlan(
          db: db,
          planRepository: planRepository,
          aiEngine: aiEngine,
          healthRepository: healthRepository,
          sensorRepository: sensorRepository,
          weatherRepository: weatherRepository,
          onboardingRepository: onboardingRepository,
          exerciseRepository: exerciseRepository,
        );

        final result = await generateDailyPlan();

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (generated) {
          expect(generated.plan.sessions, hasLength(1));
          expect(generated.plan.sessions.single.sessionType, 'cardio');
        });
        // The plan session above comes from the mocked AI engine, not the
        // catalog, so assert the bundled-fallback path directly: with no cache
        // and remote throwing, the repository must recover real cardio
        // exercises from assets/data/fallback_exercises.json.
        final fallbackResult = await exerciseRepository.getExercisesByType(
          'cardio',
        );
        expect(fallbackResult.isRight(), isTrue);
        fallbackResult.fold((_) => fail('Expected bundled fallback exercises'), (
          exercises,
        ) {
          expect(exercises, isNotEmpty);
          expect(exercises.every((e) => e.sessionType == 'cardio'), isTrue);
        });
      },
    );

    test(
      '13.1-OFFLINE-003: session completion and RPE persist through local DAOs',
      () async {
        final now = DateTime.utc(2026, 6, 4, 9);
        final planId = await _seedDailyPlan(db, now);

        final sessionLogId = await db.sessionLogsDao.upsertCompletion(
          SessionLogsCompanion(
            dailyPlanId: Value(planId),
            sessionIndex: const Value(0),
            completedAt: Value(now),
            createdAt: Value(now),
          ),
        );
        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: sessionLogId,
            sessionLogId: Value(sessionLogId),
            rpeValue: 6,
            recordedAt: now,
          ),
        );

        final logs = await db.sessionLogsDao.getLogsForPlan(planId);
        final feedback = await db.rpeFeedbackDao.getBySessionLogId(
          sessionLogId,
        );

        expect(logs, hasLength(1));
        expect(logs.single.sessionIndex, 0);
        expect(feedback?.rpeValue, 6);
      },
    );

    test(
      '13.1-OFFLINE-004: progress history renders from local data without Failure',
      () async {
        final now = DateTime.utc(2026, 6, 4, 9);
        final planId = await _seedDailyPlan(db, now);
        final sessionLogId = await db.sessionLogsDao.upsertCompletion(
          SessionLogsCompanion(
            dailyPlanId: Value(planId),
            sessionIndex: const Value(0),
            completedAt: Value(now),
            createdAt: Value(now),
          ),
        );
        await db.rpeFeedbackDao.insertFeedback(
          RpeFeedbackCompanion.insert(
            sessionId: sessionLogId,
            sessionLogId: Value(sessionLogId),
            rpeValue: 7,
            recordedAt: now,
          ),
        );
        final repository = ProgressRepositoryImpl(
          ProgressLocalDataSource(
            db.sessionLogsDao,
            db.dailyPlansDao,
            db.rpeFeedbackDao,
          ),
        );

        final result = await repository.getSessionHistory();

        expect(result.isRight(), isTrue);
        result.fold((_) => fail('Expected Right'), (entries) {
          expect(entries, hasLength(1));
          expect(entries.single.rpeValue, 7);
          expect(entries.single.sessionType, 'cardio');
        });
      },
    );

    testWidgets(
      '13.1-OFFLINE-005: mid-session optional HR I/O failure does not block step transition',
      (tester) async {
        final cubit = InSessionCubit(
          steps: _steps,
          liveHrService: _ThrowingLiveHrService(),
        )..start();

        await tester.pump(const Duration(seconds: 2));

        expect(cubit.state.currentStepIndex, 1);
        expect(cubit.state.isComplete, isFalse);
        await cubit.close();
      },
    );

    testWidgets(
      '13.1-OFFLINE-006: mid-session optional HR I/O failure does not block completion',
      (tester) async {
        final cubit = InSessionCubit(
          steps: _steps,
          liveHrService: _ThrowingLiveHrService(),
        )..start();

        await tester.pump(const Duration(seconds: 4));
        await tester.pump();

        expect(cubit.state.isComplete, isTrue);
        expect(cubit.state.persistenceError, isNull);
        await cubit.close();
      },
    );

    testWidgets(
      '13.1-E10R1-002: InSessionCubit DAO failure sets persistenceError and logs release-level error',
      (tester) async {
        final logRecords = <_LogRecord>[];
        AppLogger.debugSink = (
          message, {
          required name,
          error,
          stackTrace,
          required level,
        }) {
          logRecords.add(
            _LogRecord(
              message: message,
              name: name,
              error: error,
              stackTrace: stackTrace,
              level: level,
            ),
          );
        };
        final cubit = InSessionCubit(
          steps: _steps,
          sessionLogsDao: _ThrowingTodaySessionLogsDao(),
          planId: 7,
        )..start();
        addTearDown(cubit.close);

        await tester.pump(const Duration(seconds: 4));
        await tester.pump();

        expect(cubit.state.isComplete, isTrue);
        expect(
          cubit.state.persistenceError,
          const ServerFailure('session_log_write_failed'),
        );
        expect(
          logRecords,
          contains(
            isA<_LogRecord>()
                .having((record) => record.name, 'name', 'InSessionCubit')
                .having((record) => record.level, 'level', 1000)
                .having(
                  (record) => record.message,
                  'message',
                  contains('upsertCompletion failed'),
                )
                .having((record) => record.error, 'error', isA<StateError>()),
          ),
        );
      },
    );

    test(
      '13.1-E10R1-001: TodaySessionCubit DAO failure sets persistenceError and logs release-level error',
      () async {
        final logRecords = <_LogRecord>[];
        AppLogger.debugSink = (
          message, {
          required name,
          error,
          stackTrace,
          required level,
        }) {
          logRecords.add(
            _LogRecord(
              message: message,
              name: name,
              error: error,
              stackTrace: stackTrace,
              level: level,
            ),
          );
        };
        final dao = _ThrowingTodaySessionLogsDao();
        final cubit = TodaySessionCubit(
          dao,
          GetWeatherContext(weatherRepository),
        );
        addTearDown(cubit.close);

        await cubit.planLoaded(1, 42);
        await cubit.markSessionCompleted();

        expect(
          cubit.state.persistenceError,
          const ServerFailure('session_log_upsert_failed'),
        );
        expect(
          logRecords,
          contains(
            isA<_LogRecord>()
                .having((record) => record.name, 'name', 'TodaySessionCubit')
                .having((record) => record.level, 'level', 1000)
                .having(
                  (record) => record.message,
                  'message',
                  contains('DAO write failed'),
                )
                .having((record) => record.error, 'error', isA<StateError>()),
          ),
        );
      },
    );
  });
}

const _profile = UserProfile(
  fitnessLevel: 'medium',
  goal: 'cardio',
  availableTime: 'short',
  physicalConstraints: 'none',
);

const _cachedCardio = Exercise(
  id: 'cached-cardio',
  name: 'Cached March',
  description: 'Cached offline cardio.',
  sessionType: 'cardio',
  steps: ['March in place', 'Keep posture tall', 'Breathe steadily'],
  durationMinutes: 7,
  difficulty: 'medium',
  indoorCompatible: true,
  outdoorCompatible: true,
);

const _steps = [
  ExerciseStep(title: 'Warm-up', instruction: 'Start', durationSeconds: 1),
  ExerciseStep(title: 'Main', instruction: 'Continue', durationSeconds: 1),
];

GenerateDailyPlan _buildGenerateDailyPlan({
  required AppDatabase db,
  required DailyPlanRepository planRepository,
  required AiEngine aiEngine,
  required HealthRepository healthRepository,
  required SensorRepository sensorRepository,
  required WeatherRepository weatherRepository,
  required OnboardingRepository onboardingRepository,
  required ExerciseRepositoryImpl exerciseRepository,
}) {
  return GenerateDailyPlan(
    planRepository,
    aiEngine,
    healthRepository,
    sensorRepository,
    weatherRepository,
    onboardingRepository,
    exerciseRepository,
    db,
  );
}

domain.DailyPlan _plan({DateTime? generatedAt}) {
  return domain.DailyPlan(
    planDate: _todayDate(),
    sessions: const [
      PlannedSession(
        sessionType: 'cardio',
        intensity: 6,
        durationMinutes: 10,
        isIndoor: false,
      ),
    ],
    generatedAt: generatedAt ?? DateTime.now().toUtc(),
  );
}

Future<void> _seedWeatherCache(AppDatabase db) {
  return db.weatherCacheDao.insertOrReplace(
    WeatherCacheCompanion.insert(
      latitude: 45.46,
      longitude: 9.19,
      temperature: 21,
      precipitationProbability: 0,
      aqiValue: 25,
      cachedAt: DateTime.now().toUtc(),
    ),
  );
}

Future<int> _seedDailyPlan(AppDatabase db, DateTime now) {
  return db.dailyPlansDao.insertPlan(
    DailyPlansCompanion(
      planDate: Value(_todayDate()),
      planJson: Value(jsonEncode(_plan(generatedAt: now).toJson())),
      generatedAt: Value(now),
      createdAt: Value(now),
    ),
  );
}

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}

class _ThrowingLiveHrService implements LiveHrService {
  @override
  Future<void> init() async {}

  @override
  Future<int?> fetchLiveHr() => throw StateError('network unavailable');
}

class _ThrowingTodaySessionLogsDao extends Fake implements SessionLogsDao {
  @override
  Future<List<SessionLog>> getLogsForPlan(int planId) async => [];

  @override
  Stream<List<SessionLog>> watchLogsForPlan(int planId) =>
      const Stream<List<SessionLog>>.empty();

  @override
  Future<int> upsertCompletion(SessionLogsCompanion entry) {
    throw StateError('disk full');
  }
}

class _LogRecord {
  const _LogRecord({
    required this.message,
    required this.name,
    required this.error,
    required this.stackTrace,
    required this.level,
  });

  final String message;
  final String name;
  final Object? error;
  final StackTrace? stackTrace;
  final int level;
}
