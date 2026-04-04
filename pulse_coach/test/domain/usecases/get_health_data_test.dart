// [P1] GetHealthData use case unit tests
// Tests: call() fetches-then-saves on success, returns Left(SensorFailure) on fetch failure
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/health_data.dart';
import 'package:pulse_coach/features/session/domain/repositories/health_repository.dart';
import 'package:pulse_coach/features/session/domain/usecases/get_health_data.dart';

import 'get_health_data_test.mocks.dart';

@GenerateMocks([HealthRepository])
void main() {
  late MockHealthRepository mockRepository;
  late GetHealthData sut;

  const tHealthData = HealthData(restingHr: 58, stepCount: 12000);
  const tFailure = SensorFailure('Health permissions denied');

  setUp(() {
    mockRepository = MockHealthRepository();
    sut = GetHealthData(mockRepository);
  });

  group('GetHealthData', () {
    test(
      '3.1-UNIT-009: call() fetches then saves when fetch succeeds and returns Right(HealthData)',
      () async {
        when(mockRepository.fetchHealthData())
            .thenAnswer((_) async => const Right(tHealthData));
        when(mockRepository.saveHealthData(tHealthData))
            .thenAnswer((_) async => const Right(null));

        final result = await sut();

        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (data) {
            expect(data.restingHr, equals(58));
            expect(data.stepCount, equals(12000));
          },
        );
        verify(mockRepository.fetchHealthData()).called(1);
        verify(mockRepository.saveHealthData(tHealthData)).called(1);
      },
    );

    test(
      '3.1-UNIT-010: call() returns Left(SensorFailure) without calling save when fetch fails',
      () async {
        when(mockRepository.fetchHealthData())
            .thenAnswer((_) async => const Left(tFailure));

        final result = await sut();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<SensorFailure>());
            expect(failure.message, equals('Health permissions denied'));
          },
          (_) => fail('Expected Left(SensorFailure)'),
        );
        verify(mockRepository.fetchHealthData()).called(1);
        verifyNever(mockRepository.saveHealthData(any));
      },
    );

    test(
      '3.1-UNIT-012: returns Right(HealthData) even when saveHealthData fails (save failure silently dropped)',
      () async {
        when(mockRepository.fetchHealthData())
            .thenAnswer((_) async => const Right(tHealthData));
        when(mockRepository.saveHealthData(tHealthData))
            .thenAnswer((_) async => const Left(CacheFailure('DB full')));

        final result = await sut();

        // Save failure is intentionally swallowed — caller still gets Right(data)
        // See: review finding F1 deferred — Epic 5 will define persistence error strategy
        expect(result.isRight(), isTrue);
        result.fold(
          (_) => fail('Expected Right'),
          (data) => expect(data.restingHr, equals(58)),
        );
      },
    );
  });
}
