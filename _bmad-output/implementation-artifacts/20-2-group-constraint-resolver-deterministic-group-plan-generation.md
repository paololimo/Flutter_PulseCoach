---
baseline_commit: 85fd296f7a4d1e0c8b8e0d1e7a3b5f9c2d4e6a8b
---

# Story 20.2: GroupConstraintResolver — Deterministic Group Plan Generation

Status: done

## Story

As a developer,
I want a pure-Dart `GroupConstraintResolver` that deterministically computes the group plan constraints from all participants' profiles,
So that the shared session plan is safe for everyone and its rules are fully testable.

## Context

**Epic 20 — Co-Located Shared Sessions (v2.4b).** Story 20.1 created the Supabase tables, the `SharedSession` domain entity, the join-code flow, and the lobby navigation. Story 20.2 is the AI-layer prerequisite for the synchronized session start (Story 20.4): the resolver computes a single `GroupConstraint` from all participants' individual safety caps and profiles, ensuring the shared plan is safe for everyone.

**This is a pure-Dart domain story.** No UI, no Bloc, no DI registration, no build_runner invocation. The only dependencies are existing types from `lib/ai/safety/safety_constraints.dart` (`SessionIntensity`).

**What Story 20.2 builds:**
1. `ParticipantProfile` — immutable, plain Dart value object (`lib/ai/safety/participant_profile.dart`)
2. `GroupConstraint` — immutable, plain Dart value object output (`lib/ai/safety/group_constraint.dart`)
3. `GroupConstraintResolver` — stateless pure-Dart class (`lib/ai/safety/group_constraint_resolver.dart`)
4. Exhaustive pure-Dart unit tests (`test/domain/ai/group_constraint_resolver_test.dart`)

**This story does NOT include:**
- Integration with the AI engine or daily plan generation (Story 20.4)
- Any Bloc, Cubit, or UI wiring
- Any Supabase calls or network layer
- A use case wrapper (the resolver is called directly by the plan-generation use case in Story 20.4)

**E9-K1 fire-check (per action-item-ledger.md):**

| Active item | Fires? | Required action |
|---|---|---|
| `E18R-1` small-viewport shimmer test | ❌ No — pure Dart, no screen | Not applicable |
| `E18R-2` backend-failure localization | ❌ No — no UI surface | Not applicable |
| `E18R-4` social `ProUpsellSheet` copy | ❌ No — no UI | Not applicable |
| `E10R-2` non-UTC week-bucketing test | ❌ No — no Progress code | Not applicable |
| `E6-P1` cross-cutting DI | ❌ No — resolver not DI-registered; instantiated directly | No action |
| `E18R-CB2` localized-IT review check | ❌ No — no Failure surfaced to UI | Not applicable |

**Category A snapshot entering sprint (Story 20.2): 4 / 5.** Active: `E18R-1`, `E18R-2`, `E10R-2`, `E18R-4`. Under cap. Story 20.2 cleared to enter sprint.

## Acceptance Criteria

**AC1 — Deterministic group rules (FR70, ARCH24):**
Given `GroupConstraintResolver` is implemented at `lib/ai/safety/group_constraint_resolver.dart`
When it receives a `List<ParticipantProfile>` where each entry has `safetyCapIntensity`, `fitnessLevel`, `movementExclusions`, `availableTimeMinutes`
Then it returns a `GroupConstraint` where:
- `intensityCeiling = min(safetyCapIntensity for all)` — strictest intensity cap wins; `null` = no cap (least strict); `low` < `medium` < `high` < `null`
- `fitnessLevel = lowest(fitnessLevel for all)` — `'low'` is lower than `'medium'`; if any participant is `'low'`, the group is `'low'`
- `movementExclusions = union(movementExclusions for all)` — any participant's exclusion applies to the whole group
- `durationMinutes = min(availableTimeMinutes for all)` — shortest available time limits the group

