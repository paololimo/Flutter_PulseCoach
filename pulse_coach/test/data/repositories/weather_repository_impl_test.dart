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
      when(mockLocal.getCachedWeather()).thenAnswer((_) async => null);
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
      when(mockLocal.getCachedWeather()).thenAnswer((_) async => null);
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
        '4.1-UNIT-006b: cache write throws CacheException → Right(fresh data) anyway',
        () async {
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockLocal.getCachedWeather()).thenAnswer((_) async => null);
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

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected Right'),
        (context) {
          expect(context.temperature, 20.0);
          expect(context.precipitationProbability, 30.0);
          expect(context.aqiValue, 50);
        },
      );
    });

    // ── 4.2-UNIT-001 ─────────────────────────────────────────────────────────
    test(
        '4.2-UNIT-001: fresh cache (< 1h old) → Right(cachedContext), fetchWeatherAndAqi NOT called',
        () async {
      final freshCachedAt = DateTime.now().toUtc().subtract(const Duration(minutes: 30));
      final cachedContext = WeatherContext(
        temperature: 18.0,
        precipitationProbability: 10.0,
        aqiValue: 40,
        cachedAt: freshCachedAt,
      );
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockLocal.getCachedWeather()).thenAnswer((_) async => cachedContext);

      final result = await sut.getWeatherContext();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (context) {
        expect(context.temperature, 18.0);
        expect(context.cachedAt, freshCachedAt);
      });
      verifyNever(mockRemote.fetchWeatherAndAqi(
        latitude: anyNamed('latitude'),
        longitude: anyNamed('longitude'),
      ));
    });

    // ── 4.2-UNIT-002 ─────────────────────────────────────────────────────────
    test(
        '4.2-UNIT-002: stale cache (> 1h old), API reachable → fresh data fetched, cacheWeather called once',
        () async {
      final staleCachedAt = DateTime.now().toUtc().subtract(const Duration(hours: 2));
      final staleContext = WeatherContext(
        temperature: 15.0,
        precipitationProbability: 50.0,
        aqiValue: 30,
        cachedAt: staleCachedAt,
      );
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockLocal.getCachedWeather()).thenAnswer((_) async => staleContext);
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
        expect(context.temperature, 20.0);
        expect(context.cachedAt.isAfter(staleCachedAt), isTrue);
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

    // ── 4.2-UNIT-003 ─────────────────────────────────────────────────────────
    test(
        '4.2-UNIT-003: no cache, API reachable → fresh data fetched and returned, cacheWeather called once',
        () async {
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockLocal.getCachedWeather()).thenAnswer((_) async => null);
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
        expect(context.temperature, 20.0);
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

    // ── 4.2-UNIT-004 ─────────────────────────────────────────────────────────
    test(
        '4.2-UNIT-004: stale cache, API unreachable → stale context returned (AC3)',
        () async {
      final staleCachedAt = DateTime.now().toUtc().subtract(const Duration(hours: 3));
      final staleContext = WeatherContext(
        temperature: 12.0,
        precipitationProbability: 80.0,
        aqiValue: 60,
        cachedAt: staleCachedAt,
      );
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockLocal.getCachedWeather()).thenAnswer((_) async => staleContext);
      when(mockRemote.fetchWeatherAndAqi(latitude: 48.8, longitude: 2.3))
          .thenThrow(const ServerException('timeout'));

      final result = await sut.getWeatherContext();

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Expected Right'), (context) {
        expect(context.cachedAt, staleCachedAt);
      });
      verifyNever(
        mockLocal.cacheWeather(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          temperature: anyNamed('temperature'),
          precipitationProbability: anyNamed('precipitationProbability'),
          aqiValue: anyNamed('aqiValue'),
          cachedAt: anyNamed('cachedAt'),
        ),
      );
    });

    // ── 4.2-UNIT-005 ─────────────────────────────────────────────────────────
    test(
        '4.2-UNIT-005: no cache, API unreachable → Left(ServerFailure)',
        () async {
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockLocal.getCachedWeather()).thenAnswer((_) async => null);
      when(mockRemote.fetchWeatherAndAqi(latitude: 48.8, longitude: 2.3))
          .thenThrow(const ServerException('timeout'));

      final result = await sut.getWeatherContext();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    // ── 4.2-UNIT-007 ─────────────────────────────────────────────────────────
    test(
        '4.2-UNIT-007: getCachedWeather throws CacheException → non-fatal, falls through to network',
        () async {
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockLocal.getCachedWeather())
          .thenThrow(const CacheException('DB read failed'));
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
        expect(context.temperature, 20.0);
      });
      verify(mockRemote.fetchWeatherAndAqi(
        latitude: 48.8,
        longitude: 2.3,
      )).called(1);
    });

    // ── 4.2-UNIT-008 ─────────────────────────────────────────────────────────
    test(
        '4.2-UNIT-008: cache exactly 1h old is stale → triggers network fetch (TTL boundary)',
        () async {
      // difference == 1h is NOT < 1h → stale; documents the exact boundary
      final exactlyAtBoundary =
          DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final staleContext = WeatherContext(
        temperature: 15.0,
        precipitationProbability: 50.0,
        aqiValue: 30,
        cachedAt: exactlyAtBoundary,
      );
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockLocal.getCachedWeather()).thenAnswer((_) async => staleContext);
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
        expect(context.temperature, 20.0); // fresh data fetched, not stale 15.0
      });
      verify(mockRemote.fetchWeatherAndAqi(
        latitude: 48.8,
        longitude: 2.3,
      )).called(1);
    });

    // ── 4.1-UNIT-007 ─────────────────────────────────────────────────────────
    test(
        '4.1-UNIT-007: AQI = 110 (high threshold) → WeatherContext.isAqiHigh == true',
        () async {
      const highAqiModel = AqiModel(europeanAqi: 110);
      when(mockLocation.getCityLevelCoordinates())
          .thenAnswer((_) async => const Right((48.8, 2.3)));
      when(mockLocal.getCachedWeather()).thenAnswer((_) async => null);
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
