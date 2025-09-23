// lib/screens/marine_alerts_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../models/marine_weather_alert.dart';
import '../services/marine_weather_service.dart';
import '../services/notification_service.dart';
import '../utils/tts_service.dart';

class MarineAlertsScreen extends StatefulWidget {
  const MarineAlertsScreen({super.key});
  @override
  State<MarineAlertsScreen> createState() => _MarineAlertsScreenState();
}

class _MarineAlertsScreenState extends State<MarineAlertsScreen> {
  late Box<MarineWeatherAlert> _marineAlertsBox;
  List<MarineWeatherAlert> _marineAlerts = [];
  final MarineWeatherService _marineWeatherService = MarineWeatherService();
  final NotificationService _notificationService = NotificationService();
  final TtsService _ttsService = TtsService();
  Timer? _weatherUpdateTimer;
  bool _isLoading = true;
  String _currentLocationName = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _marineAlertsBox = Hive.box<MarineWeatherAlert>('marineAlertsBox');

    _initLocationAndFetchAlerts();

    // Schedule updates every 30 minutes
    _weatherUpdateTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _fetchAndProcessMarineWeather();
    });
  }

  @override
  void dispose() {
    _weatherUpdateTimer?.cancel();
    _ttsService.stop();
    super.dispose();
  }

  /// Initialize location and fetch alerts
  Future<void> _initLocationAndFetchAlerts() async {
    try {
      final position = await _getCurrentPosition();
      final latitude = position.latitude;
      final longitude = position.longitude;

      final locationName = await _getAddressFromLatLng(latitude, longitude);
      if (mounted) setState(() => _currentLocationName = locationName);

      await _fetchAndProcessMarineWeather(latitude: latitude, longitude: longitude);
    } catch (e) {
      if (kDebugMode) print("Error fetching location: $e");
      if (mounted) setState(() => _currentLocationName = 'Unknown location');
      await _fetchAndProcessMarineWeather(); // fallback with default coords
    }
  }

  /// Get current device position
  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
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

  /// Convert lat/lng to human-readable address
  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      return "${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
    }
    return "Unknown location";
  }

  /// Fetch and process marine weather alerts
  Future<void> _fetchAndProcessMarineWeather({double latitude = 10.0, double longitude = 76.0}) async {
    try {
      final data = await _marineWeatherService.fetchCombinedWeather(latitude, longitude);
      final newAlerts = _marineWeatherService.generateAlerts(data, 2.5);

      if (newAlerts.isNotEmpty) {
        for (var alert in newAlerts) {
          final key = alert.alertTime.toIso8601String();
          if (!_marineAlertsBox.containsKey(key)) {
            await _marineAlertsBox.put(key, alert);

            final spokenTime = DateFormat('hh:mm a, dd MMMM yyyy', 'ml_IN').format(alert.alertTime);
            final fullSpokenMessage = 'ഉയർന്ന തിരമാല മുന്നറിയിപ്പ്: ${alert.waveHeight} മീറ്റർ. സമയം: $spokenTime';

            _ttsService.speak(fullSpokenMessage);

            _notificationService.showNotification(
              id: alert.alertTime.millisecondsSinceEpoch % 2147483647,
              title: 'ഉയർന്ന തിരമാല മുന്നറിയിപ്പ്',
              body: '${alert.waveHeight} മീറ്റർ. സമയം: $spokenTime',
            );
          }
        }
        _loadCachedAlerts();
      }
    } catch (e) {
      if (kDebugMode) print("Error in marine_alerts_screen: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Load cached alerts from Hive
  void _loadCachedAlerts() {
    var alerts = _marineAlertsBox.values.toList();
    alerts.sort((a, b) => b.alertTime.compareTo(a.alertTime));
    if (mounted) setState(() => _marineAlerts = alerts);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _marineAlerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display current location
        Expanded(
          child: _marineAlerts.isEmpty
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No marine weather alerts for your area.',
                textAlign: TextAlign.center,
              ),
            ),
          )
              : ListView.builder(
            itemCount: _marineAlerts.length,
            itemBuilder: (context, index) {
              final alert = _marineAlerts[index];
              final formattedTime = DateFormat('hh:mm a, dd MMM').format(alert.alertTime);
              final displayMessage = 'High wave alert: ${alert.waveHeight} meters';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(Icons.waves, color: Colors.blue.shade700),
                  title: Text(displayMessage),
                  subtitle: Text('At $formattedTime'),
                  onTap: () {
                    final spokenTime = DateFormat('hh:mm a, dd MMMM yyyy', 'ml_IN').format(alert.alertTime);
                    final fullSpokenMessage =
                        'മുന്നറിയിപ്പ്: ${alert.waveHeight} മീറ്റർ ഉയർന്ന തിരമാല. സമയം: $spokenTime';
                    _ttsService.speak(fullSpokenMessage);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}