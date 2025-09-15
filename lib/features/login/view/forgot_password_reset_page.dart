// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/features/login/view/forgot_password_reset_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/forgot_password_controller.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordResetPage extends StatelessWidget {
  const ForgotPasswordResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ForgotPasswordController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('reset_password_title'.tr),
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
                  'รหัสผ่านใหม่',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                // No Obx needed here; we only update Rx on change
                TextFormField(
                  obscureText: true,
                  onChanged: (v) => controller.newPassword.value = v,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'อย่างน้อย 8 ตัวอักษร',
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
                const SizedBox(height: 16),
                Text(
                  'confirm_new_password'.tr,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                // No Obx needed here; we only update Rx on change
                TextFormField(
                  obscureText: true,
                  onChanged: (v) => controller.confirmPassword.value = v,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'พิมพ์ซ้ำอีกครั้ง',
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
                const SizedBox(height: 12),
                Obx(() {
                  final match = controller.newPassword.value.isNotEmpty &&
                      controller.confirmPassword.value.isNotEmpty &&
                      controller.newPassword.value == controller.confirmPassword.value;
                  return Text(
                    match ? 'รหัสผ่านตรงกัน' : 'รหัสผ่านไม่ตรงกัน',
                    style: TextStyle(
                      color: match ? Colors.green : Get.theme.colorScheme.error,
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Obx(() => SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: controller.canSubmitReset && !controller.isLoading.value
                            ? controller.resetPassword
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.canSubmitReset
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
                            : Text('confirm_password_change'.tr),
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
