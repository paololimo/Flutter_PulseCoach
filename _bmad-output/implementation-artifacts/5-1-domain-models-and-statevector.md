# Story 5.1: Domain Models & StateVector

Status: done

## Story

As a developer,
I want all AI engine domain models defined as pure Dart `@freezed` classes,
So that the AI engine and all its inputs/outputs are immutable, serializable, and testable without the Flutter framework.

## Acceptance Criteria

**Given** the domain model files exist at their designated locations
**When** `build_runner` runs
**Then** `StateVector`, `DailyPlan`, `PlannedSession`, `Explanation`, `BehavioralState` (enum), `BanditState`, and `SafetyConstraints` are generated as immutable `@freezed` classes.

**Given** `StateVector` is defined
**When** inspected
**Then** it contains exactly: `restingHR` (nullable double), `stepCount` (nullable int), `activityLevel` (nullable `ActivityLevel`), `rpeHistory` (List<int>, last 5 — can be empty), `missedSessions` (int, default 0), `streak` (int, default 0), `aqiLevel` (`AqiLevel` enum), `temperature` (nullable double), `precipitation` (nullable bool), `userProfile` (UserProfile), `currentState` (BehavioralState).

**Given** all domain model and AI layer files are implemented
**When** `dart analyze lib/ai/ lib/features/daily_plan/domain/entities/` is run
**Then** zero Flutter framework imports (`package:flutter/...`) are detected in any analyzed file (ARCH7).

**Given** `UserProfile` needs to be serializable for isolate communication
**When** `StateVector.toJson()` is called
**Then** `UserProfile` is included as a nested JSON map (requires adding `fromJson`/`toJson` to `UserProfile`).

## Tasks / Subtasks

### Task 0: Update `UserProfile` for JSON serialization

- [x] 0.1 Add `@JsonSerializable()` + `fromJson`/`toJson` to existing `lib/features/onboarding/domain/entities/user_profile.dart`:
  ```dart
  import 'package:json_annotation/json_annotation.dart';

  part 'user_profile.g.dart';

  @JsonSerializable()
  class UserProfile {
    final String fitnessLevel;        // 'low' | 'medium'
    final String goal;                // 'cardio' | 'strength' | 'mobility' | 'wellbeing'
    final String availableTime;       // 'short' | 'long'
    final String physicalConstraints; // 'none' | 'knee' | 'back' | 'indoor'

    const UserProfile({
      required this.fitnessLevel,
      required this.goal,
      required this.availableTime,
      required this.physicalConstraints,
    });

    factory UserProfile.fromJson(Map<String, dynamic> json) =>
        _$UserProfileFromJson(json);
    Map<String, dynamic> toJson() => _$UserProfileToJson(this);
  }
  ```
- [x] **This change is backward-compatible** — `UserProfile`'s constructor signature and field types are unchanged. Existing code that creates `UserProfile(fitnessLevel: ..., ...)` continues to compile with no modifications.
- [x] **Do NOT convert `UserProfile` to `@freezed`** — too many callers reference it; the JSON-only approach is sufficient for isolate communication and has minimal blast radius.

---

### Task 1: Create `BehavioralState` enum

- [x] 1.1 Create `lib/ai/state_machine/behavioral_state.dart`:
  ```dart
  /// Categorical user state derived by the BehavioralStateMachine (Story 5.2).
  ///
  /// Transitions (Story 5.2):
  ///   active → fatigued  : RPE avg > 8 for last 2 sessions (FR23)
  ///   fatigued → atRisk  : missedSessions >= 2 (FR23)
  ///   atRisk/fatigued → recovering : 2 consecutive sessions, RPE ≤ 7 (FR23)
  ///   recovering → active : 3 sessions, RPE avg ≤ 6.5, streak ≥ 3 (FR23)
  enum BehavioralState { active, fatigued, atRisk, recovering }
  ```
- [x] **No Flutter imports** — pure Dart enum in `lib/ai/`.

---

### Task 2: Create `AqiLevel` enum and `StateVector`

- [x] 2.1 Create `lib/ai/bandit/state_vector.dart`:
  ```dart
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
  class StateVector with _$StateVector {
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
  ```
- [x] **Import chain is pure Dart** — `ActivityLevel` (existing enum), `BehavioralState` (new enum), `UserProfile` (plain class + `@JsonSerializable`) — none of these import Flutter.
- [x] **`AqiLevel` is defined in this file** (co-located with its primary consumer). No separate file needed.

---

### Task 3: Create `BanditState`

