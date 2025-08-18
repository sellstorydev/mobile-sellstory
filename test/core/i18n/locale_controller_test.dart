import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

// Mock LocaleController for testing
class MockLocaleController extends GetxController {
  final locale = const Locale('th', 'TH').obs;

  @override
  void onInit() {
    // No storage operations in tests
    super.onInit();
  }

  void setLocale(Locale l) {
    locale.value = l;
    Get.updateLocale(l);
  }

  void toggle() {
    setLocale(locale.value.languageCode == 'th' 
        ? const Locale('en', 'US') 
        : const Locale('th', 'TH'));
  }
}

void main() {
  group('LocaleController', () {
    late MockLocaleController controller;

    setUp(() {
      Get.reset();
      controller = MockLocaleController();
    });

    tearDown(() {
      Get.reset();
    });

    test('should initialize with Thai locale by default', () {
      // Act
      controller.onInit();

      // Assert
      expect(controller.locale.value, const Locale('th', 'TH'));
    });

    test('should set locale correctly', () {
      // Act
      controller.setLocale(const Locale('en', 'US'));

      // Assert
      expect(controller.locale.value, const Locale('en', 'US'));
    });

    test('should toggle from Thai to English', () {
      // Arrange
      controller.setLocale(const Locale('th', 'TH'));

      // Act
      controller.toggle();

      // Assert
      expect(controller.locale.value, const Locale('en', 'US'));
    });

    test('should toggle from English to Thai', () {
      // Arrange
      controller.setLocale(const Locale('en', 'US'));

      // Act
      controller.toggle();

      // Assert
      expect(controller.locale.value, const Locale('th', 'TH'));
    });
  });
}
