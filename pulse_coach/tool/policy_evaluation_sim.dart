// Offline policy-evaluation simulation for the on-device bandit.
//
// PURPOSE
// -------
// The automated test campaign establishes the engine's *conformance* to spec,
// not the *efficacy* of the learned policy (design.tex, Section "Modelling scope
// and validity"). This standalone, deterministic harness supplies that evidence:
// it drives the REAL, unmodified engine classes (`BanditEngine`,
// `RewardCalculator`, `BanditState`) against a synthetic population and measures
// whether the epsilon-greedy learner produces sessions closer to the target RPE
// (6.5) than non-learning and fixed baselines — and whether two proposed
// extensions (annealed epsilon; per-behavioural-state value estimates) widen the
// advantage. It imports no Flutter and is NOT counted among the automated cases:
//
//     dart run tool/policy_evaluation_sim.dart          # default seed 42
//     dart run tool/policy_evaluation_sim.dart 123       # custom seed
//
// This is a CLI reporting tool, not production/UI code: printing to stdout is its
// entire purpose, so the repo-wide avoid_print lint is waived for this file.
// ignore_for_file: avoid_print
//
// SYNTHETIC GROUND TRUTH (clearly labelled — NOT product code)
// ------------------------------------------------------------
// Each user has a latent `fitnessShift`. Each session the user is in one of two
// load states — `normal` or `strained` — and a strained session makes every arm
// feel harder (perceived RPE shifts up). So the arm nearest the 6.5 target
// depends on BOTH the user (fitness) AND the session state:
//
//     meanRPE = intensityBase[intensity] + typeOffset[type]
//               - fitnessShift + (strained ? stateOffset : 0)
//     observedRPE = round(clamp(Normal(meanRPE, sigma), 1, 10))
//
// This arm x state interaction is exactly the reward-attribution confound noted
// in the design document: a single scalar weight per arm can only learn a
// state-AVERAGED value, whereas conditioning the estimate on the (observable)
// behavioural state can track the per-state optimum. The comparison below
// quantifies that gap. Common random numbers are used: for each (user, day) the
// load state and the observation noise are drawn ONCE and shared across all
// policies, so differences reflect the policies, not the luck of the draw.

import 'dart:math';

import 'package:pulse_coach/ai/bandit/bandit_state.dart';
import 'package:pulse_coach/ai/bandit/contextual_bandit.dart';
import 'package:pulse_coach/ai/bandit/reward_calculator.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';

// ─── Simulation parameters ──────────────────────────────────────────────────
const int numUsers = 500;
const int horizonDays = 60; // sessions per user
const int lateWindow = 15; // last-N days = the "converged" measurement window
const double sigma = 1.1; // RPE observation noise (std-dev)
const double goodBand = 1.5; // |RPE - 6.5| <= band counts as a "good" session
const double targetRpe = 6.5;
const double strainedProb = 0.35; // fraction of sessions in the strained state
const double stateOffset = 1.6; // extra perceived RPE when strained
const double tailThreshold = 1.5; // |fitnessShift| >= this = "atypical" user

// Annealed-epsilon schedule: eps_t = max(epsMin, eps0 / (1 + decay * day)).
const double eps0 = 0.2;
const double epsMin = 0.03;
const double epsDecay = 0.05; // 0.20 -> 0.10 (day 20) -> 0.05 (day 60)

// Synthetic ground-truth coefficients.
const Map<String, double> intensityBase = {'low': 4.0, 'medium': 6.5, 'high': 9.0};
const Map<String, double> typeOffset = {
  'cardio': 0.7,
  'mobility': 0.0,
  'breathing': -0.7,
};

const RewardCalculator reward = RewardCalculator();

