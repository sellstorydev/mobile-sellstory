import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../core/di/locator.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/mobile_permissions_service.dart';


class LoginController extends GetxController {
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();

  // Form fields
  final identity = ''.obs;
  final password = ''.obs;
  
  // UI state
  final isLoading = false.obs;
  final obscurePassword = true.obs;

  // Computed properties
  bool get canSubmit {
    return identity.value.isNotEmpty && password.value.isNotEmpty;
  }

  // Methods
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void onIdentityChanged(String value) {
    identity.value = value;
  }

  void onPasswordChanged(String value) {
    password.value = value;
  }

  // Email/Password Login
  Future<void> signInWithEmail() async {
    if (!canSubmit) return;

    try {
      isLoading.value = true;
      await _authService.signInWithEmail(identity.value, password.value);
      
      // Ensure dependencies are properly setup after login
      Locator.setup();

      // Register FCM token + device immediately after login
      if (Get.isRegistered<FcmService>()) {
        await Get.find<FcmService>().registerDeviceForPush();
      }

      // GA4: set userId and log login event
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && Get.isRegistered<AnalyticsService>()) {
        await AnalyticsService.to.setUserId(uid);
        await AnalyticsService.to.logLogin(method: 'password');
      }


      // Prefetch permissions for user's active workspace
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final chatService = Get.find<ChatService>();
          String? workspaceId = await chatService.getUserCurrentWorkspaceId(user.uid);
          workspaceId ??= await chatService.getUserFirstWorkspaceId(user.uid);
          if (workspaceId != null && workspaceId.isNotEmpty) {
            await MobilePermissionsService.to.getMyPermissions(workspaceId: workspaceId);
          }
        }
      } catch (_) {
        // Ignore errors; UI will hide actions if permissions not available
      }

      Get.offAllNamed('/shell');
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      debugPrint('signInWithEmail error: $e');
      Get.snackbar(
        'Error',
        'Login failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      await _authService.signInWithGoogle();
      
      // Ensure dependencies are properly setup after login
      Locator.setup();

      // Register FCM token + device immediately after login
      if (Get.isRegistered<FcmService>()) {
        await Get.find<FcmService>().registerDeviceForPush();
      }

      // GA4: set userId and log login event
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && Get.isRegistered<AnalyticsService>()) {
        await AnalyticsService.to.setUserId(uid);
        await AnalyticsService.to.logLogin(method: 'google');
      }

      // Prefetch permissions for user's active workspace
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final chatService = Get.find<ChatService>();
          String? workspaceId = await chatService.getUserCurrentWorkspaceId(user.uid);
          workspaceId ??= await chatService.getUserFirstWorkspaceId(user.uid);
          if (workspaceId != null && workspaceId.isNotEmpty) {
            await MobilePermissionsService.to.getMyPermissions(workspaceId: workspaceId);
          }
        }
      } catch (_) {
        // Ignore errors; UI will hide actions if permissions not available
      }

      Get.offAllNamed('/shell');
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Google sign in failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Apple Sign-In
  Future<void> signInWithApple() async {
    // Safety guard: Apple Sign-In only available on Apple platforms
    if (!GetPlatform.isIOS) {
      Get.snackbar(
        'Unavailable',
        'Apple sign-in is available only on iOS devices',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return;
    }
    try {
      isLoading.value = true;
      await _authService.signInWithApple();

      // Ensure dependencies are properly setup after login
      Locator.setup();

      // Register FCM token + device immediately after login
      if (Get.isRegistered<FcmService>()) {
        await Get.find<FcmService>().registerDeviceForPush();
      }

      // GA4
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && Get.isRegistered<AnalyticsService>()) {
        await AnalyticsService.to.setUserId(uid);
        await AnalyticsService.to.logLogin(method: 'apple');
      }

      // Prefetch permissions
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final chatService = Get.find<ChatService>();
          String? workspaceId = await chatService.getUserCurrentWorkspaceId(user.uid);
          workspaceId ??= await chatService.getUserFirstWorkspaceId(user.uid);
          if (workspaceId != null && workspaceId.isNotEmpty) {
            await MobilePermissionsService.to.getMyPermissions(workspaceId: workspaceId);
          }
        }
      } catch (_) {}

      Get.offAllNamed('/shell');
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      debugPrint('signInWithApple error: $e');
      Get.snackbar(
        'Error',
        'Apple sign in failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Password Reset
  Future<void> forgotPassword() async {
    if (identity.value.isEmpty || !identity.value.contains('@')) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return;
    }

    try {
      isLoading.value = true;
      await _authService.sendPasswordResetEmail(identity.value);
      Get.snackbar(
        'Success',
        'Password reset email sent to ${identity.value}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.primary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send reset email: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Handle Firebase Auth Errors
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
      case 'weak-password':
        message = 'Password is too weak';
        break;
      case 'email-already-in-use':
        message = 'Email is already registered';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later';
        break;
      default:
        message = e.message ?? 'Authentication failed';
    }

    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
      colorText: Get.theme.colorScheme.error,
    );
  }
}
