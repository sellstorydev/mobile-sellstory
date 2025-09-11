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
        title: const Text('ยืนยัน OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                      controller.phone.value.isNotEmpty
                          ? 'กรุณากรอกรหัส 6 หลักที่ส่งไปยัง ••••${controller.phoneLast4.value}'
                          : 'กรุณากรอกรหัส 6 หลัก',
                      style: Theme.of(context).textTheme.titleMedium,
                    )),
                const SizedBox(height: 8),
                // No Obx needed here; we don't read any Rx when typing
                TextFormField(
                  onChanged: (v) => controller.otp.value = v.replaceAll(RegExp(r'[^0-9]'), '').trim(),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.black, letterSpacing: 4),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '123456',
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
                ),
                const SizedBox(height: 8),
                Obx(() => Row(
                      children: [
                        TextButton(
                          onPressed: controller.resendCooldown.value == 0 && !controller.isLoading.value
                              ? controller.resendOtp
                              : null,
                          child: Text(
                            controller.resendCooldown.value == 0
                                ? 'ส่งใหม่'
                                : 'ส่งใหม่ใน ${controller.resendCooldown.value}s',
                            style: TextStyle(
                              color: controller.resendCooldown.value == 0
                                  ? AppTheme.primaryOrange
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    )),
                const SizedBox(height: 24),

                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: controller.canSubmitOtp && !controller.isLoading.value
                            ? controller.verifyOtp
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.canSubmitOtp
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
                            : const Text('ยืนยัน'),
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
