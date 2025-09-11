// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/data/services/auth_otp_service.dart
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';

class AuthOtpService extends GetxService {
  static AuthOtpService get to => Get.find();

  late final ApiClient _api;

  @override
  void onInit() {
    _api = Get.find<ApiClient>();
    super.onInit();
  }

  Future<Map<String, dynamic>> requestPasswordResetOtp({required String email}) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/auth/request-password-reset-otp',
        data: {
          'email': email,
        },
      );
      final data = res.data ?? {};
      final success = data['success'] == true;
      if (!success) {
        throw DioException(
          requestOptions: res.requestOptions,
          response: res,
          error: data['message'] ?? 'Failed to request OTP',
        );
      }
      return data;
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] ?? 'Request failed')
          : (e.message ?? 'Request failed');
      throw Exception(message);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/auth/verify-otp',
        data: {
          'phone': phone,
          'otp': otp,
        },
      );
      final data = res.data ?? {};
      final success = data['success'] == true;
      if (!success) {
        throw Exception(data['message'] ?? 'Invalid OTP');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] ?? 'Verification failed')
          : (e.message ?? 'Verification failed');
      throw Exception(message);
    }
  }

  Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/api/auth/reset-password-with-otp',
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
      final data = res.data ?? {};
      final success = data['success'] == true;
      if (!success) {
        throw Exception(data['message'] ?? 'Failed to reset password');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response?.data['message'] ?? 'Reset failed')
          : (e.message ?? 'Reset failed');
      throw Exception(message);
    }
  }
}

