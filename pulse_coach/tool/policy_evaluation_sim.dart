// Offline policy-evaluation simulation for the on-device bandit.
//
// PURPOSE
// -------
// The automated test campaign establishes the engine's *conformance* to spec,
// not the *efficacy* of the learned policy (design.tex, Section 4.6 "Modelling
// scope and validity"). This standalone simulation supplies that missing
// evidence: it drives the REAL, unmodified engine classes (`BanditEngine`,
// `RewardCalculator`, `BanditState`) against a synthetic population of users and
// measures whether the ε-greedy learner produces sessions closer to the target
// RPE (6.5) than non-learning baselines — i.e. whether the learner earns its
// complexity.
//
// It is deterministic (single seeded Random threaded throughout) and imports no
// Flutter, so it runs outside the widget harness and is NOT counted among the
// automated test cases:
//
//     dart run tool/policy_evaluation_sim.dart          # default seed
//     dart run tool/policy_evaluation_sim.dart 123       # custom seed
//
// SYNTHETIC GROUND TRUTH (clearly labelled — this is NOT product code)
// -------------------------------------------------------------------
// Each simulated user has a latent `fitnessShift`. The perceived exertion of an
// arm (sessionType × intensity) is modelled as
//
//     meanRPE = intensityBase[intensity] + typeOffset[type] − fitnessShift
//     observedRPE = round(clamp(Normal(meanRPE, σ), 1, 10))
//
// Because `fitnessShift` varies per user, the arm whose mean RPE sits closest to
// the 6.5 target differs from user to user — so no single fixed policy can be
// optimal for everyone, and only an adaptive policy can track it. This is the
// exact condition under which learning should pay off.

// This is a standalone CLI reporting tool, not production/UI code: printing to
// stdout is its entire purpose, so the repo-wide avoid_print lint is waived here.
// ignore_for_file: avoid_print

import 'dart:math';

import 'package:pulse_coach/ai/bandit/bandit_state.dart';
import 'package:pulse_coach/ai/bandit/contextual_bandit.dart';
import 'package:pulse_coach/ai/bandit/reward_calculator.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

// ─── Simulation parameters ──────────────────────────────────────────────────
const int _numUsers = 500;
const int _horizonDays = 60; // sessions per user
const int _lateWindow = 15; // last-N days used for the "converged" metric
const double _sigma = 1.1; // RPE observation noise (std-dev)
const double _goodBand = 1.5; // |RPE − 6.5| ≤ band counts as a "good" session
const double _targetRpe = 6.5;

// Synthetic ground-truth coefficients.
const Map<String, double> _intensityBase = {'low': 4.0, 'medium': 6.5, 'high': 9.0};
const Map<String, double> _typeOffset = {
  'cardio': 0.7,
  'mobility': 0.0,
  'breathing': -0.7,
};

// The engine's reward function — reused, not re-implemented.
const RewardCalculator _reward = RewardCalculator();

// StateVector is required by selectSessions but unused for arm selection
// (see BanditEngine docs). One permissive fixture is reused everywhere.
const StateVector _sv = StateVector(
  restingHR: 65.0,
  stepCount: 4000,
  activityLevel: ActivityLevel.moderate,
  rpeHistory: [],
  missedSessions: 0,
  streak: 0,
  aqiLevel: AqiLevel.low,
  temperature: 20.0,
  precipitation: false,
  userProfile: UserProfile(
    fitnessLevel: 'medium',
    goal: 'cardio',
    availableTime: 'short',
    physicalConstraints: 'none',
  ),
  currentState: BehavioralState.active,
);

// Permissive safety envelope: exactly one session per day, all 9 arms eligible.
// Safety is held constant on purpose — it clamps every policy identically, so
// holding it fixed isolates the learner's contribution (the variable under test).
const SafetyConstraints _oneSession = SafetyConstraints(
  maxIntensity: null,
  maxSessionCount: 1,
  outdoorAllowed: true,
);

/// Synthetic mean perceived exertion for an arm, given a user's fitness shift.
double _meanRpe(String armKey, double fitnessShift) {
  final parts = armKey.split('_');
  final type = parts.first;
  final intensity = parts.last;
  return _intensityBase[intensity]! + _typeOffset[type]! - fitnessShift;
}

