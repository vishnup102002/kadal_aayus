// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';

// Import the new TTS Service and the Dashboard Screen
import 'screens/dashboard_screen.dart';
import 'utils/tts_service.dart';

void main() async {
  // Ensure all Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage and Firebase
  await Hive.initFlutter();
  await Hive.openBox('alertsBox');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize our dedicated TTS Service once on app startup
  await TtsService().initialize();

  // Run the app
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
      ),
      // Set the dashboard as the home screen
      home: DashboardScreen(),
    );
  }
}
