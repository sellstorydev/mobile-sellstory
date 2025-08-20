import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/firebase_auth_service.dart';
import '../../../core/di/locator.dart';

class MoreController extends GetxController {
  final FirebaseAuthService _authService = Get.find<FirebaseAuthService>();
  
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
}
