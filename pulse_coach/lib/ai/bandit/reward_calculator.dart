import 'package:pulse_coach/ai/bandit/bandit_state.dart';

/// Computes reward signals for RPE-based bandit weight updates.
///
/// Target RPE ≈ 6.5 (FR22). Reward is 1.0 at target, declines linearly
/// to 0.0 at maximum deviation. RPE range: 1–10.
///
/// Arm weight update uses EMA: weight = (1 − α) × weight + α × reward.
/// Learning rate α = 0.1 is conservative — adapts over ~10 sessions.
/// Stateless — every call derives fresh values from inputs.
class RewardCalculator {
  const RewardCalculator();

  static const double _targetRpe = 6.5;

  /// Max deviation: max(|1 − 6.5|, |10 − 6.5|) = 5.5.
  static const double _maxDeviation = 5.5;

  static const double _defaultLearningRate = 0.1;

  /// Returns reward in [0.0, 1.0].
  /// reward = max(0, 1 − |rpe − 6.5| / 5.5)
  /// RPE is integer-valued (1–10), so max attainable reward is ≈0.909
  /// at RPE 6 or 7 — the theoretical 1.0 at RPE 6.5 is unreachable.
  /// RPE 1 → 0.0 · RPE 10 → ≈0.36
  double compute(int rpe) {
    assert(rpe >= 1 && rpe <= 10, 'RPE must be in [1,10], got $rpe');
    final deviation = (rpe - _targetRpe).abs();
    return (1.0 - deviation / _maxDeviation).clamp(0.0, 1.0);
  }

  /// Updates [armKey] weight via EMA; all other arms are unchanged.
  ///
  /// Returns new [BanditState] — does NOT mutate input (immutable).
  /// [armKey] must be one of [banditArmKeys]; unrecognised keys are a no-op.
  /// [learningRate] must be in [0,1].
  BanditState updateWeight(
    BanditState state,
    String armKey,
    int rpe, {
    double learningRate = _defaultLearningRate,
  }) {
    assert(
      learningRate >= 0.0 && learningRate <= 1.0,
      'learningRate must be in [0,1], got $learningRate',
    );
    if (!banditArmKeys.contains(armKey)) return state;

    final reward = compute(rpe);
    final updated = Map<String, double>.from(state.armWeights);
    final current = updated[armKey];
    assert(
      current != null,
      'Corrupt BanditState: armKey "$armKey" missing from armWeights',
    );
    assert(
      current == null || current.isFinite,
      'Corrupt BanditState: armWeights["$armKey"] is not finite ($current)',
    );
    final base = (current != null && current.isFinite) ? current : 1.0;
    updated[armKey] = (1.0 - learningRate) * base + learningRate * reward;

    return state.copyWith(
      armWeights: updated,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}
