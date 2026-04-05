// [4.1-UNIT-001..003] WeatherRemoteDataSource unit tests
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/constants/api_constants.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/weather/data/datasources/weather_remote_data_source.dart';

import 'weather_remote_data_source_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  late MockDio mockDio;
  late WeatherRemoteDataSource sut;

  setUp(() {
    mockDio = MockDio();
    sut = WeatherRemoteDataSource(mockDio);
  });

  group('WeatherRemoteDataSource.fetchWeatherAndAqi', () {
    const double lat = 48.8;
    const double lon = 2.3;

    // ── 4.1-UNIT-001 ─────────────────────────────────────────────────────────
    test('4.1-UNIT-001: success returns correct WeatherModel and AqiModel',
        () async {
      when(
        mockDio.get(
          ApiConstants.openMeteoBaseUrl,
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'current': {'temperature_2m': 22.5},
            'hourly': {
              'precipitation_probability': [40, 50, 30],
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.openMeteoBaseUrl),
        ),
      );
      when(
        mockDio.get(
          ApiConstants.openMeteoAqiUrl,
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'current': {'european_aqi': 45},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.openMeteoAqiUrl),
        ),
      );

      final (weather, aqi) =
          await sut.fetchWeatherAndAqi(latitude: lat, longitude: lon);

      expect(weather.temperature, 22.5);
      expect(weather.precipitationProbability, 40.0);
      expect(aqi.europeanAqi, 45);
    });

    // ── 4.1-UNIT-002 ─────────────────────────────────────────────────────────
    test(
        '4.1-UNIT-002: DioException on weather call throws ServerException',
        () async {
      when(
        mockDio.get(
          ApiConstants.openMeteoBaseUrl,
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ApiConstants.openMeteoBaseUrl),
          message: 'timeout',
        ),
      );
      // AQI might or might not be called — allow it
      when(
        mockDio.get(
          ApiConstants.openMeteoAqiUrl,
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'current': {'european_aqi': 45},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.openMeteoAqiUrl),
        ),
      );

      expect(
        () => sut.fetchWeatherAndAqi(latitude: lat, longitude: lon),
        throwsA(isA<ServerException>()),
      );
    });

    // ── 4.1-UNIT-003 ─────────────────────────────────────────────────────────
    test('4.1-UNIT-003: AQI above threshold (europeanAqi=120) parsed correctly',
        () async {
      when(
        mockDio.get(
          ApiConstants.openMeteoBaseUrl,
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'current': {'temperature_2m': 25.0},
            'hourly': {
              'precipitation_probability': [0],
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.openMeteoBaseUrl),
        ),
      );
      when(
        mockDio.get(
          ApiConstants.openMeteoAqiUrl,
          queryParameters: anyNamed('queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response(
          data: {
            'current': {'european_aqi': 120},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ApiConstants.openMeteoAqiUrl),
        ),
      );

      final (_, aqi) =
          await sut.fetchWeatherAndAqi(latitude: lat, longitude: lon);

      expect(aqi.europeanAqi, 120);
    });
  });
}
