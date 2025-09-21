import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class WebviewApiService {
  final ApiClient _apiClient;

  WebviewApiService(this._apiClient);

  /// Get Hashtag Settings Webview URL
  Future<String?> getHashtagSettingsUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/mobile/settings/hashtag',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting hashtag settings URL: $e');
      return null;
    }
  }

  /// Get Company Settings Webview URL
  Future<String?> getCompanySettingsUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {

      final response = await _apiClient.get(
        '/api/mobile/settings/company',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } on DioException catch (e) {
      print('❌ DioException getting company settings URL:');

      // Return a fallback URL for development/testing
      if (e.response?.statusCode == 500) {
        print('❌ Using fallback URL for company settings');
        return 'https://workspace.sellstory.me/settings/company?token=fallback&workspaceId=$workspaceId';
      }

      return null;
    } catch (e) {
      print('❌ Unexpected error getting company settings URL: $e');
      return null;
    }
  }

  /// Get Board Settings Webview URL
  Future<String?> getBoardSettingsUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/mobile/settings/board',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting board settings URL: $e');
      return null;
    }
  }

  /// Get Notification Settings Webview URL
  Future<String?> getNotificationSettingsUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/mobile/settings/notifications',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting notification settings URL: $e');
      return null;
    }
  }

  /// Get Welcome Message Settings Webview URL
  Future<String?> getWelcomeMessageSettingsUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/mobile/settings/welcome-messages',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting welcome message settings URL: $e');
      return null;
    }
  }

  /// Get Chatbot Settings Webview URL
  Future<String?> getChatbotSettingsUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/mobile/settings/chatbot',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting chatbot settings URL: $e');
      return null;
    }
  }

  /// Get ID Generation Rules Webview URL
  Future<String?> getIdGenerationRulesUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/mobile/settings/id-rules',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting ID generation rules URL: $e');
      return null;
    }
  }

  /// Get Roles & Permissions Webview URL
  Future<String?> getRolesPermissionsUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/mobile/settings/roles',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting roles & permissions URL: $e');
      return null;
    }
  }

  /// Get Approval Conditions Webview URL
  Future<String?> getApprovalConditionsUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/mobile/settings/approvals',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting approval conditions URL: $e');
      return null;
    }
  }

  /// Get Document Settings Webview URL
  Future<String?> getDocumentSettingsUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/mobile/settings/documents',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting document settings URL: $e');
      return null;
    }
  }

  /// Get Catalog Settings Webview URL
  Future<String?> getCatalogSettingsUrl({
    required String userId,
    required String workspaceId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/mobile/settings/catalog',
        queryParameters: {'userId': userId, 'workspaceId': workspaceId},
      );

      if (response.data['success'] == true) {
        return response.data['webviewUrl'] as String?;
      }

      return null;
    } catch (e) {
      print('❌ Error getting catalog settings URL: $e');
      return null;
    }
  }

  /// Get Document Share Webview URL
  /// This function handles both JSON responses (with webviewUrl) and HTML responses (direct content)
  Future<dynamic> getDocumentShareUrl({
    required String documentId,
    required String documentType,
  }) async {
    try {
      print(
        '🔄 Requesting document share for ID: $documentId, Type: $documentType',
      );

      final response = await _apiClient.get(
        '/api/mobile/document/share?documentId=$documentId&documentType=$documentType',
      );
      // Check if response is JSON with expected structure
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['webviewUrl'] != null) {
          final url = data['webviewUrl'] as String;
          return {'type': 'url', 'content': url};
        }

        print('❌ JSON response missing success=true or webviewUrl field');
        return null;
      }

      // If response is HTML (String), return the processed HTML content directly
      if (response.data is String) {
        final htmlContent = response.data as String;

        // Validate that it's actually HTML content
        if (htmlContent.trim().toLowerCase().startsWith('<!doctype html') ||
            htmlContent.trim().toLowerCase().startsWith('<html')) {
          return {'type': 'html', 'content': htmlContent};
        } else {
          return null;
        }
      }

      print('❌ Unexpected response data type: ${response.data.runtimeType}');
      return null;
    } catch (e) {
      print('❌ Error getting document share URL: $e');
      return null;
    }
  }
}
