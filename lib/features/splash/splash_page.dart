import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Check auth state and redirect accordingly
    Future.microtask(() async {
      // Wait a bit for Firebase to initialize
      await Future.delayed(const Duration(seconds: 2));
      
      // Check if user is already signed in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Get.offAllNamed(AppRoutes.shell);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SellStory Logo
            SizedBox(
              width: 80,
              height: 80,
              child: Image(
                image: AssetImage('assets/sellstory_logo.png'),
                width: 80,
                height: 80,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'SellStory',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF6A00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
