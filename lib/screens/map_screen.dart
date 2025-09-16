// lib/screens/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import '../utils/location_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  StreamSubscription<LocationData>? _locationSubscription;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() async {
    final initialLocation = await _locationService.getCurrentLocation();
    if (initialLocation != null) {
      final latLng = LatLng(initialLocation.latitude!, initialLocation.longitude!);
      if (mounted) {
        setState(() => _userLocation = latLng);
        _mapController.move(latLng, 15.0);
      }
    }

    _locationSubscription = _locationService.getLocationStream().listen((locationData) {
      if (mounted) {
        setState(() {
          _userLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });
      }
    });
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation ?? LatLng(10.8505, 76.2711), // Default to Kerala coast
          initialZoom: _userLocation != null ? 15.0 : 7.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          if (_userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: _userLocation!,
                  child: Icon(Icons.my_location, color: Colors.blue, size: 40.0),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUser,
        child: Icon(Icons.my_location),
      ),
    );
  }
}