**AC2 — Per-user FR9 safety rules applied on top (FR70):**
Given any participant's pre-computed `safetyCapIntensity` already reflects their individual v1 FR9 safety override (e.g., an `AtRisk` participant has `safetyCapIntensity = SessionIntensity.low`)
When `GroupConstraintResolver.resolve()` runs
Then the group's `intensityCeiling` is further constrained by that participant's cap — their protective state lowers the ceiling for the entire group (because the resolver takes the minimum, the pre-computed individual cap is automatically propagated)

**Note:** The resolver does NOT call `SafetyRules` internally. Per-user constraints are computed by the caller (plan generation use case, Story 20.4) and passed into `ParticipantProfile.safetyCapIntensity`. The resolver is stateless and has no constructor parameters.

**AC3 — Exhaustive test coverage (ARCH24):**
Given `test/domain/ai/group_constraint_resolver_test.dart` exists
When `flutter test` runs
Then all ≥15 tests pass and cover at minimum:
- Single participant (identity case)
- All-same profile (idempotent group)
- Heterogeneous mixed group (verify each field independently)
- Group with one `AtRisk` participant (`safetyCapIntensity = low`) — their cap lowers the group ceiling even if others are uncapped
- `movementExclusions` union: participant A has `{'knee'}`, participant B has `{'back'}` → group has `{'knee', 'back'}`
- `movementExclusions` with `{}` (none): union with empty set is identity
- `durationMinutes` min: three participants with 20/30/45 → group gets 20
- `fitnessLevel` lowest: `'low'` and `'medium'` mix → group is `'low'`
- All participants uncapped (`safetyCapIntensity = null`) → group ceiling is `null` (no cap)
- All participants same cap → group ceiling equals that cap
- Two participants: one `null` cap, one `medium` cap → group ceiling is `medium`
- Empty list argument → `ArgumentError` thrown (guard)

**AC4 — Zero Flutter imports (ARCH24):**
Given `group_constraint_resolver.dart`, `participant_profile.dart`, and `group_constraint.dart`
When `flutter analyze lib/ai/safety/` runs after this story
Then zero issues are reported and none of the three new files contains `import 'package:flutter/...'`

**AC5 — Zero regressions:**
Given all new files are in place
When `flutter test` and `flutter analyze lib/ test/` run from `pulse_coach/`
Then all existing 1166 tests pass plus all new ≥15 tests pass; analyzer reports 0 issues

## Tasks / Subtasks

---

### Task 1 — `ParticipantProfile` value object

**Why:** `GroupConstraintResolver.resolve()` takes `List<ParticipantProfile>`. This is the input type, capturing the per-participant fields the resolver needs. It is NOT `UserProfile` — it is a narrow projection assembled by the caller from `UserProfile + SafetyConstraints`.

- [x] **1.1** Create `pulse_coach/lib/ai/safety/participant_profile.dart`:

  ```dart
  import 'package:meta/meta.dart';
  import 'package:pulse_coach/ai/safety/safety_constraints.dart';

  /// Per-participant inputs for [GroupConstraintResolver].
  ///
  /// [safetyCapIntensity] is the pre-computed individual intensity cap derived
  /// by applying v1 [SafetyRules] (FR9/FR24) to this participant's StateVector.
  /// Null means no individual cap (participant is in [BehavioralState.active]
  /// with no RPE pressure).
  ///
  /// [fitnessLevel] mirrors [UserProfile.fitnessLevel]: 'low' | 'medium'.
  ///
  /// [movementExclusions] is the set of movement constraints from
  /// [UserProfile.physicalConstraints]. 'none' → empty set;
  /// 'knee' → {'knee'}, 'back' → {'back'}, 'indoor' → {'indoor'}.
  ///
  /// [availableTimeMinutes] is the session-duration budget for this participant.
  /// Derived from [UserProfile.availableTime]: 'short' → 20, 'long' → 45.
  @immutable
  class ParticipantProfile {
    final SessionIntensity? safetyCapIntensity;
    final String fitnessLevel;
    final Set<String> movementExclusions;
    final int availableTimeMinutes;

    const ParticipantProfile({
      required this.safetyCapIntensity,
      required this.fitnessLevel,
      required this.movementExclusions,
      required this.availableTimeMinutes,
    });
  }
  ```

  **Critical — `Set<String>` for `movementExclusions`:** Caller converts `UserProfile.physicalConstraints` ('none'/'knee'/'back'/'indoor') to a `Set<String>`. `'none'` maps to `const <String>{}`. The resolver computes the union using `Set.union` / `expand().toSet()`.

  **Critical — `@immutable`:** `meta` package is already in `pulse_coach/pubspec.yaml` (used across the project). No new dependency needed.

  **Critical — no `@freezed`:** This value object is never serialized, never passed across an `Isolate` boundary, and never stored in a DB. A plain `const` class is both correct and simpler. `build_runner` is NOT needed for this story.

