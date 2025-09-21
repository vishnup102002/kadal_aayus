import 'package:flutter/material.dart';
import 'package:kadal_aayus/services/auth_service.dart';
import 'package:kadal_aayus/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  bool _loading = false;

  void _signInAnonymously() async {
    setState(() => _loading = true);
    final user = await _authService.signInAnonymously();
    setState(() => _loading = false);
    if (user != null) {
      await _userService.createOrUpdateUserProfile(user);
      _navigateToHome();
    }
  }

  void _signInWithGoogle() async {
    setState(() => _loading = true);
    final user = await _authService.signInWithGoogle();
    setState(() => _loading = false);
    if (user != null) {
      await _userService.createOrUpdateUserProfile(user);
      _navigateToHome();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in cancelled or failed')),
        );
      }
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login - Kadal Aayus')),
      body: Center(
        child: _loading
            ? CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _signInWithGoogle,
                child: Text('Sign in with Google'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _signInAnonymously,
                child: Text('Continue as Guest'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
