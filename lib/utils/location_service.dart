// lib/utils/location_service.dart

import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  // This function gets a single location fix (used for SOS)
  Future<LocationData?> getCurrentLocation() async {
    if (!await _checkAndRequestPermissions()) {
      return null;
    }
    return await _location.getLocation();
  }

  // This function provides a continuous stream of location data (for the map)
  Stream<LocationData> getLocationStream() {
    _checkAndRequestPermissions();
    return _location.onLocationChanged;
  }

  // Helper function to handle permissions neatly
  Future<bool> _checkAndRequestPermissions() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return false;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        print('Location permission denied.');
        return false;
      }
    }
    return true;
  }
}
