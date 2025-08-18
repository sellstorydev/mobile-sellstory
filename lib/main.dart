import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'app/app.dart';
import 'core/theme/theme_controller.dart';
import 'core/i18n/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize GetStorage
  await GetStorage.init();
  
  // Setup dependency injection
  SellStoryApp.setupDependencies();
  
  // Register theme and locale controllers
  Get.put(ThemeController(), permanent: true);
  Get.put(LocaleController(), permanent: true);
  
  runApp(const SellStoryApp());
}
