import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// --- Background message handler for FCM ---
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");

  final data = message.data;
  if (data.isNotEmpty) {
    try {
      await FirebaseFirestore.instance.collection('alerts').add({
        'title': data['title'] ?? 'Alert',
        'body': data['body'] ?? data['message'] ?? 'No content',
        'severity': data['severity'] ?? 'Medium',
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint("Background FCM alert saved to Firestore: ${message.messageId}");
    } catch (e) {
      debugPrint("Error saving background FCM alert: $e");
    }
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Initialize all notification services
  Future<void> initNotifications() async {
    // Request FCM permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final fcmToken = await _fcm.getToken();
    debugPrint("========================================");
    debugPrint("FCM Token: $fcmToken");
    debugPrint("========================================");

    // Subscribe to the general 'alert' topic for FCM
    await _fcm.subscribeToTopic('alert');
    debugPrint('Subscribed to topic: alert');

    // Initialize the local notifications plugin
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Set up handlers for incoming FCM messages
    _setupMessageHandlers();
  }

  /// **FIX: Add this public method**
  /// This method can be called from anywhere to show a local notification on demand.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'marine_weather_channel', // A unique channel ID for marine alerts
      'Marine Weather Alerts',    // The user-visible channel name
      channelDescription: 'Channel for marine weather condition alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    // Show the notification
    await _localNotifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Private method to set up listeners for FCM messages
  void _setupMessageHandlers() {
    // Handle foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Foreground FCM message received: ${message.messageId}');
      final data = message.data;

      if (data.isNotEmpty) {
        final alertTitle = data['title'] ?? 'New Alert';
        final alertBody = data['body'] ?? 'No content';

        // Save the FCM alert to Firestore
        FirebaseFirestore.instance.collection('alerts').add({
          'title': alertTitle,
          'body': alertBody,
          'severity': data['severity'] ?? 'Medium',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Show a local notification for the incoming FCM message
        _localNotifications.show(
          message.hashCode,
          alertTitle,
          alertBody,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'fcm_alerts_channel', // A different channel for FCM alerts
              'General Alerts',
              channelDescription: 'Channel for general notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // Set the handler for background FCM messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