/// Draws one observed integer RPE (1–10) for an arm from the synthetic model.
int _sampleRpe(String armKey, double fitnessShift, Random rng) {
  final mean = _meanRpe(armKey, fitnessShift);
  // Box–Muller: standard normal from the seeded RNG (deterministic).
  final u1 = 1.0 - rng.nextDouble();
  final u2 = 1.0 - rng.nextDouble();
  final z = sqrt(-2.0 * log(u1)) * cos(2 * pi * u2);
  final raw = mean + _sigma * z;
  return raw.round().clamp(1, 10);
}

/// Reconstructs the arm key from a PlannedSession (intensity int → name).
String _armKeyOf(String sessionType, int intensityValue) {
  final name = switch (intensityValue) {
    3 => 'low',
    6 => 'medium',
    8 => 'high',
    _ => throw StateError('unexpected intensity value $intensityValue'),
  };
  return '${sessionType}_$name';
}

/// The best achievable per-user reward: pick the arm whose mean RPE is nearest
/// the target, every day. Upper bound (oracle) — uses ground truth directly.
String _oracleArm(double fitnessShift) {
  return banditArmKeys.reduce((a, b) {
    final da = (_meanRpe(a, fitnessShift) - _targetRpe).abs();
    final db = (_meanRpe(b, fitnessShift) - _targetRpe).abs();
    return da <= db ? a : b;
  });
}

class _Acc {
  double rewardSum = 0;
  double lateRewardSum = 0;
  int lateCount = 0;
  int good = 0;
  int n = 0;
  void add(double reward, int rpe, {required bool late}) {
    rewardSum += reward;
    n += 1;
    if ((rpe - _targetRpe).abs() <= _goodBand) good += 1;
    if (late) {
      lateRewardSum += reward;
      lateCount += 1;
    }
  }

  double get mean => n == 0 ? 0 : rewardSum / n;
  double get lateMean => lateCount == 0 ? 0 : lateRewardSum / lateCount;
  double get goodPct => n == 0 ? 0 : 100 * good / n;
}

