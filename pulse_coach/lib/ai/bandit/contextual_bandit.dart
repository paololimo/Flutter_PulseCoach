import 'dart:math';
import 'package:pulse_coach/ai/bandit/bandit_state.dart';
import 'package:pulse_coach/ai/bandit/reward_calculator.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

/// Epsilon-greedy contextual bandit for session selection.
///
/// Arms: 9 = 3 session types (mobility, cardio, breathing) × 3 intensities
/// (low, medium, high). Arm key format: '{sessionType}_{intensity}'.
///
/// Algorithm:
///   - With probability [epsilon]: explore (random arm from eligible set).
///   - With probability 1 − [epsilon]: exploit (highest-weight eligible arm).
/// Selection is without replacement (no duplicate sessionType×intensity per plan).
///
/// Safety contract: [selectSessions] never returns arms excluded by
/// [SafetyConstraints]. The bandit cannot override the safety layer. (FR9)
///
/// Stateless w.r.t. learning — pass in [BanditState] from DB (Story 5.5).
/// The caller (GenerateDailyPlan use case) is responsible for persisting
/// the updated state from [updateReward].
///
/// ARCH7: No Flutter imports. Runs safely in a Dart Isolate via compute().
class BanditEngine {
  final Random _random;

  /// Exploration rate. 0.0 = pure exploit. 1.0 = pure explore.
  /// Default 0.2 — moderate exploration for new users.
  /// Story 5.5 may pass a decayed epsilon based on session count.
  final double epsilon;

  final RewardCalculator _rewardCalc;

  BanditEngine({
    Random? random,
    this.epsilon = 0.2,
    RewardCalculator? rewardCalculator,
  }) : assert(
         epsilon >= 0.0 && epsilon <= 1.0 && !epsilon.isNaN,
         'epsilon must be in [0,1], got $epsilon',
       ),
       _random = random ?? Random(),
       _rewardCalc = rewardCalculator ?? const RewardCalculator();

  /// Selects up to constraints.maxSessionCount sessions.
  ///
  /// Filters arms by [constraints] (maxIntensity, outdoorAllowed) BEFORE
  /// applying epsilon-greedy selection — no safety constraint can be violated.
  ///
  /// [stateVector] is accepted for forward compatibility (contextual features
  /// in a future story). It is NOT used for arm selection in Story 5.4.
  ///
  /// Returns empty list only when NO eligible arms exist after filtering.
  List<PlannedSession> selectSessions(
    StateVector stateVector,
    SafetyConstraints constraints,
    BanditState state,
  ) {
    final eligible = _eligibleArms(constraints, state.armWeights);
    if (eligible.isEmpty) return [];

    final count = constraints.maxSessionCount.clamp(0, eligible.length);
    final remaining = List<String>.from(eligible.keys);
    final selected = <String>[];

    for (var i = 0; i < count && remaining.isNotEmpty; i++) {
      final arm = _random.nextDouble() < epsilon
          ? remaining[_random.nextInt(remaining.length)]
          : _exploit(remaining, eligible);
      selected.add(arm);
      remaining.remove(arm);
    }

    return selected.map((arm) => _toPlannedSession(arm, constraints)).toList();
  }

  /// Updates arm weight after a session; delegates to [RewardCalculator].
  ///
  /// Returns updated [BanditState] — immutable, caller must persist it.
  /// Bandit weights are NOT reset on state machine transitions (FR25) —
  /// the caller simply re-passes the same accumulated [BanditState].
  BanditState updateReward(BanditState state, String armKey, int rpe) {
    return _rewardCalc.updateWeight(state, armKey, rpe);
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  /// Returns arm keys and their weights that pass [constraints].
  Map<String, double> _eligibleArms(
    SafetyConstraints constraints,
    Map<String, double> weights,
  ) {
    final result = <String, double>{};
    for (final key in banditArmKeys) {
      final intensityName = key.split('_').last; // 'low' | 'medium' | 'high'
      if (constraints.maxIntensity != null) {
        if (_intensityRankByName(intensityName) >
            _intensityRank(constraints.maxIntensity!)) {
          continue;
        }
      }
      final w = weights[key];
      assert(
        w != null && w.isFinite,
        'Corrupt BanditState: armWeights["$key"] missing or non-finite ($w)',
      );
      result[key] = (w != null && w.isFinite) ? w : 1.0;
    }
    return result;
  }

  /// Pure-exploit pick: highest weight; alphabetical tiebreak for determinism.
  /// Uses strict `>` so equal weights fall through to the alphabetical branch
  /// (with `>=` the tiebreak was dead code — accumulator always won).
  String _exploit(List<String> candidates, Map<String, double> weights) {
    return candidates.reduce((a, b) {
      final wa = weights[a]!;
      final wb = weights[b]!;
      if (wa > wb) return a;
      if (wb > wa) return b;
      return a.compareTo(b) <= 0 ? a : b; // stable alphabetical tiebreak
    });
  }

  PlannedSession _toPlannedSession(
    String armKey,
    SafetyConstraints constraints,
  ) {
    final parts = armKey.split('_');
    final sessionType = parts.first; // 'mobility' | 'cardio' | 'breathing'
    final intensityName = parts.last;

    // NOTE: `isIndoor` is a placeholder derived from the constraint flag, not
    // the session's intrinsic nature. Story 6.x exercise catalog will own
    // indoor/outdoor semantics per session type. See deferred-work.md.
    return PlannedSession(
      sessionType: sessionType,
      intensity: _intensityValue(intensityName),
      durationMinutes:
          10, // Placeholder — Story 6.x populates from exercise catalog
      isIndoor: !constraints.outdoorAllowed,
    );
  }

  int _intensityRank(SessionIntensity i) => switch (i) {
    SessionIntensity.low => 0,
    SessionIntensity.medium => 1,
    SessionIntensity.high => 2,
  };

  int _intensityRankByName(String name) => switch (name) {
    'low' => 0,
    'medium' => 1,
    'high' => 2,
    _ => throw ArgumentError('Unknown intensity name: "$name"'),
  };

  /// Maps arm intensity name to the PlannedSession intensity int value.
  /// Ranges: low=1–3 (→3), medium=4–7 (→6), high=8–10 (→8). (safety_constraints.dart)
  int _intensityValue(String name) => switch (name) {
    'low' => 3,
    'medium' => 6,
    'high' => 8,
    _ => throw ArgumentError('Unknown intensity name: "$name"'),
  };
}
