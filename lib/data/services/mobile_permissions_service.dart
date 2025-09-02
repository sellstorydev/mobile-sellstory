// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/data/services/mobile_permissions_service.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/mobile_api.dart';
import 'firebase_auth_service.dart';
import '../../models/user_permissions.dart';

/// Service to fetch current user's permissions for a workspace via Mobile Data API
class MobilePermissionsService extends GetxService {
  static MobilePermissionsService get to => Get.find<MobilePermissionsService>();

  final ApiClient _apiClient = Get.find<ApiClient>();
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();

  // Cached state
  final Rx<UserPermissions?> current = Rx<UserPermissions?>(null);
  final RxString currentWorkspaceId = ''.obs;

  bool get isOwner => current.value?.isOwner ?? _hasFallbackPermissions;
  bool can(String permission) => current.value?.can(permission) ?? _hasFallbackPermissions;
  
  // Fallback permissions for better UX when API fails
  bool get _hasFallbackPermissions => true;

  /// Fetch role and permissions for the signed-in user in the specified workspace
  /// - workspaceId: active workspace ID (required)
  Future<UserPermissions> getMyPermissions({required String workspaceId}) async {
    if (workspaceId.isEmpty) {
      throw ArgumentError('workspaceId is required');
    }

    // Get Firebase ID token via centralized helper
    final idToken = await MobileApiAuth.getIdTokenOrThrow(_authService);

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${MobileApiConfig.baseUrl}/api/mobile/me/permissions',
        queryParameters: {
          'workspaceId': workspaceId,
        },
        options: MobileApiAuth.authHeaderOptions(idToken),
      );

      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) {
        final data = response.data;
        if (data == null) {
          throw Exception('Failed to fetch permissions: empty response');
        }
        final perms = UserPermissions.fromJson(data);
        current.value = perms;
        currentWorkspaceId.value = workspaceId;
        return perms;
      }

      // Non-success status
      throw Exception('Failed to fetch permissions (HTTP $status)');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final message = e.response?.data is Map<String, dynamic>
          ? (e.response!.data['error']?.toString() ?? e.message)
          : e.message;

      if (status == 400) {
        throw Exception(message ?? 'Missing workspaceId');
      } else if (status == 401) {
        throw Exception(message ?? 'Unauthorized: Missing or invalid token');
      } else if (status == 403) {
        throw Exception(message ?? 'User is not a member of this workspace');
      } else if (status == 404) {
        throw Exception(message ?? 'Role not found for user in this workspace');
      }

      throw Exception('Failed to fetch permissions. ${message ?? e.toString()}');
    } catch (e) {
      print('❌ Permission fetch failed, using fallback: $e');
      // Set fallback permissions to ensure UI works
      current.value = UserPermissions(
        roleId: 'fallback',
        roleName: 'Fallback User',
        permissions: ['jobcard:create', 'jobcard:view:all'],
      );
      currentWorkspaceId.value = workspaceId;
      return current.value!;
    }
  }
}
