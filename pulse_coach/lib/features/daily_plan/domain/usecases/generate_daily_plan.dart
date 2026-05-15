import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/ai/bandit/bandit_state.dart' as ai_bandit;
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/engine/ai_engine.dart';
import 'package:pulse_coach/ai/missed_sessions/missed_sessions_calculator.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart' as ai_state;
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart'
    as domain;
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/domain/repositories/daily_plan_repository.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:pulse_coach/features/session/domain/repositories/health_repository.dart';
import 'package:pulse_coach/features/session/domain/repositories/sensor_repository.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/repositories/exercise_repository.dart';
import 'package:pulse_coach/features/weather/domain/repositories/weather_repository.dart';

@injectable
class GenerateDailyPlan {
  final DailyPlanRepository _planRepo;
  final AiEngine _aiEngine;
  final HealthRepository _healthRepo;
  final SensorRepository _sensorRepo;
  final WeatherRepository _weatherRepo;
  final OnboardingRepository _onboardingRepo;
  final ExerciseRepository _exerciseRepository;
  final AppDatabase _db;

  GenerateDailyPlan(
    this._planRepo,
    this._aiEngine,
    this._healthRepo,
    this._sensorRepo,
    this._weatherRepo,
    this._onboardingRepo,
    this._exerciseRepository,
    this._db,
  );

  Future<Either<Failure, domain.DailyPlan>> call() async {
    try {
      // AC5: serve cached plan if it exists for today
      final today = _todayDate();
      final cached = await _planRepo.getPlanForDate(today);
      final cachedPlan = cached.fold<domain.DailyPlan?>((_) => null, (p) => p);
      if (cachedPlan != null) return Right(cachedPlan);

      // Build StateVector — all sensor/weather failures degrade gracefully (AC7)
      final sv = await _buildStateVector();
      if (sv == null) return const Left(CacheFailure('User profile not found'));

      // Load BanditState from DB — use initialBanditState() for new users (AC8)
      final banditRow = await _db.banditStateDao.getLatestState();
      final banditState = banditRow != null
          ? _parseBanditState(banditRow)
          : ai_bandit.initialBanditState();

      // AC1: run AI pipeline in separate Dart Isolate
      final output = await _aiEngine.call(
        AiEngineInput(stateVector: sv, banditState: banditState),
      );
      final plan = await _enrichPlanWithCatalog(output.plan);

      // AC3: persist plan FIRST so a state-row insert can never end up orphaned
      // by a savePlan failure.
      final saveResult = await _planRepo.savePlan(plan);
      return await saveResult.fold(
        (failure) async => Left<Failure, domain.DailyPlan>(failure),
        (_) async {
          // AC6: persist new BehavioralState when it changed OR when no row exists.
          // The "(or no state exists)" clause is critical for cold-start (AC8) —
          // a brand-new user landing on `active` would otherwise never persist a row.
          final currentStateRow = await _db.behavioralStateDao.getLatestState();
          final currentState = _parseState(currentStateRow?.currentState);
          if (currentStateRow == null ||
              output.newBehavioralState != currentState) {
            final now = DateTime.now().toUtc();
            await _db.behavioralStateDao.insertState(
              BehavioralStateCompanion(
                currentState: drift.Value(output.newBehavioralState.name),
                recordedAt: drift.Value(now),
                updatedAt: drift.Value(now),
              ),
            );
          }
          return Right<Failure, domain.DailyPlan>(plan);
        },
      );
    } on TimeoutException catch (e) {
      developer.log(
        'AI pipeline timed out',
        name: 'GenerateDailyPlan',
        error: e,
      );
      return Left(CacheFailure('AI pipeline timed out: ${e.message ?? ''}'));
    } catch (e, st) {
      developer.log(
        'GenerateDailyPlan failed',
        name: 'GenerateDailyPlan',
        error: e,
        stackTrace: st,
      );
      return Left(CacheFailure(e.toString()));
    }
  }

