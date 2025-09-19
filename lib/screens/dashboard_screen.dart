// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Use a relative import to avoid any package name issues.
import 'home_screen.dart';
import 'map_screen.dart';
import 'tts_settings_screen.dart';
import '../widgets/dashboard_button.dart'; // Corrected relative path for widgets
import '../utils/emergency_utils.dart';   // Corrected relative path for utils
import '../utils/location_service.dart';
import 'package:location/location.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocationService _locationService = LocationService();
  bool _isSendingSOS = false;

  void _triggerSOS() async {
    setState(() => _isSendingSOS = true);
    final LocationData? locationData = await _locationService.getCurrentLocation();
    String locationMessage = locationData != null
        ? "Lat: ${locationData.latitude}, Lon: ${locationData.longitude}"
        : "Location not available";
    await sendSOS(locationMessage);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SOS message sent!')));
    }
    setState(() => _isSendingSOS = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kadal Aayus Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            DashboardButton(
              icon: Icons.warning_amber_rounded,
              label: 'Alerts',
              color: Colors.blue,
              // --- THIS IS THE CORRECTED LINE ---
              // It now navigates to HomeScreen, which is the correct class name.
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen())),
            ),
            DashboardButton(
              icon: Icons.map_outlined,
              label: 'Live View',
              color: Colors.blue,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen())),
            ),
            DashboardButton(
              icon: Icons.settings_voice,
              label: 'Settings',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TtsSettingsScreen())),
            ),
            // Placeholder buttons
            DashboardButton(icon: FontAwesomeIcons.cloudSun, label: 'Weather', onTap: () {}),
            DashboardButton(icon: FontAwesomeIcons.anchor, label: 'My Boats', onTap: () {}),
            DashboardButton(icon: FontAwesomeIcons.users, label: 'My Crew', onTap: () {}),
            DashboardButton(icon: FontAwesomeIcons.fish, label: 'PFZ', onTap: () {}),
            DashboardButton(icon: Icons.camera_alt_outlined, label: 'Report', onTap: () {}),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSendingSOS ? null : _triggerSOS,
        backgroundColor: Colors.red,
        child: _isSendingSOS ? CircularProgressIndicator(color: Colors.white) : Icon(Icons.sos, size: 30),
      ),
    );
  }
}
