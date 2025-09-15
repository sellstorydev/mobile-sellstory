import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../translation_controller.dart';

/// Language Switcher Widget
/// Provides UI component for switching between Thai and English languages
class LanguageSwitcherWidget extends StatelessWidget {
  final TranslationController _controller = Get.find<TranslationController>();
  
  final bool showAsButton;
  final bool showText;
  final double? fontSize;
  final Color? textColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  
  LanguageSwitcherWidget({
    Key? key,
    this.showAsButton = true,
    this.showText = true,
    this.fontSize,
    this.textColor,
    this.backgroundColor,
    this.padding,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (showAsButton) {
        return _buildButton(context);
      } else {
        return _buildDropdown(context);
      }
    });
  }
  
  Widget _buildButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          onTap: () => _controller.toggleLanguage(),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  size: fontSize ?? 16,
                  color: textColor ?? Theme.of(context).primaryColor,
                ),
                if (showText) ...[
                  const SizedBox(width: 8),
                  Text(
                    _controller.currentLanguageDisplayName,
                    style: TextStyle(
                      fontSize: fontSize ?? 14,
                      color: textColor ?? Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                Icon(
                  Icons.swap_horiz,
                  size: (fontSize ?? 16) - 2,
                  color: textColor ?? Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDropdown(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _controller.currentLanguage.value,
          icon: Icon(
            Icons.arrow_drop_down,
            color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
          style: TextStyle(
            fontSize: fontSize ?? 14,
            color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              _controller.switchLanguage(newValue);
            }
          },
          items: TranslationController.supportedLanguages.entries
              .map<DropdownMenuItem<String>>((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getLanguageFlag(entry.key),
                  if (showText) ...[
                    const SizedBox(width: 8),
                    Text(entry.value),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'th':
        return const Text('🇹🇭', style: TextStyle(fontSize: 16));
      case 'en':
        return const Text('🇺🇸', style: TextStyle(fontSize: 16));
      default:
        return const Icon(Icons.language, size: 16);
    }
  }
}

/// Simple Language Toggle Button
/// Compact version for app bars and floating actions
class LanguageToggleButton extends StatelessWidget {
  final TranslationController _controller = Get.find<TranslationController>();
  final double? size;
  final Color? color;
  final String? tooltip;
  
  LanguageToggleButton({
    Key? key,
    this.size,
    this.color,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => IconButton(
      icon: Icon(
        Icons.translate,
        size: size ?? 24,
        color: color ?? Theme.of(context).primaryColor,
      ),
      onPressed: () => _controller.toggleLanguage(),
      tooltip: tooltip ?? 'switch_to_{language}'.tr.replaceFirst(
        '{language}', 
        _controller.oppositeLanguageDisplayName.toLowerCase()
      ),
    ));
  }
}

/// Language Selection Sheet
/// Bottom sheet for language selection with more options
class LanguageSelectionSheet extends StatelessWidget {
  final TranslationController _controller = Get.find<TranslationController>();
  
  LanguageSelectionSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            'language'.tr,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Language options
          ...TranslationController.supportedLanguages.entries.map((entry) {
            return Obx(() => _buildLanguageOption(
              context,
              entry.key,
              entry.value,
              _controller.currentLanguage.value == entry.key,
            ));
          }).toList(),
          
          const SizedBox(height: 20),
          
          // Close button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('close'.tr),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLanguageOption(BuildContext context, String code, String name, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected 
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            _controller.switchLanguage(code);
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _getLanguageFlag(code),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'th':
        return const Text('🇹🇭', style: TextStyle(fontSize: 24));
      case 'en':
        return const Text('🇺🇸', style: TextStyle(fontSize: 24));
      default:
        return const Icon(Icons.language, size: 24);
    }
  }
  
  /// Show language selection sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => LanguageSelectionSheet(),
    );
  }
}