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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'core/services/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background isolate
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}
  // Use print to avoid relying on app services in background isolate
  // ignore: avoid_print
  print('FCM background message: id=${message.messageId} data=${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Logger Service first
  Get.put(LoggerService(), permanent: true);
  LoggerService.to.info('Application starting...');
  LoggerService.to.devTools('SellStory App Starting', {
    'version': '1.0.0',
    'timestamp': DateTime.now().toIso8601String(),
    'platform': 'mobile',
  });
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    LoggerService.to.firebase('Firebase initialized successfully');
  } catch (e) {
    LoggerService.to.failure('Failed to initialize Firebase', e);
  }

  // Register FCM background handler
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    LoggerService.to.failure('Failed to register FCM background handler', e);
  }

  // Initialize GetStorage
  try {
    await GetStorage.init();
    LoggerService.to.cache('GetS torage initialized successfully');
  } catch (e) {
    LoggerService.to.failure('Failed to initialize GetStorage', e);
  }
  
  // Setup dependency injection
  try {
    LoggerService.to.devTools('Setting up dependencies...');
    SellStoryApp.setupDependencies();
    LoggerService.to.di('Dependency injection setup completed');
    LoggerService.to.devTools('Dependencies setup completed', {
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'success',
    });
  } catch (e) {
    LoggerService.to.failure('Failed to setup dependency injection', e);
    LoggerService.to.devTools('Dependencies setup failed', {
      'error': e.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'failed',
    });
  }

  // Register theme and locale controllers
  try {
    Get.put(ThemeController(), permanent: true);
    Get.put(LocaleController(), permanent: true);
    LoggerService.to.config('Theme and locale controllers registered');
  } catch (e) {
    LoggerService.to.failure('Failed to register controllers', e);
  }

  // Init FCM service and auto-register device token on login
  try {
    final fcm = await Get.putAsync<FcmService>(() async => FcmService().init(), permanent: true);
    // Register when already signed in
    if (FirebaseAuth.instance.currentUser != null) {
      await fcm.registerDeviceForPush();
    }

    // Register on any future login
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await fcm.registerDeviceForPush();
      }
    });
  } catch (e) {
    print(e);
    LoggerService.to.failure('Failed to initialize FCM service', e);
  }

  LoggerService.to.success('Application initialization completed');
  
  runApp(
      const SellStoryApp()
  );
}
