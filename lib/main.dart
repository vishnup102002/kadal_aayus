// /Users/vishnup/Desktop/mini_proj/kadal_aayus/lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'services/auth_gate.dart';
import 'screens/navigation_shell.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

// Your top-level background handler should be defined in a single place.
// The one in notification_service.dart is a better location.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // We can leave this in here, but it's duplicated. It's better to keep it in the service.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ All message handler registration is now done inside this service call.
  await NotificationService().initNotifications();

  await Hive.initFlutter();
  await Hive.openBox('alertsBox');

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kadal Aayus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthGate(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => NavigationShell(),
      },
    );
  }
}