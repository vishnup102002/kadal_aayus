// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:translator/translator.dart'; // Using your preferred translator
import '../utils/tts_service.dart';     // Our dedicated TTS manager

enum PlaybackState { idle, processing, playing }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box _alertsBox;
  List<Map<String, dynamic>> _cachedAlerts = [];
  final Map<String, PlaybackState> _alertStates = {};

  // Using the online translator as per your pubspec.yaml
  final GoogleTranslator _googleTranslator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    _alertsBox = Hive.box('alertsBox');
    _loadCachedAlerts(); // Calling the method that was previously missing

    // Set up the listener for when TTS completes. This will now work.
    TtsService().setCompletionHandler(() {
      final playingAlertId = _alertStates.entries.firstWhere(
            (entry) => entry.value == PlaybackState.playing,
        orElse: () => const MapEntry("", PlaybackState.idle),
      ).key;

      if (playingAlertId.isNotEmpty && mounted) {
        setState(() => _alertStates[playingAlertId] = PlaybackState.idle);
      }
    });
  }

  @override
  void dispose() {
    TtsService().stop();
    super.dispose();
  }

  void _handleLivePlayback(Map<String, dynamic> alertData) async {
    final alertId = alertData['id'] as String;

    if (_alertStates[alertId] == PlaybackState.playing) {
      await TtsService().stop();
      setState(() => _alertStates[alertId] = PlaybackState.idle);
      return;
    }

    setState(() => _alertStates[alertId] = PlaybackState.processing);
    String originalBody = alertData['body'] ?? 'No content available.';

    try {
      var translation = await _googleTranslator.translate(originalBody, to: 'ml');
      final translatedBody = translation.text;

      setState(() => _alertStates[alertId] = PlaybackState.playing);
      await TtsService().speak(translatedBody);

    } catch (e) {
      if(mounted) {
        setState(() => _alertStates[alertId] = PlaybackState.idle);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Could not translate or speak. Check internet."),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // --- INCLUDING THE MISSING DATA HANDLING METHODS ---

  void _loadCachedAlerts() {
    final data = _alertsBox.get('cachedAlerts', defaultValue: []);
    if (mounted) {
      setState(() {
        _cachedAlerts = List<Map<String, dynamic>>.from(data.map((item) => Map<String, dynamic>.from(item)));
        for (var alert in _cachedAlerts) {
          _alertStates[alert['id']] ??= PlaybackState.idle;
        }
      });
    }
  }

  Future<void> _processAndCacheAlerts(List<QueryDocumentSnapshot> docs) async {
    List<Map<String, dynamic>> alertsToCache = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      alertsToCache.add({
        'id': doc.id,
        'title': data['title'],
        'body': data['body'],
        'severity': data['severity'],
        'timestamp': (data['timestamp'] as Timestamp?)?.millisecondsSinceEpoch,
      });
    }
    await _alertsBox.put('cachedAlerts', alertsToCache);
    _loadCachedAlerts();
  }

  // --- YOUR UI BUILD METHODS (UNCHANGED) ---

  Widget _buildAlertTile(Map<String, dynamic> data) {
    final alertId = data['id'] as String;
    final currentState = _alertStates[alertId] ?? PlaybackState.idle;
    final title = data['title'] ?? 'No Title';
    final body = data['body'] ?? 'No content available.';
    final severity = data['severity'] ?? 'Medium';

    Color severityColor;
    IconData severityIcon;
    switch (severity.toLowerCase()) {
      case 'high': severityColor = Colors.red; severityIcon = Icons.error; break;
      case 'medium': severityColor = Colors.orange; severityIcon = Icons.warning; break;
      default: severityColor = Colors.blue; severityIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(severityIcon, color: severityColor, size: 40),
        title: Text(title),
        subtitle: Text(body),
        trailing: SizedBox(
          width: 48,
          height: 48,
          child: _buildTrailingIcon(currentState, data),
        ),
      ),
    );
  }

  Widget _buildTrailingIcon(PlaybackState state, Map<String, dynamic> data) {
    switch (state) {
      case PlaybackState.processing:
        return const CircularProgressIndicator(strokeWidth: 2.0);
      case PlaybackState.playing:
        return IconButton(
          icon: const Icon(Icons.stop_circle_outlined, color: Colors.red, size: 30),
          onPressed: () => _handleLivePlayback(data),
          tooltip: 'Stop Playback',
        );
      default: // PlaybackState.idle
        return IconButton(
          icon: Icon(Icons.volume_up, color: Colors.grey[600]),
          tooltip: 'Read Aloud in Malayalam',
          onPressed: () => _handleLivePlayback(data),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts Feed')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('alerts').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            _processAndCacheAlerts(snapshot.data!.docs);
          }
          if (_cachedAlerts.isEmpty) {
            return snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const Center(child: Text('No alerts at the moment.'));
          }
          return ListView.builder(
            itemCount: _cachedAlerts.length,
            itemBuilder: (context, index) => _buildAlertTile(_cachedAlerts[index]),
          );
        },
      ),
    );
  }
}
