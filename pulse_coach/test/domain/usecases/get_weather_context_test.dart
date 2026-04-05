// [4.1-UNIT-008..009] GetWeatherContext use case unit tests
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';
import 'package:pulse_coach/features/weather/domain/repositories/weather_repository.dart';
import 'package:pulse_coach/features/weather/domain/usecases/get_weather_context.dart';

import 'get_weather_context_test.mocks.dart';

@GenerateMocks([WeatherRepository])
void main() {
  late MockWeatherRepository mockRepository;
  late GetWeatherContext sut;

  setUp(() {
    mockRepository = MockWeatherRepository();
    sut = GetWeatherContext(mockRepository);
  });

  group('GetWeatherContext', () {
    final context = WeatherContext(
      temperature: 20.0,
      precipitationProbability: 30.0,
      aqiValue: 50,
      cachedAt: DateTime.utc(2026, 4, 5, 12),
    );

    // ── 4.1-UNIT-008 ─────────────────────────────────────────────────────────
    test(
        '4.1-UNIT-008: repo returns Right → use case returns Right (pass-through verified)',
        () async {
      when(mockRepository.getWeatherContext())
          .thenAnswer((_) async => Right(context));

      final result = await sut();

      expect(result, Right(context));
      verify(mockRepository.getWeatherContext()).called(1);
    });

    // ── 4.1-UNIT-009 ─────────────────────────────────────────────────────────
    test(
        '4.1-UNIT-009: repo returns Left(ServerFailure) → use case returns Left (pass-through verified)',
        () async {
      when(mockRepository.getWeatherContext()).thenAnswer(
        (_) async => const Left(ServerFailure('API error')),
      );

      final result = await sut();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
      verify(mockRepository.getWeatherContext()).called(1);
    });
  });
}
