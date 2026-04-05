import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/constants/api_constants.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/features/weather/data/models/aqi_model.dart';
import 'package:pulse_coach/features/weather/data/models/weather_model.dart';

@injectable
class WeatherRemoteDataSource {
  WeatherRemoteDataSource(this._dio);
  final Dio _dio;

  /// Fetches weather forecast and AQI in parallel (two independent API calls).
  /// Throws [ServerException] on any network error or unexpected response.
  Future<(WeatherModel weather, AqiModel aqi)> fetchWeatherAndAqi({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Launch both futures before awaiting — parallel network calls
      final weatherFuture = _dio.get(
        ApiConstants.openMeteoBaseUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': 'temperature_2m',
          'hourly': 'precipitation_probability',
          'forecast_days': 1,
          'timezone': 'auto',
        },
      );
      final aqiFuture = _dio.get(
        ApiConstants.openMeteoAqiUrl,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'current': 'european_aqi',
        },
      );

      // Await both; if one fails, ignore the other's error to avoid unhandled futures
      final responses = await Future.wait(
        [weatherFuture, aqiFuture],
        eagerError: true,
      );
      final weatherResponse = responses[0];
      final aqiResponse = responses[1];

      final weather = WeatherModel.fromJson(weatherResponse.data as Map<String, dynamic>);
      final aqi = AqiModel.fromJson(aqiResponse.data as Map<String, dynamic>);
      return (weather, aqi);
    } on DioException catch (e) {
      throw ServerException('Open-Meteo request failed: ${e.message}');
    } catch (e) {
      throw ServerException('Unexpected error fetching weather: $e');
    }
  }
}
