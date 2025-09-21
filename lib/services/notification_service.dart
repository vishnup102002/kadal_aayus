import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// --- Background message handler ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  final data = message.data;
  if (data.isNotEmpty) {
    final alertTitle = data['title'] ?? 'Alert';
    final alertBody = data['body'] ?? data['message'] ?? 'No content';
    final alertSeverity = data['severity'] ?? 'Medium';

    try {
      final docRef = await FirebaseFirestore.instance.collection('alerts').add({
        'title': alertTitle,
        'body': alertBody,
        'severity': alertSeverity,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Background alert saved to Firestore: ${docRef.id} | $alertTitle");
    } catch (e) {
      print("Failed to save background alert: $e");
    }
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  /// Initialize Firebase Messaging and Local Notifications
  Future<void> initNotifications() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final fcmToken = await _fcm.getToken();
    print("========================================");
    print("FCM Token: $fcmToken");
    print("========================================");

    // Subscribe to 'alert' topic
    await _fcm.subscribeToTopic('alert');
    print('Subscribed to topic: alert');

    // Local notification initialization
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    _setupMessageHandlers();
  }

  /// Setup foreground and background message listeners
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Foreground message received: ${message.messageId}');
      final data = message.data;

      if (data.isNotEmpty) {
        final alertTitle = data['title'] ?? 'New Alert';
        final alertBody = data['body'] ?? data['message'] ?? 'No content';
        final alertSeverity = data['severity'] ?? 'Medium';

        // Save alert to Firestore
        try {
          final docRef = await FirebaseFirestore.instance.collection('alerts').add({
            'title': alertTitle,
            'body': alertBody,
            'severity': alertSeverity,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print("Foreground alert saved to Firestore: ${docRef.id} | $alertTitle");
        } catch (e) {
          print("Failed to save foreground alert: $e");
        }

        // Show local notification
        _localNotifications.show(
          message.hashCode,
          alertTitle,
          alertBody,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'Channel for important alerts',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // Background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}