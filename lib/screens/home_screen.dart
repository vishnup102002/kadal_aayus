// lib/screens/home_screen.dart

import 'dart:io'; // Required for File operations
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart'; // For playing audio files
import 'package:path_provider/path_provider.dart'; // To find storage path

class AlertsFeed extends StatefulWidget {
  @override
  _AlertsFeedState createState() => _AlertsFeedState();
}

class _AlertsFeedState extends State<AlertsFeed> {
  late Box _alertsBox;
  List<Map<String, dynamic>> _cachedAlerts = [];

  late FlutterTts _flutterTts;
  late AudioPlayer _audioPlayer; // The new audio player for local files

  @override
  void initState() {
    super.initState();
    _alertsBox = Hive.box('alertsBox');

    // Initialize TTS and the new audio player
    _flutterTts = FlutterTts();
    _audioPlayer = AudioPlayer();
    _setupTts();

    _loadCachedAlerts();
  }

  void _setupTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage("ml-IN");
  }

  // This is the fallback for online-only playback
  void _speakOnline(String text) async {
    await _flutterTts.speak(text);
  }

  // This function plays a saved local audio file
  void _playLocalAudio(String path) async {
    try {
      await _audioPlayer.setFilePath(path);
      _audioPlayer.play();
    } catch (e) {
      print("Error playing local audio: $e");
      // If playing the file fails, speak it online as a fallback
      final alert = _cachedAlerts.firstWhere((a) => a['audioPath'] == path, orElse: () => {});
      if(alert.isNotEmpty) {
        _speakOnline(alert['body'] ?? 'Content not found.');
      }
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose(); // IMPORTANT: Clean up the audio player
    super.dispose();
  }

  void _loadCachedAlerts() {
    final data = _alertsBox.get('cachedAlerts', defaultValue: []);
    if (mounted && data != null) {
      setState(() {
        _cachedAlerts = List<Map<String, dynamic>>.from(data.map((item) => Map<String, dynamic>.from(item)));
      });
    }
  }

  // New function to handle caching and audio synthesis
  Future<void> _processAndCacheAlerts(List<QueryDocumentSnapshot> docs) async {
    final tempDir = await getApplicationDocumentsDirectory();
    List<Map<String, dynamic>> alertsToCache = [];

    for (var doc in docs) {
      final docId = doc.id;
      final data = doc.data() as Map<String, dynamic>;

      // Check if this alert is already cached with audio
      final existing = _cachedAlerts.firstWhere((a) => a['id'] == docId, orElse: () => {});
      String? audioPath = existing.isNotEmpty ? existing['audioPath'] : null;

      // If audio hasn't been created yet, create it
      if (audioPath == null || !await File(audioPath).exists()) {
        final speechFile = File('${tempDir.path}/$docId.mp3');
        if (await speechFile.exists()) {
          // If file exists but path was not in cache, just assign the path
          audioPath = speechFile.path;
        } else {
          // Synthesize the audio and save it to a file
          int result = await _flutterTts.synthesizeToFile(data['body'] ?? '', speechFile.path);
          if (result == 1) { // 1 means success
            audioPath = speechFile.path;
          }
        }
      }

      // Add all data to the map for caching
      alertsToCache.add({
        'id': docId,
        'title': data['title'],
        'body': data['body'],
        'severity': data['severity'],
        'timestamp': (data['timestamp'] as Timestamp?)?.millisecondsSinceEpoch,
        'audioPath': audioPath, // Save the audio file path
      });
    }

    await _alertsBox.put('cachedAlerts', alertsToCache);
    _loadCachedAlerts(); // Reload state from cache to update UI
  }

  Widget _buildAlertTile(Map<String, dynamic> data) {
    final title = data['title'] ?? 'No Title';
    final body = data['body'] ?? 'No content available.';
    final severity = data['severity'] ?? 'Medium';
    final audioPath = data['audioPath'] as String?;

    Color severityColor;
    IconData severityIcon;

    switch (severity.toLowerCase()) {
      case 'high': severityColor = Colors.red; severityIcon = Icons.error; break;
      case 'medium': severityColor = Colors.orange; severityIcon = Icons.warning; break;
      case 'low': severityColor = Colors.blue; severityIcon = Icons.info; break;
      default: severityColor = Colors.grey; severityIcon = Icons.help_outline;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(severityIcon, color: severityColor, size: 40),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(body),
        trailing: IconButton(
          icon: Icon(Icons.volume_up, color: Colors.grey[600]),
          tooltip: 'Read Aloud',
          onPressed: () {
            // If we have a local audio path, play the file. Otherwise, use online TTS.
            if (audioPath != null && audioPath.isNotEmpty) {
              print("Playing local audio from: $audioPath");
              _playLocalAudio(audioPath);
            } else {
              print("No local audio found, using online TTS.");
              _speakOnline(body);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          // When new data comes from Firebase, process it
          _processAndCacheAlerts(snapshot.data!.docs);
        }

        if (snapshot.connectionState == ConnectionState.waiting && _cachedAlerts.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && _cachedAlerts.isEmpty) {
          return Center(child: Text('Error loading alerts. Check connection.'));
        }

        if (_cachedAlerts.isEmpty) {
          return Center(child: Text('No alerts at the moment.'));
        }

        // Always build the list from the Hive-backed cache for a consistent UI
        return ListView.builder(
          itemCount: _cachedAlerts.length,
          itemBuilder: (context, index) => _buildAlertTile(_cachedAlerts[index]),
        );
      },
    );
  }
}
