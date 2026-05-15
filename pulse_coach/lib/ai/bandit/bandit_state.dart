import 'package:freezed_annotation/freezed_annotation.dart';

part 'bandit_state.freezed.dart';
part 'bandit_state.g.dart';

/// Persisted learning state of the contextual bandit.
///
/// armWeights maps arm keys to exploration weights.
///   Arm key format: '{sessionType}_{intensity}' (e.g., 'mobility_low').
///   9 arms total: 3 session types × 3 intensity levels.
///   Initial value: all arms = 1.0 (uniform exploration, FR10).
///
/// Stored in bandit_state_table as JSON (armWeightsJson column).
/// updatedAt tracks last reward update for audit purposes.
@freezed
abstract class BanditState with _$BanditState {
  const factory BanditState({
    required Map<String, double> armWeights,
    required DateTime updatedAt,
  }) = _BanditState;

  factory BanditState.fromJson(Map<String, dynamic> json) =>
      _$BanditStateFromJson(json);
}

/// All 9 arm keys. Guarantees no typos when initializing or reading weights.
const banditArmKeys = [
  'mobility_low',
  'mobility_medium',
  'mobility_high',
  'cardio_low',
  'cardio_medium',
  'cardio_high',
  'breathing_low',
  'breathing_medium',
  'breathing_high',
];

/// Cold-start factory — all 9 arms at 1.0 (uniform exploration, FR10).
/// Enforces 9-arm invariant via banditArmKeys; can't drift out of sync.
///
/// updatedAt is set to UTC epoch (1970-01-01T00:00:00Z) as a sentinel
/// meaning "never updated". Consumers MUST treat this value specially:
///   - Do NOT render it as a real "last updated" date in the UI.
///   - Use `state.updatedAt.isAtSameMomentAs(DateTime.utc(1970))` to detect
///     cold-start, or check `state.updatedAt.year == 1970`.
/// All real updates use UTC timestamps (see `RewardCalculator.updateWeight`).
BanditState initialBanditState() => BanditState(
  armWeights: {for (final key in banditArmKeys) key: 1.0},
  updatedAt: DateTime.utc(1970),
);
