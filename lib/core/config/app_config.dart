// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/core/config/app_config.dart

/// Centralized app config and environment flags
class AppConfig {
  // Provide MOBILE_BACKEND_SECRET at build time using:
  // flutter run --dart-define=MOBILE_BACKEND_SECRET=your_secret
  static const String mobileBackendSecret = String.fromEnvironment(
    'MOBILE_BACKEND_SECRET',
    defaultValue: '',
  );
}

