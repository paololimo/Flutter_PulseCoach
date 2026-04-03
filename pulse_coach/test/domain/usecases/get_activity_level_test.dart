// [3.2-UNIT-008..009] GetActivityLevel use case unit tests
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/session/domain/entities/activity_level.dart';
import 'package:pulse_coach/features/session/domain/repositories/sensor_repository.dart';
import 'package:pulse_coach/features/session/domain/usecases/get_activity_level.dart';

import 'get_activity_level_test.mocks.dart';

@GenerateMocks([SensorRepository])
void main() {
  late MockSensorRepository mockRepository;
  late GetActivityLevel sut;

  setUp(() {
    mockRepository = MockSensorRepository();
    sut = GetActivityLevel(mockRepository);
  });

  group('GetActivityLevel', () {
    // ── 3.2-UNIT-008 ─────────────────────────────────────────────────────────
    test('3.2-UNIT-008: delegates to SensorRepository.fetchActivityLevel()',
        () async {
      when(mockRepository.fetchActivityLevel())
          .thenAnswer((_) async => const Right(ActivityLevel.moderate));

      final result = await sut();

      verify(mockRepository.fetchActivityLevel()).called(1);
      expect(result, const Right(ActivityLevel.moderate));
    });

    // ── 3.2-UNIT-009 ─────────────────────────────────────────────────────────
    test('3.2-UNIT-009: returns Left(SensorFailure) when repository fails',
        () async {
      const failure = SensorFailure('Accelerometer unavailable');
      when(mockRepository.fetchActivityLevel())
          .thenAnswer((_) async => const Left(failure));

      final result = await sut();

      expect(result.isLeft(), isTrue);
      result.fold(
        (f) => expect(f, isA<SensorFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
