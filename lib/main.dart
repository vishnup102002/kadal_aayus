// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart'; // <-- 1. Import Hive
import 'firebase_options.dart';

// Import your new navigation shell
import 'screens/navigation_shell.dart';

void main() async {
  // --- This part is correct and doesn't need changes ---
  WidgetsFlutterBinding.ensureInitialized();

  // --- 2. Initialize Hive for local storage ---
  await Hive.initFlutter();
  await Hive.openBox('alertsBox'); // Open a 'box' to store alerts
  // ------------------------------------------

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  // --- End of correct part ---

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hides the debug banner
      title: 'Kadal Aayus',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // This now correctly points to the NavigationShell
      home: NavigationShell(),
    );
  }
}
