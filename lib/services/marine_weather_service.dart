// lib/services/marine_weather_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/marine_weather_alert.dart';

class MarineWeatherService {
  // This method is correct and does NOT need changes.
  Future<Map<String, dynamic>> fetchCombinedWeather(
      double latitude, double longitude) async {
    final forecastUrl = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'temperature_2m,wind_speed_10m',
    });
    final forecastResponse = await http.get(forecastUrl);

    final marineUrl = Uri.https('marine-api.open-meteo.com', '/v1/marine', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'wave_height',
      'hourly': 'wave_height',
    });
    final marineResponse = await http.get(marineUrl);

    if (forecastResponse.statusCode == 200 && marineResponse.statusCode == 200) {
      final forecastData = jsonDecode(forecastResponse.body) as Map<String, dynamic>;
      final marineData = jsonDecode(marineResponse.body) as Map<String, dynamic>;

      return {
        'current': {
          'temperature_2m': forecastData['current']?['temperature_2m'],
          'wind_speed_10m': forecastData['current']?['wind_speed_10m'],
          'wave_height': marineData['current']?['wave_height'],
        },
        'hourly': marineData['hourly'],
      };
    } else {
      throw Exception('Failed to fetch weather data from one or both APIs');
    }
  }

  // --- THIS IS THE FINAL FIX ---
  // This method is now updated to use the 'waveHeight' parameter correctly.
  List<MarineWeatherAlert> generateAlerts(
      Map<String, dynamic> data, double waveHeightThreshold) {
    final alerts = <MarineWeatherAlert>[];

    if (data.containsKey('hourly') && data['hourly'] != null) {
      final hourlyData = data['hourly'] as Map<String, dynamic>;
      final waveHeights = hourlyData['wave_height'] as List<dynamic>? ?? [];
      final times = hourlyData['time'] as List<dynamic>? ?? [];

      for (int i = 0; i < waveHeights.length; i++) {
        if (waveHeights[i] is num) {
          final waveHeight = (waveHeights[i] as num).toDouble();

          if (waveHeight >= waveHeightThreshold) {
            final time = DateTime.parse(times[i]);
            // Create an alert with the required 'waveHeight' parameter.
            alerts.add(MarineWeatherAlert(
              waveHeight: waveHeight,
              alertTime: time,
              severity: 'High',
            ));
          }
        }
      }
    }
    return alerts;
  }
}
