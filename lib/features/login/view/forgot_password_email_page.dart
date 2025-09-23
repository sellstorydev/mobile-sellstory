// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/features/login/view/forgot_password_email_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/forgot_password_controller.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordEmailPage extends StatelessWidget {
  const ForgotPasswordEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller exists for the flow
    final controller = Get.put(ForgotPasswordController());

    // Prefill from parameter if present
    final prefillEmail = Get.parameters['email'];
    if (prefillEmail != null && prefillEmail.isNotEmpty && controller.email.value.isEmpty) {
      controller.email.value = prefillEmail;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('forgot_password_title'.tr),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and description
                  Text(
                    'enter_registered_email'.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'forgot_password_description'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Email input
                  Text(
                    'email'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Obx(() => TextFormField(
                        initialValue: controller.email.value,
                        onChanged: (v) => controller.email.value = v,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: 'email_placeholder'.tr,
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
                      )),

                  const SizedBox(height: 32),
                  
                  // Request OTP button
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: controller.canSubmitEmail && !controller.isLoading.value
                              ? controller.requestOtp
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.canSubmitEmail && !controller.isLoading.value
                                ? AppTheme.primaryOrange
                                : AppTheme.buttonDisabled,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: controller.canSubmitEmail && !controller.isLoading.value ? 2 : 0,
                            shadowColor: AppTheme.primaryOrange.withOpacity(0.3),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2, 
                                    valueColor: AlwaysStoppedAnimation(Colors.white)
                                  ),
                                )
                              : Text(
                                  'request_otp'.tr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
