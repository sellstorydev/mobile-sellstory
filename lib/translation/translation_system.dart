// Translation System Export File
// This file provides easy access to all translation system components

export 'translation_controller.dart';
export 'widgets/language_switcher_widget.dart';

// Helper extension for easier translation access
import 'package:get/get.dart';

/// Extension to provide easier access to translations with fallback
extension TranslationExtension on String {
  /// Get translation with fallback support
  String trWith({String? fallback}) {
    final translation = this.tr;
    // If translation is the same as key, it means translation not found
    if (translation == this) {
      return fallback ?? this;
    }
    return translation;
  }
  
  /// Get translation with parameters
  String trParams(Map<String, String> params) {
    String text = this.tr;
    params.forEach((key, value) {
      text = text.replaceAll('{$key}', value);
    });
    return text;
  }
}