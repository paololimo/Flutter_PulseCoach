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
      final p = active(
          cap: SessionIntensity.medium,
          fitness: 'low',
          exclusions: {'knee'},
          minutes: 30);
      final result = resolver.resolve([p]);
      expect(
          result,
          equals(const GroupConstraint(
            intensityCeiling: SessionIntensity.medium,
            fitnessLevel: 'low',
            movementExclusions: {'knee'},
            durationMinutes: 30,
          )));
    });

    // ─── AC3: edge case 2 — all-same profile ──────────────────────────────
    test('20.2-GCR-002: all-same profile → idempotent (AC1)', () {
      final p =
          active(cap: null, fitness: 'medium', exclusions: {}, minutes: 45);
      final result = resolver.resolve([p, p, p]);
      expect(
          result,
          equals(const GroupConstraint(
            intensityCeiling: null,
            fitnessLevel: 'medium',
            movementExclusions: {},
            durationMinutes: 45,
          )));
    });

    // ─── AC3: edge case 3 — heterogeneous mixed group ─────────────────────
    test('20.2-GCR-003: heterogeneous group — all fields independently (AC1)',
        () {
      final result = resolver.resolve([
        active(
            cap: null,
            fitness: 'medium',
            exclusions: {'back'},
            minutes: 45),
        active(
            cap: SessionIntensity.medium,
            fitness: 'low',
            exclusions: {'knee'},
            minutes: 30),
        active(
            cap: SessionIntensity.high,
            fitness: 'medium',
            exclusions: {},
            minutes: 20),
      ]);
      expect(
          result,
          equals(const GroupConstraint(
            intensityCeiling: SessionIntensity.medium, // min(null, medium, high) = medium
            fitnessLevel: 'low', // any 'low' → 'low'
            movementExclusions: {'back', 'knee'}, // union
            durationMinutes: 20, // min(45, 30, 20)
          )));
    });

    // ─── AC3: edge case 4 — AtRisk participant lowers group ceiling ────────
    test('20.2-GCR-004: AtRisk participant (cap=low) lowers group ceiling (AC2)',
        () {
      final result = resolver.resolve([
        active(cap: null), // active, no individual cap
        active(cap: null), // active, no individual cap
        active(cap: SessionIntensity.low), // AtRisk: FR9/FR24 pre-applied
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

    test('20.2-GCR-008: intensityCeiling — low vs medium vs high → low (AC1)',
        () {
      final result = resolver.resolve([
        active(cap: SessionIntensity.low),
        active(cap: SessionIntensity.medium),
        active(cap: SessionIntensity.high),
      ]);
      expect(result.intensityCeiling, SessionIntensity.low);
    });

    test('20.2-GCR-009: intensityCeiling — all null → null (no group cap) (AC1)',
        () {
      final result =
          resolver.resolve([active(cap: null), active(cap: null)]);
      expect(result.intensityCeiling, isNull);
    });

    // ─── movementExclusions: union semantics ──────────────────────────────
    test(
        '20.2-GCR-010: movementExclusions union — knee + back = {knee, back} (AC1)',
        () {
      final result = resolver.resolve([
        active(exclusions: {'knee'}),
        active(exclusions: {'back'}),
      ]);
      expect(result.movementExclusions, equals({'knee', 'back'}));
    });

    test(
        '20.2-GCR-011: movementExclusions union with empty set — identity (AC1)',
        () {
      final result = resolver.resolve([
        active(exclusions: {'knee'}),
        active(exclusions: {}),
      ]);
      expect(result.movementExclusions, equals({'knee'}));
    });

    test(
        '20.2-GCR-012: movementExclusions — overlapping sets deduplicated (AC1)',
        () {
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

    // ─── AC3 guard: empty list ─────────────────────────────────────────────
    test('20.2-GCR-016: empty list → ArgumentError (AC3 guard)', () {
      expect(() => resolver.resolve([]), throwsArgumentError);
    });

    // ─── regression: two participants, symmetric result ────────────────────
    test('20.2-GCR-017: two symmetric participants — min/union stable (AC1)',
        () {
      final p1 = active(
          cap: SessionIntensity.medium,
          fitness: 'medium',
          exclusions: {'back'},
          minutes: 30);
      final p2 = active(
          cap: SessionIntensity.medium,
          fitness: 'medium',
          exclusions: {'back'},
          minutes: 30);
      final result = resolver.resolve([p1, p2]);
      expect(
          result,
          equals(const GroupConstraint(
            intensityCeiling: SessionIntensity.medium,
            fitnessLevel: 'medium',
            movementExclusions: {'back'},
            durationMinutes: 30,
          )));
    });
  });
}
