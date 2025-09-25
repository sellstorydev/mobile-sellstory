import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static const _k = 'themeMode';
  final box = GetStorage();
  final mode = ThemeMode.system.obs;

  @override
  void onInit() {
    final saved = box.read<String>(_k);
    mode.value = saved == 'dark' 
        ? ThemeMode.dark 
        : saved == 'light' 
            ? ThemeMode.light 
            : ThemeMode.system;
    super.onInit();
  }

  void setMode(ThemeMode m) {
    mode.value = m;
    box.write(_k, m.name);
    // Update Get's theme mode to reflect immediately without rebuilding root
    Get.changeThemeMode(m);
  }

  void toggle() {
    setMode(mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
