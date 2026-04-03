// [3.2-UNIT-005..007] SensorRepositoryImpl unit tests
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/data/datasources/accelerometer_data_source.dart';
import 'package:pulse_coach/features/session/data/repositories/sensor_repository_impl.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';

import 'sensor_repository_impl_test.mocks.dart';

@GenerateMocks([AccelerometerDataSource])
void main() {
  late MockAccelerometerDataSource mockDataSource;
  late SensorRepositoryImpl sut;

  setUp(() {
    mockDataSource = MockAccelerometerDataSource();
    sut = SensorRepositoryImpl(mockDataSource);
  });

  group('SensorRepositoryImpl.fetchActivityLevel', () {
    // ── 3.2-UNIT-005 ─────────────────────────────────────────────────────────
    test('3.2-UNIT-005: returns Right(ActivityLevel) when datasource succeeds',
        () async {
      when(mockDataSource.fetchActivityLevel())
          .thenAnswer((_) async => ActivityLevel.active);

      final result = await sut.fetchActivityLevel();

      expect(result, const Right(ActivityLevel.active));
    });

    // ── 3.2-UNIT-006 ─────────────────────────────────────────────────────────
    test(
        '3.2-UNIT-006: returns Left(SensorFailure) when datasource throws SensorException',
        () async {
      when(mockDataSource.fetchActivityLevel())
          .thenThrow(const SensorException('Some platform error'));

      final result = await sut.fetchActivityLevel();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<SensorFailure>());
          expect(failure.message, 'Accelerometer unavailable');
        },
        (_) => fail('Expected Left'),
      );
    });

    // ── 3.2-UNIT-007 ─────────────────────────────────────────────────────────
    test(
        '3.2-UNIT-007: returns Left(SensorFailure) on unexpected exception',
        () async {
      when(mockDataSource.fetchActivityLevel())
          .thenThrow(Exception('Unexpected'));

      final result = await sut.fetchActivityLevel();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<SensorFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
