/// DTO for Open-Meteo Air Quality API response.
/// Custom fromJson — same reasoning as WeatherModel (nested 'current' key).
class AqiModel {
  final int europeanAqi;

  const AqiModel({required this.europeanAqi});

  /// Parses the full Open-Meteo air-quality response:
  /// { "current": { "european_aqi": 45 } }
  /// european_aqi can be null if data unavailable for the location.
  factory AqiModel.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    return AqiModel(
      europeanAqi: (current['european_aqi'] as num?)?.toInt() ?? 0,
    );
  }
}
