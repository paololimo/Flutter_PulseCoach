// [3.2-UNIT-001..004] AccelerometerDataSource unit tests
// Strategy: inject a custom stream factory via AccelerometerDataSource.withOverride
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/session/data/datasources/accelerometer_data_source.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';
import 'package:sensors_plus/sensors_plus.dart';

AccelerometerEvent _event(double x, double y, double z) =>
    AccelerometerEvent(x, y, z, DateTime.now());

/// Builds 30 identical events (uniform magnitude → near-zero std dev → sedentary).
Stream<AccelerometerEvent> _uniformStream(double x, double y, double z) =>
    Stream.fromIterable(
      List.generate(30, (_) => _event(x, y, z)),
    );

void main() {
  group('AccelerometerDataSource', () {
    // ── 3.2-UNIT-001 ─────────────────────────────────────────────────────────
    test('3.2-UNIT-001: returns sedentary when std dev < 0.3', () async {
      // ~9.8 m/s² uniform (phone lying still, only gravity)
      final sut = AccelerometerDataSource.withOverride(
        () => _uniformStream(9.8, 0.0, 0.0),
      );

      final result = await sut.fetchActivityLevel();

      expect(result, ActivityLevel.sedentary);
    });

    // ── 3.2-UNIT-002 ─────────────────────────────────────────────────────────
    test('3.2-UNIT-002: returns moderate when std dev between 0.3 and 1.5',
        () async {
      // 15 events at 9.3, 15 at 10.3 → mean = 9.8, stdDev = 0.5 (clearly moderate)
      final events = [
        ...List.generate(15, (_) => _event(9.3, 0.0, 0.0)),
        ...List.generate(15, (_) => _event(10.3, 0.0, 0.0)),
      ];
      final sut = AccelerometerDataSource.withOverride(
        () => Stream.fromIterable(events),
      );

      final result = await sut.fetchActivityLevel();

      expect(result, ActivityLevel.moderate);
    });

    // ── 3.2-UNIT-003 ─────────────────────────────────────────────────────────
    test('3.2-UNIT-003: returns active when std dev >= 1.5', () async {
      // Alternating 7.0 and 12.6 → std dev >> 1.5
      final events = [
        ...List.generate(15, (_) => _event(7.0, 0.0, 0.0)),
        ...List.generate(15, (_) => _event(12.6, 0.0, 0.0)),
      ];
      final sut = AccelerometerDataSource.withOverride(
        () => Stream.fromIterable(events),
      );

      final result = await sut.fetchActivityLevel();

      expect(result, ActivityLevel.active);
    });

    // ── 3.2-UNIT-004 ─────────────────────────────────────────────────────────
    test('3.2-UNIT-004: throws SensorException when stream throws', () async {
      final sut = AccelerometerDataSource.withOverride(
        () => Stream.error(Exception('Sensor unavailable')),
      );

      expect(
        () => sut.fetchActivityLevel(),
        throwsA(isA<SensorException>()),
      );
    });

    // ── 3.2-UNIT-010 ─────────────────────────────────────────────────────────
    test('3.2-UNIT-010: throws SensorException on empty stream', () async {
      final sut = AccelerometerDataSource.withOverride(
        () => const Stream<AccelerometerEvent>.empty(),
      );

      expect(
        () => sut.fetchActivityLevel(),
        throwsA(isA<SensorException>()),
      );
    });

    // ── 3.2-UNIT-011 ─────────────────────────────────────────────────────────
    test('3.2-UNIT-011: throws SensorException when fewer than min samples',
        () async {
      // Only 5 events — below _minSampleCount (10)
      final events = List.generate(5, (_) => _event(9.8, 0.0, 0.0));
      final sut = AccelerometerDataSource.withOverride(
        () => Stream.fromIterable(events),
      );

      expect(
        () => sut.fetchActivityLevel(),
        throwsA(isA<SensorException>()),
      );
    });

    // ── 3.2-UNIT-012 ─────────────────────────────────────────────────────────
    test('3.2-UNIT-012: throws SensorException on stream timeout', () async {
      // Stream that never emits
      final sut = AccelerometerDataSource.withOverride(
        () => Stream<AccelerometerEvent>.periodic(
          const Duration(seconds: 60),
          (_) => _event(9.8, 0.0, 0.0),
        ),
      );

      expect(
        () => sut.fetchActivityLevel(),
        throwsA(isA<SensorException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 10)));

    // ── 3.2-UNIT-005 ─────────────────────────────────────────────────────────
    // Boundary: stdDev = 0.25 (just below lower threshold 0.3) → sedentary
    // 15 events at 9.75 + 15 at 10.25 (exact binary fractions); mean=10.0,
    // variance=0.0625, stdDev=0.25 < 0.3. Verifies the `< _sedentaryThreshold`
    // comparison is strict (< not <=).
    test('3.2-UNIT-005: stdDev = 0.25 → sedentary (below lower threshold)', () async {
      final events = [
        ...List.generate(15, (_) => _event(9.75, 0.0, 0.0)),
        ...List.generate(15, (_) => _event(10.25, 0.0, 0.0)),
      ];
      final sut = AccelerometerDataSource.withOverride(
        () => Stream.fromIterable(events),
      );

      final result = await sut.fetchActivityLevel();

      expect(result, ActivityLevel.sedentary);
    });

    // ── 3.2-UNIT-006 ─────────────────────────────────────────────────────────
    // Boundary: stdDev = 0.5 (just above lower threshold 0.3) → moderate
    // 15 events at 9.5 + 15 at 10.5 (exact binary fractions); mean=10.0,
    // variance=0.25, stdDev=0.5. Verifies lower threshold is exclusive upward.
    test('3.2-UNIT-006: stdDev = 0.5 → moderate (above lower threshold)', () async {
      final events = [
        ...List.generate(15, (_) => _event(9.5, 0.0, 0.0)),
        ...List.generate(15, (_) => _event(10.5, 0.0, 0.0)),
      ];
      final sut = AccelerometerDataSource.withOverride(
        () => Stream.fromIterable(events),
      );

      final result = await sut.fetchActivityLevel();

      expect(result, ActivityLevel.moderate);
    });

    // ── 3.2-UNIT-007 ─────────────────────────────────────────────────────────
    // Boundary: stdDev = 1.25 (just below upper threshold 1.5) → moderate
    // 15 events at 8.75 + 15 at 11.25 (exact binary fractions); mean=10.0,
    // variance=1.5625, stdDev=1.25 < 1.5. Verifies `< _moderateThreshold` is strict.
    test('3.2-UNIT-007: stdDev = 1.25 → moderate (below upper threshold)', () async {
      final events = [
        ...List.generate(15, (_) => _event(8.75, 0.0, 0.0)),
        ...List.generate(15, (_) => _event(11.25, 0.0, 0.0)),
      ];
      final sut = AccelerometerDataSource.withOverride(
        () => Stream.fromIterable(events),
      );

      final result = await sut.fetchActivityLevel();

      expect(result, ActivityLevel.moderate);
    });

    // ── 3.2-UNIT-008 ─────────────────────────────────────────────────────────
    // Boundary: stdDev = 1.75 (just above upper threshold 1.5) → active
    // 15 events at 8.25 + 15 at 11.75 (exact binary fractions); mean=10.0,
    // variance=3.0625, stdDev=1.75. Verifies upper threshold is exclusive upward.
    test('3.2-UNIT-008: stdDev = 1.75 → active (above upper threshold)', () async {
      final events = [
        ...List.generate(15, (_) => _event(8.25, 0.0, 0.0)),
        ...List.generate(15, (_) => _event(11.75, 0.0, 0.0)),
      ];
      final sut = AccelerometerDataSource.withOverride(
        () => Stream.fromIterable(events),
      );

      final result = await sut.fetchActivityLevel();

      expect(result, ActivityLevel.active);
    });

    // ── 3.2-UNIT-013 ─────────────────────────────────────────────────────────
    test(
        '3.2-UNIT-013: skips NaN magnitude events and classifies with valid samples',
        () async {
      // 15 NaN events (sqrt(NaN²) = NaN → skipped by isNaN guard)
      // followed by 30 uniform valid events → sedentary
      final events = [
        ...List.generate(15, (_) => _event(double.nan, 0.0, 0.0)),
        ...List.generate(30, (_) => _event(9.8, 0.0, 0.0)),
      ];
      final sut = AccelerometerDataSource.withOverride(
        () => Stream.fromIterable(events),
      );

      final result = await sut.fetchActivityLevel();

      expect(result, ActivityLevel.sedentary);
    });
  });
}
