import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../core/services/workspace_members_service.dart';
import '../view/add_edit_document_page.dart';
import '../view/document_view_page.dart';

class QuotationsListController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  
  // Observable variables
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final quotations = <Map<String, dynamic>>[].obs;
  final filteredQuotations = <Map<String, dynamic>>[].obs;
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
  
  // All quotations for filtering
  final allQuotations = <Map<String, dynamic>>[].obs;
  
  // Highlighting variables
  final highlightedDocumentId = Rx<String?>(null);

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
      print('👤 Initializing quotations list with user: ${currentUserId.value}');
      
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
        
        print('✅ Quotations list initialized with workspace: $selectedWorkspaceName');
        
        // Load quotations
        await _loadQuotations();
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

  Future<void> _loadQuotations() async {
    try {
      isLoading.value = true;
      
      if (currentWorkspaceId.value.isEmpty) {
        print('⚠️ No workspace ID available');
        return;
      }

      // Reset pagination state
      lastDocument = null;
      hasMore.value = true;

      // Load first page of quotations from Firestore
      final result = await _repository.getDocumentsPaginated(
        workspaceId: currentWorkspaceId.value,
        documentType: 'QT', // Filter for quotations only
        limit: pageSize,
      );
      
      final documents = result['documents'] as List<Map<String, dynamic>>;
      lastDocument = result['lastDocument'] as DocumentSnapshot?;
      hasMore.value = result['hasMore'] as bool;
      
      print('📄 Raw documents loaded: ${documents.length}');
      
      // No need to filter again since we already filtered by type in the query
      allQuotations.value = documents;
      this.quotations.value = documents;
      filteredQuotations.value = documents;
      
      print('📄 Loaded ${quotations.length} quotations (first page), hasMore: ${hasMore.value}');
      
    } catch (e) {
      print('❌ Failed to load quotations: $e');
      Get.snackbar(
        'Error',
        'Failed to load quotations: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreQuotations() async {
    if (isLoadingMore.value || !hasMore.value || lastDocument == null) {
      print('🚫 Skip loadMore: isLoadingMore=${isLoadingMore.value}, hasMore=${hasMore.value}, lastDocument=${lastDocument != null}');
      return;
    }

    try {
      isLoadingMore.value = true;
      
      if (currentWorkspaceId.value.isEmpty) {
        print('⚠️ No workspace ID available');
        return;
      }

      print('📄 Loading more quotations... Current total: ${allQuotations.length}');

      // Load next page of quotations
      final result = await _repository.getDocumentsPaginated(
        workspaceId: currentWorkspaceId.value,
        documentType: 'QT', // Filter for quotations only
        limit: pageSize,
        startAfter: lastDocument,
      );
      
      final documents = result['documents'] as List<Map<String, dynamic>>;
      lastDocument = result['lastDocument'] as DocumentSnapshot?;
      hasMore.value = result['hasMore'] as bool;
      
      print('📄 Raw documents from loadMore: ${documents.length}');
      
      // No need to filter again since we already filtered by type in the query
      final newQuotations = documents;
      
      // Add to existing lists
      allQuotations.addAll(newQuotations);
      quotations.addAll(newQuotations);
      
      // Reapply filters to include new data
      _applyFilters();
      
      print('📄 Loaded ${newQuotations.length} more quotations. Total: ${allQuotations.length}, Filtered: ${filteredQuotations.length}, hasMore: ${hasMore.value}');
      
    } catch (e) {
      print('❌ Failed to load more quotations: $e');
      Get.snackbar(
        'Error',
        'Failed to load more quotations: ${e.toString()}',
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
      List<Map<String, dynamic>> filtered = List.from(allQuotations);
      
      // Apply search filter
      final searchQuery = searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((quotation) {
          final docNo = (quotation['docNo'] ?? '').toString().toLowerCase();
          final customerName = (quotation['customer']?['name'] ?? '').toString().toLowerCase();
          final sellerName = (quotation['seller']?['displayName'] ?? '').toString().toLowerCase();
          
          return docNo.contains(searchQuery) || 
                 customerName.contains(searchQuery) ||
                 sellerName.contains(searchQuery);
        }).toList();
      }
      
      // Apply seller filter
      if (selectedSeller.value != null) {
        filtered = filtered.where((quotation) {
          final sellerId = quotation['seller']?['uid'] ?? '';
          return sellerId == selectedSeller.value!.uid;
        }).toList();
      }
      
      // Apply date range filter
      if (selectedDateRange.value != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        filtered = filtered.where((quotation) {
          final createdAt = quotation['createdAt'] ?? 0;
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
        filtered = filtered.where((quotation) {
          final status = quotation['status'] ?? '';
          return selectedStatuses.contains(status);
        }).toList();
      }
      
      filteredQuotations.value = filtered;
      quotations.value = filtered;
      
      print('🔍 Applied filters - ${filtered.length} quotations found');
      
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
    quotations.value = List.from(allQuotations);
    filteredQuotations.value = List.from(allQuotations);
  }

  void createNewQuotation() {
    Get.to(() => const AddEditDocumentPage(documentType: 'QT'));
  }

  void viewQuotation(Map<String, dynamic> quotation) {
    final quotationId = quotation['id'] as String?;
    if (quotationId != null) {
      Navigator.push(
        Get.context!,
        MaterialPageRoute(
          builder: (context) => DocumentViewPage(
            documentType: 'QT',
            documentId: quotationId,
            title: quotation['docNo'] as String?,
          ),
        ),
      );
    }
  }

  Future<void> reviseQuotationToInvoice(Map<String, dynamic> quotation) async {
    try {
      // Show loading
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      if (currentWorkspaceId.value.isEmpty) {
        Get.back(); // Close loading dialog
        Get.snackbar('Error', 'No workspace available');
        return;
      }

      // Create invoice data by copying quotation data
      final invoiceData = Map<String, dynamic>.from(quotation);
      
      // Remove quotation-specific fields
      invoiceData.remove('id');
      invoiceData.remove('validUntil');
      invoiceData.remove('approval');
      invoiceData.remove('approvers');
      
      // Update fields for invoice
      invoiceData['type'] = 'INV';
      invoiceData['status'] = 'DRAFT';
      invoiceData['relatedQuotationId'] = quotation['id'];
      invoiceData['paymentStatus'] = 'unpaid';
      invoiceData['invoiceType'] = 'full';
      
      // Set due date (30 days from now)
      final dueDate = DateTime.now().add(const Duration(days: 30));
      invoiceData['dueDate'] = dueDate.millisecondsSinceEpoch;
      
      // Update timestamps and user info
      final now = DateTime.now().millisecondsSinceEpoch;
      invoiceData['createdAt'] = now;
      invoiceData['updatedAt'] = now;
      invoiceData['createdBy'] = currentUserId.value;
      invoiceData['updatedBy'] = currentUserId.value;
      
      // Update activity log
      invoiceData['activityLog'] = [
        {
          'timestamp': now,
          'userId': currentUserId.value,
          'userDisplayName': invoiceData['seller']?['email'] ?? 'Unknown',
          'action': 'Created',
          'details': 'Created invoice from quotation ${quotation['docNo']}',
        }
      ];

      // Create invoice in Firestore
      final invoiceId = await _repository.createDocument(
        workspaceId: currentWorkspaceId.value,
        documentData: invoiceData,
      );

      Get.back(); // Close loading dialog
      
      // Show success message and navigate to invoice
      Get.snackbar(
        'Success', 
        'Invoice created from quotation ${quotation['docNo']}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );

      // Navigate to the new invoice
      Navigator.push(
        Get.context!,
        MaterialPageRoute(
          builder: (context) => AddEditDocumentPage(documentType: 'INV', documentId: invoiceId),
        ),
      );

    } catch (e) {
      Get.back(); // Close loading dialog
      print('❌ Failed to create invoice from quotation: $e');
      Get.snackbar(
        'Error',
        'Failed to create invoice: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    }
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
  Future<void> refreshData({String? highlightDocumentId}) async {
    // Set the document to highlight
    if (highlightDocumentId != null) {
      highlightedDocumentId.value = highlightDocumentId;
      // Clear highlighting after 4 seconds for better visibility
      Future.delayed(const Duration(seconds: 4), () {
        if (highlightedDocumentId.value == highlightDocumentId) {
          highlightedDocumentId.value = null;
        }
      });
    }
    
    // Store current state
    final int currentItemCount = allQuotations.length;
    print('🔄 Refresh started - Current item count: $currentItemCount');
    
    await _loadQuotations();
    
    print('🔄 After _loadQuotations - New count: ${allQuotations.length}, hasMore: ${hasMore.value}');
    
    // If we had more items before refresh and still have more available,
    // automatically load to match previous state
    if (currentItemCount > quotations.length && hasMore.value) {
      // Calculate how many more pages we need to load
      final pagesNeeded = ((currentItemCount - quotations.length) / pageSize).ceil();
      
      print('🔄 Need to reload $pagesNeeded more pages to restore $currentItemCount items');
      
      for (int i = 0; i < pagesNeeded && hasMore.value; i++) {
        await loadMoreQuotations();
        print('🔄 Loaded page ${i + 1}/${pagesNeeded} - Current count: ${allQuotations.length}');
        // Add a small delay to prevent overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    print('🔄 Refresh completed - Final count: ${allQuotations.length}');
  }
  
  // Check if a document should be highlighted
  bool isDocumentHighlighted(String? documentId) {
    return highlightedDocumentId.value != null && 
           highlightedDocumentId.value == documentId;
  }
}
