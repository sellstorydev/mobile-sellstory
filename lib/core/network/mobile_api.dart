// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/core/network/mobile_api.dart
import 'package:dio/dio.dart';

import '../../data/services/firebase_auth_service.dart';

/// Central config/constants for Mobile Data API
class MobileApiConfig {
  static const String baseUrl = 'http://10.1.3.17:3000';
  // static const String baseUrl = 'https://workspace.sellstory.me';
}


/// Common helpers for Mobile Data API auth
class MobileApiAuth {
  /// Retrieve Firebase ID token or throw if missing/unauthorized
  static Future<String> getIdTokenOrThrow(FirebaseAuthService auth) async {
    final user = auth.currentUser;
    if (user == null) {
      throw Exception('Unauthorized: Not signed in');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw Exception('Unauthorized: Missing token');
    }
    return token;
  }

  /// Convenience Options with Authorization header
  static Options authHeaderOptions(String token) => Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
}
