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
        'Invalid email or password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Bootstrap current social user (first login) via API per docs/social-login-signup.md
  // Returns active workspaceId if available
  Future<String?> _bootstrapSocialUser() async {
    try {
      final api = Get.find<ApiClient>();
      final idToken = await MobileApiAuth.getIdTokenOrThrow(_authService);
      final resp = await api.post<Map<String, dynamic>>(
        '${MobileApiConfig.baseUrl}/api/auth/bootstrap',
        options: MobileApiAuth.authHeaderOptions(idToken),
      );
      final status = resp.statusCode ?? 0;
      final data = resp.data ?? const <String, dynamic>{};
      if (status >= 200 && status < 300) {
        // Prefer activeWorkspace.id; fallback to user.lastActiveWorkspaceId or first workspace.id
        final aw = (data['activeWorkspace'] is Map) ? (data['activeWorkspace'] as Map) : null;
        final awId = (aw?['id']?.toString() ?? '').trim();
        if (awId.isNotEmpty) return awId;
        final user = (data['user'] is Map) ? (data['user'] as Map) : null;
        final lastId = (user?['lastActiveWorkspaceId']?.toString() ?? '').trim();
        if (lastId.isNotEmpty) return lastId;
        final ws = (user?['workspaces'] is List) ? (user!['workspaces'] as List) : const [];
        if (ws.isNotEmpty) {
          final first = (ws.first is Map) ? (ws.first as Map) : null;
          final fid = (first?['id']?.toString() ?? '').trim();
          if (fid.isNotEmpty) return fid;
        }
        return null;
      }
    } on DioException catch (e) {
      // Non-2xx: try to parse workspaceId-like hints but otherwise ignore
      final data = (e.response?.data is Map<String, dynamic>)
          ? (e.response!.data as Map<String, dynamic>)
          : const <String, dynamic>{};
      final wsId = (data['workspaceId']?.toString() ?? data['workspace_id']?.toString() ?? '').trim();
      if (wsId.isNotEmpty) return wsId;
      debugPrint('bootstrap-social failed: ${e.message} (${e.response?.statusCode})');
    } catch (e) {
      debugPrint('bootstrap-social unexpected: $e');
    }
    return null;
  }

  // Ensure first-time social login users are provisioned with profile + workspace via bootstrap API
  Future<String?> _ensureSocialProvisioning() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

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
        final wsId = await _bootstrapSocialUser();
        if (wsId != null && wsId.isNotEmpty) {
          await chatService.updateUserLastActiveWorkspaceId(uid, wsId);
          return wsId;
        }
      }
    } catch (e) {
      debugPrint('Provisioning check failed/skipped: $e');
    }
    return null;
  }


  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      await _authService.signInWithGoogle();
      
      // Ensure dependencies are properly setup after login
      Locator.setup();
      // First-time social provisioning (bootstrap): ensure user profile + initial workspace
      final bootWorkspaceId = await _ensureSocialProvisioning();

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

      // Prefetch permissions for user's active workspace (prefer bootstrap result to avoid race)
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final chatService = Get.find<ChatService>();
          String? workspaceId = bootWorkspaceId;
          workspaceId ??= await chatService.getUserCurrentWorkspaceId(user.uid);
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
        'Invalid email or password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
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
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
      return;
    }

    try {
      isLoading.value = true;
      // await _authService.signInWithAppleFirebase();

      // Ensure dependencies are properly setup after login
      Locator.setup();

      // First-time social provisioning (bootstrap)
      final bootWorkspaceId = await _ensureSocialProvisioning();

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
          String? workspaceId = bootWorkspaceId;
          workspaceId ??= await chatService.getUserCurrentWorkspaceId(user.uid);
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
        'Invalid email or password',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
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
    String message = 'Invalid email or password';

    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
      colorText: Get.theme.colorScheme.error,
    );
  }
}
