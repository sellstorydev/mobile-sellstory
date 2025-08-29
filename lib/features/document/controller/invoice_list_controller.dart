import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../core/services/workspace_members_service.dart';

class InvoiceListController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  
  // Observable variables
  final isLoading = false.obs;
  final invoices = <Map<String, dynamic>>[].obs;
  final filteredInvoices = <Map<String, dynamic>>[].obs;
  final currentUserId = ''.obs;
  final currentWorkspaceId = ''.obs;
  
  // Search and filter variables
  final searchController = TextEditingController();
  final selectedSeller = Rx<WorkspaceMember?>(null);
  final selectedDateRange = Rx<String?>(null);
  final selectedCustomDateRange = Rx<DateTimeRange?>(null);
  final selectedStatuses = <String>{}.obs;
  
  // All invoices for filtering
  final allInvoices = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUserAndWorkspace();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      isLoading.value = true;
      
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      currentUserId.value = currentUser.uid;
      print('👤 Initializing invoice list with user: ${currentUserId.value}');
      
      // Get user's workspaces
      print('📋 Fetching user workspaces...');
      final workspaces = await _repository.getUserWorkspaces(currentUserId.value);
      
      print('📋 User workspaces loaded: ${workspaces.length} workspaces');
      
      if (workspaces.isNotEmpty) {
        // Use the first workspace as default
        final firstWorkspace = workspaces.first;
        currentWorkspaceId.value = firstWorkspace['id'] as String;
        
        print('✅ Invoice list initialized with workspace: ${firstWorkspace['name']}');
        
        // Load invoices
        await _loadInvoices();
      } else {
        print('⚠️ No workspaces found for user: ${currentUserId.value}');
      }
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadInvoices() async {
    try {
      isLoading.value = true;
      
      if (currentWorkspaceId.value.isEmpty) {
        print('⚠️ No workspace ID available');
        return;
      }

      // Load invoices from Firestore
      final documents = await _repository.getDocuments(
        workspaceId: currentWorkspaceId.value,
      );
      
      // Filter only invoices
      final invoices = documents.where((doc) => doc['type'] == 'INV').toList();
      
      print('📄 Loaded ${invoices.length} invoices from Firestore');
      
      allInvoices.value = List.from(invoices);
      this.invoices.value = List.from(invoices);
      filteredInvoices.value = List.from(invoices);
      
    } catch (e) {
      print('❌ Error loading invoices: $e');
      Get.snackbar(
        'Error',
        'Failed to load invoices: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    applyFilters();
  }

  void applyFilters() {
    try {
      var filtered = List<Map<String, dynamic>>.from(allInvoices);
      
      // Apply search filter
      final searchQuery = searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((invoice) {
          final docNo = (invoice['docNo'] ?? '').toString().toLowerCase();
          final customerName = (invoice['customer']?['name'] ?? '').toString().toLowerCase();
          return docNo.contains(searchQuery) || customerName.contains(searchQuery);
        }).toList();
      }
      
      // Apply seller filter
      if (selectedSeller.value != null) {
        filtered = filtered.where((invoice) {
          final sellerId = invoice['seller']?['uid'] ?? '';
          return sellerId == selectedSeller.value!.uid;
        }).toList();
      }
      
      // Apply date filter
      if (selectedDateRange.value != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        filtered = filtered.where((invoice) {
          final createdAt = invoice['createdAt'] ?? 0;
          final createdDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
          
          switch (selectedDateRange.value) {
            case 'today':
              return createdDate.isAfter(today.subtract(const Duration(days: 1)));
            case 'this_week':
              final weekStart = today.subtract(Duration(days: today.weekday - 1));
              return createdDate.isAfter(weekStart.subtract(const Duration(days: 1)));
            case 'this_month':
              final monthStart = DateTime(now.year, now.month, 1);
              return createdDate.isAfter(monthStart.subtract(const Duration(days: 1)));
            case 'custom':
              if (selectedCustomDateRange.value != null) {
                final startDate = selectedCustomDateRange.value!.start;
                final endDate = selectedCustomDateRange.value!.end.add(const Duration(days: 1));
                return createdDate.isAfter(startDate.subtract(const Duration(days: 1))) && 
                       createdDate.isBefore(endDate);
              }
              return true;
            default:
              return true;
          }
        }).toList();
      }
      
      // Apply status filter
      if (selectedStatuses.isNotEmpty) {
        filtered = filtered.where((invoice) {
          final status = invoice['status'] ?? '';
          return selectedStatuses.contains(status);
        }).toList();
      }
      
      filteredInvoices.value = filtered;
      invoices.value = filtered;
      
      print('🔍 Applied filters - ${filtered.length} invoices found');
      
    } catch (e) {
      print('❌ Error applying filters: $e');
    }
  }

  void clearFilters() {
    selectedSeller.value = null;
    selectedDateRange.value = null;
    selectedCustomDateRange.value = null;
    selectedStatuses.clear();
    searchController.clear();
    invoices.value = List.from(allInvoices);
    filteredInvoices.value = List.from(allInvoices);
  }

  void createNewInvoice() {
    // TODO: Navigate to create invoice page
    Get.snackbar(
      'Info',
      'Create invoice page coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void viewInvoice(Map<String, dynamic> invoice) {
    // TODO: Navigate to invoice detail page
    Get.snackbar(
      'Info',
      'Invoice detail page coming soon',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String formatDate(int timestamp) {
    if (timestamp == 0) return '-';
    
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date.isAfter(yesterday) && date.isBefore(today.add(const Duration(days: 1)))) {
      return 'วันนี้';
    } else if (date.isAfter(yesterday.subtract(const Duration(days: 1))) && date.isBefore(today)) {
      return 'เมื่อวาน';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Refresh data
  Future<void> refreshData() async {
    await _loadInvoices();
  }
}
