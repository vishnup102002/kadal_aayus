// lib/screens/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Services and Controllers
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  final FlutterTts _flutterTts = FlutterTts();

  // State variables
  StreamSubscription<LocationData>? _locationSubscription;
  LatLng? _userLocation;
  bool _isInsideSafeZone = false;

  // Data for safe zones
  final List<List<LatLng>> safeZones = [
    [LatLng(8.9300, 76.5000), LatLng(8.9300, 76.5500), LatLng(8.8500, 76.5500), LatLng(8.8500, 76.5000)], // Kollam
    [LatLng(8.4100, 76.9500), LatLng(8.4100, 77.0000), LatLng(8.3500, 77.0000), LatLng(8.3500, 76.9500)], // Trivandrum
    [LatLng(9.5100, 76.2800), LatLng(9.5100, 76.3300), LatLng(9.4500, 76.3300), LatLng(9.4500, 76.2800)], // Alappuzha
    [LatLng(10.2000, 76.0500), LatLng(10.2000, 76.1000), LatLng(9.9000, 76.1000), LatLng(9.9000, 76.0500)], // Ernakulam
    [LatLng(10.5500, 75.9500), LatLng(10.5500, 76.0000), LatLng(10.4500, 76.0000), LatLng(10.4500, 75.9500)], // Thrissur
    [LatLng(10.9500, 75.8500), LatLng(10.9500, 75.9000), LatLng(10.8500, 75.9000), LatLng(10.8500, 75.8500)], // Malappuram
    [LatLng(11.2000, 75.6000), LatLng(11.2000, 75.6500), LatLng(11.1000, 75.6500), LatLng(11.1000, 75.6000)], // Kozhikode
    [LatLng(11.9000, 75.4000), LatLng(11.9000, 75.4500), LatLng(11.8000, 75.4500), LatLng(11.8000, 75.4000)], // Kannur
    [LatLng(12.5000, 74.8000), LatLng(12.5000, 74.8500), LatLng(12.4000, 74.8500), LatLng(12.4000, 74.8000)], // Kasaragod
  ];

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  void _startLocationUpdates() async {
    final initialLocation = await _locationService.getCurrentLocation();
    if (initialLocation != null && mounted) {
      final latLng = LatLng(initialLocation.latitude!, initialLocation.longitude!);
      setState(() => _userLocation = latLng);
      _mapController.move(latLng, 15.0);
      _checkAndAlertSafeZone(latLng);
    }

    _locationSubscription = _locationService.getLocationStream().listen((locationData) {
      if (mounted) {
        final newLocation = LatLng(locationData.latitude!, locationData.longitude!);
        setState(() => _userLocation = newLocation);
        _checkAndAlertSafeZone(newLocation);
      }
    });
  }

  void _checkAndAlertSafeZone(LatLng point) {
    bool isCurrentlyInside = _isPointInAnyPolygon(point, safeZones);
    if (isCurrentlyInside != _isInsideSafeZone) {
      setState(() => _isInsideSafeZone = isCurrentlyInside);
      _showSafeZoneAlert(isCurrentlyInside);
    }
  }

  bool _isPointInAnyPolygon(LatLng point, List<List<LatLng>> polygons) {
    for (var polygon in polygons) {
      if (_isPointInPolygon(point, polygon)) return true;
    }
    return false;
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool isInside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude < (polygon[j].longitude - polygon[i].longitude) * (point.latitude - polygon[i].latitude) / (polygon[j].latitude - polygon[i].latitude) + polygon[i].longitude)) {
        isInside = !isInside;
      }
    }
    return isInside;
  }

  void _showSafeZoneAlert(bool entered) {
    final message = entered ? 'You have entered a designated safe zone.' : 'You have exited the safe zone.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: entered ? Colors.green : Colors.orange,
    ));
    _flutterTts.speak(message);
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for current location...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Map View'),
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.black,
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation ?? const LatLng(10.8505, 76.2711), // Default to Kerala center
          initialZoom: _userLocation != null ? 15.0 : 7.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          PolygonLayer(
            polygons: safeZones.map((zonePoints) => Polygon(
              points: zonePoints,
              color: Colors.green.withOpacity(0.3),
              borderColor: Colors.green.shade800,
              borderStrokeWidth: 3,
            )).toList(),
          ),
          if (_userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: _userLocation!,
                  child: const Icon(Icons.location_on, color: Colors.blue, size: 40.0),
                ),
              ],
            ),
        ],
      ),
      // --- CONSOLIDATED a Column of Floating Action Buttons ---
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'center_button',
            tooltip: 'Center on my location',
            backgroundColor: Colors.blue,
            onPressed: _centerOnUser,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'test_button',
            tooltip: 'Test safe zone entry',
            backgroundColor: Colors.orange,
            onPressed: () {
              final testLocation = LatLng(8.8900, 76.5300); // A point inside the Kollam safe zone
              setState(() => _userLocation = testLocation);
              _mapController.move(testLocation, 15.0);
              _checkAndAlertSafeZone(testLocation);
            },
            child: const Icon(Icons.rule_folder),
          ),
        ],
      ),
    );
  }
}
