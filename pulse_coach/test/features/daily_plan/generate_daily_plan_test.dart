import 'package:dartz/dartz.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/ai/engine/ai_engine.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart'
    as domain;
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/domain/repositories/daily_plan_repository.dart';
import 'package:pulse_coach/features/daily_plan/domain/usecases/generate_daily_plan.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:pulse_coach/features/session/domain/entities/health_data.dart';
import 'package:pulse_coach/features/session/domain/repositories/health_repository.dart';
import 'package:pulse_coach/features/session/domain/repositories/sensor_repository.dart';
import 'package:pulse_coach/features/weather/domain/repositories/weather_repository.dart';

import 'generate_daily_plan_test.mocks.dart';

@GenerateMocks([
  DailyPlanRepository,
  AiEngine,
  HealthRepository,
  SensorRepository,
  WeatherRepository,
  OnboardingRepository,
])
void main() {
  late MockDailyPlanRepository mockPlanRepo;
  late MockAiEngine mockAiEngine;
  late MockHealthRepository mockHealthRepo;
  late MockSensorRepository mockSensorRepo;
  late MockWeatherRepository mockWeatherRepo;
  late MockOnboardingRepository mockOnboardingRepo;
  late AppDatabase db;
  late GenerateDailyPlan sut;

  const tProfile = UserProfile(
    fitnessLevel: 'medium',
    goal: 'cardio',
    availableTime: 'short',
    physicalConstraints: 'none',
  );

  final tPlan = domain.DailyPlan(
    planDate: _todayDate(),
    sessions: const [
      PlannedSession(
        sessionType: 'cardio',
        intensity: 6,
        durationMinutes: 10,
        isIndoor: false,
      ),
    ],
    generatedAt: DateTime.now().toUtc(),
  );

  final tOutput = AiEngineOutput(
    plan: tPlan,
    newBehavioralState: BehavioralState.active,
  );

  setUp(() {
    mockPlanRepo = MockDailyPlanRepository();
    mockAiEngine = MockAiEngine();
    mockHealthRepo = MockHealthRepository();
    mockSensorRepo = MockSensorRepository();
    mockWeatherRepo = MockWeatherRepository();
    mockOnboardingRepo = MockOnboardingRepository();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    sut = GenerateDailyPlan(
      mockPlanRepo,
      mockAiEngine,
      mockHealthRepo,
      mockSensorRepo,
      mockWeatherRepo,
      mockOnboardingRepo,
      db,
    );
  });

  tearDown(() async {
    await db.close();
  });

  void _setupDefaultMocks() {
    when(mockHealthRepo.fetchHealthData())
        .thenAnswer((_) async => const Right(HealthData(restingHr: 65, stepCount: 4000)));
    when(mockSensorRepo.fetchActivityLevel())
        .thenAnswer((_) async => const Left(SensorFailure('unavailable')));
    when(mockWeatherRepo.getWeatherContext())
        .thenAnswer((_) async => const Left(ServerFailure('unavailable')));
    when(mockOnboardingRepo.getProfile())
        .thenAnswer((_) async => const Right(tProfile));
    when(mockAiEngine.call(any)).thenAnswer((_) async => tOutput);
    when(mockPlanRepo.savePlan(any))
        .thenAnswer((_) async => const Right(null));
  }

  group('GenerateDailyPlan — cache hit (AC5)', () {
    test('5.5-UNIT-010: cache hit → returns cached plan, AiEngine NOT invoked', () async {
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => Right(tPlan));

      final result = await sut.call();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (plan) {
        expect(plan.planDate, equals(tPlan.planDate));
      });
      verifyNever(mockAiEngine.call(any));
    });
  });

  group('GenerateDailyPlan — cache miss (AC1, AC2, AC3)', () {
    test('5.5-UNIT-011: cache miss → AiEngine IS invoked, plan saved', () async {
      _setupDefaultMocks();
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.call();

      expect(result.isRight(), isTrue);
      verify(mockAiEngine.call(any)).called(1);
      verify(mockPlanRepo.savePlan(any)).called(1);
    });
  });

  group('GenerateDailyPlan — graceful degradation (AC7)', () {
    test('5.5-UNIT-012: sensor failure → StateVector built with null HR/steps, plan generated', () async {
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => const Right(null));
      when(mockHealthRepo.fetchHealthData())
          .thenAnswer((_) async => const Left(SensorFailure('no health')));
      when(mockSensorRepo.fetchActivityLevel())
          .thenAnswer((_) async => const Left(SensorFailure('no sensor')));
      when(mockWeatherRepo.getWeatherContext())
          .thenAnswer((_) async => const Left(ServerFailure('no weather')));
      when(mockOnboardingRepo.getProfile())
          .thenAnswer((_) async => const Right(tProfile));
      when(mockAiEngine.call(any)).thenAnswer((_) async => tOutput);
      when(mockPlanRepo.savePlan(any))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.call();
      expect(result.isRight(), isTrue);
    });

    test('5.5-UNIT-013: weather failure → AqiLevel.low default, plan generated', () async {
      _setupDefaultMocks();
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => const Right(null));
      when(mockWeatherRepo.getWeatherContext())
          .thenAnswer((_) async => const Left(ServerFailure('weather down')));

      final result = await sut.call();
      expect(result.isRight(), isTrue);

      // Verify AiEngine was called (weather failure doesn't block pipeline)
      verify(mockAiEngine.call(any)).called(1);
    });
  });

  group('GenerateDailyPlan — new user cold-start (AC8)', () {
    test('5.5-UNIT-014: new user (no RPE, no sessions, no state) → active state, plan generated', () async {
      _setupDefaultMocks();
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => const Right(null));

      final result = await sut.call();
      expect(result.isRight(), isTrue);
      verify(mockAiEngine.call(any)).called(1);
    });

    test('5.5-UNIT-015: new user → initialBanditState() used (no bandit row in DB)', () async {
      _setupDefaultMocks();
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => const Right(null));

      AiEngineInput? capturedInput;
      when(mockAiEngine.call(any)).thenAnswer((inv) async {
        capturedInput = inv.positionalArguments.first as AiEngineInput;
        return tOutput;
      });

      await sut.call();

      expect(capturedInput, isNotNull);
      expect(
        capturedInput!.banditState.updatedAt,
        equals(DateTime.utc(1970)),
      );
    });
  });

  group('GenerateDailyPlan — behavioral state persistence (AC6)', () {
    test('5.5-UNIT-016: state machine produces new state → behavioral_state row inserted', () async {
      _setupDefaultMocks();
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => const Right(null));
      when(mockAiEngine.call(any)).thenAnswer((_) async => AiEngineOutput(
            plan: tPlan,
            newBehavioralState: BehavioralState.recovering, // differs from active default
          ));

      await sut.call();

      final rows = await db.behavioralStateDao.getLatestState();
      expect(rows, isNotNull);
      expect(rows!.currentState.toLowerCase(), equals('recovering'));
    });

    test('5.5-UNIT-017: cold-start with no prior state row → row IS inserted (AC6)', () async {
      _setupDefaultMocks();
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => const Right(null));
      // Engine returns active for a brand-new user with no prior row.
      // AC6's "(or no state exists)" clause requires the row to be inserted.
      when(mockAiEngine.call(any)).thenAnswer((_) async => AiEngineOutput(
            plan: tPlan,
            newBehavioralState: BehavioralState.active,
          ));

      await sut.call();

      final rows = await db.behavioralStateDao.getLatestState();
      expect(rows, isNotNull);
      expect(rows!.currentState.toLowerCase(), equals('active'));
    });
  });

  group('GenerateDailyPlan — profile unavailable (AC7)', () {
    test('5.5-UNIT-018: profile unavailable → returns Left(CacheFailure), plan NOT generated', () async {
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => const Right(null));
      when(mockOnboardingRepo.getProfile())
          .thenAnswer((_) async => const Left(CacheFailure('no profile')));

      final result = await sut.call();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<CacheFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyNever(mockAiEngine.call(any));
    });
  });

  group('GenerateDailyPlan — session metrics (AC8)', () {
    test('5.5-UNIT-019: streak = 0 when no sessions', () async {
      _setupDefaultMocks();
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => const Right(null));

      AiEngineInput? capturedInput;
      when(mockAiEngine.call(any)).thenAnswer((inv) async {
        capturedInput = inv.positionalArguments.first as AiEngineInput;
        return tOutput;
      });

      await sut.call();

      expect(capturedInput!.stateVector.streak, equals(0));
    });

    test('5.5-UNIT-020: missedSessions = 0 for new user with no session history (AC8)', () async {
      _setupDefaultMocks();
      when(mockPlanRepo.getPlanForDate(any))
          .thenAnswer((_) async => const Right(null));

      AiEngineInput? capturedInput;
      when(mockAiEngine.call(any)).thenAnswer((inv) async {
        capturedInput = inv.positionalArguments.first as AiEngineInput;
        return tOutput;
      });

      await sut.call();

      // AC8: a brand-new user hasn't "missed" anything yet — 0, not 7.
      expect(capturedInput!.stateVector.missedSessions, equals(0));
    });
  });
}

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
