// lib/services/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/navigation_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key}); // const constructor for optimization

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading spinner while connecting to Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Show error if something goes wrong
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                "Something went wrong. Please restart the app.",
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        // Check user authentication state
        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(); // Not signed in
        } else {
          return NavigationShell(); // Signed in → go to app
        }
      },
    );
  }
}