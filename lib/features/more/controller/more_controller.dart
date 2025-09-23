import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../data/services/webview_api_service.dart';
import '../../../core/di/locator.dart';
import '../../../core/services/fcm_service.dart';

class MoreController extends GetxController {
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();
  final WebviewApiService _webviewApiService = Get.find<WebviewApiService>();
  
  // User data
  final user = Rx<User?>(null);
  final isLoading = false.obs;
  final firestoreDisplayName = ''.obs;
  final firestorePhotoURL = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    // Get current user
    user.value = FirebaseAuth.instance.currentUser;
    
    // Load user data from Firestore
    _loadUserDataFromFirestore();
    
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      this.user.value = user;
      if (user != null) {
        _loadUserDataFromFirestore();
      } else {
        // Clear Firestore data when user logs out
        firestoreDisplayName.value = '';
        firestorePhotoURL.value = null;
      }
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserDataFromFirestore() async {
    final currentUser = user.value;
    if (currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        firestoreDisplayName.value = data['displayName'] ?? '';
        firestorePhotoURL.value = data['photoURL'];
      }
    } catch (e) {
      print('Error loading user data from Firestore: $e');
    }
  }

  // Public method to refresh user data (called from EditProfilePage)
  Future<void> refreshUserData() async {
    await _loadUserDataFromFirestore();
  }




  // Logout with confirmation
  Future<void> logout() async {
    // Show confirmation dialog
    final bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('logout'.tr),
        content: Text('confirm_logout_question'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('logout'.tr),
          ),
        ],
      ),
    );

    // If user confirmed, proceed with logout
    if (confirmed == true) {
      try {
        isLoading.value = true;
        // Unregister FCM device & delete token before auth sign-out
        try {
          if (Get.isRegistered<FcmService>()) {
            await Get.find<FcmService>().unregisterDeviceForPush();
          }
        } catch (_) {}
        await _authService.signOut();
        
        // Reset dependencies to prevent issues after logout
        Locator.resetDependencies();
        
        Get.offAllNamed('/login');
      } catch (e) {
        Get.snackbar(
          'error'.tr,
          'logout_failed_details'.trParams({'error': e.toString()}),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  // Get user display name (prioritize Firestore data)
  String get displayName {
    // First try Firestore data
    if (firestoreDisplayName.value.isNotEmpty) {
      return firestoreDisplayName.value;
    }
    
    // Fallback to Firebase Auth data
    final currentUser = user.value;
    if (currentUser == null) return 'guest'.tr;
    
    if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
      return currentUser.displayName!;
    }
    
    if (currentUser.email != null) {
      return currentUser.email!.split('@')[0];
    }
    
    return 'user'.tr;
  }

  // Get user email
  String get email {
    return user.value?.email ?? 'no_email'.tr;
  }

  // Get user photo URL (prioritize Firestore data)
  String? get photoURL {
    // First try Firestore data
    if (firestorePhotoURL.value != null && firestorePhotoURL.value!.isNotEmpty) {
      return firestorePhotoURL.value;
    }
    
    // Fallback to Firebase Auth data
    return user.value?.photoURL;
  }

  // Get current user ID
  String get currentUserId {
    return user.value?.uid ?? '';
  }

  // Open Hashtag Settings Webview
  Future<void> openHashtagSettings(String workspaceId) async {
    try {
      isLoading.value = true;
      
      final webviewUrl = await _webviewApiService.getHashtagSettingsUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'hashtag_settings'.tr,
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_load_hashtag_settings'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_open_hashtag_settings'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Open Company Settings Webview
  Future<void> openCompanySettings(String workspaceId) async {
    try {
      isLoading.value = true;
      
      print('🔄 Opening company settings for workspace: $workspaceId');
      
      final webviewUrl = await _webviewApiService.getCompanySettingsUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        print('✅ Company settings URL obtained: $webviewUrl');
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'company_settings'.tr,
        });
      } else {
        print('❌ Failed to get company settings URL');
        Get.snackbar(
          'error'.tr,
          'failed_load_company_settings'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
          duration: const Duration(seconds: 3),
        );
      }
    } on DioException catch (e) {
      print('❌ DioException in openCompanySettings: ${e.message}');
      String errorMessage = 'cannot_open_company_settings'.tr;

      if (e.response?.statusCode == 500) {
        errorMessage = 'server_problem_try_again'.tr;
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'page_not_found'.tr;
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'connection_slow_check_internet'.tr;
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'response_slow_try_again'.tr;
      }

      Get.snackbar(
        'error'.tr,
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('❌ Unexpected error in openCompanySettings: $e');
      Get.snackbar(
        'error'.tr,
        'server_problem_try_again'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Open Board Settings Webview
  Future<void> openBoardSettings(String workspaceId) async {
    try {
      isLoading.value = true;
      
      final webviewUrl = await _webviewApiService.getBoardSettingsUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'board_settings'.tr,
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_load_board_settings'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_open_board_settings'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Open Notification Settings Webview
  Future<void> openNotificationSettings(String workspaceId) async {
    try {
      isLoading.value = true;
      
      final webviewUrl = await _webviewApiService.getNotificationSettingsUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'notification_settings'.tr,
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_load_notification_settings'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_open_notification_settings'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Open Welcome Message Settings Webview
  Future<void> openWelcomeMessageSettings(String workspaceId) async {
    try {
      isLoading.value = true;
      
      final webviewUrl = await _webviewApiService.getWelcomeMessageSettingsUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'welcome_message'.tr,
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_load_welcome_message_settings'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_open_welcome_message_settings'.trParams({
          'error': e.toString(),
        }),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Open Chatbot Settings Webview
  Future<void> openChatbotSettings(String workspaceId) async {
    try {
      isLoading.value = true;
      
      final webviewUrl = await _webviewApiService.getChatbotSettingsUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'chatbot_settings'.tr,
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_load_chatbot_settings'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_open_chatbot_settings'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Open ID Generation Rules Webview
  Future<void> openIdGenerationRules(String workspaceId) async {
    try {
      isLoading.value = true;
      
      final webviewUrl = await _webviewApiService.getIdGenerationRulesUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'id_generation_rules'.tr,
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_load_id_generation_rules'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_open_id_generation_rules'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Open Roles & Permissions Webview
  Future<void> openRolesPermissions(String workspaceId) async {
    try {
      isLoading.value = true;
      
      final webviewUrl = await _webviewApiService.getRolesPermissionsUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'roles_permissions'.tr,
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_load_roles_permissions'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_open_roles_permissions'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Open Approval Conditions Webview
  Future<void> openApprovalConditions(String workspaceId) async {
    try {
      isLoading.value = true;
      
      final webviewUrl = await _webviewApiService.getApprovalConditionsUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'approval_conditions'.tr,
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_load_approval_conditions'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_open_approval_conditions'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Open Document Settings Webview
  Future<void> openDocumentSettings(String workspaceId) async {
    try {
      isLoading.value = true;
      
      final webviewUrl = await _webviewApiService.getDocumentSettingsUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'document_settings'.tr,
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_load_document_settings'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_open_document_settings'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Open Catalog Settings Webview
  Future<void> openCatalogSettings(String workspaceId) async {
    try {
      isLoading.value = true;
      
      final webviewUrl = await _webviewApiService.getCatalogSettingsUrl(
        userId: currentUserId,
        workspaceId: workspaceId,
      );

      if (webviewUrl != null) {
        Get.toNamed('/webview', parameters: {
          'url': webviewUrl,
          'title': 'catalog_settings'.tr,
        });
      } else {
        Get.snackbar(
          'error'.tr,
          'failed_load_catalog_settings'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_open_catalog_settings'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withOpacity(0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
