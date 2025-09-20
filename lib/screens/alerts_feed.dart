import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';

// --- BACKGROUND HANDLER ---
// This function runs when a data message is received and the app is closed.
// It saves the alert directly to Firestore.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  if (message.data.isNotEmpty) {
    await FirebaseFirestore.instance.collection('alerts').add({
      'title': message.data['title'] ?? 'Alert',
      'body': message.data['body'] ?? message.data['message'], // Use body or message
      'severity': message.data['severity'] ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Background alert saved to Firestore.");
  }
}


// --- ALERTS UI WIDGET ---
// This is your updated AlertsFeed that displays the rich data.
class AlertsFeed extends StatelessWidget {
  final Stream<QuerySnapshot> _alertsStream = FirebaseFirestore.instance
      .collection('alerts')
      .orderBy('timestamp', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _alertsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Something went wrong'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No alerts found."));
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

            Color severityColor;
            IconData severityIcon;
            switch (data['severity']?.toLowerCase()) {
              case 'high':
                severityColor = Colors.red.shade700;
                severityIcon = Icons.error;
                break;
              case 'medium':
                severityColor = Colors.orange.shade700;
                severityIcon = Icons.warning_amber_rounded;
                break;
              case 'low':
                severityColor = Colors.blue.shade700;
                severityIcon = Icons.info;
                break;
              default:
                severityColor = Colors.grey.shade700;
                severityIcon = Icons.notifications;
            }

            final timestamp = data['timestamp'] as Timestamp?;
            final formattedTime = timestamp != null
                ? DateFormat('hh:mm a, dd MMM yyyy').format(timestamp.toDate())
                : '...';

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: severityColor.withOpacity(0.5), width: 1),
              ),
              child: ListTile(
                leading: Icon(severityIcon, color: severityColor, size: 40),
                title: Text(
                  data['title'] ?? 'No Title',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(data['body'] ?? data['message'] ?? 'No content available.'),
                trailing: Text(
                  formattedTime,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                isThreeLine: true,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}


// --- NOTIFICATION SERVICE ---
// This service now saves to DB, shows a local notification, AND uses TTS.
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FlutterTts _tts = FlutterTts(); // The TTS instance

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

        // 1. Add the new alert to Firestore.
        await FirebaseFirestore.instance.collection('alerts').add({
          'title': alertTitle,
          'body': alertBody,
          'severity': alertSeverity,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 2. Display a local notification.
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

        // 3. RE-ADDED: Speak the alert using TTS.
        await _tts.speak(alertBody);
      }
    });

    // Set the handler for background messages.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
