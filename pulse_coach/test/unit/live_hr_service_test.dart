import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/features/session/presentation/utils/live_hr_service.dart';

import '../data/datasources/health_data_source_test.mocks.dart';

HealthDataPoint _point(num value) {
  final now = DateTime.now();
  return HealthDataPoint(
    uuid: 'live-hr-$value',
    value: NumericHealthValue(numericValue: value),
    type: HealthDataType.HEART_RATE,
    unit: HealthDataUnit.BEATS_PER_MINUTE,
    dateFrom: now.subtract(const Duration(seconds: 1)),
    dateTo: now,
    sourcePlatform: HealthPlatformType.appleHealth,
    sourceDeviceId: '',
    sourceId: '',
    sourceName: '',
  );
}

void main() {
  group('HealthLiveHrService (Story 8.4)', () {
    late MockHealth health;
    late HealthLiveHrService service;

    setUp(() {
      health = MockHealth();
      service = HealthLiveHrService(health);
      when(health.configure()).thenAnswer((_) async {});
    });

    test(
      '8.4-SERVICE-001: fetchLiveHr returns latest rounded HEART_RATE value when authorized',
      () async {
        when(
          health.requestAuthorization(
            [HealthDataType.HEART_RATE],
            permissions: [HealthDataAccess.READ],
          ),
        ).thenAnswer((_) async => true);
        when(
          health.getHealthDataFromTypes(
            startTime: anyNamed('startTime'),
            endTime: anyNamed('endTime'),
            types: [HealthDataType.HEART_RATE],
          ),
        ).thenAnswer((_) async => [_point(71.2), _point(72.6)]);

        await service.init();

        expect(await service.fetchLiveHr(), 73);
      },
    );

    test(
      '8.4-SERVICE-002: fetchLiveHr returns null when permission is denied',
      () async {
        when(
          health.requestAuthorization(
            [HealthDataType.HEART_RATE],
            permissions: [HealthDataAccess.READ],
          ),
        ).thenAnswer((_) async => false);

        await service.init();

        expect(await service.fetchLiveHr(), isNull);
        verifyNever(
          health.getHealthDataFromTypes(
            startTime: anyNamed('startTime'),
            endTime: anyNamed('endTime'),
            types: anyNamed('types'),
          ),
        );
      },
    );

    test('8.4-SERVICE-003: init is idempotent', () async {
      when(
        health.requestAuthorization(
          [HealthDataType.HEART_RATE],
          permissions: [HealthDataAccess.READ],
        ),
      ).thenAnswer((_) async => true);

      await Future.wait([service.init(), service.init()]);
      await service.init();

      verify(health.configure()).called(1);
      verify(
        health.requestAuthorization(
          [HealthDataType.HEART_RATE],
          permissions: [HealthDataAccess.READ],
        ),
      ).called(1);
    });

    test(
      '8.4-SERVICE-004: health plugin failures are swallowed and return null',
      () async {
        when(
          health.requestAuthorization(
            [HealthDataType.HEART_RATE],
            permissions: [HealthDataAccess.READ],
          ),
        ).thenAnswer((_) async => true);
        when(
          health.getHealthDataFromTypes(
            startTime: anyNamed('startTime'),
            endTime: anyNamed('endTime'),
            types: [HealthDataType.HEART_RATE],
          ),
        ).thenThrow(Exception('sensor unavailable'));

        await service.init();

        expect(await service.fetchLiveHr(), isNull);
      },
    );
  });
}
