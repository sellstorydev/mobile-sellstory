import 'package:get/get.dart';
import '../../models/auth_result.dart';
import '../../models/user.dart';

/// Abstract interface for authentication service
abstract class AuthService {
  Future<AuthResult> login({
    required String identity,
    required String password,
  });
}

/// Dummy implementation for testing and development
class DummyAuthService implements AuthService {
  @override
  Future<AuthResult> login({
    required String identity,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));

    // Success when password is "123456" and identity is not empty
    if (password == "123456" && identity.trim().isNotEmpty) {
      return AuthResult.success(
        User(
          id: "user_${DateTime.now().millisecondsSinceEpoch}",
          name: "Test User",
          email: identity.contains('@') ? identity : "test@example.com",
          phone: identity.contains('@') ? null : identity,
        ),
      );
    } else {
      return AuthResult.failure('invalid_credentials'.tr);
    }
  }
}
