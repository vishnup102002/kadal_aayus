// lib/screens/map_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// Import the location service you created
import '../utils/location_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LocationService _locationService = LocationService();
  MapboxMap? _mapboxMap;
  StreamSubscription<LocationData>? _locationSubscription;
  Point? _userLocation;

  @override
  void initState() {
    super.initState();
    // Start listening for location changes as soon as the screen is loaded
    _startLocationUpdates();
  }

  // This function sets up the map once it's created
  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    // Enable the built-in user location puck (the blue dot)
    _mapboxMap?.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true, // Adds a nice animation
      ),
    );
  }

  // This function gets location updates and moves the camera
  void _startLocationUpdates() async {
    // Get the very first location to quickly center the map
    final initialLocation = await _locationService.getCurrentLocation();
    if (initialLocation != null) {
      _centerMapOnLocation(initialLocation);
    }

    // Then, start a stream to listen for continuous updates
    _locationSubscription = _locationService.getLocationStream().listen((locationData) {
      if (mounted) { // Ensure the widget is still in the tree
        setState(() {
          _userLocation = Point.fromLngLat(locationData.longitude!, locationData.latitude!);
        });
        // Optionally, you can keep centering the map on the user
        // _centerMapOnLocation(locationData);
      }
    });
  }

  void _centerMapOnLocation(LocationData locationData) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point.fromLngLat(locationData.longitude!, locationData.latitude!),
        zoom: 15.0, // Zoom in closer
      ),
      MapAnimationOptions(duration: 1500),
    );
  }

  // We need to update the location service to provide a stream
  // This is a placeholder; you'll need to update `location_service.dart`

  @override
  void dispose() {
    // IMPORTANT: Cancel the subscription to avoid memory leaks and save battery
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Map View"),
      ),
      body: MapWidget(
        resourceOptions: ResourceOptions(
          // ** IMPORTANT: PASTE YOUR MAPBOX TOKEN HERE **
          accessToken: "YOUR_MAPBOX_PUBLIC_ACCESS_TOKEN",
        ),
        onMapCreated: _onMapCreated,
        cameraOptions: CameraOptions(
          // Set initial map position over a relevant area, like the coast of Kerala
          center: Point.fromLngLat(76.2711, 10.8505),
          zoom: 7.0,
        ),
      ),
      // Add a button to re-center the map on the user
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_userLocation != null) {
            final locationData = LocationData.fromMap({
              "latitude": _userLocation!.coordinates.lat,
              "longitude": _userLocation!.coordinates.lng,
            });
            _centerMapOnLocation(locationData);
          }
        },
        child: Icon(Icons.my_location),
      ),
    );
  }
}
