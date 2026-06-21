class PredictionModel {
  final String timestamp;
  final String liveTemp;
  final String shortTermForecast;
  final String vedicLongTermForecast;
  final String? liveHumidity;
  final String? liveWindSpeed;

  PredictionModel({
    required this.timestamp,
    required this.liveTemp,
    required this.shortTermForecast,
    required this.vedicLongTermForecast,
    this.liveHumidity,
    this.liveWindSpeed,
  });

  Map<String, dynamic> toMap() {
    return {
      'live_temp': liveTemp,
      'short_term_forecast': shortTermForecast,
      'vedic_long_term_forecast': vedicLongTermForecast,
      if (liveHumidity != null) 'live_humidity': liveHumidity,
      if (liveWindSpeed != null) 'live_wind_speed': liveWindSpeed,
    };
  }

  factory PredictionModel.fromMap(Map<dynamic, dynamic> map, String timestamp) {
    return PredictionModel(
      timestamp: timestamp,
      liveTemp: map['live_temp'] as String? ?? '',
      shortTermForecast: map['short_term_forecast'] as String? ?? '',
      vedicLongTermForecast: map['vedic_long_term_forecast'] as String? ?? '',
      liveHumidity: map['live_humidity'] as String?,
      liveWindSpeed: map['live_wind_speed'] as String?,
    );
  }
}
