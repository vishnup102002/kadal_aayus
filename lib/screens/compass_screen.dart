// lib/screens/compass_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  StreamSubscription? _compassSubscription;
  StreamSubscription? _locationSubscription;

  double? _heading;
  LocationData? _locationData;

  @override
  void initState() {
    super.initState();
    // Subscribe to compass data stream
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted) {
        setState(() {
          _heading = event.heading;
        });
      }
    });

    // Subscribe to location data stream
    _locationSubscription = Location().onLocationChanged.listen((currentLocation) {
      if (mounted) {
        setState(() {
          _locationData = currentLocation;
        });
      }
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  // Helper function to format GPS coordinates
  String _formatCoordinate(double? value, bool isLatitude) {
    if (value == null) return 'N/A';
    String direction = isLatitude ? (value >= 0 ? 'N' : 'S') : (value >= 0 ? 'E' : 'W');
    int degrees = value.abs().truncate();
    double minutesDecimal = (value.abs() - degrees) * 60;
    int minutes = minutesDecimal.truncate();
    int seconds = ((minutesDecimal - minutes) * 60).round();
    return '$degrees°$minutes\'$seconds"$direction';
  }

  @override
  Widget build(BuildContext context) {
    final bool isMockLocation = _locationData?.isMock == true;
    final String latitude = _formatCoordinate(_locationData?.latitude, true);
    final String longitude = _formatCoordinate(_locationData?.longitude, false);
    final String bearing = _heading != null ? '${_heading!.toStringAsFixed(1)}°' : 'N/A';
    final String speed = _locationData?.speed != null ? '${(_locationData!.speed! * 1.94384).toStringAsFixed(1)} kn' : 'N/A';
    final String lastUpdated = _locationData?.time != null ? DateFormat('MM-dd-yyyy HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(_locationData!.time!.toInt())) : 'Waiting for GPS...';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('Compass', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.blue.shade100,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isMockLocation)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text('WARNING: Mock Location Detected', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            Text('Time updated:', style: TextStyle(color: Colors.black)),
            const SizedBox(height: 4),
            Text(
              lastUpdated,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- UPDATED to pass unique colors ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _infoColumn('Latitude', latitude, Colors.cyan.shade700)),
                        Expanded(child: _infoColumn('Longitude', longitude, Colors.orange.shade700)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: _infoColumn('Bearing', bearing, Colors.purple.shade600)),
                        Expanded(child: _infoColumn('Speed', speed, Colors.teal.shade600)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            Expanded(
              child: Center(
                child: Transform.rotate(
                  angle: ((_heading ?? 0) * (math.pi / 180) * -1),
                  child: Image.asset('assets/compass.png'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UPDATED to accept a 'valueColor' parameter ---
  Widget _infoColumn(String title, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor, // Use the passed-in color
          ),
        ),
      ],
    );
  }
}
