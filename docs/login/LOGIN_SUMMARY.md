````markdown
# Login Summary

## Recent Changes

### Password Reset Error Message Translation (September 25, 2025)

**Issue:** The `requestOtp()` function in password reset flow was showing hardcoded Thai text "เกิดข้อผิดพลาด กรุณาติดต่อ admin sellstory" instead of using proper translation keys.

**Solution Applied:**
1. **Added Translation Key**: Created new translation key `contact_admin_error` with the same Thai text
2. **Updated Code**: Changed hardcoded text to use `'contact_admin_error'.tr` for proper internationalization
3. **Consistency**: Applied the same translation key to both `requestOtp()` and `resendOtp()` functions

**Technical Changes:**

**Before:**
```dart
} else {
  errorMessage = 'เกิดข้อผิดพลาด กรุณาติดต่อ admin sellstory';
}
```

**After:**
```dart
} else {
  errorMessage = 'contact_admin_error'.tr;
}
```

**Translation Key Added:**
```dart
// English (en_US)
'contact_admin_error': 'เกิดข้อผิดพลาด กรุณาติดต่อ admin sellstory',

// Thai (th)  
'contact_admin_error': 'เกิดข้อผิดพลาด กรุณาติดต่อ admin sellstory',
```

**Files Modified:**
- `lib/core/i18n/app_translations.dart`
  - Added `contact_admin_error` translation key for both English and Thai
- `lib/features/login/controller/forgot_password_controller.dart`
  - Updated error message in `requestOtp()` function to use translation key
  - Updated error message in `resendOtp()` function to use translation key

**Benefits:**
- **Proper I18N**: Now follows established translation pattern using GetX .tr system
- **Maintainability**: Text can be updated in translation files without code changes  
- **Localization Ready**: Easy to provide different translations for other languages
- **Consistent Pattern**: Matches the established codebase internationalization approach

### In-App Browser Link Opening Implementation (September 21, 2025)

**Issue:** Link "สอบถามเพิ่มเติม" (https://lin.ee/uaT3pzf) in login page was opening external browser instead of in-app browser.

**Solution Applied:**
1. **Added url_launcher Import**: Added `package:url_launcher/url_launcher.dart` import for URL handling
2. **In-App Browser Configuration**: Modified TapGestureRecognizer to use `launchUrl()` with `LaunchMode.inAppBrowserView`
3. **Error Handling**: Added try-catch with proper error messages using TopSnack

**Technical Changes:**

**Before:**
```dart
recognizer: TapGestureRecognizer()
  ..onTap = () {
    TopSnack.info('Opening LINE link...', title: 'Info');
  },
```

**After:**
```dart
recognizer: TapGestureRecognizer()
  ..onTap = () async {
    final Uri url = Uri.parse('https://lin.ee/uaT3pzf');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.inAppBrowserView,
          browserConfiguration: const BrowserConfiguration(
            showTitle: true,
          ),
        );
      } else {
        TopSnack.error('Cannot open link', title: 'Error');
      }
    } catch (e) {
      TopSnack.error('Failed to open link', title: 'Error');
    }
  },
```

**Features:**
- **In-App Browser**: Opens link within the app using `LaunchMode.inAppBrowserView`
- **Browser Configuration**: Shows title in the in-app browser for better UX
- **Error Handling**: Proper error handling with user-friendly messages
- **URL Validation**: Checks if URL can be launched before attempting to open

**Files Modified:**
- `lib/features/login/view/login_page.dart`
  - Added url_launcher import
  - Modified TapGestureRecognizer onTap callback
  - Added async URL launching with in-app browser mode
  - Added error handling with TopSnack messages

**Benefits:**
- **Better UX**: Users stay within the app when viewing the link
- **Consistent Experience**: No context switching to external browser
- **Error Feedback**: Clear error messages if link cannot be opened
- **Professional Look**: In-app browser with title bar

### Generic Login Error Message Implementation (September 18, 2025)

**Issue:** Login error messages were showing specific details that could be used for account enumeration and provided too much information about authentication failures.

**Security Concern:**
- Specific error messages like "No user found with this email address" or "Wrong password provided" could help attackers identify valid email addresses
- Different error messages for different failure types could be exploited for user enumeration attacks

**Solution Applied:**
1. **Unified Error Handling**: Modified `_handleAuthError()` method in `login_controller.dart`
2. **Generic Message**: All authentication failures now show "Invalid email or password"
3. **Consistent Experience**: Applied the same generic message to all login methods (email/password, Google, Apple)

**Technical Changes:**

**Before:**
```dart
void _handleAuthError(FirebaseAuthException e) {
  String message;
  switch (e.code) {
    case 'user-not-found':
      message = 'No user found with this email address';
      break;
    case 'wrong-password':
      message = 'Wrong password provided';
      break;
    case 'invalid-email':
      message = 'Invalid email address';
      break;
    // ... more specific messages
    default:
      message = e.message ?? 'Authentication failed';
  }
}
```

**After:**
```dart
void _handleAuthError(FirebaseAuthException e) {
  String message = 'Invalid email or password';
  // Simplified error handling with generic message
}
```

**Updated Error Messages:**
- Email/Password login failures: "Invalid email or password"
- Google sign-in failures: "Invalid email or password" 
- Apple sign-in failures: "Invalid email or password"
- All FirebaseAuthException cases: "Invalid email or password"

**Benefits:**
- **Enhanced Security**: Prevents user enumeration attacks
- **Consistent UX**: Same error message across all login methods
- **Privacy Protection**: Doesn't reveal whether email exists in system
- **Simplified Debugging**: Errors still logged to console for developers

**Files Modified:**
- `lib/features/login/controller/login_controller.dart`
  - Updated `_handleAuthError()` method
  - Updated catch blocks in `signInWithEmail()`, `signInWithGoogle()`, `signInWithApple()`

**Testing:**
- All login failure scenarios now display the generic "Invalid email or password" message
- Error logging still occurs in debug console for development purposes
- User experience is consistent regardless of failure type


````

