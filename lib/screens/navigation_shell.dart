// lib/screens/navigation_shell.dart

import 'package:flutter/material.dart';
import 'package:kadal_aayus/screens/home_screen.dart'; // Contains AlertsFeed
import 'package:kadal_aayus/screens/map_screen.dart';
import 'package:kadal_aayus/utils/emergency_utils.dart';
import 'package:kadal_aayus/utils/location_service.dart';
import 'package:location/location.dart';

class NavigationShell extends StatefulWidget {
  @override
  _NavigationShellState createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;
  final LocationService _locationService = LocationService();
  bool _isSendingSOS = false;

  // List of the main screens
  static final List<Widget> _widgetOptions = <Widget>[
    AlertsFeed(), // Your existing alerts feed
    MapScreen(),  // Your new map screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _triggerSOS() async {
    setState(() => _isSendingSOS = true);
    final LocationData? locationData = await _locationService.getCurrentLocation();
    String locationMessage = locationData != null
        ? "Lat: ${locationData.latitude}, Lon: ${locationData.longitude}"
        : "Location not available";

    await sendSOS(locationMessage);

    // Add feedback to the user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SOS message sent!')),
      );
    }
    setState(() => _isSendingSOS = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Kadal Aayus - Alerts' : 'Live Map View'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
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
            ? CircularProgressIndicator(color: Colors.white)
            : Icon(Icons.sos),
      ),
    );
  }
}

