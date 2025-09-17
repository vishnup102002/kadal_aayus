import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:flutter_tts/flutter_tts.dart';
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

  final List<LatLng> seaSafeZoneKollam = [
    LatLng(8.9300, 76.5000), // North
    LatLng(8.9300, 76.5500), // North-East
    LatLng(8.8500, 76.5500), // South-East
    LatLng(8.8500, 76.5000), // South
  ];
  final List<LatLng> seaSafeZoneTrivandrum = [
    LatLng(8.4100, 76.9500), // North
    LatLng(8.4100, 77.0000), // North-East
    LatLng(8.3500, 77.0000), // South-East
    LatLng(8.3500, 76.9500), // South
  ];
  final List<LatLng> seaSafeZoneAlappuzha = [
    LatLng(9.5100, 76.2800), // North
    LatLng(9.5100, 76.3300), // North-East
    LatLng(9.4500, 76.3300), // South-East
    LatLng(9.4500, 76.2800), // South
  ];
  final List<LatLng> seaSafeZoneErnakulam = [
    LatLng(10.2000, 76.0500), // North
    LatLng(10.2000, 76.1000), // North-East
    LatLng(9.9000, 76.1000), // South-East
    LatLng(9.9000, 76.0500), // South
  ];
  final List<LatLng> seaSafeZoneThrissur = [
    LatLng(10.5500, 75.9500), // North
    LatLng(10.5500, 76.0000), // North-East
    LatLng(10.4500, 76.0000), // South-East
    LatLng(10.4500, 75.9500), // South
  ];
  final List<LatLng> seaSafeZoneMalappuram = [
    LatLng(10.9500, 75.8500), // North
    LatLng(10.9500, 75.9000), // North-East
    LatLng(10.8500, 75.9000), // South-East
    LatLng(10.8500, 75.8500), // South
  ];
  final List<LatLng> seaSafeZoneKozhikode = [
    LatLng(11.2000, 75.6000), // North
    LatLng(11.2000, 75.6500), // North-East
    LatLng(11.1000, 75.6500), // South-East
    LatLng(11.1000, 75.6000), // South
  ];
  final List<LatLng> seaSafeZoneKannur = [
    LatLng(11.9000, 75.4000), // North
    LatLng(11.9000, 75.4500), // North-East
    LatLng(11.8000, 75.4500), // South-East
    LatLng(11.8000, 75.4000), // South
  ];
  final List<LatLng> seaSafeZoneKasaragod = [
    LatLng(12.5000, 74.8000), // North
    LatLng(12.5000, 74.8500), // North-East
    LatLng(12.4000, 74.8500), // South-East
    LatLng(12.4000, 74.8000), // South
  ];

  late final List<List<LatLng>> safeZones;

  bool _isInsideSafeZone = false;

  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    safeZones = [
      seaSafeZoneKollam,
      seaSafeZoneTrivandrum,
      seaSafeZoneAlappuzha,
      seaSafeZoneErnakulam,
      seaSafeZoneThrissur,
      seaSafeZoneMalappuram,
      seaSafeZoneKozhikode,
      seaSafeZoneKannur,
      seaSafeZoneKasaragod
    ];
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
        final newLocation = LatLng(locationData.latitude!, locationData.longitude!);

        bool inside = _isPointInAnyPolygon(newLocation, safeZones);
        if (inside != _isInsideSafeZone) {
          _isInsideSafeZone = inside;
          _showSafeZoneAlert(inside);
        }

        setState(() {
          _userLocation = newLocation;
        });
      }
    });
  }

  bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    bool c = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i, i++) {
      if (((polygon[i].latitude > point.latitude) != (polygon[j].latitude > point.latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                  (point.latitude - polygon[i].latitude) /
                  (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        c = !c;
      }
    }
    return c;
  }

  bool _isPointInAnyPolygon(LatLng point, List<List<LatLng>> polygons) {
    for (var polygon in polygons) {
      if (_isPointInPolygon(point, polygon)) {
        return true;
      }
    }
    return false;
  }

  void _showSafeZoneAlert(bool entered) {
    final message = entered ? 'Entered Safe Zone' : 'Exited Safe Zone';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _flutterTts.speak(message);
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _userLocation ?? LatLng(10.8505, 76.2711),
          initialZoom: _userLocation != null ? 15.0 : 7.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          PolygonLayer(
            polygons: safeZones.map((zonePoints) => Polygon(
              points: zonePoints,
              color: Colors.green.withOpacity(0.3),
              borderColor: Colors.green,
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
                  child: Icon(Icons.my_location, color: Colors.blue, size: 40.0),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'center_location',
            tooltip: 'Center on current location',
            backgroundColor: Colors.blue,
            onPressed: _centerOnUser,
            child: Icon(Icons.my_location),
          ),
          SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'manual_test_location',
            tooltip: 'Test safe zone alert',
            backgroundColor: Colors.red,
            onPressed: () {
              final testLocation = LatLng(8.8900, 76.5300);
              bool inside = _isPointInAnyPolygon(testLocation, safeZones);
              setState(() {
                _userLocation = testLocation;
                if (inside != _isInsideSafeZone) {
                  _isInsideSafeZone = inside;
                  _showSafeZoneAlert(inside);
                }
                _mapController.move(testLocation, 15.0);
              });
            },
            child: Icon(Icons.location_pin),
          ),
        ],
      ),
    );
  }
}
