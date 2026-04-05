/// Immutable snapshot of current weather and air quality conditions.
/// Used by StateVector (Story 5.1) to drive session routing decisions.
///
/// [aqiValue] is raw AQI (european_aqi from Open-Meteo). Story 5.1 applies
/// the threshold (≥ 100 = high, blocks outdoor sessions per FR8).
///
/// Plain class — NOT freezed. No copyWith or JSON serialization needed at
/// domain level; DTOs handle serialization in the data layer.
class WeatherContext {
  final double temperature; // °C, from Open-Meteo current.temperature_2m
  final double precipitationProbability; // 0–100%, from Open-Meteo hourly[0]
  final int aqiValue; // European AQI from air-quality API
  final DateTime cachedAt; // when this snapshot was fetched

  const WeatherContext({
    required this.temperature,
    required this.precipitationProbability,
    required this.aqiValue,
    required this.cachedAt,
  });

  /// True when AQI meets the "unhealthy for sensitive groups" threshold (FR8).
  /// Story 5.1 uses this to constrain session routing to indoor only.
  bool get isAqiHigh => aqiValue >= 100;
}
