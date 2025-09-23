// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// --- THIS IS THE FINAL FIX ---
// The import statement now has a colon after 'package'.
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'models/marine_weather_alert.dart';
// Note: The generic 'Alert' model and adapter are removed as they are not used
// by the 'alerts_feed.dart' screen you provided.
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'utils/tts_service.dart';
import 'services/auth_gate.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
  // Your background handler logic remains the same
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register the adapter for your marine weather alerts
  Hive.registerAdapter(MarineWeatherAlertAdapter());

  // Open the box for your marine weather alerts
  await Hive.openBox<MarineWeatherAlert>('marineAlertsBox');

  // Open the generic box for your admin alerts
  await Hive.openBox('alertsBox');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await initializeDateFormatting('ml_IN', null);

  await TtsService().initialize();

  final notificationService = NotificationService();
  await notificationService.initNotifications();

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ml', 'IN'),
      ],
      home: const AuthGate(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => const DashboardScreen(),
      },
    );
  }
}