---

### Task 2 — `GroupConstraint` value object

**Why:** `GroupConstraintResolver.resolve()` returns a `GroupConstraint`. This is the output type, consumed by the plan-generation use case (Story 20.4) to filter session candidates.

- [x] **2.1** Create `pulse_coach/lib/ai/safety/group_constraint.dart`:

  ```dart
  import 'package:meta/meta.dart';
  import 'package:pulse_coach/ai/safety/safety_constraints.dart';

  /// Deterministic group-level constraint computed by [GroupConstraintResolver].
  ///
  /// Derived from all participants' [ParticipantProfile]s via:
  ///   - [intensityCeiling] = min(safetyCapIntensity for all) (FR70, ARCH24)
  ///   - [fitnessLevel]     = lowest(fitnessLevel for all) (FR70)
  ///   - [movementExclusions] = union(movementExclusions for all) (FR70)
  ///   - [durationMinutes] = min(availableTimeMinutes for all) (FR70)
  ///
  /// Null [intensityCeiling] means no intensity restriction for the group.
  @immutable
  class GroupConstraint {
    final SessionIntensity? intensityCeiling;
    final String fitnessLevel;
    final Set<String> movementExclusions;
    final int durationMinutes;

    const GroupConstraint({
      required this.intensityCeiling,
      required this.fitnessLevel,
      required this.movementExclusions,
      required this.durationMinutes,
    });

    @override
    bool operator ==(Object other) =>
        identical(this, other) ||
        other is GroupConstraint &&
            intensityCeiling == other.intensityCeiling &&
            fitnessLevel == other.fitnessLevel &&
            _setsEqual(movementExclusions, other.movementExclusions) &&
            durationMinutes == other.durationMinutes;

    @override
    int get hashCode => Object.hash(
          intensityCeiling,
          fitnessLevel,
          Object.hashAll(movementExclusions.toList()..sort()),
          durationMinutes,
        );

    static bool _setsEqual(Set<String> a, Set<String> b) =>
        a.length == b.length && a.containsAll(b);
  }
  ```

  **Critical — explicit `==` / `hashCode`:** Tests compare `GroupConstraint` instances directly. Without `==`, `expect(result, equals(expected))` would use identity comparison and always fail. `Set<String>` comparison requires containment check, not reference equality.

  **Critical — sorted hash for `movementExclusions`:** `Object.hashAll` order-depends on iteration order. Sorting before hashing ensures two sets with the same elements (different insertion order) produce the same hash.

---

### Task 3 — `GroupConstraintResolver`

