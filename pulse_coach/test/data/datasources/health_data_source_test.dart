// [P1] HealthDataSource unit tests
// Tests: fetchHealthData returns HealthData, throws SensorException on denied/error
import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/session/data/datasources/health_data_source.dart';

import 'health_data_source_test.mocks.dart';

@GenerateMocks([Health])
void main() {
  late MockHealth mockHealth;
  late HealthDataSource sut;

  final now = DateTime.now();
  final yesterday = now.subtract(const Duration(days: 1));

  HealthDataPoint makePoint({
    required HealthDataType type,
    required HealthDataUnit unit,
    required num value,
  }) => HealthDataPoint(
    uuid: 'test-uuid',
    value: NumericHealthValue(numericValue: value),
    type: type,
    unit: unit,
    dateFrom: yesterday,
    dateTo: now,
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: '',
    sourceId: '',
    sourceName: '',
  );

  setUp(() {
    mockHealth = MockHealth();
    sut = HealthDataSource(mockHealth);
    when(mockHealth.configure()).thenAnswer((_) async {});
  });

  group('HealthDataSource.fetchHealthData', () {
    test(
      '3.1-UNIT-001: returns HealthData with parsed restingHr and stepCount when permissions granted and data available',
      () async {
        final hrPoint = makePoint(
          type: HealthDataType.RESTING_HEART_RATE,
          unit: HealthDataUnit.BEATS_PER_MINUTE,
          value: 62.0,
        );
        final stepPoint = makePoint(
          type: HealthDataType.STEPS,
          unit: HealthDataUnit.COUNT,
          value: 3500.0,
        );

        when(
          mockHealth.requestAuthorization(
            any,
            permissions: anyNamed('permissions'),
          ),
        ).thenAnswer((_) async => true);
        when(
          mockHealth.getHealthDataFromTypes(
            startTime: anyNamed('startTime'),
            endTime: anyNamed('endTime'),
            types: [HealthDataType.RESTING_HEART_RATE],
          ),
        ).thenAnswer((_) async => [hrPoint]);
        when(
          mockHealth.getHealthDataFromTypes(
            startTime: anyNamed('startTime'),
            endTime: anyNamed('endTime'),
            types: [HealthDataType.STEPS],
          ),
        ).thenAnswer((_) async => [stepPoint]);

        final result = await sut.fetchHealthData();

        expect(result.restingHr, equals(62));
        expect(result.stepCount, equals(3500));
      },
    );

    test(
      '3.1-UNIT-002: throws SensorException("Health permissions denied") when requestAuthorization returns false',
      () async {
        when(
          mockHealth.requestAuthorization(
            any,
            permissions: anyNamed('permissions'),
          ),
        ).thenAnswer((_) async => false);

        await expectLater(
          () => sut.fetchHealthData(),
          throwsA(
            isA<SensorException>().having(
              (e) => e.message,
              'message',
              'Health permissions denied',
            ),
          ),
        );
      },
    );

    test(
      '3.1-UNIT-003: returns HealthData(restingHr: null, stepCount: null) when both data lists are empty',
      () async {
        when(
          mockHealth.requestAuthorization(
            any,
            permissions: anyNamed('permissions'),
          ),
        ).thenAnswer((_) async => true);
        when(
          mockHealth.getHealthDataFromTypes(
            startTime: anyNamed('startTime'),
            endTime: anyNamed('endTime'),
            types: anyNamed('types'),
          ),
        ).thenAnswer((_) async => []);

        final result = await sut.fetchHealthData();

        expect(result.restingHr, isNull);
        expect(result.stepCount, isNull);
      },
    );

    test('3.1-UNIT-004: wraps unknown exceptions as SensorException', () async {
      when(
        mockHealth.requestAuthorization(
          any,
          permissions: anyNamed('permissions'),
        ),
      ).thenThrow(Exception('platform channel error'));

      await expectLater(
        () => sut.fetchHealthData(),
        throwsA(isA<SensorException>()),
      );
    });

    test('3.1-UNIT-011: sums multiple step data points correctly', () async {
      final stepPoint1 = makePoint(
        type: HealthDataType.STEPS,
        unit: HealthDataUnit.COUNT,
        value: 2000.0,
      );
      final stepPoint2 = makePoint(
        type: HealthDataType.STEPS,
        unit: HealthDataUnit.COUNT,
        value: 3500.0,
      );

      when(
        mockHealth.requestAuthorization(
          any,
          permissions: anyNamed('permissions'),
        ),
      ).thenAnswer((_) async => true);
      when(
        mockHealth.getHealthDataFromTypes(
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          types: [HealthDataType.RESTING_HEART_RATE],
        ),
      ).thenAnswer((_) async => []);
      when(
        mockHealth.getHealthDataFromTypes(
          startTime: anyNamed('startTime'),
          endTime: anyNamed('endTime'),
          types: [HealthDataType.STEPS],
        ),
      ).thenAnswer((_) async => [stepPoint1, stepPoint2]);

      final result = await sut.fetchHealthData();

      expect(result.restingHr, isNull);
      expect(result.stepCount, equals(5500)); // 2000 + 3500
    });
  });
}
