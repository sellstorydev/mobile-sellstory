import 'user.dart';

class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  const AuthResult.success(this.user) 
      : success = true, 
        errorMessage = null;

  const AuthResult.failure(this.errorMessage) 
      : success = false, 
        user = null;

  @override
  String toString() {
    return 'AuthResult(success: $success, user: $user, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthResult &&
        other.success == success &&
        other.user == user &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return success.hashCode ^ user.hashCode ^ errorMessage.hashCode;
  }
}
