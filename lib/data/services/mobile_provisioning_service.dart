import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/mobile_api.dart';
import 'firebase_auth_service.dart';

/// Service to provision user + initial workspace on first-time Social login
class MobileProvisioningService extends GetxService {
  static MobileProvisioningService get to => Get.find<MobileProvisioningService>();


  final ApiClient _apiClient = Get.find<ApiClient>();
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();

  /// Call server to provision current social user if needed.
  /// Returns workspaceId when created or already existed, otherwise null.
  Future<String?> provisionSocialUser() async {
    // Acquire ID token for Authorization header
    final idToken = await MobileApiAuth.getIdTokenOrThrow(_authService);

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${MobileApiConfig.baseUrl}/api/mobile/me/provision-social',
        options: MobileApiAuth.authHeaderOptions(idToken),
      );

      final status = response.statusCode ?? 0;
      final data = response.data ?? const <String, dynamic>{};

      if (status >= 200 && status < 300) {
        // Expecting { success: true, workspaceId: '...' } or similar
        return (data['workspaceId'] as String?) ?? data['workspace_id'] as String?;
      }

      // Non-success status; try to interpret idempotent responses
      if (status == 409 || status == 304) {
        // Conflict or Not Modified -> already provisioned; try to extract workspaceId if present
        return (data['workspaceId'] as String?) ?? data['workspace_id'] as String?;
      }

      throw Exception('Provisioning failed (HTTP $status)');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = e.response?.data is Map<String, dynamic>
          ? e.response!.data['error']?.toString()
          : e.message;

      // If server says already exists, it's fine to proceed
      if (status == 409 || status == 304) {
        final data = (e.response?.data is Map<String, dynamic>)
            ? (e.response!.data as Map<String, dynamic>)
            : const <String, dynamic>{};
        return (data['workspaceId'] as String?) ?? data['workspace_id'] as String?;
      }

      // Surface the error for caller to decide UX; do not throw to avoid blocking login
      print('❌ provisionSocialUser error: ${message ?? e}');
      return null;
    } catch (e) {
      print('❌provisionSocialUser unexpected error: $e');
      return null;
    }
  }
}