  Future<domain.DailyPlan> _enrichPlanWithCatalog(domain.DailyPlan plan) async {
    final enrichedSessions = <PlannedSession>[];

    for (final session in plan.sessions) {
      final result = await _exerciseRepository.getExercisesByType(
        session.sessionType,
      );
      final enriched = result.fold(
        (failure) {
          developer.log(
            'Catalog enrichment skipped for ${session.sessionType}',
            name: 'GenerateDailyPlan',
            error: failure,
          );
          return session;
        },
        (exercises) {
          if (exercises.isEmpty) {
            return session;
          }

          final preferred = _selectExerciseForSession(session, exercises);
          // Fill-only contract: AI engine commits `durationMinutes` from
          // profile.availableTime (Story 5.5). Catalog only refines `isIndoor`
          // when the selected exercise is incompatible with the AI's choice.
          final isIndoor = _resolveIsIndoor(session.isIndoor, preferred);
          return session.copyWith(isIndoor: isIndoor);
        },
      );
      enrichedSessions.add(enriched);
    }

    return plan.copyWith(sessions: enrichedSessions);
  }

  Exercise _selectExerciseForSession(
    PlannedSession session,
    List<Exercise> exercises,
  ) {
    final desiredDifficulty = _difficultyForIntensity(session.intensity);
    final environmentFiltered = exercises
        .where((exercise) {
          if (session.isIndoor) {
            return exercise.indoorCompatible;
          }
          return exercise.outdoorCompatible;
        })
        .toList(growable: false);
    final candidates = environmentFiltered.isNotEmpty
        ? environmentFiltered
        : exercises;

    for (final exercise in candidates) {
      if (exercise.difficulty == desiredDifficulty) {
        return exercise;
      }
    }
    return candidates.first;
  }

  bool _resolveIsIndoor(bool aiIsIndoor, Exercise preferred) {
    if (aiIsIndoor) {
      // Flip to outdoor only when the chosen exercise cannot be done indoors
      // but can be done outdoors. Otherwise keep the AI's decision.
      if (!preferred.indoorCompatible && preferred.outdoorCompatible) {
        return false;
      }
      return true;
    }
    // AI chose outdoor; flip to indoor only when the chosen exercise cannot
    // be done outdoors but can be done indoors.
    if (!preferred.outdoorCompatible && preferred.indoorCompatible) {
      return true;
    }
    return false;
  }

