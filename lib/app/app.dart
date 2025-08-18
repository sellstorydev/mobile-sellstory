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
import 'routes.dart';

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
        darkTheme: AppTheme.darkTheme,
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
          connectTimeout: const Duration(seconds: 7),
          receiveTimeout: const Duration(seconds: 7),
        ),
      ),
    );

    // API client setup
    Get.put<ApiClient>(ApiClient(Get.find<Dio>()));

    // Firebase Auth service setup
    Get.put<FirebaseAuthService>(FirebaseAuthService(), permanent: true);
  }
}
