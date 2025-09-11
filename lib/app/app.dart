import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../data/services/firebase_auth_service.dart';
import '../core/theme/theme_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/i18n/locale_controller.dart';
import '../core/i18n/app_translations.dart';
import '../core/di/locator.dart';
import 'routes.dart';
import '../data/services/mobile_permissions_service.dart';
import '../data/services/canned_responses_service.dart';
import '../data/services/auth_otp_service.dart';
import '../data/services/firestore_service.dart';

class SellStoryApp extends StatelessWidget {
  const SellStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeController = Get.find<ThemeController>();
      final localeController = Get.find<LocaleController>();
      
      return GetMaterialApp(
        title: 'SellStory',
        theme: AppTheme.lightTheme,
        // darkTheme: AppTheme.darkTheme,
        themeMode: themeController.mode.value,
        translations: AppTranslations(),
        locale: localeController.locale.value,
        fallbackLocale: const Locale('en', 'US'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('th', 'TH'),
        ],
        initialRoute: AppRoutes.splash,
        getPages: AppRoutes.routes,
        debugShowCheckedModeBanner: false,
      );
    });
  }

  static void setupDependencies() {
    // HTTP client setup
    Get.put<Dio>(
      Dio(
        BaseOptions(
          baseUrl: 'https://workspace.sellstory.me', // Base URL for SellStory API
          connectTimeout: const Duration(seconds: 7),
          receiveTimeout: const Duration(seconds: 7),
        ),
      ),
    );

    // API client setup
    Get.put<ApiClient>(ApiClient(Get.find<Dio>()));

    // Firebase Auth service setup
    Get.put<FirebaseAuthService>(FirebaseAuthService(), permanent: true);

    // Firestore service setup (needed for ShellController email save)
    Get.put<FirestoreService>(FirestoreService(), permanent: true);

    // Mobile permissions service
    Get.put<MobilePermissionsService>(MobilePermissionsService(), permanent: true);

    // Canned responses service
    Get.put<CannedResponsesService>(CannedResponsesService(), permanent: true);

    // Auth OTP service
    Get.put<AuthOtpService>(AuthOtpService(), permanent: true);

    // Analytics service setup
    // Get.put<AnalyticsService>(AnalyticsService(), permanent: true);

    // Board feature dependencies
    Locator.setup();
  }
}
