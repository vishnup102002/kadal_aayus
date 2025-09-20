import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// This function MUST be a top-level function.
// It now handles background data messages and writes them to Firestore.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You MUST initialize Firebase in the background handler.
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");

  // Check if the message contains a data payload with a 'message' key.
  if (message.data.containsKey('message')) {
    final alertMessage = message.data['message'];
    print("Background data received: $alertMessage");

    // Add the new alert to the 'alerts' collection in Firestore.
    await FirebaseFirestore.instance.collection('alerts').add({
      'message': alertMessage,
      'timestamp': FieldValue.serverTimestamp(),
    });
    print("Background alert saved to Firestore.");
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await _fcm.requestPermission();

    final fcmToken = await _fcm.getToken();
    print("========================================");
    print("FCM Token: $fcmToken");
    print("========================================");

    // Subscribe to the 'alert' topic.
    await _fcm.subscribeToTopic('alert');
    print('Successfully subscribed to topic: alert');

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(initializationSettings);

    _setupMessageHandlers();
  }

  void _setupMessageHandlers() {
    // Handler for messages that arrive while the app is in the FOREGROUND.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('Got a message whilst in the FOREGROUND!');

      // The notification payload (title, body) for what the user sees.
      final notification = message.notification;
      // The custom data payload for our app's logic.
      final data = message.data;

      if (notification != null && data.containsKey('message')) {
        final alertMessage = data['message'];
        print("Foreground data received: $alertMessage");

        // 1. Add the new alert to the 'alerts' collection in Firestore.
        await FirebaseFirestore.instance.collection('alerts').add({
          'message': alertMessage,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print("Foreground alert saved to Firestore.");

        // 2. Display a local notification to make the user aware.
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription:
              'This channel is used for important notifications.',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // Set the handler for background messages.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