- [x] 3.1 Create `lib/ai/bandit/bandit_state.dart`:
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'bandit_state.freezed.dart';
  part 'bandit_state.g.dart';

  /// Persisted learning state of the contextual bandit.
  ///
  /// [armWeights] maps arm keys to exploration weights.
  ///   Arm key format: '{sessionType}_{intensity}' (e.g., 'mobility_low').
  ///   9 arms total: 3 session types × 3 intensity levels.
  ///   Initial value: all arms = 1.0 (uniform exploration, FR10).
  ///
  /// Stored in [bandit_state_table] as JSON (armWeightsJson column).
  /// [updatedAt] tracks last reward update for audit purposes.
  @freezed
  class BanditState with _$BanditState {
    const factory BanditState({
      required Map<String, double> armWeights,
      required DateTime updatedAt,
    }) = _BanditState;

    factory BanditState.fromJson(Map<String, dynamic> json) =>
        _$BanditStateFromJson(json);
  }

  /// All 9 arm keys. Guarantees no typos when initializing or reading weights.
  const banditArmKeys = [
    'mobility_low', 'mobility_medium', 'mobility_high',
    'cardio_low',   'cardio_medium',   'cardio_high',
    'breathing_low','breathing_medium','breathing_high',
  ];
  ```
- [x] **`banditArmKeys` constant** — prevents arm key typos across Stories 5.4 (reward update) and 5.5 (session selection). Defined here so all bandit code imports from one place.

---

### Task 4: Create `SafetyConstraints`

- [x] 4.1 Create `lib/ai/safety/safety_constraints.dart`:
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'safety_constraints.freezed.dart';
  part 'safety_constraints.g.dart';

  /// Categorical session intensity for safety filtering.
  /// Maps to the DB `intensity` int column (1–10):
  ///   low = 1–3, medium = 4–7, high = 8–10 (Story 5.3 enforces the mapping).
  enum SessionIntensity { low, medium, high }

  /// Output of the SafetyRules engine (Story 5.3).
  ///
  /// [maxIntensity] null = no intensity restriction (normal state).
  /// [maxSessionCount] capped at 2 when state is AtRisk/Recovering (FR24).
  /// [outdoorAllowed] false when AQI >= 100 (FR8).
  ///
  /// Passed to BanditEngine.selectSessions() (Story 5.4) to filter candidates.
  @freezed
  class SafetyConstraints with _$SafetyConstraints {
    const factory SafetyConstraints({
      required SessionIntensity? maxIntensity,
      required int maxSessionCount,
      required bool outdoorAllowed,
    }) = _SafetyConstraints;

    factory SafetyConstraints.fromJson(Map<String, dynamic> json) =>
        _$SafetyConstraintsFromJson(json);
  }

  /// No restrictions — used as baseline when user state is Active and AQI is low.
  const SafetyConstraints noConstraints = SafetyConstraints(
    maxIntensity: null,
    maxSessionCount: 3,
    outdoorAllowed: true,
  );
  ```
- [x] **`noConstraints` constant** — used by Story 5.5's GenerateDailyPlan use case and Story 5.3 tests as the "no restriction" baseline.

---

### Task 5: Create `DailyPlan`, `PlannedSession`, `Explanation`

- [x] 5.1 Create `lib/features/daily_plan/domain/entities/explanation.dart`:
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'explanation.freezed.dart';
  part 'explanation.g.dart';

  /// One-line AI-generated explanation for a single session recommendation.
  ///
  /// [sessionIndex] = position in DailyPlan.sessions (0-based).
  /// [text] = human-readable reason (e.g., "Short sleep + elevated HR. Starting gentle.").
  ///   Always non-null and non-empty — guaranteed by ExplanationGenerator (Story 5.6).
  ///
  /// Output of ExplanationGenerator; merged into PlannedSession.explanation by
  /// DailyPlanGenerationPipeline (Story 5.5).
  @freezed
  class Explanation with _$Explanation {
    const factory Explanation({
      required int sessionIndex,
      required String text,
    }) = _Explanation;

    factory Explanation.fromJson(Map<String, dynamic> json) =>
        _$ExplanationFromJson(json);
  }
  ```

- [x] 5.2 Create `lib/features/daily_plan/domain/entities/planned_session.dart`:
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'planned_session.freezed.dart';
  part 'planned_session.g.dart';

  /// A single session within a DailyPlan, selected by the bandit engine.
  ///
  /// [sessionType]: 'mobility' | 'cardio' | 'breathing' — matches Sessions DB table.
  /// [intensity]:   1–10 — maps to SessionIntensity enum for safety rule checking.
  /// [durationMinutes]: from exercise catalog (populated in Story 6.x).
  /// [isIndoor]:    true when SafetyConstraints.outdoorAllowed = false, or
  ///                user physicalConstraints = 'indoor'.
  /// [explanation]: generated by ExplanationGenerator (Story 5.6).
  ///   Empty string '' is the placeholder — Story 5.6 guarantees non-empty on write.
  @freezed
  class PlannedSession with _$PlannedSession {
    const factory PlannedSession({
      required String sessionType,
      required int intensity,
      required int durationMinutes,
      required bool isIndoor,
      @Default('') String explanation,
    }) = _PlannedSession;

    factory PlannedSession.fromJson(Map<String, dynamic> json) =>
        _$PlannedSessionFromJson(json);
  }
  ```

