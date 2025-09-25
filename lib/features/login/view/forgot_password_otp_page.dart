// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/features/login/view/forgot_password_otp_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/forgot_password_controller.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordOtpPage extends StatelessWidget {
  const ForgotPasswordOtpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgotPasswordController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('confirm_otp'.tr),
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
                  Obx(() => Text(
                        controller.phone.value.isNotEmpty
                            ? 'enter_6_digit_code_with_phone'.tr.replaceAll('\${last4}', controller.phoneLast4.value)
                            : 'enter_6_digit_code'.tr,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                  const SizedBox(height: 32),
                  // No Obx needed here; we don't read any Rx when typing
                  TextFormField(
                    onChanged: (v) => controller.otp.value = v.replaceAll(RegExp(r'[^0-9]'), '').trim(),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: const TextStyle(color: Colors.black, letterSpacing: 4),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'otp_hint_placeholder'.tr,
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
                  const SizedBox(height: 16),
                  Obx(() => Row(
                        children: [
                          TextButton(
                            onPressed: controller.resendCooldown.value == 0 && !controller.isLoading.value
                                ? controller.resendOtp
                                : null,
                            child: Text(
                              controller.resendCooldown.value == 0
                                  ? 'resend'.tr
                                  : 'resend_in_seconds'.tr.replaceAll('\${seconds}', controller.resendCooldown.value.toString()),
                              style: TextStyle(
                                color: controller.resendCooldown.value == 0
                                    ? AppTheme.primaryOrange
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      )),
                  const SizedBox(height: 32),

                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: controller.canSubmitOtp && !controller.isLoading.value
                              ? controller.verifyOtp
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.canSubmitOtp && !controller.isLoading.value
                                ? AppTheme.primaryOrange
                                : AppTheme.buttonDisabled,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: controller.canSubmitOtp && !controller.isLoading.value ? 2 : 0,
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
                                  'confirm'.tr,
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
