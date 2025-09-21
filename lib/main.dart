// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

// Import all necessary screens and services
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'utils/tts_service.dart';
import 'services/auth_gate.dart';
import 'services/notification_service.dart';

// -----------------------------
// FCM Background Handler
// Must be a top-level function
// -----------------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");

  // Optional: you can handle Firestore saving here if NotificationService does not handle background
  final data = message.data;
  if (data.isNotEmpty) {
    try {
      await FirebaseFirestore.instance.collection('alerts').add({
        'title': data['title'] ?? 'Alert',
        'body': data['body'] ?? data['message'] ?? 'No content',
        'severity': data['severity'] ?? 'Medium',
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Background alert saved to Firestore: ${message.messageId}");
    } catch (e) {
      print("Error saving background alert: $e");
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox('alertsBox');

  // --- Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  // --- Set FCM background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // --- Initialize Text-to-Speech
  await TtsService().initialize();

  // --- Initialize NotificationService (foreground + topic subscription)
  final notificationService = NotificationService();
  await notificationService.initNotifications();

  // --- Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kadal Aayus',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
      ),
      // --- AuthGate checks if the user is logged in
      home: const AuthGate(),
      // --- Named routes
      routes: {
        '/login': (context) =>  LoginScreen(),
        '/home': (context) => const DashboardScreen(),
      },
    );
  }
}