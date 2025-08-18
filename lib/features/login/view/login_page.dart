import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';
import '../widgets/branded_logo.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/app_theme.dart';

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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email field
                          Text(
                            'อีเมล',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                                                      TextFormField(
                              onChanged: controller.onIdentityChanged,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'กรอกอีเมล',
                              ),
                            ),
                          
                          const SizedBox(height: 24),
                          
                          // Password field
                          Text(
                            'รหัสผ่าน',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Obx(() => TextFormField(
                            onChanged: controller.onPasswordChanged,
                            obscureText: controller.obscurePassword.value,
                            decoration: InputDecoration(
                              hintText: 'กรอกรหัสผ่าน',
                              suffixIcon: IconButton(
                                onPressed: controller.togglePasswordVisibility,
                                icon: Icon(
                                  controller.obscurePassword.value 
                                      ? Icons.visibility_off 
                                      : Icons.visibility,
                                  color: AppTheme.textSecondary,
                                ),
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
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Login button
                      Obx(() => SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: controller.canSubmit ? controller.signInWithEmail : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.canSubmit 
                                ? AppTheme.primaryOrange 
                                : AppTheme.buttonDisabled,
                            foregroundColor: controller.canSubmit 
                                ? Colors.white 
                                : AppTheme.buttonDisabledText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'เข้าสู่ระบบ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      )),
                      
                      const SizedBox(height: 24),
                      
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.borderLightGrey)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'หรือ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: AppTheme.borderLightGrey)),
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
                            backgroundColor: AppTheme.backgroundWhite,
                            side: BorderSide(color: AppTheme.borderGrey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      )),
                      
                      const SizedBox(height: 32),
                      
                      // Information link
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            children: [
                              const TextSpan(text: 'สอบถามข้อมูลเพิ่มเติม '),
                                                             TextSpan(
                                 text: 'https://lin.ee/uaT3pzf',
                                 style: TextStyle(
                                   color: AppTheme.primaryOrange,
                                   decoration: TextDecoration.underline,
                                 ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: Open URL
                                    Get.snackbar('Info', 'Opening LINE link...');
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Version text
                      Center(
                        child: Text(
                          'version 1.10.6 (288)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ),
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
