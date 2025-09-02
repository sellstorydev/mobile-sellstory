// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/data/services/canned_responses_service.dart
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../core/network/api_client.dart';
import '../../core/network/mobile_api.dart';
import 'firebase_auth_service.dart';
import '../../models/canned_responses.dart';


class CannedResponsesService extends GetxService {
  static CannedResponsesService get to => Get.find<CannedResponsesService>();

  final ApiClient _apiClient = Get.find<ApiClient>();
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();

  Options _authHeaders(String token) => MobileApiAuth.authHeaderOptions(token);

  Future<List<CannedResponseGroup>> fetchGroups({required String workspaceId, String? search}) async {
    final token = await MobileApiAuth.getIdTokenOrThrow(_authService);
    try {
      final resp = await _apiClient.get<Map<String, dynamic>>(
        '${MobileApiConfig.baseUrl}/api/mobile/canned-responses',
        queryParameters: {
          'workspaceId': workspaceId,
          if (search != null && search.isNotEmpty) 'search': search,
          'pageSize': 50,
        },
        options: _authHeaders(token),
      );
      final data = resp.data;
      if (data == null || data['success'] != true) {
        throw Exception('Failed to fetch canned responses');
      }
      final groups = (data['groups'] as List<dynamic>? ?? [])
          .map((e) => CannedResponseGroup.fromJson(e as Map<String, dynamic>))
          .toList();
      return groups;
    } on DioException catch (e) {
      final msg = e.response?.data is Map<String, dynamic>
          ? ((e.response!.data['error'] ?? e.message)?.toString())
          : e.message;
      throw Exception(msg ?? 'Network error');
    }
  }

  Future<CannedResponseGroup> createGroup({required String workspaceId, required String name}) async {
    final token = await MobileApiAuth.getIdTokenOrThrow(_authService);
    final body = {
      'workspaceId': workspaceId,
      'action': 'create_group',
      'name': name,
    };
    final resp = await _apiClient.post<Map<String, dynamic>>(
      '${MobileApiConfig.baseUrl}/api/mobile/canned-responses',
      data: body,
      options: _authHeaders(token),
    );
    final data = resp.data;
    if (data == null || data['success'] != true || data['group'] == null) {
      throw Exception('Create group failed');
    }
    return CannedResponseGroup.fromJson(data['group'] as Map<String, dynamic>);
  }

  Future<CannedResponse> addResponse({
    required String workspaceId,
    required String groupId,
    required String title,
    required String type,
    String? text,
    String? imageUrl,
  }) async {
    final token = await MobileApiAuth.getIdTokenOrThrow(_authService);
    final body = {
      'workspaceId': workspaceId,
      'action': 'add_response',
      'groupId': groupId,
      'response': {
        'title': title,
        'type': type,
        if (text != null) 'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
      }
    };
    final resp = await _apiClient.post<Map<String, dynamic>>(
      '${MobileApiConfig.baseUrl}/api/mobile/canned-responses',
      data: body,
      options: _authHeaders(token),
    );
    final data = resp.data;
    if (data == null || data['success'] != true || data['response'] == null) {
      throw Exception('Add response failed');
    }
    return CannedResponse.fromJson(data['response'] as Map<String, dynamic>);
  }

  Future<void> updateGroup({required String workspaceId, required String groupId, required String name}) async {
    final token = await MobileApiAuth.getIdTokenOrThrow(_authService);
    final body = {
      'workspaceId': workspaceId,
      'action': 'update_group',
      'groupId': groupId,
      'name': name,
    };
    await _apiClient.put(
      '${MobileApiConfig.baseUrl}/api/mobile/canned-responses',
      data: body,
      options: _authHeaders(token),
    );
  }

  Future<void> updateResponse({
    required String workspaceId,
    required String groupId,
    required CannedResponse response,
  }) async {
    final token = await MobileApiAuth.getIdTokenOrThrow(_authService);
    final body = {
      'workspaceId': workspaceId,
      'action': 'update_response',
      'groupId': groupId,
      'response': response.toJson(),
    };
    await _apiClient.put(
      '${MobileApiConfig.baseUrl}/api/mobile/canned-responses',
      data: body,
      options: _authHeaders(token),
    );
  }

  Future<void> deleteGroup({required String workspaceId, required String groupId}) async {
    final token = await MobileApiAuth.getIdTokenOrThrow(_authService);
    final body = {
      'workspaceId': workspaceId,
      'action': 'delete_group',
      'groupId': groupId,
    };
    await _apiClient.delete(
      '${MobileApiConfig.baseUrl}/api/mobile/canned-responses',
      data: body,
      options: _authHeaders(token),
    );
  }

  Future<void> deleteResponse({required String workspaceId, required String groupId, required String responseId}) async {
    final token = await MobileApiAuth.getIdTokenOrThrow(_authService);
    final body = {
      'workspaceId': workspaceId,
      'action': 'delete_response',
      'groupId': groupId,
      'responseId': responseId,
    };
    await _apiClient.delete(
      '${MobileApiConfig.baseUrl}/api/mobile/canned-responses',
      data: body,
      options: _authHeaders(token),
    );
  }
}
