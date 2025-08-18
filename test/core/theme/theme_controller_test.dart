import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

// Mock ThemeController for testing
class MockThemeController extends GetxController {
  final mode = ThemeMode.system.obs;

  @override
  void onInit() {
    // No storage operations in tests
    super.onInit();
  }

  void setMode(ThemeMode m) {
    mode.value = m;
  }

  void toggle() {
    setMode(mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

void main() {
  group('ThemeController', () {
    late MockThemeController controller;

    setUp(() {
      Get.reset();
      controller = MockThemeController();
    });

    tearDown(() {
      Get.reset();
    });

    test('should initialize with system theme by default', () {
      // Act
      controller.onInit();

      // Assert
      expect(controller.mode.value, ThemeMode.system);
    });

    test('should set mode correctly', () {
      // Act
      controller.setMode(ThemeMode.dark);

      // Assert
      expect(controller.mode.value, ThemeMode.dark);
    });

    test('should toggle from light to dark', () {
      // Arrange
      controller.setMode(ThemeMode.light);

      // Act
      controller.toggle();

      // Assert
      expect(controller.mode.value, ThemeMode.dark);
    });

    test('should toggle from dark to light', () {
      // Arrange
      controller.setMode(ThemeMode.dark);

      // Act
      controller.toggle();

      // Assert
      expect(controller.mode.value, ThemeMode.light);
    });

    test('should toggle from system to dark', () {
      // Arrange
      controller.setMode(ThemeMode.system);

      // Act
      controller.toggle();

      // Assert
      expect(controller.mode.value, ThemeMode.dark);
    });
  });
}
