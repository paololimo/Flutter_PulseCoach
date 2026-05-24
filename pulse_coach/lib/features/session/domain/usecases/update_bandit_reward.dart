import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart' show compute;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/ai/bandit/bandit_state.dart' as ai_bandit;
import 'package:pulse_coach/ai/bandit/contextual_bandit.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/missed_sessions/missed_sessions_calculator.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state_machine.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/logging/app_logger.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';

class BanditRewardInput {
  final ai_bandit.BanditState currentBanditState;
  final String armKey;
  final int rpeValue;
  final List<int> updatedRpeHistory;
  final int missedSessions;
  final int streak;
  final BehavioralState currentBehavioralState;

  const BanditRewardInput({
    required this.currentBanditState,
    required this.armKey,
    required this.rpeValue,
    required this.updatedRpeHistory,
    required this.missedSessions,
    required this.streak,
    required this.currentBehavioralState,
  });
}

class BanditRewardOutput {
  final ai_bandit.BanditState newBanditState;
  final BehavioralState newBehavioralState;
  final bool stateChanged;

  const BanditRewardOutput({
    required this.newBanditState,
    required this.newBehavioralState,
    required this.stateChanged,
  });
}

const _kDummyProfile = UserProfile(
  fitnessLevel: 'medium',
  goal: 'wellbeing',
  availableTime: 'short',
  physicalConstraints: 'none',
);

BanditRewardOutput _computeRewardUpdate(BanditRewardInput input) {
  final newBanditState = BanditEngine().updateReward(
    input.currentBanditState,
    input.armKey,
    input.rpeValue,
  );

  final updatedSv = StateVector(
    restingHR: null,
    stepCount: null,
    activityLevel: null,
    rpeHistory: input.updatedRpeHistory,
    missedSessions: input.missedSessions,
    streak: input.streak,
    aqiLevel: AqiLevel.low,
    temperature: null,
    precipitation: null,
    userProfile: _kDummyProfile,
    currentState: input.currentBehavioralState,
  );

  const machine = BehavioralStateMachine();
  final transition = machine.evaluate(updatedSv);

  return BanditRewardOutput(
    newBanditState: newBanditState,
    newBehavioralState: transition.newState,
    stateChanged: transition.stateChanged,
  );
}

@injectable
class UpdateBanditReward {
  final AppDatabase _db;

  UpdateBanditReward(this._db);

  Future<Either<Failure, Unit>> call({
    required String armKey,
    required int rpeValue,
  }) async {
    try {
      final banditRow = await _db.banditStateDao.getLatestState();
      final currentBanditState = banditRow != null
          ? _parseBanditState(banditRow)
          : ai_bandit.initialBanditState();

      final rpeRows = await _db.rpeFeedbackDao.getLastN(10);
      final updatedRpeHistory = rpeRows
          .map((row) => row.rpeValue)
          .where((value) => value >= 1 && value <= 10)
          .toList()
          .reversed
          .toList();

      final stateRow = await _db.behavioralStateDao.getLatestState();
      final currentBehavioralState = _parseState(stateRow?.currentState);

      final sessions = await _db.sessionsDao.getAllSessions();
      final streak = _calculateStreak(sessions);
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
        plansInWindow.map((plan) => plan.isCompleted).toList(),
      );

      final output = await compute(
        _computeRewardUpdate,
        BanditRewardInput(
          currentBanditState: currentBanditState,
          armKey: armKey,
          rpeValue: rpeValue,
          updatedRpeHistory: updatedRpeHistory,
          missedSessions: missedSessions,
          streak: streak,
          currentBehavioralState: currentBehavioralState,
        ),
      );

      final now = DateTime.now().toUtc();
      final weightsJson = jsonEncode(output.newBanditState.armWeights);
      if (banditRow != null) {
        await _db.banditStateDao.updateState(
          BanditStateData(
            id: banditRow.id,
            armWeightsJson: weightsJson,
            updatedAt: now,
          ),
        );
      } else {
        await _db.banditStateDao.insertState(
          BanditStateCompanion(
            armWeightsJson: drift.Value(weightsJson),
            updatedAt: drift.Value(now),
          ),
        );
      }

      if (output.stateChanged) {
        await _db.behavioralStateDao.insertState(
          BehavioralStateCompanion(
            currentState: drift.Value(output.newBehavioralState.name),
            recordedAt: drift.Value(now),
            updatedAt: drift.Value(now),
          ),
        );
      }

      return const Right(unit);
    } catch (e, st) {
      AppLogger.error(
        'UpdateBanditReward failed',
        name: 'UpdateBanditReward',
        error: e,
        stackTrace: st,
      );
      return const Left(ServerFailure('bandit_reward_update_failed'));
    }
  }

  ai_bandit.BanditState _parseBanditState(BanditStateData row) {
    try {
      final decoded = (jsonDecode(row.armWeightsJson) as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num).toDouble()));
      final weights = {
        for (final key in ai_bandit.banditArmKeys)
          key: _validWeight(decoded[key], key),
      };
      return ai_bandit.BanditState(
        armWeights: weights,
        updatedAt: row.updatedAt,
      );
    } catch (e, st) {
      AppLogger.warning(
        'Corrupt BanditState JSON; cold start',
        name: 'UpdateBanditReward',
        error: e,
        stackTrace: st,
      );
      return ai_bandit.initialBanditState();
    }
  }

  double _validWeight(double? weight, String armKey) {
    if (weight != null && weight.isFinite && weight >= 0) return weight;
    AppLogger.warning(
      'bandit_state: invalid weight coerced to 1.0 for arm=$armKey, raw=$weight',
      name: 'UpdateBanditReward',
    );
    return 1.0;
  }

  BehavioralState _parseState(String? stateStr) {
    return switch (stateStr?.toLowerCase()) {
      'recovering' => BehavioralState.recovering,
      'atrisk' => BehavioralState.atRisk,
      'fatigued' => BehavioralState.fatigued,
      _ => BehavioralState.active,
    };
  }

  int _calculateStreak(List<Session> sessions) {
    final completed = sessions
        .where((session) => session.completedAt != null && !session.abandoned)
        .map((session) => _dateStr(session.completedAt!.toLocal()))
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

  String _dateStr(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
