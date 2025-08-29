import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Lightweight helper to show a consistent top-positioned snackbar across the app.
class TopSnack {
  TopSnack._();

  static void show(String message, {bool isError = false, String? title, Duration? duration}) {
    // Dismiss existing to avoid stacking many
    try {
      Get.closeAllSnackbars();
    } catch (_) {}

    Get.snackbar(
      title ?? (isError ? 'เกิดข้อผิดพลาด' : 'แจ้งเตือน'),
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      backgroundColor: isError ? Colors.redAccent : Colors.black87,
      colorText: Colors.white,
      icon: Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  static void success(String message, {String? title, Duration? duration}) =>
      show(message, isError: false, title: title ?? 'สำเร็จ', duration: duration);

  static void error(String message, {String? title, Duration? duration}) =>
      show(message, isError: true, title: title ?? 'เกิดข้อผิดพลาด', duration: duration);

  static void info(String message, {String? title, Duration? duration}) =>
      show(message, isError: false, title: title ?? 'แจ้งเตือน', duration: duration);
}

