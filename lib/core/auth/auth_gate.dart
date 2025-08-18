import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/firebase_auth_service.dart';
import '../../features/shell/shell_page.dart';
import '../../features/login/view/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is signed in, go to shell
        if (snapshot.hasData && snapshot.data != null) {
          return const ShellPage();
        }

        // If user is not signed in, go to login
        return const LoginPage();
      },
    );
  }
}

