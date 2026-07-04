import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';

@injectable
class SubmitSharedSessionResultUseCase {
  final LeaderboardRepository _repository;
  const SubmitSharedSessionResultUseCase(this._repository);

  /// No entitlement/behavioral-state guard here (AC3 — shared-session
  /// scoring awards unconditionally, protective-state or not; only the
  /// display-side rank freeze in Story 21.2 is state-aware).
  Future<void> call({
    required String sessionId,
    required int rpe,
    required String armKey,
    required int durationMinutes,
  }) async {
    await _repository.submitSharedSessionResult(
      sessionId: sessionId,
      rpe: rpe,
      armKey: armKey,
      durationMinutes: durationMinutes,
    );
  }
}