- [x] **3.1** Create `pulse_coach/lib/ai/safety/group_constraint_resolver.dart`:

  ```dart
  import 'package:pulse_coach/ai/safety/group_constraint.dart';
  import 'package:pulse_coach/ai/safety/participant_profile.dart';
  import 'package:pulse_coach/ai/safety/safety_constraints.dart';

  /// Deterministic group constraint resolver (FR70, ARCH24).
  ///
  /// Stateless — no constructor parameters. Every call computes fresh from
  /// the input list. No Flutter dependency; no DI registration; no isolate
  /// boundary crossing.
  ///
  /// Per-user v1 FR9/FR24 safety caps are pre-computed by the caller and
  /// stored in [ParticipantProfile.safetyCapIntensity]. This class only applies
  /// the group-level aggregation rules on top.
  class GroupConstraintResolver {
    const GroupConstraintResolver();

    /// Computes the [GroupConstraint] for [participants].
    ///
    /// Throws [ArgumentError] if [participants] is empty.
    GroupConstraint resolve(List<ParticipantProfile> participants) {
      if (participants.isEmpty) {
        throw ArgumentError('participants must not be empty');
      }

      SessionIntensity? ceiling;
      for (final p in participants) {
        ceiling = _strictest(ceiling, p.safetyCapIntensity);
      }

      final fitnessLevel =
          participants.any((p) => p.fitnessLevel == 'low') ? 'low' : 'medium';

      final movementExclusions =
          participants.expand((p) => p.movementExclusions).toSet();

      final durationMinutes = participants
          .map((p) => p.availableTimeMinutes)
          .reduce((a, b) => a < b ? a : b);

      return GroupConstraint(
        intensityCeiling: ceiling,
        fitnessLevel: fitnessLevel,
        movementExclusions: movementExclusions,
        durationMinutes: durationMinutes,
      );
    }

    /// Returns the stricter of [a] and [b].
    ///
    /// Strictness: low (0) < medium (1) < high (2) < null (3, least strict).
    /// Null means no cap — the other value always wins over null.
    SessionIntensity? _strictest(SessionIntensity? a, SessionIntensity? b) {
      if (a == null) return b;
      if (b == null) return a;
      return _rank(a) <= _rank(b) ? a : b;
    }

    /// Exhaustive rank — adding a new [SessionIntensity] value must fail-compile
    /// here (safety-layer discipline, same as in [SafetyRules]).
    int _rank(SessionIntensity i) => switch (i) {
          SessionIntensity.low => 0,
          SessionIntensity.medium => 1,
          SessionIntensity.high => 2,
        };
  }
  ```

  **Critical — no `@injectable` annotation:** `GroupConstraintResolver` is NOT registered with `get_it`. It is a stateless value-computation helper, instantiated with `const GroupConstraintResolver()` by its caller. `E6-P1` does not fire for this story.

  **Critical — `_strictest` semantics match `SafetyRules._strictest`:** The intensity strictness ordering must be identical to `SafetyRules._strictnessRank` in `lib/ai/safety/safety_rules.dart`. Compare before committing — both must agree that `low < medium < high < null`.

  **Critical — exhaustive `switch` on `SessionIntensity`:** Forces a compile error if a new intensity value is added (same discipline as `SafetyRules._strictnessRank`). Do NOT use `default:` or `_:` arms in the switch.

  **Critical — `fitnessLevel` binary ordering:** The current `UserProfile.fitnessLevel` only has two values: `'low'` and `'medium'`. The `any(p => p.fitnessLevel == 'low')` check is the correct and simplest implementation. If a third level is ever added, this comparison would need to be updated — the test suite would catch the regression.

---

### Task 4 — Tests

