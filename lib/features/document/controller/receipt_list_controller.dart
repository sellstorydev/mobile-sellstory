import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../core/services/workspace_members_service.dart';

class ReceiptListController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  
  // Observable variables
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final receipts = <Map<String, dynamic>>[].obs;
  final filteredReceipts = <Map<String, dynamic>>[].obs;
  final currentUserId = ''.obs;
  final currentWorkspaceId = ''.obs;
  
  // Pagination variables
  final hasMore = true.obs;
  DocumentSnapshot? lastDocument;
  final pageSize = 20;
  
  // Search and filter variables
  final searchController = TextEditingController();
  final selectedSeller = Rx<WorkspaceMember?>(null);
  final selectedDateRange = Rx<String?>(null);
  final selectedCustomDateRange = Rx<DateTimeRange?>(null);
  final selectedStatuses = <String>{}.obs;
  
  // All receipts for filtering
  final allReceipts = <Map<String, dynamic>>[].obs;

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
      print('👤 Initializing receipt list with user: ${currentUserId.value}');
      
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
        
        print('✅ Receipt list initialized with workspace: $selectedWorkspaceName');
        
        // Load receipts
        await _loadReceipts();
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

  Future<void> _loadReceipts() async {
    try {
      isLoading.value = true;
      
      if (currentWorkspaceId.value.isEmpty) {
        print('⚠️ No workspace ID available');
        return;
      }

      // Reset pagination state
      lastDocument = null;
      hasMore.value = true;

      // Load first page of receipts from Firestore
      final result = await _repository.getDocumentsPaginated(
        workspaceId: currentWorkspaceId.value,
        documentType: 'RT', // Filter for receipts only
        limit: pageSize,
      );
      
      final documents = result['documents'] as List<Map<String, dynamic>>;
      lastDocument = result['lastDocument'] as DocumentSnapshot?;
      hasMore.value = result['hasMore'] as bool;
      
      // No need to filter again since we already filtered by type in the query
      print('📄 Loaded ${documents.length} receipts from Firestore (first page)');
      
      allReceipts.value = List.from(documents);
      this.receipts.value = List.from(documents);
      filteredReceipts.value = List.from(documents);
      
    } catch (e) {
      print('❌ Error loading receipts: $e');
      Get.snackbar(
        'Error',
        'Failed to load receipts: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreReceipts() async {
    if (isLoadingMore.value || !hasMore.value || lastDocument == null) {
      return;
    }

    try {
      isLoadingMore.value = true;
      
      if (currentWorkspaceId.value.isEmpty) {
        print('⚠️ No workspace ID available');
        return;
      }

      // Load next page of receipts
      final result = await _repository.getDocumentsPaginated(
        workspaceId: currentWorkspaceId.value,
        documentType: 'RT', // Filter for receipts only
        limit: pageSize,
        startAfter: lastDocument,
      );
      
      final documents = result['documents'] as List<Map<String, dynamic>>;
      lastDocument = result['lastDocument'] as DocumentSnapshot?;
      hasMore.value = result['hasMore'] as bool;
      
      // No need to filter again since we already filtered by type in the query
      final newReceipts = documents;
      
      // Add to existing lists
      allReceipts.addAll(newReceipts);
      receipts.addAll(newReceipts);
      
      // Reapply filters to include new data
      _applyFilters();
      
      print('📄 Loaded ${newReceipts.length} more receipts (page ${(allReceipts.length / pageSize).ceil()})');
      
    } catch (e) {
      print('❌ Failed to load more receipts: $e');
      Get.snackbar(
        'Error',
        'Failed to load more receipts: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  void onSearchChanged(String query) {
    _applyFilters();
  }

  void applyFilters() {
    _applyFilters();
  }

  void _applyFilters() {
    try {
      List<Map<String, dynamic>> filtered = List.from(allReceipts);
      
      // Apply search filter
      final searchQuery = searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((receipt) {
          final docNo = (receipt['docNo'] ?? '').toString().toLowerCase();
          final customerName = (receipt['customer']?['name'] ?? '').toString().toLowerCase();
          final sellerName = (receipt['seller']?['displayName'] ?? '').toString().toLowerCase();
          
          return docNo.contains(searchQuery) || 
                 customerName.contains(searchQuery) ||
                 sellerName.contains(searchQuery);
        }).toList();
      }
      
      // Apply seller filter
      if (selectedSeller.value != null) {
        filtered = filtered.where((receipt) {
          final sellerId = receipt['seller']?['uid'] ?? '';
          return sellerId == selectedSeller.value!.uid;
        }).toList();
      }
      
      // Apply date range filter
      if (selectedDateRange.value != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        filtered = filtered.where((receipt) {
          final createdAt = receipt['createdAt'] ?? 0;
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
        filtered = filtered.where((receipt) {
          final status = receipt['status'] ?? '';
          return selectedStatuses.contains(status);
        }).toList();
      }
      
      filteredReceipts.value = filtered;
      receipts.value = filtered;
      
      print('🔍 Applied filters - ${filtered.length} receipts found');
      
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
    receipts.value = List.from(allReceipts);
    filteredReceipts.value = List.from(allReceipts);
  }

  void createNewReceipt() {
    // Implementation for creating new receipt
    print('Creating new receipt');
  }

  void viewReceipt(Map<String, dynamic> receipt) {
    final receiptId = receipt['id'] as String?;
    // Implementation for viewing receipt
    print('Viewing receipt: $receiptId');
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
    await _loadReceipts();
  }
}
