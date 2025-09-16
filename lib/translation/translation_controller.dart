import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Enhanced Translation Service Controller
/// Manages language switching, persistence, and provides utility methods
class TranslationController extends GetxController {
  static TranslationController get to => Get.find();
  
  final _storage = GetStorage();
  static const String _storageKey = 'app_locale';
  static const String _defaultLanguage = 'en';
  
  // Reactive language state
  final RxString currentLanguage = 'en'.obs;
  final Rx<Locale> currentLocale = const Locale('en', 'US').obs;
  
  // Available languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'th': 'ไทย',
  };
  
  static const Map<String, Locale> localeMap = {
    'en': Locale('en', 'US'),
    'th': Locale('th', 'TH'),
  };
  
  @override
  void onInit() {
    super.onInit();
    _initializeLanguage();
  }
  
  @override
  void onReady() {
    super.onReady();
    // Ensure GetX locale is synchronized after app is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.updateLocale(currentLocale.value);
    });
  }
  
  /// Initialize language from storage or use default
  void _initializeLanguage() {
    final savedLanguage = _storage.read<String>(_storageKey);
    if (savedLanguage != null && supportedLanguages.containsKey(savedLanguage)) {
      _setLanguage(savedLanguage, updateGetX: true);
    } else {
      _setLanguage(_defaultLanguage, updateGetX: true);
    }
  }
  
  /// Set language and update all reactive states
  void _setLanguage(String languageCode, {bool updateGetX = true}) {
    if (!supportedLanguages.containsKey(languageCode)) {
      return;
    }
    
    currentLanguage.value = languageCode;
    currentLocale.value = localeMap[languageCode]!;
    
    if (updateGetX) {
      // Force update GetX locale system
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.updateLocale(currentLocale.value);
      });
    }
    
    _storage.write(_storageKey, languageCode);
  }
  
  /// Switch language between Thai and English
  void switchLanguage(String languageCode) {
    if (languageCode != currentLanguage.value) {
      _setLanguage(languageCode);
    }
  }
  
  /// Toggle between Thai and English
  void toggleLanguage() {
    final newLanguage = currentLanguage.value == 'th' ? 'en' : 'th';
    switchLanguage(newLanguage);
  }
  
  /// Check if current language is Thai
  bool get isThaiLanguage => currentLanguage.value == 'th';
  
  /// Check if current language is English
  bool get isEnglishLanguage => currentLanguage.value == 'en';
  
  /// Get localized text with fallback support
  String getText(String key, {String? fallback}) {
    final translation = key.tr;
    
    // If translation is the same as key, it means translation not found
    if (translation == key) {
      return fallback ?? key;
    }
    
    return translation;
  }
  
  /// Get text with parameters
  String getTextWithParams(String key, Map<String, String> params, {String? fallback}) {
    String text = getText(key, fallback: fallback);
    
    // Replace parameters in the format {paramName}
    params.forEach((paramKey, paramValue) {
      text = text.replaceAll('{$paramKey}', paramValue);
    });
    
    return text;
  }
  
  /// Format date based on current locale
  String formatDate(DateTime date) {
    if (isThaiLanguage) {
      return '${date.day}/${date.month}/${date.year + 543}'; // Thai Buddhist year
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
  
  /// Format currency based on locale
  String formatCurrency(double amount) {
    if (isThaiLanguage) {
      return '฿${amount.toStringAsFixed(2)}';
    } else {
      return '\$${amount.toStringAsFixed(2)}';
    }
  }
  
  /// Get language display name
  String get currentLanguageDisplayName {
    return supportedLanguages[currentLanguage.value] ?? 'Unknown';
  }
  
  /// Get opposite language code for toggle display
  String get oppositeLanguageCode {
    return currentLanguage.value == 'th' ? 'en' : 'th';
  }
  
  /// Get opposite language display name
  String get oppositeLanguageDisplayName {
    return supportedLanguages[oppositeLanguageCode] ?? 'Unknown';
  }
  
  /// Reset to default language
  void resetToDefault() {
    switchLanguage(_defaultLanguage);
  }
  
  /// Clear storage and reset to default
  void clearAndReset() {
    _storage.remove(_storageKey);
    resetToDefault();
  }
}