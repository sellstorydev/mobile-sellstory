import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../core/di/locator.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/analytics_service.dart';
import '../../../data/services/chat_service.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/mobile_api.dart';
import '../../../app/routes.dart';



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

  // Call server to provision current social user if needed; returns workspaceId or null
  Future<String?> _provisionSocialUserViaApi() async {
    try {
      final api = Get.find<ApiClient>();
      final idToken = await MobileApiAuth.getIdTokenOrThrow(_authService);
      final resp = await api.post<Map<String, dynamic>>(
        '${MobileApiConfig.baseUrl}/api/mobile/me/provision-social',
        options: MobileApiAuth.authHeaderOptions(idToken),
      );
      final status = resp.statusCode ?? 0;
      final data = resp.data ?? const <String, dynamic>{};
      if (status >= 200 && status < 300) {
        return (data['workspaceId'] as String?) ?? data['workspace_id'] as String?;
      }
      if (status == 409 || status == 304) {
        return (data['workspaceId'] as String?) ?? data['workspace_id'] as String?;
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 409 || status == 304) {
        final data = (e.response?.data is Map<String, dynamic>)
            ? (e.response!.data as Map<String, dynamic>)
            : const <String, dynamic>{};
        return (data['workspaceId'] as String?) ?? data['workspace_id'] as String?;
      }
      debugPrint('provision-social failed: ${e.message}');
    } catch (e) {
      debugPrint('provision-social unexpected: $e');
    }
    return null;
  }

  // Ensure first-time social login users are provisioned with profile + workspace
  Future<void> _ensureSocialProvisioning() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final chatService = Get.find<ChatService>();
    try {
      final userDoc = await chatService.usersCollection.doc(uid).get();
      bool needsProvision = true;
      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        final workspaces = (data['workspaces'] as List<dynamic>?) ?? const [];
        needsProvision = workspaces.isEmpty;
      }

      if (needsProvision) {
        final wsId = await _provisionSocialUserViaApi();
        if (wsId != null && wsId.isNotEmpty) {
          await chatService.updateUserLastActiveWorkspaceId(uid, wsId);
        }
      }
    } catch (e) {
      debugPrint('Provisioning check failed/skipped: $e');
    }
  }


  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      await _authService.signInWithGoogle();
      
      // Ensure dependencies are properly setup after login
      Locator.setup();
      // First-time social provisioning: ensure user profile + initial workspace
      await _ensureSocialProvisioning();

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
      await _authService.signInWithAppleFirebase();

      // Ensure dependencies are properly setup after login
      Locator.setup();

      // First-time social provisioning: ensure user profile + initial workspace
      await _ensureSocialProvisioning();

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

  // Forgot Password (navigate to OTP flow)
  void forgotPassword() {
    final email = identity.value.trim();
    Get.toNamed(
      AppRoutes.forgotPasswordEmail,
      parameters: email.isNotEmpty ? {'email': email} : {},
    );
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
      case 'invalid-credential':
        message = 'Apple sign-in failed: invalid credential. Check device iCloud login, bundle ID, Apple capability, and Firebase Apple provider.';
        break;
      case 'account-exists-with-different-credential':
        message = 'Account exists with a different sign-in method. Try logging in with your original provider.';
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