- [x] 5.3 Create `lib/features/daily_plan/domain/entities/daily_plan.dart`:
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';
  import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

  part 'daily_plan.freezed.dart';
  part 'daily_plan.g.dart';

  /// The AI-generated plan for a single calendar day.
  ///
  /// [planDate]: 'YYYY-MM-DD' — matches daily_plans_table.planDate (unique key).
  /// [sessions]: 1–3 sessions. Count is constrained by SafetyConstraints.maxSessionCount.
  /// [generatedAt]: isolate completion timestamp. Used with daily_plans_table.generatedAt.
  ///
  /// Serialized as JSON → stored in daily_plans_table.planJson column.
  @freezed
  class DailyPlan with _$DailyPlan {
    const factory DailyPlan({
      required String planDate,
      required List<PlannedSession> sessions,
      required DateTime generatedAt,
    }) = _DailyPlan;

    factory DailyPlan.fromJson(Map<String, dynamic> json) =>
        _$DailyPlanFromJson(json);
  }
  ```

---

### Task 6: Run `build_runner`

- [x] 6.1 Run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
- [x] 6.2 Verify generated files exist:
  - `lib/features/onboarding/domain/entities/user_profile.g.dart`
  - `lib/ai/bandit/state_vector.freezed.dart` + `state_vector.g.dart`
  - `lib/ai/bandit/bandit_state.freezed.dart` + `bandit_state.g.dart`
  - `lib/ai/safety/safety_constraints.freezed.dart` + `safety_constraints.g.dart`
  - `lib/features/daily_plan/domain/entities/explanation.freezed.dart` + `explanation.g.dart`
  - `lib/features/daily_plan/domain/entities/planned_session.freezed.dart` + `planned_session.g.dart`
  - `lib/features/daily_plan/domain/entities/daily_plan.freezed.dart` + `daily_plan.g.dart`
- [x] 6.3 Run `dart analyze` — zero issues expected.
- [x] **Do NOT manually edit generated files** — `*.freezed.dart` and `*.g.dart` are fully auto-generated.

---

### Task 7: Write unit tests

- [x] 7.1 Create `test/domain/ai/domain_models_test.dart`:

```dart
// Domain Model Tests — Story 5.1
// Tests: equality, copyWith, JSON round-trips, edge cases, no Flutter imports
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/ai/bandit/bandit_state.dart';
import 'package:pulse_coach/ai/bandit/state_vector.dart';
import 'package:pulse_coach/ai/safety/safety_constraints.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/explanation.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

/// Shared test fixture — used across multiple tests to avoid repetition.
StateVector _makeStateVector({
  List<int> rpeHistory = const [],
  BehavioralState currentState = BehavioralState.active,
  AqiLevel aqiLevel = AqiLevel.low,
}) =>
    StateVector(
      restingHR: 62.0,
      stepCount: 4500,
      activityLevel: ActivityLevel.moderate,
      rpeHistory: rpeHistory,
      missedSessions: 0,
      streak: 3,
      aqiLevel: aqiLevel,
      temperature: 21.0,
      precipitation: false,
      userProfile: const UserProfile(
        fitnessLevel: 'medium',
        goal: 'cardio',
        availableTime: 'short',
        physicalConstraints: 'none',
      ),
      currentState: currentState,
    );

