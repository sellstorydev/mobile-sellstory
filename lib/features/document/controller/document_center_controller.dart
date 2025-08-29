import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../view/quotations_list_page.dart';

class DocumentCenterController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  
  // Observable variables
  final isLoading = false.obs;
  final currentUserId = ''.obs;
  final currentWorkspaceId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUserAndWorkspace();
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      currentUserId.value = currentUser.uid;
      print('👤 Initializing document center with user: ${currentUserId.value}');
      
      // Get user's workspaces
      print('📋 Fetching user workspaces...');
      final workspaces = await _repository.getUserWorkspaces(currentUserId.value);
      
      print('📋 User workspaces loaded: ${workspaces.length} workspaces');
      
      if (workspaces.isNotEmpty) {
        // Use the first workspace as default
        final firstWorkspace = workspaces.first;
        currentWorkspaceId.value = firstWorkspace['id'] as String;
        
        print('✅ Document center initialized with workspace: ${firstWorkspace['name']}');
        
        // Removed recent documents loading since we removed that section
      } else {
        print('⚠️ No workspaces found for user: ${currentUserId.value}');
      }
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
    }
  }

  // Removed _loadRecentDocuments method since we removed the recent documents section

  // Navigation methods
  void navigateToQuotations() {
    Get.to(() => const QuotationsListPage());
  }

  void navigateToInvoices() {
    // TODO: Navigate to invoices list page
    Get.snackbar(
      'Info',
      'Invoices page coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void navigateToReceipts() {
    // TODO: Navigate to receipts list page
    Get.snackbar(
      'Info',
      'Receipts page coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Removed navigateToCreateDocument and viewAllDocuments methods since they're no longer needed

  // Refresh data
  Future<void> refreshData() async {
    // Removed since we no longer load recent documents
  }
}
