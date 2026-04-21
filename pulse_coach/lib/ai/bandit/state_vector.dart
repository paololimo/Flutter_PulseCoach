import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

part 'state_vector.freezed.dart';
part 'state_vector.g.dart';

/// Derived from WeatherContext.aqiValue: high when aqiValue >= 100 (FR8).
/// 'low' covers all values < 100 (no outdoor restriction).
enum AqiLevel { low, high }

/// Immutable snapshot of all user signals fed to the AI engine.
///
/// Passed across Dart Isolate boundary via compute() — must be JSON serializable.
/// Source: sensor data (Stories 3.x), weather context (Stories 4.x),
///         RPE history (DB), user profile (onboarding).
///
/// [rpeHistory] holds the last N RPE values (1–10), most recent last.
///   - Empty list = new user, no sessions completed yet.
///   - Story 5.1 does NOT cap this list; the state machine reads it and
///     evaluates only the last 2–3 entries (Stories 5.2, 5.4).
///
/// [aqiLevel] is derived from [WeatherContext.isAqiHigh] at the use case layer.
/// [precipitation] is true when precipitationProbability > 50%.
@freezed
abstract class StateVector with _$StateVector {
  const factory StateVector({
    required double? restingHR,
    required int? stepCount,
    required ActivityLevel? activityLevel,
    required List<int> rpeHistory,
    required int missedSessions,
    required int streak,
    required AqiLevel aqiLevel,
    required double? temperature,
    required bool? precipitation,
    required UserProfile userProfile,
    required BehavioralState currentState,
  }) = _StateVector;

  factory StateVector.fromJson(Map<String, dynamic> json) =>
      _$StateVectorFromJson(json);
}
