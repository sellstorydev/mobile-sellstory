class Validators {
  /// Validates identity (email or phone number)
  /// Returns true if length is at least 5 characters
  static bool isValidIdentity(String identity) {
    return identity.trim().length >= 5;
  }

  /// Validates password
  /// Returns true if length is at least 6 characters
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Validates email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Validates phone number format (Thai format)
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^(\+66|66|0)[0-9]{8,9}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\s+'), ''));
  }

  /// Validates if the input is either a valid email or phone number
  static bool isValidIdentityFormat(String identity) {
    return isValidEmail(identity) || isValidPhone(identity);
  }
}