  String _difficultyForIntensity(int intensity) {
    if (intensity >= 8) {
      return 'high';
    }
    if (intensity >= 4) {
      return 'medium';
    }
    return 'low';
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  Future<StateVector?> _buildStateVector() async {
    // Profile is required — use case fails if unavailable (not graceful)
    final profileResult = await _onboardingRepo.getProfile();
    final profile = profileResult.fold((_) => null, (r) => r);
    if (profile == null) return null;

    // Sensor data — null on failure (AC7)
    double? restingHR;
    int? stepCount;
    final healthResult = await _healthRepo.fetchHealthData();
    healthResult.fold(
      (_) {}, // sensor failure → null fields
      (data) {
        restingHR = data.restingHr?.toDouble();
        stepCount = data.stepCount;
      },
    );

    // Activity level — null on failure (AC7)
    final sensorResult = await _sensorRepo.fetchActivityLevel();
    final activityLevel = sensorResult.fold((_) => null, (a) => a);

    // Weather — indoor defaults on failure (AC7)
    final weatherResult = await _weatherRepo.getWeatherContext();
    final aqiLevel = weatherResult.fold(
      (_) => AqiLevel.low, // indoor default on failure
      (w) => w.isAqiHigh ? AqiLevel.high : AqiLevel.low,
    );
    final temperature = weatherResult.fold<double?>(
      (_) => null,
      (w) => w.temperature,
    );
    final precipitation = weatherResult.fold<bool?>(
      (_) => null,
      (w) => w.precipitationProbability > 50.0,
    );

    // RPE history — last 10 in chronological order, validated 1–10 (AC7, defer from 5.2/5.3)
    final rpeRows = await _db.rpeFeedbackDao.getLastN(10);
    final rpeHistory = rpeRows
        .map((r) => r.rpeValue)
        .where((v) => v >= 1 && v <= 10)
        .toList()
        .reversed
        .toList(); // getLastN returns most-recent-first; reverse to chronological

    // Current behavioral state — Active for new users (AC8)
    final stateRow = await _db.behavioralStateDao.getLatestState();
    final currentState = _parseState(stateRow?.currentState);

    // Session history — for streak
    final sessions = await _db.sessionsDao.getAllSessions();
    final streak = _calculateStreak(sessions);
    // Window: 7 prior days, EXCLUDING today.
    // Today's plan is generated by this very call; counting it as "missed"
    // before the user has had a chance to complete it would prematurely trip
    // active → atRisk on same-day regenerate. The miss signal must reflect
    // disengagement on days the user has already passed.
    final windowStart = _dateStr(
      DateTime.now().subtract(const Duration(days: 7)),
    );
    final windowEnd = _dateStr(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final plansInWindow = await _db.dailyPlansDao.getPlansInDateRange(
      windowStart,
      windowEnd,
    );
    final missedSessions = const MissedSessionsCalculator().calculate(
      plansInWindow.map((p) => p.isCompleted).toList(),
    );

    return StateVector(
      restingHR: restingHR,
      stepCount: stepCount,
      activityLevel: activityLevel,
      rpeHistory: rpeHistory,
      missedSessions: missedSessions,
      streak: streak,
      aqiLevel: aqiLevel,
      temperature: temperature,
      precipitation: precipitation,
      userProfile: profile,
      currentState: currentState,
    );
  }

  /// Converts Drift BanditStateData row to the AI domain BanditState.
  ///
  /// [BanditStateData] is the Drift data class (from bandit_state_table.dart).
  /// [ai_bandit.BanditState] is the AI domain model (from bandit_state.dart).
  /// The Drift TABLE class is also named BanditState — resolved via 'as ai_bandit' alias.
  ai_bandit.BanditState _parseBanditState(BanditStateData row) {
    try {
      final decoded = (jsonDecode(row.armWeightsJson) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      // Validate all 9 expected arms present; reject NaN/infinite/negative
      // weights (corrupt) and fall back to 1.0 for missing or invalid entries.
      final weights = {
        for (final key in ai_bandit.banditArmKeys)
          key: _validWeight(decoded[key]),
      };
      return ai_bandit.BanditState(
        armWeights: weights,
        updatedAt: row.updatedAt,
      );
    } on FormatException catch (e) {
      developer.log(
        'Corrupt BanditState JSON — cold start',
        name: 'GenerateDailyPlan',
        error: e,
      );
      return ai_bandit.initialBanditState();
    } on TypeError catch (e) {
      developer.log(
        'Malformed BanditState payload — cold start',
        name: 'GenerateDailyPlan',
        error: e,
      );
      return ai_bandit.initialBanditState();
    }
  }

  double _validWeight(double? w) =>
      (w != null && w.isFinite && w >= 0) ? w : 1.0;

  ai_state.BehavioralState _parseState(String? stateStr) {
    return switch (stateStr?.toLowerCase()) {
      'recovering' => ai_state.BehavioralState.recovering,
      'atrisk' => ai_state.BehavioralState.atRisk,
      'fatigued' => ai_state.BehavioralState.fatigued,
      _ =>
        ai_state.BehavioralState.active, // null or 'active' or unknown → active
    };
  }

  /// Consecutive calendar days ending today with ≥1 completed session.
  ///
  /// If today's session is not yet completed, the streak counts back from
  /// yesterday so it doesn't "crash" mid-day for an active user.
  int _calculateStreak(List<Session> sessions) {
    final completed = sessions
        .where((s) => s.completedAt != null && s.abandoned == false)
        .map((s) => _dateStr(s.completedAt!.toLocal()))
        .toSet();
    var day = DateTime.now();
    if (!completed.contains(_dateStr(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (completed.contains(_dateStr(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _dateStr(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _todayDate() => _dateStr(DateTime.now());
}
