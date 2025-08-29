import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../data/services/webview_api_service.dart';
import '../../../core/di/locator.dart';

class MoreController extends GetxController {
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();
  final WebviewApiService _webviewApiService = Get.find<WebviewApiService>();
  
  // User data
  final user = Rx<User?>(null);
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Get current user
    user.value = FirebaseAuth.instance.currentUser;
    
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      this.user.value = user;
    });
  }

  // Logout
  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _authService.signOut();
      
      // Reset dependencies to prevent issues after logout
      Locator.resetDependencies();
      
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'Error',
        'Logout failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get user display name
  String get displayName {
    final currentUser = user.value;
    if (currentUser == null) return 'Guest';
    
    if (currentUser.displayName != null && currentUser.displayName!.isNotEmpty) {
      return currentUser.displayName!;
    }
    
    if (currentUser.email != null) {
      return currentUser.email!.split('@')[0];
    }
    
    return 'User';
  }

  // Get user email
  String get email {
    return user.value?.email ?? 'No email';
  }

  // Get user photo URL
  String? get photoURL {
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
          'title': 'Hashtag Settings',
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to load hashtag settings',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open hashtag settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
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
          'title': 'Company Settings',
        });
      } else {
        print('❌ Failed to get company settings URL');
        Get.snackbar(
          'Error',
          'ไม่สามารถโหลดตั้งค่าบริษัทได้ กรุณาลองใหม่อีกครั้ง',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
          duration: const Duration(seconds: 3),
        );
      }
    } on DioException catch (e) {
      print('❌ DioException in openCompanySettings: ${e.message}');
      String errorMessage = 'ไม่สามารถเปิดตั้งค่าบริษัทได้';
      
      if (e.response?.statusCode == 500) {
        errorMessage = 'เซิร์ฟเวอร์มีปัญหา กรุณาลองใหม่อีกครั้ง';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'ไม่พบหน้าเว็บที่ต้องการ';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'การเชื่อมต่อช้า กรุณาตรวจสอบอินเทอร์เน็ต';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'การตอบสนองช้า กรุณาลองใหม่อีกครั้ง';
      }
      
      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('❌ Unexpected error in openCompanySettings: $e');
      Get.snackbar(
        'Error',
        'เกิดข้อผิดพลาดที่ไม่คาดคิด กรุณาลองใหม่อีกครั้ง',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
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
          'title': 'Board Settings',
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to load board settings',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open board settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
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
          'title': 'Notification Settings',
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to load notification settings',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open notification settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
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
          'title': 'Welcome Message Settings',
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to load welcome message settings',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open welcome message settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
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
          'title': 'Chatbot Settings',
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to load chatbot settings',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open chatbot settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
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
          'title': 'ID Generation Rules',
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to load ID generation rules',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open ID generation rules: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
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
          'title': 'Roles & Permissions',
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to load roles & permissions',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open roles & permissions: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
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
          'title': 'Approval Conditions',
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to load approval conditions',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open approval conditions: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
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
          'title': 'Document Settings',
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to load document settings',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open document settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
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
          'title': 'Catalog Settings',
        });
      } else {
        Get.snackbar(
          'Error',
          'Failed to load catalog settings',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to open catalog settings: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