void main() {
  group('BehavioralState', () {
    test('5.1-UNIT-001: has all four required values', () {
      expect(BehavioralState.values, containsAll([
        BehavioralState.active,
        BehavioralState.fatigued,
        BehavioralState.atRisk,
        BehavioralState.recovering,
      ]));
    });
  });

  group('AqiLevel', () {
    test('5.1-UNIT-002: has low and high values', () {
      expect(AqiLevel.values, containsAll([AqiLevel.low, AqiLevel.high]));
    });
  });

  group('StateVector', () {
    test('5.1-UNIT-003: equality — two identical StateVectors are equal', () {
      final a = _makeStateVector();
      final b = _makeStateVector();
      expect(a, equals(b));
    });

    test('5.1-UNIT-004: copyWith — mutating one field does not affect others', () {
      final original = _makeStateVector(streak: 3);
      final updated = original.copyWith(streak: 7);
      expect(updated.streak, equals(7));
      expect(updated.restingHR, equals(original.restingHR));
      expect(updated.rpeHistory, equals(original.rpeHistory));
    });

    test('5.1-UNIT-005: empty rpeHistory is valid — new user, no sessions yet', () {
      final sv = _makeStateVector(rpeHistory: []);
      expect(sv.rpeHistory, isEmpty);
    });

    test('5.1-UNIT-006: nullable fields accept null values', () {
      final sv = StateVector(
        restingHR: null,
        stepCount: null,
        activityLevel: null,
        rpeHistory: const [],
        missedSessions: 0,
        streak: 0,
        aqiLevel: AqiLevel.low,
        temperature: null,
        precipitation: null,
        userProfile: const UserProfile(
          fitnessLevel: 'low',
          goal: 'wellbeing',
          availableTime: 'long',
          physicalConstraints: 'indoor',
        ),
        currentState: BehavioralState.active,
      );
      expect(sv.restingHR, isNull);
      expect(sv.stepCount, isNull);
      expect(sv.activityLevel, isNull);
    });

    test('5.1-UNIT-007: JSON round-trip — all fields survive serialization', () {
      final original = _makeStateVector(
        rpeHistory: [7, 6, 8],
        currentState: BehavioralState.recovering,
        aqiLevel: AqiLevel.high,
      );
      final json = original.toJson();
      final restored = StateVector.fromJson(json);
      expect(restored, equals(original));
    });
  });

  group('BanditState', () {
    test('5.1-UNIT-008: JSON round-trip — arm weights map preserved', () {
      final state = BanditState(
        armWeights: {for (final k in banditArmKeys) k: 1.0},
        updatedAt: DateTime(2026, 4, 12),
      );
      final restored = BanditState.fromJson(state.toJson());
      expect(restored.armWeights, equals(state.armWeights));
      expect(restored.updatedAt, equals(state.updatedAt));
    });

    test('5.1-UNIT-009: banditArmKeys has exactly 9 entries', () {
      expect(banditArmKeys, hasLength(9));
      expect(banditArmKeys, contains('mobility_low'));
      expect(banditArmKeys, contains('breathing_high'));
    });

    test('5.1-UNIT-010: copyWith — updatedAt change preserves weights', () {
      final original = BanditState(
        armWeights: {'mobility_low': 1.5, 'cardio_medium': 0.8},
        updatedAt: DateTime(2026, 1, 1),
      );
      final updated = original.copyWith(updatedAt: DateTime(2026, 4, 12));
      expect(updated.armWeights, equals(original.armWeights));
      expect(updated.updatedAt, equals(DateTime(2026, 4, 12)));
    });
  });

  group('SafetyConstraints', () {
    test('5.1-UNIT-011: noConstraints — null maxIntensity, outdoorAllowed true', () {
      expect(noConstraints.maxIntensity, isNull);
      expect(noConstraints.outdoorAllowed, isTrue);
      expect(noConstraints.maxSessionCount, equals(3));
    });

    test('5.1-UNIT-012: JSON round-trip — null maxIntensity handled correctly', () {
      const sc = SafetyConstraints(
        maxIntensity: null,
        maxSessionCount: 3,
        outdoorAllowed: true,
      );
      final restored = SafetyConstraints.fromJson(sc.toJson());
      expect(restored.maxIntensity, isNull);
      expect(restored.outdoorAllowed, isTrue);
    });

    test('5.1-UNIT-013: maxIntensity low — survives JSON round-trip', () {
      const sc = SafetyConstraints(
        maxIntensity: SessionIntensity.low,
        maxSessionCount: 2,
        outdoorAllowed: false,
      );
      final restored = SafetyConstraints.fromJson(sc.toJson());
      expect(restored.maxIntensity, equals(SessionIntensity.low));
      expect(restored.maxSessionCount, equals(2));
      expect(restored.outdoorAllowed, isFalse);
    });
  });

  group('DailyPlan and PlannedSession', () {
    test('5.1-UNIT-014: DailyPlan JSON round-trip — nested sessions preserved', () {
      final plan = DailyPlan(
        planDate: '2026-04-12',
        sessions: [
          const PlannedSession(
            sessionType: 'mobility',
            intensity: 3,
            durationMinutes: 20,
            isIndoor: false,
          ),
          const PlannedSession(
            sessionType: 'breathing',
            intensity: 2,
            durationMinutes: 10,
            isIndoor: true,
            explanation: 'Recovery day. Light breathing session.',
          ),
        ],
        generatedAt: DateTime(2026, 4, 12, 8, 0),
      );
      final restored = DailyPlan.fromJson(plan.toJson());
      expect(restored.planDate, equals('2026-04-12'));
      expect(restored.sessions, hasLength(2));
      expect(restored.sessions[1].explanation,
          equals('Recovery day. Light breathing session.'));
    });

    test('5.1-UNIT-015: PlannedSession explanation defaults to empty string', () {
      const session = PlannedSession(
        sessionType: 'cardio',
        intensity: 5,
        durationMinutes: 30,
        isIndoor: false,
      );
      expect(session.explanation, equals(''));
    });
  });

  group('Explanation', () {
    test('5.1-UNIT-016: JSON round-trip — sessionIndex and text preserved', () {
      const ex = Explanation(sessionIndex: 0, text: 'High steps today. Cardio session.');
      final restored = Explanation.fromJson(ex.toJson());
      expect(restored.sessionIndex, equals(0));
      expect(restored.text, equals('High steps today. Cardio session.'));
    });
  });
}
```

- [x] 7.2 Run `flutter test test/domain/ai/domain_models_test.dart` — all 16 tests must pass.
- [x] 7.3 Run `flutter test` — **all tests** must pass. Starting count: **181 tests**; target: **~197 tests** (+16).

---

## Dev Notes

### Architecture: File Placement Rationale

The architecture explicitly separates AI layer files from feature domain entities:

| Model | File | Rationale |
|---|---|---|
| `BehavioralState` | `lib/ai/state_machine/behavioral_state.dart` | Consumed by state machine algorithm (Story 5.2) |
| `AqiLevel` | `lib/ai/bandit/state_vector.dart` (co-located) | Derived field for StateVector; no standalone need |
| `StateVector` | `lib/ai/bandit/state_vector.dart` | AI engine INPUT — lives with bandit code (architecture explicit) |
| `BanditState` | `lib/ai/bandit/bandit_state.dart` | AI engine INTERNAL STATE |
| `SafetyConstraints` | `lib/ai/safety/safety_constraints.dart` | AI engine OUTPUT constraint (Story 5.3) |
| `SessionIntensity` | `lib/ai/safety/safety_constraints.dart` (co-located) | Only used by SafetyConstraints |
| `DailyPlan` | `lib/features/daily_plan/domain/entities/daily_plan.dart` | Feature domain entity (UI-facing) |
| `PlannedSession` | `lib/features/daily_plan/domain/entities/planned_session.dart` | Feature domain entity (UI-facing) |
| `Explanation` | `lib/features/daily_plan/domain/entities/explanation.dart` | Feature domain entity (UI-facing) |

**Note on AC wording:** The epic's AC says "in `lib/features/daily_plan/domain/entities/`" — this refers to `DailyPlan`, `PlannedSession`, and `Explanation` which ARE there. The AI-layer models (`StateVector`, `BanditState`, `BehavioralState`, `SafetyConstraints`) follow the architecture's `lib/ai/` placement because they are inputs/internals of the AI engine, not user-facing entities.

**Empty folder:** `lib/features/daily_plan/domain/ai/` was created during project setup but is NOT referenced in the architecture. Leave it empty — it may be used in future stories or cleaned up at epic close.

### `lib/ai/` Folder — Does Not Exist Yet

Create the folder hierarchy by creating files within it:
```
pulse_coach/lib/ai/
├── bandit/
│   ├── state_vector.dart         ← Task 2
│   └── bandit_state.dart         ← Task 3
├── state_machine/
│   └── behavioral_state.dart     ← Task 1
└── safety/
    └── safety_constraints.dart   ← Task 4
