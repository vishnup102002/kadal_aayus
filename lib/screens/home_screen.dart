// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';

// Import all the necessary utility and screen files
import '../utils/emergency_utils.dart';
import '../utils/location_service.dart';
import 'map_screen.dart'; // <-- Import the map screen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  bool _isSendingSOS = false;

  void _triggerSOS() async {
    setState(() {
      _isSendingSOS = true;
    });

    final LocationData? locationData = await _locationService.getCurrentLocation();

    String locationMessage;
    if (locationData != null) {
      locationMessage = "Lat: ${locationData.latitude}, Lon: ${locationData.longitude}";
    } else {
      locationMessage = "Location not available";
    }

    await sendSOS(locationMessage);

    setState(() {
      _isSendingSOS = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kadal Aayus - Alerts'),
        // *** THIS IS THE ONLY ADDITION ***
        actions: [
          IconButton(
            icon: Icon(Icons.map_outlined),
            tooltip: 'Open Map',
            onPressed: () {
              // This navigates to the MapScreen you created
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MapScreen()),
              );
            },
          ),
        ],
        // ********************************
      ),
      body: AlertsFeed(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSendingSOS ? null : _triggerSOS,
        child: _isSendingSOS
            ? CircularProgressIndicator(color: Colors.white)
            : Icon(Icons.sos),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// The AlertsFeed widget remains unchanged
class AlertsFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading alerts.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No alerts at the moment.'));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] as String? ?? 'No Title';
            final body = data['body'] as String? ?? 'No content available.';

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.warning, color: Colors.orange),
                title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(body),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
