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

// The background handler MUST be a top-level function (not inside any class).
// Note: We need a reference to the NotificationService logic here if we want to
// process the message, but for simplicity, we assume the OS handles showing it.
// The main logic is handled by the NotificationService when the app is active.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");
  // The logic inside your NotificationService will handle saving this data
  // when the app is next launched or brought to the foreground.
}

Future<void> main() async {
  // Ensure all Flutter bindings are properly initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  // --- Initialize all services ONCE in the correct order ---

  // 1. Initialize local storage (Hive).
  await Hive.initFlutter();
  await Hive.openBox('alertsBox');

  // 2. Initialize Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Enable Firestore's offline data persistence.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // 4. Set the background message handler for Firebase Messaging.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 5. Initialize your custom Text-to-Speech service.
  await TtsService().initialize();

  // 6. Run the app.
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

      // --- CORRECTED APP ENTRY POINT ---
      // AuthGate will check if the user is logged in and show either the
      // LoginScreen or the DashboardScreen. This is the correct approach.
      home: const AuthGate(),

      // Routes are defined for named navigation, which is good practice.
      routes: {
        '/login': (context) =>  LoginScreen(),
        '/home': (context) =>  DashboardScreen(),
      },
    );
  }
}