```

Dart/Flutter does not require empty `__init__` files — just create the `.dart` files in the correct directories.

### `UserProfile` Refactor — Minimal Impact

`UserProfile` already uses `const UserProfile(...)` constructor everywhere. Adding `@JsonSerializable()` + `fromJson`/`toJson` + the `part` directive changes the file but does NOT change:
- The class name
- The constructor signature
- The field names or types
- The `const` keyword

All existing callers continue to compile. The only new requirement is that `build_runner` generates `user_profile.g.dart`.

### `@freezed` and Enum Serialization

`json_serializable` (used by freezed) serializes enums by **name** by default:
- `BehavioralState.atRisk` → `"atRisk"` in JSON
- `AqiLevel.high` → `"high"` in JSON
- `SessionIntensity.low` → `"low"` in JSON

**Do NOT add `@JsonEnum(fieldRename: FieldRename.snake)` or custom values** — the default name-based serialization is correct and consistent with the existing codebase.

### `@Default('')` on `PlannedSession.explanation`

Using `@Default('')` (from `freezed_annotation`) provides a sensible default for `explanation`. This allows `PlannedSession` to be constructed without specifying `explanation` (pre-Story 5.6 use). Story 5.6 guarantees a non-empty string is always written before storage.

### `Map<String, double>` in `BanditState`

`json_serializable` handles `Map<String, double>` natively. The generated code produces:
```dart
// In toJson:
'armWeights': instance.armWeights,   // Map<String, double> → JSON map
// In fromJson:
armWeights: Map<String, double>.from(json['armWeights'] as Map),
```

No custom `@JsonKey` needed.

### `DateTime` Serialization in `@freezed`

`json_serializable` serializes `DateTime` as ISO 8601 string by default. Consistent with the existing `weather_cache_table.dart` and `rpe_feedback_table.dart` handling. No custom serialization needed.

### Test Count

Starting: **181 tests** (177 after Story 4.3 + 4 additional found in review)

New tests (Story 5.1):
- `5.1-UNIT-001`: BehavioralState has all 4 values
- `5.1-UNIT-002`: AqiLevel has 2 values
- `5.1-UNIT-003`: StateVector equality
- `5.1-UNIT-004`: StateVector copyWith
- `5.1-UNIT-005`: empty rpeHistory is valid
- `5.1-UNIT-006`: nullable fields accept null
- `5.1-UNIT-007`: StateVector JSON round-trip
- `5.1-UNIT-008`: BanditState JSON round-trip
- `5.1-UNIT-009`: banditArmKeys has 9 entries
- `5.1-UNIT-010`: BanditState copyWith
- `5.1-UNIT-011`: noConstraints values
- `5.1-UNIT-012`: SafetyConstraints null maxIntensity round-trip
- `5.1-UNIT-013`: SafetyConstraints maxIntensity.low round-trip
- `5.1-UNIT-014`: DailyPlan nested JSON round-trip
- `5.1-UNIT-015`: PlannedSession explanation defaults to empty string
- `5.1-UNIT-016`: Explanation JSON round-trip

Target: **~197 tests** (+16)

### Files To Change

| File | Action | Notes |
|---|---|---|
| `lib/features/onboarding/domain/entities/user_profile.dart` | **Modify** | Add `@JsonSerializable`, `fromJson`, `toJson`, `part` directive |
| `lib/ai/state_machine/behavioral_state.dart` | **Create** | New: `BehavioralState` enum |
| `lib/ai/bandit/state_vector.dart` | **Create** | New: `AqiLevel` enum + `StateVector` @freezed |
| `lib/ai/bandit/bandit_state.dart` | **Create** | New: `BanditState` @freezed + `banditArmKeys` constant |
| `lib/ai/safety/safety_constraints.dart` | **Create** | New: `SessionIntensity` enum + `SafetyConstraints` @freezed + `noConstraints` |
| `lib/features/daily_plan/domain/entities/explanation.dart` | **Create** | New: `Explanation` @freezed |
| `lib/features/daily_plan/domain/entities/planned_session.dart` | **Create** | New: `PlannedSession` @freezed |
| `lib/features/daily_plan/domain/entities/daily_plan.dart` | **Create** | New: `DailyPlan` @freezed |
| Generated: `*.freezed.dart`, `*.g.dart` | **Generate** | Via `build_runner` |
| `test/domain/ai/domain_models_test.dart` | **Create** | 16 unit tests |

### Files That Must NOT Be Changed

- `lib/features/onboarding/domain/entities/user_profile.dart` — constructor and fields unchanged; only adding annotations and methods
- Any existing test files — 181 existing tests must all still pass
- `lib/core/database/tables/*.dart` — DB schema unchanged in this story
- `lib/core/di/injection.dart` — no new `@injectable` registrations in this story (pure data classes don't use DI)

### Cross-Story References

- **Story 5.2** will import `BehavioralState`, `StateVector` — implement `BehavioralStateMachine` in `lib/ai/state_machine/behavioral_state_machine.dart`
- **Story 5.3** will import `SafetyConstraints`, `BehavioralState`, `StateVector` — implement `SafetyRules` in `lib/ai/safety/safety_rules.dart`
- **Story 5.4** will import `BanditState`, `StateVector`, `banditArmKeys` — implement `ContextualBandit` in `lib/ai/bandit/contextual_bandit.dart`
- **Story 5.5** will import `DailyPlan`, `PlannedSession`, `StateVector`, `SafetyConstraints` — implement the pipeline
- **Story 5.6** will set `PlannedSession.explanation` to a non-empty generated string

### Defensive Requirements

- **`rpeHistory` accepts any length.** The AC says "last 5" but that's a convention enforced by the state machine (Story 5.2), not a constraint on the data model itself. Do NOT add length validation in `StateVector` — the BehavioralStateMachine reads only what it needs.
- **Do NOT add `assert` or validation** in `@freezed` factories — freezed-generated factories don't support asserts cleanly, and domain models are pure data containers. Business rules belong in the AI engine classes (Stories 5.2–5.4).
- **`const` keyword in tests** — `PlannedSession(...)` and `Explanation(...)` support `const` construction. Use it in tests to verify the generated code is correct.
- **`dart analyze` check:** Run `dart analyze lib/ai/ lib/features/daily_plan/domain/entities/` — zero issues required. If any `flutter/...` import is found, remove it.

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

1. **freezed 3.x requires `abstract class`**: In freezed 3.x, simple data classes (single factory constructor) must be declared as `abstract class X with _$X`. The mixin `_$X` declares abstract getters and `toJson()` which need to be satisfied. Union-type classes (multiple factories like in ProfileState) don't require `abstract` because the mixin generates no abstract field getters. Fixed by adding `abstract` to all 5 new freezed classes.

2. **`explicit_to_json` required for nested serialization**: `json_serializable` defaults to `explicitToJson: false`, which stores nested objects (e.g., `UserProfile`) as raw instances instead of calling `.toJson()`. This caused `StateVector.fromJson()` to fail with `type 'UserProfile' is not a subtype of Map<String, dynamic>`. Fixed by creating `build.yaml` with `explicit_to_json: true`.

3. **`UserProfile` equality**: After JSON round-trip, a new `UserProfile` instance is created. Without custom `==`, the freezed-generated `StateVector` equality comparison fails (reference equality). Added `operator==` and `hashCode` to `UserProfile` — backward-compatible as it only adds methods without changing constructor/fields.

4. **`_makeStateVector` test helper**: The story's test code was missing `streak` in the helper function parameters. Added `int streak = 3` as a named parameter.

### Completion Notes List

- Created `lib/ai/` folder hierarchy from scratch: `bandit/`, `state_machine/`, `safety/`
- Added `@JsonSerializable` + `fromJson`/`toJson` + `==`/`hashCode` to `UserProfile` (backward-compatible)
- Created `BehavioralState` enum (pure Dart, no Flutter imports)
- Created `AqiLevel` enum + `StateVector` @freezed (uses `abstract class` per freezed 3.x requirement)
- Created `BanditState` @freezed + `banditArmKeys` constant
- Created `SessionIntensity` enum + `SafetyConstraints` @freezed + `noConstraints` constant
- Created `Explanation`, `PlannedSession`, `DailyPlan` @freezed entities
- Created `build.yaml` with `explicit_to_json: true` to enable nested JSON serialization
- Ran `build_runner` (generated 13 `.freezed.dart` / `.g.dart` files)
- `dart analyze` → 2 info only (doc comment references to names in comments, not errors)
- Zero Flutter imports in `lib/ai/` and `lib/features/daily_plan/domain/entities/` (ARCH7 satisfied)
- All 16 new tests pass; total suite: **197 tests** (+16 from 181), zero regressions

### File List

**Modified:**
- `pulse_coach/lib/features/onboarding/domain/entities/user_profile.dart` — added `@JsonSerializable`, `fromJson`, `toJson`, `==`, `hashCode`, `part` directive

**Created (source):**
- `pulse_coach/lib/ai/state_machine/behavioral_state.dart`
- `pulse_coach/lib/ai/bandit/state_vector.dart`
- `pulse_coach/lib/ai/bandit/bandit_state.dart`
- `pulse_coach/lib/ai/safety/safety_constraints.dart`
- `pulse_coach/lib/features/daily_plan/domain/entities/explanation.dart`
- `pulse_coach/lib/features/daily_plan/domain/entities/planned_session.dart`
- `pulse_coach/lib/features/daily_plan/domain/entities/daily_plan.dart`
- `pulse_coach/build.yaml`
- `pulse_coach/test/domain/ai/domain_models_test.dart`

**Generated (do not edit):**
- `pulse_coach/lib/features/onboarding/domain/entities/user_profile.g.dart`
- `pulse_coach/lib/ai/bandit/state_vector.freezed.dart`
- `pulse_coach/lib/ai/bandit/state_vector.g.dart`
- `pulse_coach/lib/ai/bandit/bandit_state.freezed.dart`
- `pulse_coach/lib/ai/bandit/bandit_state.g.dart`
- `pulse_coach/lib/ai/safety/safety_constraints.freezed.dart`
- `pulse_coach/lib/ai/safety/safety_constraints.g.dart`
- `pulse_coach/lib/features/daily_plan/domain/entities/explanation.freezed.dart`
- `pulse_coach/lib/features/daily_plan/domain/entities/explanation.g.dart`
- `pulse_coach/lib/features/daily_plan/domain/entities/planned_session.freezed.dart`
- `pulse_coach/lib/features/daily_plan/domain/entities/planned_session.g.dart`
- `pulse_coach/lib/features/daily_plan/domain/entities/daily_plan.freezed.dart`
- `pulse_coach/lib/features/daily_plan/domain/entities/daily_plan.g.dart`

### Review Findings

**Reviewed:** 2026-04-21 · claude-opus-4-7 · 3-layer parallel review (Blind Hunter, Edge Case Hunter, Acceptance Auditor)

**Acceptance Auditor verdict:** All 4 AC PASS. Three documented deviations (`abstract class` for freezed 3.x, `==`/`hashCode` on `UserProfile`, `build.yaml`) each justified in Dev Agent Record and required for AC compliance.

**Triage summary:** 1 patch · 3 defer · 22 dismissed (most rejected by the "Defensive Requirements" directive in Dev Notes — no assert/validation in freezed models; business rules belong to AI-engine stories 5.2–5.4).

- [x] [Review][Patch] `DateTime` JSON round-trip test covers only local timezone — added `5.1-UNIT-008b` UTC round-trip assertion [test/domain/ai/domain_models_test.dart]
- [x] [Review][Defer] `BanditState` name collision with existing drift table class `BanditState` [lib/core/database/tables/bandit_state_table.dart] — deferred to Story 5.4 (DAO/repo layer will need `as` prefix or rename)
- [x] [Review][Defer] `UserProfile.physicalConstraints` is a single string — cannot co-express "indoor preference" + "knee/back" constraint [lib/features/onboarding/domain/entities/user_profile.dart] — deferred, pre-existing (onboarding design, outside Story 5.1 scope)
- [x] [Review][Defer] `BanditState` lacks `BanditState.initial()` factory — 9-arm invariant only documented via `banditArmKeys`, not enforced at construction [lib/ai/bandit/bandit_state.dart] — deferred to Story 5.4 (bandit initialization belongs with reward-update logic)

## Change Log

- 2026-04-12: Story created by SM agent. Epic 5 starts. All AI domain models defined from scratch — no pre-existing implementations. `UserProfile` requires JSON serialization addition (backward-compatible). File placement follows architecture.md's `lib/ai/` hierarchy for AI-layer models and `lib/features/daily_plan/domain/entities/` for UI-facing entities.
- 2026-04-16: Story implemented by dev agent (claude-sonnet-4-6). All 7 tasks complete. 16 new tests pass; total 197 tests, zero regressions. Key discoveries: freezed 3.x requires `abstract class` for simple data models; `explicit_to_json: true` required via `build.yaml` for nested serialization; `UserProfile` equality added for JSON round-trip tests. Status: review.
- 2026-04-21: Code review completed by claude-opus-4-7 (3-layer parallel: Blind Hunter + Edge Case Hunter + Acceptance Auditor). All 4 AC PASS. 1 patch applied (UTC DateTime round-trip test `5.1-UNIT-008b`), 3 findings deferred (BanditState name-collision, UserProfile.physicalConstraints orthogonality, BanditState.initial factory — all to Story 5.4 or onboarding rework). 198 tests passing, zero regressions. Status: done.
