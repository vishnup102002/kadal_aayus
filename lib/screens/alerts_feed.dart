// lib/screens/alert_feed.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:translator/translator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/tts_service.dart'; // Using your dedicated TTS Service

// --- BACKGROUND HANDLER (FROM TEAMMATE) ---
// This top-level function is required to handle messages when the app is terminated.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  if (message.data.isNotEmpty) {
    await FirebaseFirestore.instance.collection('alerts').add({
      'title': message.data['title'] ?? 'Alert',
      'body': message.data['body'] ?? message.data['message'],
      'severity': message.data['severity'] ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Background alert saved to Firestore.");
  }
}

// --- NOTIFICATION SERVICE (MERGED LOGIC) ---
// This service initializes notifications but delegates UI and TTS control.
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await _fcm.requestPermission();
    final fcmToken = await _fcm.getToken();
    print("FCM Token: $fcmToken");

    await _fcm.subscribeToTopic('alert');

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings);

    _setupMessageHandlers();
  }

  void _setupMessageHandlers() {
    // --- Foreground Message Handler ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message whilst in the FOREGROUND!');
      final data = message.data;

      if (data.isNotEmpty) {
        final alertTitle = data['title'] ?? 'New Alert';
        final alertBody = data['body'] ?? data['message'] ?? 'No content';
        final alertSeverity = data['severity'] ?? 'Unknown';

        // 1. Save the new alert to Firestore (the UI will update automatically via StreamBuilder).
        await FirebaseFirestore.instance.collection('alerts').add({
          'title': alertTitle,
          'body': alertBody,
          'severity': alertSeverity,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 2. Display a local notification popup.
        _localNotifications.show(
          message.hashCode,
          alertTitle,
          alertBody,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
        // NOTE: Automatic speaking is removed from here to give the user full control via the UI.
      }
    });

    // Set the handler for background messages.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}


// --- THE MERGED UI: AlertsFeedScreen (YOUR UI IS THE BASE) ---
enum PlaybackState { idle, processing, playing }

class AlertsFeedScreen extends StatefulWidget {
  const AlertsFeedScreen({super.key});

  @override
  State<AlertsFeedScreen> createState() => _AlertsFeedScreenState();
}

class _AlertsFeedScreenState extends State<AlertsFeedScreen> {
  late Box _alertsBox;
  List<Map<String, dynamic>> _cachedAlerts = [];
  final Map<String, PlaybackState> _alertStates = {};
  final GoogleTranslator _googleTranslator = GoogleTranslator();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _alertsBox = Hive.box('alertsBox');
    _loadCachedAlerts();

    // Initialize the merged notification service
    _notificationService.initNotifications();

    // Your TTS completion handler remains unchanged
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

  // Your interactive playback logic remains the core feature
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
      if (mounted) {
        setState(() => _alertStates[alertId] = PlaybackState.idle);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Could not translate or speak. Check internet."),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // Your offline caching logic is preserved
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

  // Your UI tile is the base, but enhanced with the teammate's timestamp
  Widget _buildAlertTile(Map<String, dynamic> data) {
    final alertId = data['id'] as String;
    final currentState = _alertStates[alertId] ?? PlaybackState.idle;
    final title = data['title'] ?? 'No Title';
    final body = data['body'] ?? 'No content available.';
    final severity = data['severity'] ?? 'Medium';

    final timestampMillis = data['timestamp'] as int?;
    final formattedTime = timestampMillis != null
        ? DateFormat('hh:mm a, dd MMM').format(DateTime.fromMillisecondsSinceEpoch(timestampMillis))
        : '';

    Color severityColor;
    IconData severityIcon;
    switch (severity.toLowerCase()) {
      case 'high': severityColor = Colors.red.shade700; severityIcon = Icons.error; break;
      case 'medium': severityColor = Colors.orange.shade700; severityIcon = Icons.warning_amber_rounded; break;
      default: severityColor = Colors.blue.shade700; severityIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        leading: Icon(severityIcon, color: severityColor, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 48,
              height: 32, // Adjusted height
              child: _buildTrailingIcon(currentState, data),
            ),
            const SizedBox(height: 4),
            Text(formattedTime, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // Your playback icon logic is preserved
  Widget _buildTrailingIcon(PlaybackState state, Map<String, dynamic> data) {
    switch (state) {
      case PlaybackState.processing:
        return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.0)));
      case PlaybackState.playing:
        return IconButton(
          icon: const Icon(Icons.stop_circle_outlined, color: Colors.red, size: 30),
          onPressed: () => _handleLivePlayback(data),
          tooltip: 'Stop Playback',
        );
      default:
        return IconButton(
          icon: Icon(Icons.volume_up, color: Colors.grey[600]),
          tooltip: 'Read Aloud in Malayalam',
          onPressed: () => _handleLivePlayback(data),
        );
    }
  }

  // Your main build method, driving the UI from the live stream and cache
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
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
    );
  }
}