void main(List<String> args) {
  final seed = args.isNotEmpty ? int.parse(args.first) : 42;
  final rng = Random(seed);

  // Whole-population accumulators.
  final learner = _Acc();
  final noLearn = _Acc(); // ε-greedy machinery, weights never updated
  final fixedSensible = _Acc(); // always mobility_medium (a hand-tuned static policy)
  final oracle = _Acc();

  // "Atypical tail" accumulators — users whose optimum is far from the
  // population centre (|fitnessShift| ≥ threshold), i.e. exactly the users a
  // single fixed policy serves badly and personalization is meant to help.
  const double tailThreshold = 1.5;
  final learnerTail = _Acc();
  final fixedTail = _Acc();
  final oracleTail = _Acc();
  var tailUsers = 0;

  for (var u = 0; u < _numUsers; u++) {
    // Heterogeneous population: fitnessShift ∈ [−2.5, 2.5], wide enough that the
    // arm nearest the 6.5 target spans low / medium / high across users — so no
    // single fixed intensity is optimal for everyone (the premise of adaptivity).
    final fitnessShift = -2.5 + 5.0 * rng.nextDouble();
    final isTail = fitnessShift.abs() >= tailThreshold;
    if (isTail) tailUsers++;
    final oracleArm = _oracleArm(fitnessShift);

    // Independent engines/state per user; all share the one seeded RNG so the
    // whole run is reproducible from `seed` alone.
    final learnEngine = BanditEngine(epsilon: 0.2, random: rng);
    final baseEngine = BanditEngine(epsilon: 0.2, random: rng);
    var learnState = initialBanditState();
    final baseState = initialBanditState(); // never updated

    for (var day = 0; day < _horizonDays; day++) {
      final late = day >= _horizonDays - _lateWindow;

      // 1) LEARNING bandit — select, observe, update weights.
      final lSel = learnEngine.selectSessions(_sv, _oneSession, learnState);
      final lArm = _armKeyOf(lSel.first.sessionType, lSel.first.intensity);
      final lRpe = _sampleRpe(lArm, fitnessShift, rng);
      learner.add(_reward.compute(lRpe), lRpe, late: late);
      if (isTail && late) learnerTail.add(_reward.compute(lRpe), lRpe, late: late);
      learnState = learnEngine.updateReward(learnState, lArm, lRpe);

      // 2) NO-LEARNING bandit — identical selection code, weights frozen.
      final bSel = baseEngine.selectSessions(_sv, _oneSession, baseState);
      final bArm = _armKeyOf(bSel.first.sessionType, bSel.first.intensity);
      final bRpe = _sampleRpe(bArm, fitnessShift, rng);
      noLearn.add(_reward.compute(bRpe), bRpe, late: late);

      // 3) FIXED-SENSIBLE — a static policy a designer might ship instead.
      final fRpe = _sampleRpe('mobility_medium', fitnessShift, rng);
      fixedSensible.add(_reward.compute(fRpe), fRpe, late: late);
      if (isTail && late) fixedTail.add(_reward.compute(fRpe), fRpe, late: late);

      // 4) ORACLE — best achievable, upper bound.
      final oRpe = _sampleRpe(oracleArm, fitnessShift, rng);
      oracle.add(_reward.compute(oRpe), oRpe, late: late);
      if (isTail && late) oracleTail.add(_reward.compute(oRpe), oRpe, late: late);
    }
  }

  // ─── Report ───────────────────────────────────────────────────────────────
  final gapTotal = oracle.mean - noLearn.mean;
  final gapClosedAll = gapTotal <= 0 ? 0 : 100 * (learner.mean - noLearn.mean) / gapTotal;
  final gapClosedLate =
      gapTotal <= 0 ? 0 : 100 * (learner.lateMean - noLearn.mean) / gapTotal;

  String row(String name, _Acc a) =>
      '${name.padRight(22)}  ${a.mean.toStringAsFixed(4)}      '
      '${a.lateMean.toStringAsFixed(4)}       ${a.goodPct.toStringAsFixed(1)}%';

  const total = _numUsers * _horizonDays;
  print('PulseCoach — offline policy-evaluation simulation');
  print('seed=$seed  users=$_numUsers  horizon=$_horizonDays days  '
      'decisions=$total  σ=$_sigma');
  print('reward = max(0, 1 − |RPE − 6.5| / 5.5)  (engine RewardCalculator)');
  print('');
  print('policy                  mean_reward  late_reward   good_band');
  print('-' * 62);
  print(row('learning bandit', learner));
  print(row('no-learning (frozen)', noLearn));
  print(row('fixed mobility_medium', fixedSensible));
  print(row('oracle (upper bound)', oracle));
  print('-' * 62);
  print('learner uplift vs no-learning : '
      '${(100 * (learner.mean / noLearn.mean - 1)).toStringAsFixed(1)}% overall, '
      '${(100 * (learner.lateMean / noLearn.mean - 1)).toStringAsFixed(1)}% once converged');
  print('oracle gap closed by learner  : '
      '${gapClosedAll.toStringAsFixed(1)}% overall, '
      '${gapClosedLate.toStringAsFixed(1)}% once converged');
  print('');
  final tailPct = 100 * tailUsers / _numUsers;
  print('── atypical tail (|fitnessShift| ≥ 1.5, converged window) '
      '— ${tailPct.toStringAsFixed(0)}% of users ──');
  print('  learning bandit      ${learnerTail.mean.toStringAsFixed(4)}   good ${learnerTail.goodPct.toStringAsFixed(1)}%');
  print('  fixed mobility_medium ${fixedTail.mean.toStringAsFixed(4)}   good ${fixedTail.goodPct.toStringAsFixed(1)}%');
  print('  oracle               ${oracleTail.mean.toStringAsFixed(4)}   good ${oracleTail.goodPct.toStringAsFixed(1)}%');
  print('  learner vs best fixed on the tail : '
      '${(100 * (learnerTail.mean / fixedTail.mean - 1)).toStringAsFixed(1)}%');
}
