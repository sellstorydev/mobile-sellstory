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
        title: const Text('ลืมรหัสผ่าน'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'กรอกอีเมลที่ใช้สมัคร',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Obx(() => TextFormField(
                      initialValue: controller.email.value,
                      onChanged: (v) => controller.email.value = v,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'your@email.com',
                        filled: true,
                        fillColor: AppTheme.backgroundGrey,
                        border: OutlineInputBorder(
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

                const SizedBox(height: 24),
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: controller.canSubmitEmail && !controller.isLoading.value
                            ? controller.requestOtp
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.canSubmitEmail
                              ? AppTheme.primaryOrange
                              : AppTheme.buttonDisabled,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                              )
                            : const Text('ขอรหัส OTP'),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
