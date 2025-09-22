import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../controller/login_controller.dart';
import '../widgets/branded_logo.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/top_snack.dart';
import 'package:url_launcher/url_launcher.dart';



class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(LoginController());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside
            FocusScope.of(context).unfocus();
          },
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
                              'email_field_label'.tr,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              onChanged: controller.onIdentityChanged,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.black),

                              decoration: InputDecoration(
                                hintText: 'enter_email_hint'.tr,
                                filled: true,
                                fillColor: AppTheme.backgroundGrey,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Password field
                            Text(
                              'password_field_label'.tr,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Obx(() => TextFormField(
                              onChanged: controller.onPasswordChanged,
                              obscureText: controller.obscurePassword.value,
                              style: const TextStyle(color: Colors.black), // Added black text color
                              decoration: InputDecoration(
                                hintText: 'enter_password_hint'.tr,
                                filled: true,
                                fillColor: AppTheme.backgroundGrey,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                              'forgot_password'.tr,
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
                          height: 44,
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: controller.canSubmit ? 2 : 0,
                              shadowColor: AppTheme.primaryOrange.withOpacity(0.3),
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
                                : Text(
                                    'login'.tr,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      height: 1.2,
                                    ),
                                  ),
                          ),
                        )),
                        
                        const SizedBox(height: 24),
                        
                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppTheme.borderLightGrey)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or_divider'.tr,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: AppTheme.borderLightGrey)),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Google Sign-In button
                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed: controller.isLoading.value ? null : controller.signInWithGoogle,
                            icon: Image.asset(
                              'assets/google_icon.png',
                              width: 24,
                              height: 24,
                            ),
                            label: Text(
                              'sign_in_with_google'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: AppTheme.borderGrey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 2,
                              shadowColor: Colors.black.withOpacity(0.1),
                            ),
                          ),
                        )),

                        // Apple Sign-In button (Apple platforms only)
                        const SizedBox(height: 12),
                        if (GetPlatform.isIOS)
                          Obx(() => SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: controller.isLoading.value ? null : controller.signInWithApple,
                              icon: const FaIcon(FontAwesomeIcons.apple, size: 24, color: Colors.black),
                              label: Text(
                                'sign_in_with_apple'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppTheme.borderGrey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 2,
                                shadowColor: Colors.black.withOpacity(0.1),
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
                                TextSpan(text: '${'for_more_information'.tr} '),
                                TextSpan(
                                  text: 'https://lin.ee/uaT3pzf',
                                  style: const TextStyle(
                                    color: AppTheme.primaryOrange,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      final Uri url = Uri.parse('https://lin.ee/uaT3pzf');
                                      try {
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(
                                            url,
                                            mode: LaunchMode.inAppBrowserView,
                                            browserConfiguration: const BrowserConfiguration(
                                              showTitle: true,
                                            ),
                                          );
                                        } else {
                                          TopSnack.error('Cannot open link', title: 'Error');
                                        }
                                      } catch (e) {
                                        TopSnack.error('Failed to open link', title: 'Error');
                                      }
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
              // Positioned(
              //   top: 16,
              //   right: 16,
              //   child: IconButton(
              //     onPressed: () {
              //       Get.find<ThemeController>().toggle();
              //     },
              //     icon: Obx(() {
              //       final themeController = Get.find<ThemeController>();
              //       return Icon(
              //         themeController.mode.value == ThemeMode.dark 
              //             ? Icons.light_mode 
              //             : Icons.dark_mode,
              //       );
              //     }),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
