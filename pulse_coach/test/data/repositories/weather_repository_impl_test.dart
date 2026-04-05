// [4.1-UNIT-004..007] WeatherRepositoryImpl unit tests
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/utils/location_service.dart';
import 'package:pulse_coach/features/weather/data/datasources/weather_local_data_source.dart';
import 'package:pulse_coach/features/weather/data/datasources/weather_remote_data_source.dart';
import 'package:pulse_coach/features/weather/data/models/aqi_model.dart';
import 'package:pulse_coach/features/weather/data/models/weather_model.dart';
import 'package:pulse_coach/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:pulse_coach/features/weather/domain/entities/weather_context.dart';

import 'weather_repository_impl_test.mocks.dart';

@GenerateMocks([WeatherRemoteDataSource, WeatherLocalDataSource, LocationService])
void main() {
  late MockWeatherRemoteDataSource mockRemote;
  late MockWeatherLocalDataSource mockLocal;
  late MockLocationService mockLocation;
  late WeatherRepositoryImpl sut;

  setUp(() {
    mockRemote = MockWeatherRemoteDataSource();
    mockLocal = MockWeatherLocalDataSource();
    mockLocation = MockLocationService();
    sut = WeatherRepositoryImpl(mockRemote, mockLocal, mockLocation);
  });

  group('WeatherRepositoryImpl.getWeatherContext', () {
    const weatherModel = WeatherModel(temperature: 20.0, precipitationProbability: 30.0);
    const aqiModel = AqiModel(europeanAqi: 50);

    // ── 4.1-UNIT-004 ─────────────────────────────────────────────────────────
    test(
        '4.1-UNIT-004: location available + API succeeds → Right(WeatherContext), cacheWeather called once',
        () async {
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockRemote.fetchWeatherAndAqi(latitude: 48.8, longitude: 2.3))
          .thenAnswer((_) async => (weatherModel, aqiModel));
      when(
        mockLocal.cacheWeather(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          temperature: anyNamed('temperature'),
          precipitationProbability: anyNamed('precipitationProbability'),
          aqiValue: anyNamed('aqiValue'),
          cachedAt: anyNamed('cachedAt'),
        ),
      ).thenAnswer((_) async {});

      final result = await sut.getWeatherContext();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (context) {
        expect(context, isA<WeatherContext>());
        expect(context.temperature, 20.0);
        expect(context.precipitationProbability, 30.0);
        expect(context.aqiValue, 50);
      });
      verify(
        mockLocal.cacheWeather(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          temperature: anyNamed('temperature'),
          precipitationProbability: anyNamed('precipitationProbability'),
          aqiValue: anyNamed('aqiValue'),
          cachedAt: anyNamed('cachedAt'),
        ),
      ).called(1);
    });

    // ── 4.1-UNIT-005 ─────────────────────────────────────────────────────────
    test(
        '4.1-UNIT-005: location denied → Left(LocationFailure), remote NOT called',
        () async {
      when(mockLocation.getCityLevelCoordinates()).thenAnswer(
        (_) async => Left(LocationFailure('Permission denied')),
      );

      final result = await sut.getWeatherContext();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<LocationFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyNever(mockRemote.fetchWeatherAndAqi(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      ));
    });

    // ── 4.1-UNIT-006 ─────────────────────────────────────────────────────────
    test(
        '4.1-UNIT-006: location available, API throws ServerException → Left(ServerFailure)',
        () async {
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockRemote.fetchWeatherAndAqi(latitude: 48.8, longitude: 2.3))
          .thenThrow(const ServerException('timeout'));

      final result = await sut.getWeatherContext();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyNever(mockLocal.cacheWeather(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
        temperature: anyNamed('temperature'),
        precipitationProbability: anyNamed('precipitationProbability'),
        aqiValue: anyNamed('aqiValue'),
        cachedAt: anyNamed('cachedAt'),
      ));
    });

    // ── 4.1-UNIT-006b ────────────────────────────────────────────────────────
    test(
        '4.1-UNIT-006b: cache write throws CacheException → Left(ServerFailure)',
        () async {
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockRemote.fetchWeatherAndAqi(latitude: 48.8, longitude: 2.3))
          .thenAnswer((_) async => (weatherModel, aqiModel));
      when(
        mockLocal.cacheWeather(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          temperature: anyNamed('temperature'),
          precipitationProbability: anyNamed('precipitationProbability'),
          aqiValue: anyNamed('aqiValue'),
          cachedAt: anyNamed('cachedAt'),
        ),
      ).thenThrow(const CacheException('DB write failed'));

      final result = await sut.getWeatherContext();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(
            (failure as ServerFailure).message,
            contains('Cache write failed'),
          );
        },
        (_) => fail('Expected Left'),
      );
    });

    // ── 4.1-UNIT-007 ─────────────────────────────────────────────────────────
    test(
        '4.1-UNIT-007: AQI = 110 (high threshold) → WeatherContext.isAqiHigh == true',
        () async {
      const highAqiModel = AqiModel(europeanAqi: 110);
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockRemote.fetchWeatherAndAqi(latitude: 48.8, longitude: 2.3))
          .thenAnswer((_) async => (weatherModel, highAqiModel));
      when(
        mockLocal.cacheWeather(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          temperature: anyNamed('temperature'),
          precipitationProbability: anyNamed('precipitationProbability'),
          aqiValue: anyNamed('aqiValue'),
          cachedAt: anyNamed('cachedAt'),
        ),
      ).thenAnswer((_) async {});

      final result = await sut.getWeatherContext();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (context) => expect(context.isAqiHigh, isTrue),
      );
    });
  });
}
