import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';
import '../widgets/branded_logo.dart';
import '../widgets/primary_button.dart';
import '../../../core/theme/theme_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const BrandedLogo(),
                      const SizedBox(height: 48),
                      
                      // Email/Password form
                      Column(
                        children: [
                          // Email field
                          TextFormField(
                            onChanged: controller.onIdentityChanged,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'อีเมล',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).primaryColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Password field
                          Obx(() => TextFormField(
                            onChanged: controller.onPasswordChanged,
                            obscureText: controller.obscurePassword.value,
                            decoration: InputDecoration(
                              hintText: 'รหัสผ่าน',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                onPressed: controller.togglePasswordVisibility,
                                icon: Icon(
                                  controller.obscurePassword.value 
                                      ? Icons.visibility_off 
                                      : Icons.visibility,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Theme.of(context).primaryColor),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          )),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: controller.forgotPassword,
                          child: Text(
                            'ลืมรหัสผ่าน',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Login button
                      Obx(() => PrimaryButton(
                        text: 'เข้าสู่ระบบ',
                        onPressed: controller.canSubmit ? controller.signInWithEmail : null,
                        isLoading: controller.isLoading.value,
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[300])),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'หรือ',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Google Sign-In button
                      Obx(() => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: controller.isLoading.value ? null : controller.signInWithGoogle,
                          icon: const Icon(
                            Icons.g_mobiledata,
                            size: 24,
                            color: Colors.black87,
                          ),
                          label: const Text(
                            'เข้าสู่ระบบด้วย Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ),
            
            // Theme toggle button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () {
                  Get.find<ThemeController>().toggle();
                },
                icon: Obx(() {
                  final themeController = Get.find<ThemeController>();
                  return Icon(
                    themeController.mode.value == ThemeMode.dark 
                        ? Icons.light_mode 
                        : Icons.dark_mode,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