// StateVector is required by selectSessions but unused for arm selection
// (see BanditEngine docs). One permissive fixture is reused everywhere.
const StateVector sv = StateVector(
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

// Permissive safety envelope: one session/day, all nine arms eligible. Safety is
// held constant on purpose — it clamps every policy identically, so holding it
// fixed isolates the learner (the variable under test).
const SafetyConstraints oneSession = SafetyConstraints(
  maxIntensity: null,
  maxSessionCount: 1,
  outdoorAllowed: true,
);

double epsilonAt(int day) => max(epsMin, eps0 / (1 + epsDecay * day));

double meanRpe(String armKey, double fitnessShift, bool strained) {
  final parts = armKey.split('_');
  return intensityBase[parts.last]! +
      typeOffset[parts.first]! -
      fitnessShift +
      (strained ? stateOffset : 0.0);
}

/// Observed integer RPE (1–10) given a pre-drawn standard-normal shock [z].
int observe(String armKey, double fitnessShift, bool strained, double z) {
  final raw = meanRpe(armKey, fitnessShift, strained) + sigma * z;
  return raw.round().clamp(1, 10);
}

String armKeyOf(String sessionType, int intensityValue) {
  final name = switch (intensityValue) {
    3 => 'low',
    6 => 'medium',
    8 => 'high',
    _ => throw StateError('unexpected intensity value $intensityValue'),
  };
  return '${sessionType}_$name';
}

/// Best achievable arm for a given user and session state (uses ground truth).
String oracleArm(double fitnessShift, bool strained) {
  return banditArmKeys.reduce((a, b) {
    final da = (meanRpe(a, fitnessShift, strained) - targetRpe).abs();
    final db = (meanRpe(b, fitnessShift, strained) - targetRpe).abs();
    return da <= db ? a : b;
  });
}

/// Standard-normal draw (Box–Muller) from a seeded RNG.
double gauss(Random rng) {
  final u1 = 1.0 - rng.nextDouble();
  final u2 = 1.0 - rng.nextDouble();
  return sqrt(-2.0 * log(u1)) * cos(2 * pi * u2);
}

class Acc {
  double sum = 0;
  int good = 0;
  int n = 0;
  void add(double r, int rpe) {
    sum += r;
    n += 1;
    if ((rpe - targetRpe).abs() <= goodBand) good += 1;
  }

  double get mean => n == 0 ? 0 : sum / n;
  double get goodPct => n == 0 ? 0 : 100 * good / n;
}

void main(List<String> args) {
  final seed = args.isNotEmpty ? int.parse(args.first) : 42;

  // Full-population accumulators (measured on the converged window).
  final fixed = Acc();
  final learner = Acc(); // shipped: eps=0.2 fixed, single state
  final annealed = Acc(); // eps annealed, single state
  final contextual = Acc(); // eps annealed + per-state value estimates
  final oracle = Acc();

  // Atypical-tail accumulators (|fitnessShift| >= threshold).
  final learnerTail = Acc();
  final contextualTail = Acc();
  final fixedTail = Acc();
  var tailUsers = 0;

  for (var u = 0; u < numUsers; u++) {
    // Per-user environment stream — shared by every policy (common random
    // numbers): same fitness, same load-state sequence, same noise shocks.
    final env = Random(seed * 7919 + u);
    final fitnessShift = -2.5 + 5.0 * env.nextDouble();
    final isTail = fitnessShift.abs() >= tailThreshold;
    if (isTail) tailUsers++;
    final strainedSeq = List<bool>.generate(horizonDays, (_) => env.nextDouble() < strainedProb);
    final zSeq = List<double>.generate(horizonDays, (_) => gauss(env));

    // Independent, reproducible exploration streams per policy.
    final rngLearner = Random(seed * 104729 + u * 97 + 1);
    final rngAnnealed = Random(seed * 104729 + u * 97 + 2);
    final rngContext = Random(seed * 104729 + u * 97 + 3);

    var learnerState = initialBanditState();
    var annealedState = initialBanditState();
    // Per-behavioural-state value estimates: one BanditState per load bucket.
    final contextStates = <bool, BanditState>{
      false: initialBanditState(),
      true: initialBanditState(),
    };

    for (var day = 0; day < horizonDays; day++) {
      final strained = strainedSeq[day];
      final z = zSeq[day];
      final late = day >= horizonDays - lateWindow;
      final epsT = epsilonAt(day);

      // 1) FIXED — always mobility_medium (a hand-tuned static policy).
      final fRpe = observe('mobility_medium', fitnessShift, strained, z);
      if (late) {
        fixed.add(reward.compute(fRpe), fRpe);
        if (isTail) fixedTail.add(reward.compute(fRpe), fRpe);
      }

      // 2) SHIPPED LEARNER — eps=0.2 fixed, single state-averaged model.
      //    One engine per day reusing the persistent rngLearner stream.
      final lEngine = BanditEngine(epsilon: 0.2, random: rngLearner);
      final lSel = lEngine.selectSessions(sv, oneSession, learnerState).first;
      final lArmKey = armKeyOf(lSel.sessionType, lSel.intensity);
      final lRpe = observe(lArmKey, fitnessShift, strained, z);
      if (late) {
        learner.add(reward.compute(lRpe), lRpe);
        if (isTail) learnerTail.add(reward.compute(lRpe), lRpe);
      }
      learnerState = lEngine.updateReward(learnerState, lArmKey, lRpe);

      // 3) ANNEALED — eps decays over time, still a single state-averaged model.
      final aEngine = BanditEngine(epsilon: epsT, random: rngAnnealed);
      final aSel = aEngine.selectSessions(sv, oneSession, annealedState).first;
      final aArmKey = armKeyOf(aSel.sessionType, aSel.intensity);
      final aRpe = observe(aArmKey, fitnessShift, strained, z);
      if (late) annealed.add(reward.compute(aRpe), aRpe);
      annealedState = aEngine.updateReward(annealedState, aArmKey, aRpe);

      // 4) CONTEXTUAL — annealed eps + a separate value model per load state
      //    (the behavioural-state analogue the app already computes).
      final cEngine = BanditEngine(epsilon: epsT, random: rngContext);
      final cState = contextStates[strained]!;
      final cSel = cEngine.selectSessions(sv, oneSession, cState).first;
      final cArmKey = armKeyOf(cSel.sessionType, cSel.intensity);
      final cRpe = observe(cArmKey, fitnessShift, strained, z);
      if (late) {
        contextual.add(reward.compute(cRpe), cRpe);
        if (isTail) contextualTail.add(reward.compute(cRpe), cRpe);
      }
      contextStates[strained] = cEngine.updateReward(cState, cArmKey, cRpe);

      // 5) ORACLE — best achievable arm for this (user, state). Upper bound.
      final oRpe = observe(oracleArm(fitnessShift, strained), fitnessShift, strained, z);
      if (late) oracle.add(reward.compute(oRpe), oRpe);
    }
  }

  // ─── Report ─────────────────────────────────────────────────────────────
  double gapClosed(Acc p) {
    final span = oracle.mean - fixed.mean;
    return span <= 0 ? 0 : 100 * (p.mean - fixed.mean) / span;
  }

  String row(String name, Acc a) =>
      '${name.padRight(26)} ${a.mean.toStringAsFixed(4)}     ${a.goodPct.toStringAsFixed(1)}%';

  print('PulseCoach — offline policy-evaluation simulation');
  print('seed=$seed  users=$numUsers  horizon=$horizonDays  '
      'converged-window=$lateWindow  sigma=$sigma  P(strained)=$strainedProb');
  print('reward = max(0, 1 - |RPE - 6.5| / 5.5)   (engine RewardCalculator)');
  print('measured on the converged window; common random numbers across policies');
  print('');
  print('policy                     mean_reward  good_band');
  print('-' * 50);
  print(row('fixed mobility_medium', fixed));
  print(row('shipped learner (eps=.2)', learner));
  print(row('  + annealed eps', annealed));
  print(row('  + annealed + per-state', contextual));
  print(row('oracle (upper bound)', oracle));
  print('-' * 50);
  print('vs fixed (avg):  shipped ${(100 * (learner.mean / fixed.mean - 1)).toStringAsFixed(1)}%'
      '   annealed ${(100 * (annealed.mean / fixed.mean - 1)).toStringAsFixed(1)}%'
      '   per-state ${(100 * (contextual.mean / fixed.mean - 1)).toStringAsFixed(1)}%');
  print('oracle gap closed:  shipped ${gapClosed(learner).toStringAsFixed(0)}%'
      '   annealed ${gapClosed(annealed).toStringAsFixed(0)}%'
      '   per-state ${gapClosed(contextual).toStringAsFixed(0)}%');
  print('');
  final tailPct = 100 * tailUsers / numUsers;
  print('atypical tail (|fitnessShift| >= $tailThreshold) — ${tailPct.toStringAsFixed(0)}% of users:');
  print('  fixed ${fixedTail.mean.toStringAsFixed(4)}   shipped ${learnerTail.mean.toStringAsFixed(4)}'
      '   per-state ${contextualTail.mean.toStringAsFixed(4)}');
}