- [x] **4.1** Create `pulse_coach/test/domain/ai/group_constraint_resolver_test.dart`:

  ```dart
  // [20.2-GCR-001..017] GroupConstraintResolver exhaustive pure-Dart tests (ARCH24)
  import 'package:flutter_test/flutter_test.dart';
  import 'package:pulse_coach/ai/safety/group_constraint.dart';
  import 'package:pulse_coach/ai/safety/group_constraint_resolver.dart';
  import 'package:pulse_coach/ai/safety/participant_profile.dart';
  import 'package:pulse_coach/ai/safety/safety_constraints.dart';

  void main() {
    const resolver = GroupConstraintResolver();

    // ─── helpers ───────────────────────────────────────────────────────────────
    ParticipantProfile active({
      SessionIntensity? cap,
      String fitness = 'medium',
      Set<String> exclusions = const {},
      int minutes = 45,
    }) =>
        ParticipantProfile(
          safetyCapIntensity: cap,
          fitnessLevel: fitness,
          movementExclusions: exclusions,
          availableTimeMinutes: minutes,
        );

    group('GroupConstraintResolver (20.2)', () {
      // ─── AC3: edge case 1 — single participant ─────────────────────────────
      test('20.2-GCR-001: single participant → identity (AC1)', () {
        final p = active(cap: SessionIntensity.medium, fitness: 'low', exclusions: {'knee'}, minutes: 30);
        final result = resolver.resolve([p]);
        expect(result, equals(GroupConstraint(
          intensityCeiling: SessionIntensity.medium,
          fitnessLevel: 'low',
          movementExclusions: {'knee'},
          durationMinutes: 30,
        )));
      });

      // ─── AC3: edge case 2 — all-same profile ──────────────────────────────
      test('20.2-GCR-002: all-same profile → idempotent (AC1)', () {
        final p = active(cap: null, fitness: 'medium', exclusions: {}, minutes: 45);
        final result = resolver.resolve([p, p, p]);
        expect(result, equals(GroupConstraint(
          intensityCeiling: null,
          fitnessLevel: 'medium',
          movementExclusions: {},
          durationMinutes: 45,
        )));
      });

      // ─── AC3: edge case 3 — heterogeneous mixed group ─────────────────────
      test('20.2-GCR-003: heterogeneous group — all fields independently (AC1)', () {
        final result = resolver.resolve([
          active(cap: null,                      fitness: 'medium', exclusions: {'back'},  minutes: 45),
          active(cap: SessionIntensity.medium,   fitness: 'low',   exclusions: {'knee'},  minutes: 30),
          active(cap: SessionIntensity.high,     fitness: 'medium', exclusions: {},        minutes: 20),
        ]);
        expect(result, equals(GroupConstraint(
          intensityCeiling: SessionIntensity.medium, // min(null, medium, high) = medium
          fitnessLevel: 'low',                        // any 'low' → 'low'
          movementExclusions: {'back', 'knee'},        // union
          durationMinutes: 20,                         // min(45, 30, 20)
        )));
      });

      // ─── AC3: edge case 4 — AtRisk participant lowers group ceiling ────────
      test('20.2-GCR-004: AtRisk participant (cap=low) lowers group ceiling (AC2)', () {
        final result = resolver.resolve([
          active(cap: null),                   // active, no individual cap
          active(cap: null),                   // active, no individual cap
          active(cap: SessionIntensity.low),   // AtRisk: FR9/FR24 pre-applied
        ]);
        expect(result.intensityCeiling, equals(SessionIntensity.low));
      });

      // ─── intensityCeiling: exhaustive strictness ordering ─────────────────
      test('20.2-GCR-005: intensityCeiling — null vs low → low (AC1)', () {
        final result = resolver.resolve([
          active(cap: null),
          active(cap: SessionIntensity.low),
        ]);
        expect(result.intensityCeiling, SessionIntensity.low);
      });

      test('20.2-GCR-006: intensityCeiling — null vs medium → medium (AC1)', () {
        final result = resolver.resolve([
          active(cap: null),
          active(cap: SessionIntensity.medium),
        ]);
        expect(result.intensityCeiling, SessionIntensity.medium);
      });

      test('20.2-GCR-007: intensityCeiling — medium vs high → medium (AC1)', () {
        final result = resolver.resolve([
          active(cap: SessionIntensity.medium),
          active(cap: SessionIntensity.high),
        ]);
        expect(result.intensityCeiling, SessionIntensity.medium);
      });

      test('20.2-GCR-008: intensityCeiling — low vs medium vs high → low (AC1)', () {
        final result = resolver.resolve([
          active(cap: SessionIntensity.low),
          active(cap: SessionIntensity.medium),
          active(cap: SessionIntensity.high),
        ]);
        expect(result.intensityCeiling, SessionIntensity.low);
      });

      test('20.2-GCR-009: intensityCeiling — all null → null (no group cap) (AC1)', () {
        final result = resolver.resolve([active(cap: null), active(cap: null)]);
        expect(result.intensityCeiling, isNull);
      });

      // ─── movementExclusions: union semantics ──────────────────────────────
      test('20.2-GCR-010: movementExclusions union — knee + back = {knee, back} (AC1)', () {
        final result = resolver.resolve([
          active(exclusions: {'knee'}),
          active(exclusions: {'back'}),
        ]);
        expect(result.movementExclusions, equals({'knee', 'back'}));
      });

      test('20.2-GCR-011: movementExclusions union with empty set — identity (AC1)', () {
        final result = resolver.resolve([
          active(exclusions: {'knee'}),
          active(exclusions: {}),
        ]);
        expect(result.movementExclusions, equals({'knee'}));
      });

      test('20.2-GCR-012: movementExclusions — overlapping sets deduplicated (AC1)', () {
        final result = resolver.resolve([
          active(exclusions: {'knee', 'back'}),
          active(exclusions: {'knee', 'indoor'}),
        ]);
        expect(result.movementExclusions, equals({'knee', 'back', 'indoor'}));
      });

      // ─── durationMinutes: min semantics ───────────────────────────────────
      test('20.2-GCR-013: durationMinutes — min of 20/30/45 = 20 (AC1)', () {
        final result = resolver.resolve([
          active(minutes: 45),
          active(minutes: 20),
          active(minutes: 30),
        ]);
        expect(result.durationMinutes, 20);
      });

      // ─── fitnessLevel: lowest semantics ───────────────────────────────────
      test('20.2-GCR-014: fitnessLevel — low + medium → low (AC1)', () {
        final result = resolver.resolve([
          active(fitness: 'medium'),
          active(fitness: 'low'),
        ]);
        expect(result.fitnessLevel, 'low');
      });

      test('20.2-GCR-015: fitnessLevel — all medium → medium (AC1)', () {
        final result = resolver.resolve([
          active(fitness: 'medium'),
          active(fitness: 'medium'),
        ]);
        expect(result.fitnessLevel, 'medium');
      });

      // ─── AC4: empty list guard ─────────────────────────────────────────────
      test('20.2-GCR-016: empty list → ArgumentError (AC3 guard)', () {
        expect(() => resolver.resolve([]), throwsArgumentError);
      });

      // ─── regression: two participants, symmetric result ────────────────────
      test('20.2-GCR-017: two symmetric participants — min/union stable (AC1)', () {
        final p1 = active(cap: SessionIntensity.medium, fitness: 'medium', exclusions: {'back'}, minutes: 30);
        final p2 = active(cap: SessionIntensity.medium, fitness: 'medium', exclusions: {'back'}, minutes: 30);
        final result = resolver.resolve([p1, p2]);
        expect(result, equals(GroupConstraint(
          intensityCeiling: SessionIntensity.medium,
          fitnessLevel: 'medium',
          movementExclusions: {'back'},
          durationMinutes: 30,
        )));
      });
    });
  }
  ```

  **Test naming convention:** `20.2-GCR-NNN` — prefix `20.2` (epic.story), `GCR` (GroupConstraintResolver), three-digit index. Matches project test ID pattern from prior stories.

  **No mocks needed:** `GroupConstraintResolver` is pure computation. All tests are pure-Dart `test()` calls — no `testWidgets`, no `blocTest`, no `mockito`. The test file compiles as a Dart-only unit test.

