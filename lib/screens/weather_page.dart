// lib/screens/weather_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'marine_alerts_screen.dart';
import '../services/marine_weather_service.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final MarineWeatherService _marineWeatherService = MarineWeatherService();
  late Future<Map<String, dynamic>> _weatherFuture;

  String _currentLocationName = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _initLocationAndWeather();
  }

  /// Fetch location first, then weather
  Future<void> _initLocationAndWeather() async {
    try {
      final position = await _getCurrentPosition();
      final locationName = await _getAddressFromLatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _currentLocationName = locationName);

      _weatherFuture = _fetchCurrentWeather(position.latitude, position.longitude);
    } catch (e) {
      if (mounted) setState(() => _currentLocationName = 'Unknown location');
      _weatherFuture = _fetchCurrentWeather(10.0, 76.0); // fallback coords
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      return "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
    }
    return "Unknown location";
  }

  Future<Map<String, dynamic>> _fetchCurrentWeather(double latitude, double longitude) {
    return _marineWeatherService.fetchCombinedWeather(latitude, longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marine Weather')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Display current location at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _currentLocationName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),

          FutureBuilder<Map<String, dynamic>>(
            future: _weatherFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.red.shade100,
                  child: const Center(
                    child: Text('Could not fetch weather data.\nPlease check your connection.'),
                  ),
                );
              }
              if (snapshot.hasData) {
                final current = snapshot.data!['current'];
                final temperature = current['temperature_2m']?.toString() ?? '--';
                final windSpeed = current['wind_speed_10m']?.toString() ?? '--';
                final waveHeight = current['wave_height']?.toString() ?? '--';
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.blue.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Conditions', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildWeatherMetric(Icons.thermostat, temperature, '°C'),
                          _buildWeatherMetric(Icons.air, windSpeed, 'km/h'),
                          _buildWeatherMetric(Icons.waves, waveHeight, 'm'),
                        ],
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Marine Alerts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const Expanded(
            child: MarineAlertsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetric(IconData icon, String value, String unit) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Colors.blue.shade800),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        Text(unit, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}