import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
// Corrected import statement for path_provider
import 'package:path_provider/path_provider.dart';

// Model class for an Alert
class Alert {
  final String id;
  final String title;
  final String body;
  final String severity;
  final Timestamp timestamp;
  String? audioPath;

  Alert({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.timestamp,
    this.audioPath,
  });

  factory Alert.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Alert(
      id: doc.id,
      title: data['title'] ?? 'No Title',
      body: data['body'] ?? 'No Body',
      severity: data['severity'] ?? 'Normal',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }
}

class AlertsFeed extends StatefulWidget {
  @override
  _AlertsFeedState createState() => _AlertsFeedState();
}

class _AlertsFeedState extends State<AlertsFeed> {
  late FlutterTts _flutterTts;
  late AudioPlayer _audioPlayer;

  final Map<String, String> _audioCache = {};

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _audioPlayer = AudioPlayer();
    _setupTts();
  }

  void _setupTts() async {
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage("ml-IN");
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _processAndCacheAudio(Alert alert) async {
    if (_audioCache.containsKey(alert.id)) return;

    try {
      final tempDir = await getApplicationDocumentsDirectory();
      final speechFile = File('${tempDir.path}/${alert.id}.mp3');

      if (await speechFile.exists()) {
        if (mounted) setState(() => _audioCache[alert.id] = speechFile.path);
      } else {
        int result = await _flutterTts.synthesizeToFile(alert.body, speechFile.path);
        if (result == 1) {
          if (mounted) setState(() => _audioCache[alert.id] = speechFile.path);
        }
      }
    } catch (e) {
      print("Error caching audio for alert ${alert.id}: $e");
    }
  }

  void _playAudio(Alert alert) async {
    final audioPath = _audioCache[alert.id];
    if (audioPath != null && audioPath.isNotEmpty) {
      try {
        await _audioPlayer.setFilePath(audioPath);
        _audioPlayer.play();
      } catch (e) {
        print("Error playing local audio, falling back to online TTS: $e");
        await _flutterTts.speak(alert.body);
      }
    } else {
      await _flutterTts.speak(alert.body);
    }
  }

  Widget _buildAlertTile(Alert alert) {
    Color severityColor;
    IconData severityIcon;

    switch (alert.severity.toLowerCase()) {
      case 'high': severityColor = Colors.red; severityIcon = Icons.error; break;
      case 'medium': severityColor = Colors.orange; severityIcon = Icons.warning; break;
      case 'low': severityColor = Colors.blue; severityIcon = Icons.info; break;
      default: severityColor = Colors.grey; severityIcon = Icons.help_outline;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(severityIcon, color: severityColor, size: 40),
        title: Text(alert.title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(alert.body),
        trailing: IconButton(
          icon: Icon(Icons.volume_up, color: Colors.grey[600]),
          tooltip: 'Read Aloud',
          onPressed: () => _playAudio(alert),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong! Please check your connection.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No alerts at the moment.'));
        }

        final alerts = snapshot.data!.docs.map((doc) => Alert.fromFirestore(doc)).toList();

        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            _processAndCacheAudio(alert);
            return _buildAlertTile(alert);
          },
        );
      },
    );
  }
}
