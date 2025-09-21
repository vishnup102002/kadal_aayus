// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../widgets/dashboard_button.dart';

// Import all the feature screens
import 'alerts_feed.dart';
import 'map_screen.dart';
import 'tts_settings_screen.dart';
import 'compass_screen.dart';

// Import utility and authentication services
import '../utils/emergency_utils.dart';
import '../utils/location_service.dart';
import '../utils/tts_service.dart';
import '../services/auth_service.dart'; // Make sure you have this service
import 'package:location/location.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocationService _locationService = LocationService();
  final TtsService _ttsService = TtsService();
  final AuthService _authService = AuthService(); // Instance of AuthService
  bool _isSendingSOS = false;

  void _triggerSOS() async {
    // SOS logic remains the same...
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm SOS'),
          content: const Text('Are you sure you want to send an emergency SOS signal?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('SEND SOS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ) ?? false;
    if (!confirm) return;
    setState(() => _isSendingSOS = true);
    final LocationData? locationData = await _locationService.getCurrentLocation();
    String locationMessage = locationData != null
        ? "Emergency! My location is: Lat: ${locationData.latitude}, Lon: ${locationData.longitude}"
        : "Emergency! Location not available.";
    await sendSOS(locationMessage);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS message sent!')));
      setState(() => _isSendingSOS = false);
    }
  }

  // --- NEW LOGOUT METHOD ---
  Future<void> _signOut() async {
    // Show a confirmation dialog before logging out
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
          ],
        );
      },
    ) ?? false;

    if (confirmLogout && mounted) {
      await _authService.signOut();
      // After signing out, navigate to the login screen and remove all previous routes
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kadal Aayus', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.blue.shade100,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
        // --- ADDED THE ACTIONS PROPERTY WITH THE LOGOUT BUTTON ---
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            tooltip: 'Logout',
            onPressed: _signOut,
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF9F9F9),
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // Your DashboardButtons remain the same...
            DashboardButton(
              icon: Icons.warning_amber_rounded,
              label: 'Alerts',
              color: Colors.amber.shade400,
              onTap: () {
                _ttsService.speak("[translate:നിങ്ങൾക്ക് വന്നിട്ടുള്ള മുന്നറിയിപ്പുകൾ കാണാൻ]");
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsFeedScreen()));
              },
            ),
            DashboardButton(
              icon: Icons.map_outlined,
              label: 'Live Map',
              color: Colors.teal.shade300,
              onTap: () {
                _ttsService.speak("[translate:നിങ്ങൾ ഇപ്പോൾ എവിടെയാണെന്ന് മാപ്പിൽ കാണാൻ]");
                Navigator.push(context, MaterialPageRoute(builder: (context) => MapScreen()));
              },
            ),
            DashboardButton(
              icon: FontAwesomeIcons.compass,
              label: 'Compass',
              color: Colors.brown.shade400,
              onTap: () {
                _ttsService.speak("[translate:ദിശ അറിയാൻ]");
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CompassScreen()));
              },
            ),
            DashboardButton(
              icon: Icons.build_circle_outlined,
              label: 'Tools &\nSettings',
              color: Colors.grey.shade400,
              onTap: () {
                _ttsService.speak("[translate:ആപ്പിന്റെ ക്രമീകരണങ്ങൾ മാറ്റാൻ]");
                Navigator.push(context, MaterialPageRoute(builder: (context) => TtsSettingsScreen()));
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: GestureDetector(
        onLongPress: () {
          _ttsService.speak("[translate:അടിയന്തര സഹായത്തിനായി ഈ ബട്ടൺ അമർത്തുക]");
        },
        child: FloatingActionButton.large(
          onPressed: _isSendingSOS ? null : _triggerSOS,
          backgroundColor: Colors.red.shade400,
          elevation: 8,
          child: _isSendingSOS
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 4)
              : const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sos, size: 40, color: Colors.white),
              Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
