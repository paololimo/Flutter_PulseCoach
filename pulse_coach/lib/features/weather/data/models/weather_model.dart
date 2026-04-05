/// DTO for Open-Meteo Forecast API response.
/// Custom fromJson — NOT json_serializable — because the API nests data under
/// 'current' and 'hourly' keys, making generated code verbose and fragile.
class WeatherModel {
  final double temperature;
  final double precipitationProbability;

  const WeatherModel({
    required this.temperature,
    required this.precipitationProbability,
  });

  /// Parses the full Open-Meteo forecast response:
  /// {
  ///   "current": { "temperature_2m": 18.5 },
  ///   "hourly": { "precipitation_probability": [20, 30, ...] }
  /// }
  /// precipitation_probability is NOT available under 'current' — must use hourly[0]
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final hourly = json['hourly'] as Map<String, dynamic>;
    final precipList = hourly['precipitation_probability'] as List<dynamic>;
    return WeatherModel(
      temperature: (current['temperature_2m'] as num).toDouble(),
      precipitationProbability: precipList.isNotEmpty
          ? (precipList[0] as num?)?.toDouble() ?? 0.0
          : 0.0,
    );
  }
}
