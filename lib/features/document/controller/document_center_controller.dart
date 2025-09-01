import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../view/quotations_list_page.dart';
import '../view/invoice_list_page.dart';
import '../view/receipt_list_page.dart';

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
        // Try to get last active workspace ID
        String? selectedWorkspaceId;
        String? selectedWorkspaceName;
        
        try {
          final lastActiveWorkspaceId = await _repository.getUserLastActiveWorkspaceId(currentUserId.value);
          print('📋 Last active workspace ID: $lastActiveWorkspaceId');
          
          if (lastActiveWorkspaceId != null && lastActiveWorkspaceId.isNotEmpty) {
            // Check if the last active workspace still exists in user's workspaces
            final lastActiveWorkspace = workspaces.firstWhereOrNull(
              (ws) => ws['id'] == lastActiveWorkspaceId
            );
            
            if (lastActiveWorkspace != null) {
              selectedWorkspaceId = lastActiveWorkspaceId;
              selectedWorkspaceName = lastActiveWorkspace['name'] as String;
              print('✅ Using last active workspace: $selectedWorkspaceName ($selectedWorkspaceId)');
            } else {
              print('⚠️ Last active workspace not found in user workspaces, using first workspace');
            }
          }
        } catch (e) {
          print('⚠️ Failed to get last active workspace: $e');
        }
        
        // Fallback to first workspace if no last active workspace
        if (selectedWorkspaceId == null) {
          final firstWorkspace = workspaces.first;
          selectedWorkspaceId = firstWorkspace['id'] as String;
          selectedWorkspaceName = firstWorkspace['name'] as String;
          print('✅ Using first workspace: $selectedWorkspaceName ($selectedWorkspaceId)');
        }
        
        currentWorkspaceId.value = selectedWorkspaceId;
        
        print('✅ Document center initialized with workspace: $selectedWorkspaceName');
        
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
    Get.to(() => const InvoiceListPage());
  }

  void navigateToReceipts() {
    Get.to(() => const ReceiptListPage());
  }

  // Removed navigateToCreateDocument and viewAllDocuments methods since they're no longer needed

  // Refresh data
  Future<void> refreshData() async {
    // Removed since we no longer load recent documents
  }
}