---

### Task 5 — flutter analyze verification

- [x] **5.1** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ai/safety/ test/domain/ai/
  ```
  Expected: 0 issues. Verify none of the three new source files contains `import 'package:flutter/...'`.

- [x] **5.2** From `pulse_coach/`, run:
  ```bash
  flutter test test/domain/ai/group_constraint_resolver_test.dart --reporter expanded
  ```
  Expected: all 17 tests pass.

- [x] **5.3** From `pulse_coach/`, run:
  ```bash
  flutter test
  ```
  Expected: all previous 1166 tests + 17 new = 1183 tests pass.

---

### Review Findings

_Code review 2026-06-25 (adversarial: Blind Hunter + Edge Case Hunter + Acceptance Auditor, model claude-opus-4-8). Verification: `flutter analyze lib/ai/safety/ test/domain/ai/` → 0 issues; `flutter test` resolver suite → 17/17 pass. Acceptance Auditor: AC1–AC5 all satisfied; strictness ordering byte-identical to `SafetyRules._strictnessRank`._

**Patch (unchecked):**

- [x] [Review][Patch] `@immutable` value objects leak a mutable `Set<String>` — resolver output `movementExclusions` is a mutable `LinkedHashSet`; honor the `@immutable` contract by wrapping the resolver-produced set in `Set.unmodifiable(...)` [pulse_coach/lib/ai/safety/group_constraint_resolver.dart:43] (blind+edge). Low severity: object is produced fresh per `resolve()`, consumed once in Story 20.4, never serialized/stored in a hashed collection. Targeted at the resolver call site so the `const GroupConstraint(...)` constructor used by tests stays `const`. **FIXED 2026-06-25** — `Set<String>.unmodifiable(...)` applied; analyze 0 issues, 1183/1183 tests pass.

**Dismissed (accepted-risk notes for Story 20.4 awareness):**

- `fitnessLevel == 'low' ? 'low' : 'medium'` fails open to the less-restrictive `'medium'` on any unexpected string (`'high'`, `''`, casing drift). **Accepted by spec** (Task 3 note, story line 283): `UserProfile.fitnessLevel` is a controlled two-value domain upstream; a third value would be caught by the suite. If `fitnessLevel` ever becomes free-form, revisit in Story 20.4's mapping layer.
- `availableTimeMinutes` unvalidated (0/negative → bad group `durationMinutes`). Input is derived by the caller from `UserProfile.availableTime` (`'short'→20`, `'long'→45`) per spec Dev Notes — always positive in practice. Out of story scope.
- `ParticipantProfile` has no `==`/`hashCode`: it is an input projection, never compared; not required. Related: GCR-002 reuses the same instance 3× so "all-same → idempotent" is proven over identical, not distinct-but-equal, instances — minor test-strength nit (heterogeneous GCR-003 exercises distinct instances).
- Exposed `movementExclusions` iteration order is participant-order-dependent — but `==`/`hashCode` are correctly order-independent (sorted before `hashAll`) and no consumer depends on iteration order.
- `meta: ^1.16.0` added as a direct dependency — **correct, not noise**: the new files import `package:meta/meta.dart` directly, so `depend_on_referenced_packages` requires the explicit dep for `flutter analyze` to stay at 0 (Acceptance Auditor confirmed; supersedes the spec's outdated "no new dependency" note).

## Dev Notes

### Architecture Context

- **File placement:** `lib/ai/safety/` is the correct home for `group_constraint_resolver.dart` per ARCH24 (`architecture.md` line 1335). The `lib/ai/safety/` directory already contains `safety_constraints.dart` and `safety_rules.dart` — this story adds three new files to it.

- **No build_runner:** Stories 20.1 required `build_runner` for freezed/json_serializable. Story 20.2 does NOT — the new types are plain `@immutable` classes. Do not run `dart run build_runner build` for this story.

- **No DI registration:** `GroupConstraintResolver` is stateless (`const GroupConstraintResolver()`). Its caller in Story 20.4 instantiates it directly. `get_it` / `injectable` are not involved.

- **`SessionIntensity` import:** Import from `package:pulse_coach/ai/safety/safety_constraints.dart`. This is the existing type, not a new one.

- **`@immutable` import:** `package:meta/meta.dart`. The `meta` package is already a transitive dependency (Flutter SDK provides it). Check `pubspec.yaml` if `meta` needs an explicit dependency — in this project it is available without explicit declaration.

### Existing Safety Layer: How `safetyCapIntensity` Is Derived (Context for Story 20.4)

The caller (plan generation use case, Story 20.4) assembles `ParticipantProfile` like this:

```dart
// Pseudocode — NOT part of Story 20.2
final safetyConstraints = SafetyRules(_machine).apply(participantStateVector);
final profile = ParticipantProfile(
  safetyCapIntensity: safetyConstraints.maxIntensity,
  fitnessLevel: participantStateVector.userProfile.fitnessLevel,
  movementExclusions: _toExclusionSet(participantStateVector.userProfile.physicalConstraints),
  availableTimeMinutes: _toMinutes(participantStateVector.userProfile.availableTime),
);
```

Mapping conventions for Story 20.4:
- `physicalConstraints: 'none'` → `{}`
- `physicalConstraints: 'knee'` → `{'knee'}`
- `physicalConstraints: 'back'` → `{'back'}`
- `physicalConstraints: 'indoor'` → `{'indoor'}`
- `availableTime: 'short'` → `20`
- `availableTime: 'long'` → `45`

These mappings are **not part of Story 20.2** — they are documented here so Story 20.4's developer can see the full picture without re-deriving it.

### `GroupConstraint` vs `SafetyConstraints`

| | `SafetyConstraints` | `GroupConstraint` |
|---|---|---|
| Producer | `SafetyRules.apply()` (per-user) | `GroupConstraintResolver.resolve()` (group) |
| Consumer | `BanditEngine.selectSessions()` | Plan-generation use case (Story 20.4) |
| Serialized | Yes (`@freezed`, JSON-capable) | No (in-memory only) |
| Contains `outdoorAllowed` | Yes (AQI rule) | No — handled upstream per-user |
| Contains `maxSessionCount` | Yes | No — irrelevant for shared sessions |

`GroupConstraint` intentionally does NOT mirror `SafetyConstraints` field-for-field. It is a narrower, group-specific view.

### Intensity Strictness Ordering

Both `SafetyRules._strictnessRank` and `GroupConstraintResolver._rank` must agree on:
- `low` (rank 0) is the strictest
- `medium` (rank 1)
- `high` (rank 2)
- `null` (conceptual rank 3) = no cap = least strict

Verify both files use the same ordering after implementation.

### Testing Pattern

These tests are pure-Dart unit tests — no `testWidgets`, no `blocTest`, no `pump`. The test file can be run with `dart test` as well as `flutter test`. This is identical to the discipline used for `safety_rules_test.dart`, `contextual_bandit_test.dart`, and `behavioral_state_machine_test.dart`.

### E18R-CB2 / E18R-2 Note

These items do not fire for Story 20.2 (pure Dart, no UI). They remain active for Epic 20 stories that surface Failure objects in the UI (Stories 20.3, 20.4).

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- Implemented `ParticipantProfile`, `GroupConstraint`, `GroupConstraintResolver` as plain `@immutable` classes (no freezed, no build_runner, no DI registration). `meta` package added explicitly to `pubspec.yaml` to satisfy `depend_on_referenced_packages` lint.
- ATDD followed: test file written first (RED = compile error), then production code (GREEN = 17/17), then analyzer cleanup (REFACTOR).
- `GroupConstraint` has explicit `==`/`hashCode` with `_setsEqual` helper for `Set<String>` comparison — required for `expect(result, equals(...))` in tests.
- `_rank` switch in resolver is exhaustive with no `default:` arm — compile-error discipline if `SessionIntensity` gains new values.
- Doc-comment `[...]` cross-references limited to types imported in that file to satisfy `comment_references` lint.
- All 17 tests pass; 0 regressions (1183 total); `flutter analyze lib/ test/` reports 0 issues; no `import 'package:flutter/...'` in any new production file (AC4 ✅).

### File List

- `pulse_coach/lib/ai/safety/participant_profile.dart` (new)
- `pulse_coach/lib/ai/safety/group_constraint.dart` (new)
- `pulse_coach/lib/ai/safety/group_constraint_resolver.dart` (new)
- `pulse_coach/test/domain/ai/group_constraint_resolver_test.dart` (new)
- `pulse_coach/pubspec.yaml` (added `meta: ^1.16.0`)
- `_bmad-output/implementation-artifacts/20-2-group-constraint-resolver-deterministic-group-plan-generation.md` (status → review)
