import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    // Redirect to login after first frame
    Future.microtask(() {
      Get.offAllNamed(AppRoutes.login);
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
            // Placeholder for splash logo
            Icon(
              Icons.shopping_cart,
              size: 80,
              color: Color(0xFFFF6A00),
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
