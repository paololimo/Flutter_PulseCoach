// [P1] HealthRepositoryImpl unit tests
// Tests: fetchHealthData success/SensorException, saveHealthData success/DB error
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/database/daos/behavioral_state_dao.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/data/datasources/health_data_source.dart';
import 'package:pulse_coach/features/session/data/repositories/health_repository_impl.dart';
import 'package:pulse_coach/features/session/domain/entities/health_data.dart';

import 'health_repository_impl_test.mocks.dart';

@GenerateMocks([HealthDataSource, BehavioralStateDao])
void main() {
  late MockHealthDataSource mockDataSource;
  late MockBehavioralStateDao mockDao;
  late HealthRepositoryImpl sut;

  const tHealthData = HealthData(restingHr: 60, stepCount: 8000);

  setUp(() {
    mockDataSource = MockHealthDataSource();
    mockDao = MockBehavioralStateDao();
    sut = HealthRepositoryImpl(mockDataSource, mockDao);
  });

  group('HealthRepositoryImpl.fetchHealthData', () {
    test(
      '3.1-UNIT-005: returns Right(HealthData) when data source succeeds',
      () async {
        when(mockDataSource.fetchHealthData())
            .thenAnswer((_) async => tHealthData);

        final result = await sut.fetchHealthData();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (data) {
            expect(data.restingHr, equals(60));
            expect(data.stepCount, equals(8000));
          },
        );
      },
    );

    test(
      '3.1-UNIT-006: returns Left(SensorFailure) when data source throws SensorException',
      () async {
        when(mockDataSource.fetchHealthData())
            .thenThrow(const SensorException('Health permissions denied'));

        final result = await sut.fetchHealthData();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<SensorFailure>());
            expect(failure.message, equals('Health permissions denied'));
          },
          (_) => fail('Expected Left(SensorFailure)'),
        );
      },
    );
  });

  group('HealthRepositoryImpl.saveHealthData', () {
    test(
      '3.1-UNIT-007: calls behavioralStateDao.insertState() with correct companion and returns Right',
      () async {
        when(mockDao.insertState(any)).thenAnswer((_) async => 1);

        final result = await sut.saveHealthData(tHealthData);

        expect(result.isRight(), isTrue);
        final captured = verify(mockDao.insertState(captureAny)).captured.single;
        expect(captured.restingHr.value, equals(60));
        expect(captured.stepCount.value, equals(8000));
        expect(captured.currentState.value, equals('Active'));
      },
    );

    test(
      '3.1-UNIT-008: returns Left(CacheFailure) when DB throws',
      () async {
        when(mockDao.insertState(any)).thenThrow(Exception('DB write error'));

        final result = await sut.saveHealthData(tHealthData);

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected Left(CacheFailure)'),
        );
      },
    );
  });
}
