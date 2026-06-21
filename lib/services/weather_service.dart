import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final String temp;
  final String humidity;
  final String windSpeed;
  final String description;
  final double latitude;
  final double longitude;

  WeatherData({
    required this.temp,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.latitude,
    required this.longitude,
  });
}

class WeatherService {
  Future<WeatherData> fetchWeather(String location) async {
    try {
      // 1. Geocode location name to latitude and longitude
      double lat = 18.52; // Default to Pune, India coordinates
      double lon = 73.85;
      
      try {
        final geocodeUrl = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(location)}&count=1&language=en&format=json',
        );
        final geocodeResponse = await http.get(geocodeUrl);
        if (geocodeResponse.statusCode == 200) {
          final data = json.decode(geocodeResponse.body);
          if (data['results'] != null && (data['results'] as List).isNotEmpty) {
            final firstResult = data['results'][0];
            lat = (firstResult['latitude'] as num).toDouble();
            lon = (firstResult['longitude'] as num).toDouble();
            print('Resolved location $location to Lat: $lat, Lon: $lon');
          }
        }
      } catch (ge) {
        print('Geocoding failed for $location: $ge. Using default coordinates.');
      }

      // 2. Fetch weather from Open-Meteo using the geocoded coordinates
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&windspeed_unit=kmh',
      );
      final weatherResponse = await http.get(weatherUrl);

      if (weatherResponse.statusCode == 200) {
        final data = json.decode(weatherResponse.body);
        final current = data['current'];
        
        final double tempVal = (current['temperature_2m'] as num).toDouble();
        final int humidityVal = (current['relative_humidity_2m'] as num).toInt();
        final double windSpeedVal = (current['wind_speed_10m'] as num).toDouble();
        final int weatherCode = (current['weather_code'] as num).toInt();
        
        final desc = _getWeatherDescription(weatherCode);

        return WeatherData(
          temp: '${tempVal.toStringAsFixed(1)}°C',
          humidity: '$humidityVal%',
          windSpeed: '${windSpeedVal.toStringAsFixed(1)} km/h',
          description: desc,
          latitude: lat,
          longitude: lon,
        );
      } else {
        throw Exception('Failed to fetch weather (Code: ${weatherResponse.statusCode})');
      }
    } catch (e) {
      print('Weather Service Error: $e. Falling back to local data.');
      return WeatherData(
        temp: '29.0°C',
        humidity: '72%',
        windSpeed: '12.0 km/h',
        description: 'Light Breeze, Partly Cloudy',
        latitude: 18.52,
        longitude: 73.85,
      );
    }
  }

  String _getWeatherDescription(int code) {
    switch (code) {
      case 0: return 'Clear Sky';
      case 1:
      case 2:
      case 3: return 'Partly Cloudy';
      case 45:
      case 48: return 'Foggy';
      case 51:
      case 53:
      case 55: return 'Drizzle';
      case 61:
      case 63:
      case 65: return 'Rainy';
      case 71:
      case 73:
      case 75: return 'Snowy';
      case 80:
      case 81:
      case 82: return 'Showers';
      case 95:
      case 96:
      case 99: return 'Thunderstorm';
      default: return 'Clear';
    }
  }
}
