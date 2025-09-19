// lib/screens/navigation_shell.dart

import 'package:flutter/material.dart';
import 'package:kadal_aayus/screens/home_screen.dart';
import 'package:kadal_aayus/screens/map_screen.dart';
import 'package:kadal_aayus/screens/tts_settings_screen.dart';
import 'package:kadal_aayus/utils/emergency_utils.dart';
import 'package:kadal_aayus/utils/location_service.dart';
import 'package:location/location.dart';

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  _NavigationShellState createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;
  final LocationService _locationService = LocationService();
  bool _isSendingSOS = false;

  // ✅ Fixed widget options
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),   // ✅ Removed translatedBody
    MapScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _triggerSOS() async {
    setState(() => _isSendingSOS = true);

    final LocationData? locationData = await _locationService.getCurrentLocation();
    String locationMessage = locationData != null
        ? "Lat: ${locationData.latitude}, Lon: ${locationData.longitude}"
        : "Location not available";

    await sendSOS(locationMessage);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS message sent!')),
      );
    }

    setState(() => _isSendingSOS = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Kadal Aayus - Alerts' : 'Live Map View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_voice),
            tooltip: 'Voice Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TtsSettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_rounded),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSendingSOS ? null : _triggerSOS,
        backgroundColor: Colors.red,
        child: _isSendingSOS
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.sos),
      ),
    );
  }
}
