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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'new_password'.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  // No Obx needed here; we only update Rx on change
                  TextFormField(
                    obscureText: true,
                    onChanged: (v) => controller.newPassword.value = v,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'new_password_hint'.tr,
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
                      hintText: 'confirm_password_hint'.tr,
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
                  const SizedBox(height: 12),
                  Obx(() {
                    final match = controller.newPassword.value.isNotEmpty &&
                        controller.confirmPassword.value.isNotEmpty &&
                        controller.newPassword.value == controller.confirmPassword.value;
                    return Text(
                      match ? 'passwords_match'.tr : 'passwords_do_not_match'.tr,
                      style: TextStyle(
                        color: match ? Colors.green : Get.theme.colorScheme.error,
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: controller.canSubmitReset && !controller.isLoading.value
                              ? controller.resetPassword
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: controller.canSubmitReset && !controller.isLoading.value
                                ? AppTheme.primaryOrange
                                : AppTheme.buttonDisabled,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: controller.canSubmitReset && !controller.isLoading.value ? 2 : 0,
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
                                  'confirm_password_change'.tr,
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
