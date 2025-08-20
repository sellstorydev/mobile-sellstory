import 'package:flutter/material.dart';

class KeyboardUtils {
  /// Dismiss keyboard by unfocusing current focus
  static void dismissKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  /// Wrap widget with keyboard dismissal on tap
  static Widget wrapWithKeyboardDismissal({
    required Widget child,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () => dismissKeyboard(context),
      child: child,
    );
  }

  /// Create a scrollable widget that dismisses keyboard on drag
  static Widget createKeyboardAwareScrollView({
    required Widget child,
    ScrollViewKeyboardDismissBehavior dismissBehavior = ScrollViewKeyboardDismissBehavior.onDrag,
  }) {
    return SingleChildScrollView(
      keyboardDismissBehavior: dismissBehavior,
      child: child,
    );
  }
}
