import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_preview/device_preview.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'core/theme/theme_controller.dart';
import 'core/i18n/locale_controller.dart';
import 'core/services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Logger Service first
  Get.put(LoggerService(), permanent: true);
  LoggerService.to.info('Application starting...');
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    LoggerService.to.firebase('Firebase initialized successfully');
  } catch (e) {
    LoggerService.to.failure('Failed to initialize Firebase', e);
  }
  
  // Initialize GetStorage
  try {
    await GetStorage.init();
    LoggerService.to.cache('GetStorage initialized successfully');
  } catch (e) {
    LoggerService.to.failure('Failed to initialize GetStorage', e);
  }
  
  // Setup dependency injection
  try {
    SellStoryApp.setupDependencies();
    LoggerService.to.di('Dependency injection setup completed');
  } catch (e) {
    LoggerService.to.failure('Failed to setup dependency injection', e);
  }
  
  // Register theme and locale controllers
  try {
    Get.put(ThemeController(), permanent: true);
    Get.put(LocaleController(), permanent: true);
    LoggerService.to.config('Theme and locale controllers registered');
  } catch (e) {
    LoggerService.to.failure('Failed to register controllers', e);
  }
  
  LoggerService.to.success('Application initialization completed');
  
  runApp(
    DevicePreview(
      enabled: true, // Enable device preview
      builder: (context) => const SellStoryApp(),
    ),
  );
}
