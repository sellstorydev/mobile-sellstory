import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../core/services/workspace_members_service.dart';
import '../../../core/services/algolia_search_service.dart';
import '../view/add_edit_document_page.dart';

class InvoiceListController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  
  // Observable variables
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final invoices = <Map<String, dynamic>>[].obs;
  final filteredInvoices = <Map<String, dynamic>>[].obs;
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
  
  // All invoices for filtering
  final allInvoices = <Map<String, dynamic>>[].obs;
  
  // Algolia search state
  final useAlgoliaSearch = false.obs;
  final isSearching = false.obs;
  
  // Search debounce timer
  Timer? _searchDebounceTimer;

  @override
  void onInit() {
    super.onInit();
    _initializeUserAndWorkspace();
  }

  @override
  void onClose() {
    searchController.dispose();
    _searchDebounceTimer?.cancel();
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
        
        print('✅ Invoice list initialized with workspace: $selectedWorkspaceName');
        
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

      // Reset pagination state
      lastDocument = null;
      hasMore.value = true;

      // Load first page of invoices from Firestore
      final result = await _repository.getDocumentsPaginated(
        workspaceId: currentWorkspaceId.value,
        documentType: 'INV', // Filter for invoices only
        limit: pageSize,
      );
      
      final documents = result['documents'] as List<Map<String, dynamic>>;
      lastDocument = result['lastDocument'] as DocumentSnapshot?;
      hasMore.value = result['hasMore'] as bool;
      
      // No need to filter again since we already filtered by type in the query
      print('📄 Loaded ${documents.length} invoices from Firestore (first page)');
      
      allInvoices.value = List.from(documents);
      this.invoices.value = List.from(documents);
      filteredInvoices.value = List.from(documents);
      
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

  Future<void> loadMoreInvoices() async {
    if (isLoadingMore.value || !hasMore.value || lastDocument == null) {
      return;
    }

    try {
      isLoadingMore.value = true;
      
      if (currentWorkspaceId.value.isEmpty) {
        print('⚠️ No workspace ID available');
        return;
      }

      // Load next page of invoices
      final result = await _repository.getDocumentsPaginated(
        workspaceId: currentWorkspaceId.value,
        documentType: 'INV', // Filter for invoices only
        limit: pageSize,
        startAfter: lastDocument,
      );
      
      final documents = result['documents'] as List<Map<String, dynamic>>;
      lastDocument = result['lastDocument'] as DocumentSnapshot?;
      hasMore.value = result['hasMore'] as bool;
      
      // No need to filter again since we already filtered by type in the query
      final newInvoices = documents;
      
      // Add to existing lists
      allInvoices.addAll(newInvoices);
      invoices.addAll(newInvoices);
      
      // Reapply filters to include new data
      _applyFilters();
      
      print('📄 Loaded ${newInvoices.length} more invoices (page ${(allInvoices.length / pageSize).ceil()})');
      
    } catch (e) {
      print('❌ Failed to load more invoices: $e');
      Get.snackbar(
        'Error',
        'Failed to load more invoices: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoadingMore.value = false;
    }
  }

  void onSearchChanged(String query) {
    // Cancel previous timer if exists
    _searchDebounceTimer?.cancel();
    
    // If query is empty, reset search immediately
    if (query.trim().isEmpty) {
      useAlgoliaSearch.value = false;
      isSearching.value = false;
      _applyFilters();
      return;
    }
    
    // Debounce search for 500ms to avoid too many API calls while typing
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      triggerAlgoliaSearch(query.trim());
    });
  }

  void applyFilters() {
    _applyFilters();
  }

  void _applyFilters() {
    try {
      final searchQuery = searchController.text.trim();
      
      // Don't apply filters if we're currently doing an Algolia search
      // The search will handle filtering through Algolia instead
      if (useAlgoliaSearch.value && searchQuery.isNotEmpty) {
        return;
      }
      
      // If there's a search query but we're not using Algolia, trigger search
      if (searchQuery.isNotEmpty) {
        triggerAlgoliaSearch(searchQuery);
        return;
      }
      
      // Reset to show all when no search query
      useAlgoliaSearch.value = false;
      isSearching.value = false;
      List<Map<String, dynamic>> filtered = List.from(allInvoices);
      
      // Apply seller filter
      if (selectedSeller.value != null) {
        filtered = filtered.where((invoice) {
          final sellerId = invoice['seller']?['uid'] ?? '';
          return sellerId == selectedSeller.value!.uid;
        }).toList();
      }
      
      // Apply date range filter
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
    useAlgoliaSearch.value = false;
    isSearching.value = false;
    invoices.value = List.from(allInvoices);
    filteredInvoices.value = List.from(allInvoices);
  }

  /// Trigger Algolia search manually (called by search button)
  void triggerAlgoliaSearch(String query) {
    if (query.trim().isEmpty) {
      // If query is empty, reset to show all invoices with current filters
      useAlgoliaSearch.value = false;
      isSearching.value = false;
      _applyFilters();
      return;
    }
    
    isSearching.value = true;
    _searchWithAlgolia(query.trim());
  }

  /// Search invoices using Algolia
  void _searchWithAlgolia(String query) async {
    try {
      useAlgoliaSearch.value = true;
      isSearching.value = true;
      
      // Build filters for Algolia
      final filters = <String, dynamic>{};
      
      // Add seller filter
      if (selectedSeller.value != null) {
        filters['seller.uid'] = selectedSeller.value!.uid;
      }
      
      // Add status filter
      if (selectedStatuses.isNotEmpty) {
        filters['status'] = selectedStatuses.toList();
      }
      
      // Search with Algolia
      final searchStream = AlgoliaSearchService.searchInvoices(
        query: query,
        workspaceId: currentWorkspaceId.value,
        filters: filters,
        hitsPerPage: 50,
      );
      
      // Listen to search results
      searchStream.listen(
        (response) {
          final hits = response.hits;
          final results = hits.map((hit) {
            final data = Map<String, dynamic>.from(hit);
            data['id'] = hit['objectID'] ?? '';
            return data;
          }).toList();
          
          filteredInvoices.value = results;
          invoices.value = results; // Update the main observable list too
          isSearching.value = false;
          print('🔍 Algolia search results: ${results.length} invoices found');
        },
        onError: (error) {
          print('❌ Algolia search error: $error');
          // Fallback to local search
          useAlgoliaSearch.value = false;
          isSearching.value = false;
          _applyLocalSearch(query);
        },
      );
      
    } catch (e) {
      print('❌ Failed to search with Algolia: $e');
      useAlgoliaSearch.value = false;
      isSearching.value = false;
      _applyLocalSearch(query);
    }
  }

  /// Fallback local search method
  void _applyLocalSearch(String query) {
    final searchQuery = query.toLowerCase();
    final filtered = allInvoices.where((invoice) {
      final docNo = (invoice['docNo'] ?? '').toString().toLowerCase();
      final customerName = (invoice['customer']?['name'] ?? '').toString().toLowerCase();
      final sellerName = (invoice['seller']?['displayName'] ?? '').toString().toLowerCase();
      
      return docNo.contains(searchQuery) || 
             customerName.contains(searchQuery) ||
             sellerName.contains(searchQuery);
    }).toList();
    
    filteredInvoices.value = filtered;
    invoices.value = filtered; // Update the main observable list too
    print('🔍 Local search results: ${filtered.length} invoices found');
  }

  void viewInvoice(Map<String, dynamic> invoice) {
    final invoiceId = invoice['id'] as String?;
    Navigator.push(
      Get.context!,
      MaterialPageRoute(
        builder: (context) => AddEditDocumentPage(documentType: 'INV', documentId: invoiceId),
      ),
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
