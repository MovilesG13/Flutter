import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Screens/principal.dart';
import '../Screens/welcome.dart';

class AuthGate extends StatelessWidget {
  final Function(String)? onThemeChanged;
  
  const AuthGate({super.key, this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?> (
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error de autenticación')),
          );
        }
        if (snapshot.data != null) {
          return HomeScreen(onThemeChanged: onThemeChanged);
        }
        return const WelcomeScreen();
      },
    );
  }
}
