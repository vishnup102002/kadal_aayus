// lib/services/auth_service.dart

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Anonymous Sign-In
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('Anonymous sign-in error: $e');
      return null;
    }
  }

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // The user canceled the sign-in.
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;

    } catch (e) {
      print("An error occurred during Google Sign-In: $e");
      return null;
    }
  }

  // --- THIS IS THE MISSING METHOD ---
  // Sign out from both Firebase and Google Sign-In
  Future<void> signOut() async {
    try {
      // It's important to sign out of both services to ensure a clean logout.
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }
}
