// [3.3-UNIT-001..005] GetSensorContext use case unit tests
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';
import 'package:pulse_coach/features/session/domain/entities/health_data.dart';
import 'package:pulse_coach/features/session/domain/entities/sensor_context.dart';
import 'package:pulse_coach/features/session/domain/usecases/get_activity_level.dart';
import 'package:pulse_coach/features/session/domain/usecases/get_health_data.dart';
import 'package:pulse_coach/features/session/domain/usecases/get_sensor_context.dart';

import 'get_sensor_context_test.mocks.dart';

@GenerateMocks([GetHealthData, GetActivityLevel])
void main() {
  late MockGetHealthData mockGetHealthData;
  late MockGetActivityLevel mockGetActivityLevel;
  late GetSensorContext sut;

  setUp(() {
    mockGetHealthData = MockGetHealthData();
    mockGetActivityLevel = MockGetActivityLevel();
    sut = GetSensorContext(mockGetHealthData, mockGetActivityLevel);
  });

  group('GetSensorContext', () {
    // ── 3.3-UNIT-001 ─────────────────────────────────────────────────────────
    test('3.3-UNIT-001: both sources succeed → all fields populated', () async {
      when(mockGetHealthData()).thenAnswer(
        (_) async =>
            const Right(HealthData(restingHr: 62, stepCount: 4500)),
      );
      when(mockGetActivityLevel()).thenAnswer(
        (_) async => const Right(ActivityLevel.moderate),
      );

      final result = await sut();

      expect(result.restingHr, 62);
      expect(result.stepCount, 4500);
      expect(result.activityLevel, ActivityLevel.moderate);
      expect(result.isRpeOnly, isFalse);
      expect(result.hasSensorData, isTrue);
      verify(mockGetHealthData()).called(1);
      verify(mockGetActivityLevel()).called(1);
    });

    // ── 3.3-UNIT-002 ─────────────────────────────────────────────────────────
    test(
        '3.3-UNIT-002: health fails, activity succeeds → HR/steps null, activityLevel set',
        () async {
      when(mockGetHealthData()).thenAnswer(
        (_) async => const Left(SensorFailure('Permission denied')),
      );
      when(mockGetActivityLevel()).thenAnswer(
        (_) async => const Right(ActivityLevel.sedentary),
      );

      final result = await sut();

      expect(result.restingHr, isNull);
      expect(result.stepCount, isNull);
      expect(result.activityLevel, ActivityLevel.sedentary);
      expect(result.isRpeOnly, isFalse);
    });

    // ── 3.3-UNIT-003 ─────────────────────────────────────────────────────────
    test(
        '3.3-UNIT-003: health succeeds, activity fails → HR/steps set, activityLevel null',
        () async {
      when(mockGetHealthData()).thenAnswer(
        (_) async =>
            const Right(HealthData(restingHr: 58, stepCount: 8200)),
      );
      when(mockGetActivityLevel()).thenAnswer(
        (_) async =>
            const Left(SensorFailure('Accelerometer unavailable')),
      );

      final result = await sut();

      expect(result.restingHr, 58);
      expect(result.stepCount, 8200);
      expect(result.activityLevel, isNull);
      expect(result.isRpeOnly, isFalse);
    });

    // ── 3.3-UNIT-004 ─────────────────────────────────────────────────────────
    test(
        '3.3-UNIT-004: both fail → all null — RPE-only mode confirmed',
        () async {
      when(mockGetHealthData()).thenAnswer(
        (_) async => const Left(SensorFailure('Permission denied')),
      );
      when(mockGetActivityLevel()).thenAnswer(
        (_) async =>
            const Left(SensorFailure('Accelerometer unavailable')),
      );

      final result = await sut();

      expect(result.restingHr, isNull);
      expect(result.stepCount, isNull);
      expect(result.activityLevel, isNull);
      expect(result.isRpeOnly, isTrue);
      expect(result.hasSensorData, isFalse);
    });

    // ── 3.3-UNIT-005 ─────────────────────────────────────────────────────────
    test(
        '3.3-UNIT-005: health returns partial data (null restingHr) — steps only',
        () async {
      when(mockGetHealthData()).thenAnswer(
        (_) async =>
            const Right(HealthData(restingHr: null, stepCount: 6100)),
      );
      when(mockGetActivityLevel()).thenAnswer(
        (_) async => const Left(SensorFailure('Unavailable')),
      );

      final result = await sut();

      expect(result.restingHr, isNull);
      expect(result.stepCount, 6100);
      expect(result.activityLevel, isNull);
      expect(result.isRpeOnly, isFalse);
    });

    // ── 3.3-UNIT-006 ─────────────────────────────────────────────────────────
    test(
        '3.3-UNIT-006: dependency throws exception → degrades to RPE-only',
        () async {
      when(mockGetHealthData()).thenThrow(Exception('unexpected crash'));
      when(mockGetActivityLevel()).thenAnswer(
        (_) async => const Right(ActivityLevel.active),
      );

      final result = await sut();

      expect(result.restingHr, isNull);
      expect(result.stepCount, isNull);
      expect(result.activityLevel, isNull);
      expect(result.isRpeOnly, isTrue);
    });
  });
}
