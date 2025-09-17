import 'package:flutter/material.dart';
import 'package:kadal_aayus/screens/home_screen.dart'; // Contains AlertsFeed
import 'package:kadal_aayus/screens/map_screen.dart';
import 'package:kadal_aayus/utils/emergency_utils.dart';
import 'package:kadal_aayus/utils/location_service.dart';
import 'package:location/location.dart';
import 'package:kadal_aayus/screens/alerts_feed.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class NavigationShell extends StatefulWidget {
  @override
  _NavigationShellState createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _selectedIndex = 0;
  final LocationService _locationService = LocationService();
  bool _isSendingSOS = false;
  LocationData? _currentLocation;

  static final List<Widget> _widgetOptions = <Widget>[
    AlertsFeed(),
    MapScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _locationService.getLocationStream().listen((locationData) {
      setState(() {
        _currentLocation = locationData;
      });
    });
  }

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

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SOS message sent!')),
      );
    }
    setState(() => _isSendingSOS = false);
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0
            ? 'Kadal Aayus - Alerts'
            : _currentLocation != null
            ? 'Live Map: Lat: ${_currentLocation!.latitude?.toStringAsFixed(4)}, Lon: ${_currentLocation!.longitude?.toStringAsFixed(4)}'
            : 'Live Map View'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
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
