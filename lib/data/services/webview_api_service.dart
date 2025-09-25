import 'dart:convert';
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

  /// Generate PDF from document
  /// Returns the PDF as bytes along with the filename
  Future<Map<String, dynamic>?> generatePdfFromDocument({
    required String documentId,
    required String documentType,
    String? workspaceId,
    bool? twoPass,
    bool? forceManualFontEmbedding,
  }) async {
    try {
      print('🔄 Generating PDF for document ID: $documentId, Type: $documentType');

      // Prepare request data
      final requestData = <String, dynamic>{
        'documentId': documentId,
        'documentType': documentType,
      };

      if (workspaceId != null) {
        requestData['workspaceId'] = workspaceId;
      }
      if (twoPass != null) {
        requestData['twoPass'] = twoPass;
      }
      if (forceManualFontEmbedding != null) {
        requestData['forceManualFontEmbedding'] = forceManualFontEmbedding;
      }

      print('📤 Request data: $requestData');

      final response = await _apiClient.post(
        '/api/generate-pdf-from-doc',
        data: requestData,
        options: Options(
          responseType: ResponseType.bytes, // Important: Request response as bytes
          headers: {
            'Content-Type': 'application/json',
          },
          // PDF generation can take longer, so increase timeout
          receiveTimeout: const Duration(minutes: 2), // 2 minutes for PDF generation
          sendTimeout: const Duration(seconds: 30), // 30 seconds for request sending
        ),
      );

      // Check if we received PDF data
      if (response.data != null) {
        print('📥 Response received: ${response.data.runtimeType}, size: ${response.data is List ? (response.data as List).length : 'unknown'} bytes');
        print('📋 Response headers: ${response.headers.toString()}');
        
        // Extract filename from Content-Disposition header if available
        String? filename;
        final contentDisposition = response.headers['content-disposition']?.first;
        if (contentDisposition != null) {
          final filenameMatch = RegExp(r'filename[^;=\n]*=(.*)')
              .firstMatch(contentDisposition);
          if (filenameMatch != null) {
            filename = filenameMatch.group(1)?.replaceAll('"', '').trim();
          }
        }

        // Fallback filename if not provided in headers
        filename ??= '${documentType.toUpperCase()}_$documentId.pdf';

        print('📁 Extracted filename: $filename');

        return {
          'data': response.data as List<int>,
          'filename': filename,
          'contentType': response.headers['content-type']?.first ?? 'application/pdf',
        };
      }

      print('❌ Empty PDF response received');
      return null;
    } on DioException catch (e) {
      print('❌ DioException generating PDF: ${e.message}');
      
      // Try to parse error response if it's JSON
      if (e.response?.data != null) {
        try {
          // Convert bytes to string if needed
          String errorText;
          if (e.response!.data is List<int>) {
            errorText = String.fromCharCodes(e.response!.data);
          } else {
            errorText = e.response!.data.toString();
          }
          
          // Try to parse as JSON error response
          final errorData = jsonDecode(errorText);
          if (errorData is Map<String, dynamic> && errorData['error'] != null) {
            print('❌ Server error: ${errorData['error']}');
            return {
              'error': errorData['error'],
              'details': errorData['details'],
            };
          }
        } catch (parseError) {
          print('❌ Could not parse error response: $parseError');
        }
      }
      
      // Handle specific timeout errors with more helpful messages
      String errorMessage = 'Failed to generate PDF: ${e.message}';
      if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'PDF generation timed out. The document may be complex or the server is busy. Please try again.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'Request timed out while sending data. Please check your internet connection and try again.';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timed out. Please check your internet connection and try again.';
      }
      
      return {
        'error': errorMessage,
        'statusCode': e.response?.statusCode,
        'type': e.type.toString(),
      };
    } catch (e) {
      print('❌ Unexpected error generating PDF: $e');
      return {
        'error': 'Unexpected error: $e',
      };
    }
  }
}
