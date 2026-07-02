import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/entitlement_gate.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/scoring_constants.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';

@injectable
class AwardSessionPointsUseCase {
  final LeaderboardRepository _repository;
  final EntitlementGate _entitlementGate;

  AwardSessionPointsUseCase(this._repository, this._entitlementGate);

  /// No-op (never enqueues) for shared sessions, non-Pro users, or a
  /// zero/negative computed award — call sites do not need to pre-check
  /// these; this is the single guard point (AC5, AC6).
  Future<void> call({
    required int sessionLogId,
    required String armKey,
    required int durationMinutes,
  }) async {
    if (_entitlementGate.currentTier != SubscriptionTier.pro) return;
    final weight = ScoringConstants.intensityWeightFor(armKey);
    final basePoints = (durationMinutes * weight).round();
    if (basePoints <= 0) return;
    await _repository.awardSessionPoints(
      sessionLogId: sessionLogId,
      basePoints: basePoints,
      awardedOnUtc: DateTime.now().toUtc(),
    );
  }
}
