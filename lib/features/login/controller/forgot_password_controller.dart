// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/features/login/controller/forgot_password_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_otp_service.dart';

class ForgotPasswordController extends GetxController {
  final AuthOtpService _otpService = Get.find<AuthOtpService>();

  // Inputs
  final email = ''.obs;
  final phone = ''.obs;
  final phoneLast4 = ''.obs;
  final otp = ''.obs;
  final newPassword = ''.obs;
  final confirmPassword = ''.obs;

  // UI State
  final isLoading = false.obs;
  final resendCooldown = 0.obs; // seconds

  Timer? _timer;

  bool get canSubmitEmail => email.value.isNotEmpty && email.value.contains('@');
  bool get canSubmitOtp => otp.value.length == 6;
  bool get canSubmitReset =>
      newPassword.value.length >= 8 && newPassword.value == confirmPassword.value;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // Step 1: request OTP via email
  Future<void> requestOtp() async {
    if (!canSubmitEmail) return;
    try {
      isLoading.value = true;
      final res = await _otpService.requestPasswordResetOtp(email: email.value);
      final p = (res['phone'] as String?) ?? '';
      final last4 = (res['phoneLast4'] as String?) ?? (p.isNotEmpty ? p.substring(p.length - 4) : '');
      phone.value = p;
      phoneLast4.value = last4;

      // Start cooldown 30s like web
      _startCooldown(seconds: 30);

      Get.toNamed('/forgot-password-otp');
    } catch (e) {
      String errorMessage = e.toString();
      // Check for common error patterns and provide friendly messages
      if (errorMessage.toLowerCase().contains('not found') || 
          errorMessage.toLowerCase().contains('user not found')) {
        errorMessage = 'email_not_found'.tr;
      } else if (errorMessage.toLowerCase().contains('network') ||
                 errorMessage.toLowerCase().contains('connection')) {
        errorMessage = 'network_error'.tr;
      } else {
        errorMessage = 'contact_admin_error'.tr;
      }
      _toastError(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // Step 1b: resend
  Future<void> resendOtp() async {
    if (resendCooldown.value > 0 || !canSubmitEmail) return;
    try {
      isLoading.value = true;
      await _otpService.requestPasswordResetOtp(email: email.value);
      _startCooldown(seconds: 30);
      _toastInfo('otp_sent_again'.tr);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.toLowerCase().contains('not found') || 
          errorMessage.toLowerCase().contains('user not found')) {
        errorMessage = 'email_not_found'.tr;
      } else if (errorMessage.toLowerCase().contains('network') ||
                 errorMessage.toLowerCase().contains('connection')) {
        errorMessage = 'network_error'.tr;
      } else {
        errorMessage = 'contact_admin_error'.tr;
      }
      _toastError(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // Step 2: verify otp
  Future<void> verifyOtp() async {
    if (!canSubmitOtp) return;
    try {
      isLoading.value = true;
      await _otpService.verifyOtp(phone: phone.value, otp: otp.value);
      Get.toNamed('/forgot-password-reset');
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.toLowerCase().contains('invalid') || 
          errorMessage.toLowerCase().contains('wrong')) {
        errorMessage = 'invalid_otp'.tr;
      } else if (errorMessage.toLowerCase().contains('expired')) {
        errorMessage = 'otp_expired'.tr;
      } else {
        errorMessage = 'verification_failed'.tr;
      }
      _toastError(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  // Step 3: reset password
  Future<void> resetPassword() async {
    if (!canSubmitReset) return;
    try {
      isLoading.value = true;
      await _otpService.resetPasswordWithOtp(
        email: email.value,
        otp: otp.value,
        newPassword: newPassword.value,
      );
      _toastSuccess('password_changed_success'.tr);
      // Clear state and go back to login
      _timer?.cancel();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.toLowerCase().contains('weak') || 
          errorMessage.toLowerCase().contains('too short')) {
        errorMessage = 'password_too_weak'.tr;
      } else if (errorMessage.toLowerCase().contains('invalid') || 
                 errorMessage.toLowerCase().contains('wrong')) {
        errorMessage = 'invalid_otp'.tr;
      } else {
        errorMessage = 'password_reset_failed'.tr;
      }
      _toastError(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  void _startCooldown({required int seconds}) {
    resendCooldown.value = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendCooldown.value <= 1) {
        resendCooldown.value = 0;
        t.cancel();
      } else {
        resendCooldown.value = resendCooldown.value - 1;
      }
    });
  }

  void _toastError(String message) {
    Get.snackbar(
      'error'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
      colorText: Get.theme.colorScheme.error,
    );
  }

  void _toastInfo(String message) {
    Get.snackbar(
      'info'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.primaryOrange.withOpacity(0.08),
      colorText: AppTheme.primaryOrange,
    );
  }

  void _toastSuccess(String message) {
    Get.snackbar(
      'success'.tr,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.08),
      colorText: Colors.green,
    );
  }
}
