import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../data/services/firestore_service.dart';
import '../../../domain/entities/customer.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../core/services/quota_usage_service.dart';
import '../../../core/services/algolia_search_service.dart';
import '../../board/controller/board_controller.dart';
import '../../../core/services/algolia_customer_sync_service.dart';

class CustomersController extends GetxController {
  final CustomerRepository _customerRepository;
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();

  // Observable variables
  final RxList<Customer> customers = <Customer>[].obs;
  final RxList<Customer> filteredCustomers = <Customer>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isPageLoading = false.obs; // loading next page
  final RxBool hasMore = true.obs; // whether more pages are available
  final RxString searchQuery = ''.obs;
  final RxString errorMessage = ''.obs;
  
  // Search state management
  final RxBool isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  final RxList<String> customerSources = <String>[].obs;
  final RxInt totalCustomersCount = 0.obs; // total, ignoring pagination

  // Pagination cursor
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  final int _pageSize = 25;

  // Quota (cached from workspace subscription)
  final RxInt customersQuotaUsed = 0.obs;
  final RxInt customersQuotaLimit = (-2).obs; // -1 unlimited, -2 unknown
  final RxInt usersQuotaUsed = 0.obs; // new users quota
  final RxInt usersQuotaLimit = (-2).obs;

  // User and workspace management
  final RxString currentUserId = ''.obs;
  final RxString currentWorkspaceId = ''.obs;
  final RxList<Map<String, dynamic>> userWorkspaces = <Map<String, dynamic>>[].obs;

  // Companies index for search (companyId -> { name, taxId })
  final Map<String, Map<String, String>> _companyIndex = {};
  StreamSubscription<List<Customer>>? _customersSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _workspaceQuotaSub;
  StreamSubscription<User?>? _authSub;

  // Algolia search state
  final RxBool useAlgoliaSearch = false.obs;

  CustomersController(this._customerRepository);

  bool _can(String permission) =>
      MobilePermissionsService.to.isOwner || MobilePermissionsService.to.can(permission);

  @override
  void onInit() {
    super.onInit();
    // Listen to search query changes
    ever(searchQuery, (_) => _filterCustomers());

    // Initialize with current user
    print('[CustomersController] onInit');
    // Subscribe to auth state to handle app restarts where FirebaseAuth restores session asynchronously
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        if (currentUserId.value != user.uid) {
          print('[CustomersController] auth user available -> initialize');
          await initializeWithUser(user.uid);
        } else if (customers.isEmpty && currentWorkspaceId.value.isNotEmpty) {
          // Re-subscribe if needed
          await loadCustomers(currentWorkspaceId.value);
        }
      } else {
        // Signed out: clear state
        print('[CustomersController] auth signed out -> clear customers');
        await _customersSub?.cancel();
        customers.clear();
        filteredCustomers.clear();
        currentUserId.value = '';
        currentWorkspaceId.value = '';
      }
    });

    // Also attempt immediate initialization in case currentUser is already available
    _initializeWithCurrentUser();
  }

  @override
  void onReady() {
    super.onReady();
    // Extra safety: if after full initialization the customers list is still empty but we have workspace
    Future.delayed(Duration(seconds: 2), () async {
      if (customers.isEmpty && currentWorkspaceId.value.isNotEmpty && FirebaseAuth.instance.currentUser != null) {
        print('[CustomersController] onReady: customers still empty, forcing reload');
        await loadCustomers(currentWorkspaceId.value);
      }
    });
  }

  // Initialize with current user from Firebase Auth
  Future<void> _initializeWithCurrentUser() async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        errorMessage.value = 'No authenticated user found';
        return;
      }

      final String userId = currentUser.uid;
      print('👤 Initializing customers with user: $userId');

      await initializeWithUser(userId);
    } catch (e) {
      print('❌ Failed to initialize with current user: $e');
      errorMessage.value = 'Failed to initialize user data';
    }
  }

  // Initialize with specific user ID
  Future<void> initializeWithUser(String userId) async {
    try {
      print('🔄 Initializing user: $userId');

      currentUserId.value = userId;

      // Get user's workspaces
      print('📋 Fetching user workspaces...');
      final workspaces = await _repository.getUserWorkspaces(userId);
      userWorkspaces.value = workspaces;

      print('📋 User workspaces loaded: ${workspaces.length} workspaces');

      if (workspaces.isNotEmpty) {
        // Try to get last active workspace ID
        String? selectedWorkspaceId;
        String? selectedWorkspaceName;

        try {
          final lastActiveWorkspaceId = await _repository.getUserLastActiveWorkspaceId(userId);
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

        print('✅ User initialized with workspace: $selectedWorkspaceName');

        // Load data for the selected workspace
        await loadCustomers(currentWorkspaceId.value);
        await loadCustomerSources(currentWorkspaceId.value);
        await _loadCompaniesIndex(currentWorkspaceId.value);
      } else {
        print('⚠️ No workspaces found for user: $userId');
        errorMessage.value = 'No workspaces found for this user';
      }
    } catch (e) {
      print('❌ Failed to initialize user: $e');
      errorMessage.value = 'Failed to initialize user data';
    }
  }

  // Load customers for a workspace (initial page)
  Future<void> loadCustomers(String workspaceId) async {
    print('[CustomersController] loadCustomers (paged) workspaceId=$workspaceId');
    await _customersSub?.cancel(); // stop any previous stream
    _subscribeWorkspaceQuota(workspaceId); // ensure quota subscription

    isLoading.value = true;
    isPageLoading.value = false;
    errorMessage.value = '';
    customers.clear();
    filteredCustomers.clear();
    hasMore.value = true;
    _lastDoc = null;

    try {
      // Fetch first page
      final result = await _customerRepository.getCustomersPage(
        workspaceId,
        limit: _pageSize,
        startAfter: null,
      );
      customers.addAll(result.customers);
      _lastDoc = result.lastDoc;
      hasMore.value = result.hasMore;
      _filterCustomers();

      // Fetch total count (not limited by pagination)
      try {
        final count = await _customerRepository.getCustomersCount(workspaceId);
        totalCustomersCount.value = count;
      } catch (e) {
        print('[CustomersController] total count error: $e');
      }
    } catch (e) {
      print('[CustomersController] loadCustomers exception: $e');
      errorMessage.value = 'Failed to load customers: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreCustomers() async {
    final wsId = currentWorkspaceId.value;
    if (wsId.isEmpty) return;
    if (!hasMore.value) return;
    if (isPageLoading.value) return;

    isPageLoading.value = true;
    try {
      final result = await _customerRepository.getCustomersPage(
        wsId,
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      if (result.customers.isNotEmpty) {
        customers.addAll(result.customers);
        _filterCustomers();
      }
      _lastDoc = result.lastDoc;
      hasMore.value = result.hasMore;
    } catch (e) {
      print('[CustomersController] loadMoreCustomers error: $e');
      // Don't set global error to avoid replacing current list; log only
    } finally {
      isPageLoading.value = false;
    }
  }

  Future<void> refreshCustomers() async {
    final wsId = currentWorkspaceId.value;
    if (wsId.isEmpty) return;
    await loadCustomers(wsId);
  }

  // Load customer sources from workspace
  Future<void> loadCustomerSources(String workspaceId) async {
    try {
      final sources = await _customerRepository.getCustomerSources(workspaceId);
      customerSources.value = sources;
    } catch (e) {
      // If loading fails, use default sources
      customerSources.value = [];
    }
  }

  Future<void> _loadCompaniesIndex(String workspaceId) async {
    try {
      _companyIndex.clear();
      final qs = await FirestoreService.to
          .getWorkspaceCompaniesCollection(workspaceId)
          .get();
      for (final doc in qs.docs) {
        final data = doc.data();
        String displayName = '';
        final companyNames = data['companyNames'];
        if (companyNames is List && companyNames.isNotEmpty) {
          final first = companyNames.first;
          if (first is Map<String, dynamic>) {
            displayName = (first['value']?.toString() ?? '').trim();
          }
        } else {
          displayName = (data['name']?.toString() ?? '').trim();
        }
        final taxId = (data['taxId']?.toString() ?? '').trim();
        _companyIndex[doc.id] = {
          'name': displayName,
          'taxId': taxId,
        };
      }
    } catch (e) {
      print('⚠️ Failed to load companies index: $e');
    }
  }

  // Filter customers based on search query
  void _filterCustomers() {
    // Determine permission
    final isOwner = MobilePermissionsService.to.isOwner;
    final canViewAll = MobilePermissionsService.to.can('customer:view:all');
    final canViewAssigned = MobilePermissionsService.to.can('customer:view:assigned');
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Base list: all or assigned only
    List<Customer> baseList;
    if (isOwner || canViewAll) {
      baseList = customers;
    } else if (canViewAssigned && userId.isNotEmpty) {
      baseList = customers.where((c) => c.assignees.contains(userId)).toList();
    } else {
      baseList = [];
    }

    if (searchQuery.value.isEmpty) {
      filteredCustomers.value = baseList;
    } else {
      filteredCustomers.value = baseList.where((customer) {
        final query = searchQuery.value.toLowerCase();
        // Search in emails
        final emailMatch = customer.emails.any((email) =>
          email['value']?.toString().toLowerCase().contains(query) == true ||
          email['label']?.toString().toLowerCase().contains(query) == true
        );

        // Search in phones
        final phoneMatch = customer.phones.any((phone) =>
          phone['value']?.toString().toLowerCase().contains(query) == true ||
          phone['label']?.toString().toLowerCase().contains(query) == true
        );

        // Search in company names
        final companyNameMatch = customer.companyNames.any((c) =>
          (c['value']?.toString().toLowerCase().contains(query) ?? false) ||
          (c['label']?.toString().toLowerCase().contains(query) ?? false)
        );

        // Search in linked companies index (name or taxId)
        bool companyIndexMatch = false;
        for (final c in customer.companyNames) {
          final compId = (c['id']?.toString() ?? '').trim();
          if (compId.isEmpty) continue;
          final idx = _companyIndex[compId];
          if (idx != null) {
            final name = idx['name']?.toLowerCase() ?? '';
            final tax = idx['taxId']?.toLowerCase() ?? '';
            if (name.contains(query) || tax.contains(query)) {
              companyIndexMatch = true;
              break;
            }
          }
        }

        return customer.name.toLowerCase().contains(query) ||
               customer.customId.toLowerCase().contains(query) ||
               customer.nationalId.toLowerCase().contains(query) ||
               (customer.source.toLowerCase().contains(query)) ||
               emailMatch ||
               phoneMatch ||
               companyNameMatch ||
               companyIndexMatch;
      }).toList();
    }
  }

  // Set search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  // Handle search input changes with debouncing
  void onSearchChanged(String query) {
    // Cancel previous timer if exists
    _searchDebounceTimer?.cancel();
    
    searchQuery.value = query;
    
    // If query is empty, reset search immediately
    if (query.trim().isEmpty) {
      useAlgoliaSearch.value = false;
      isSearching.value = false;
      _filterCustomers();
      return;
    }
    
    // Debounce search for 500ms to avoid too many API calls while typing
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      triggerAlgoliaSearch(query.trim());
    });
  }

  /// Trigger Algolia search manually (called by search button)
  void triggerAlgoliaSearch(String query) {
    if (query.trim().isEmpty) {
      // If query is empty, reset to show all customers
      useAlgoliaSearch.value = false;
      isSearching.value = false;
      _filterCustomers();
      return;
    }
    
    print('🔍 Triggering Algolia search for customers with query: "$query"');
    isSearching.value = true;
    searchWithAlgolia(query.trim());
  }
  
  /// Test method to search for customers by company name
  void testCompanyNameSearch(String companyName) {
    print('🧪 Testing company name search: "$companyName"');
    triggerAlgoliaSearch(companyName);
  }

  // Clear search
  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
    useAlgoliaSearch.value = false;
    isSearching.value = false;
    _searchDebounceTimer?.cancel();
    _filterCustomers();
  }

  // Get customer by ID
  Customer? getCustomerById(String customerId) {
    try {
      return customers.firstWhere((customer) => customer.id == customerId);
    } catch (e) {
      return null;
    }
  }

  // Two-way link helpers
  Future<void> _addCustomerToCompanies({
    required String workspaceId,
    required String customerDocId,
    required List<Map<String, dynamic>> companyNames,
  }) async {
    final companiesColl = FirestoreService.to.getWorkspaceCompaniesCollection(workspaceId);
    for (final c in companyNames) {
      final compId = (c['id'] as String?)?.trim();
      if (compId == null || compId.isEmpty) continue;
      try {
        await companiesColl.doc(compId).update({
          'associatedCustomerIds': FieldValue.arrayUnion([customerDocId]),
        });
      } catch (e) {
        // If doc missing or update fails, ignore silently
        print('⚠️ Failed to add customer to company $compId: $e');
      }
    }
  }

  Future<void> _syncCustomerCompanyLinksOnUpdate({
    required String workspaceId,
    required String customerDocId,
    required List<Map<String, dynamic>> prevCompanyNames,
    required List<Map<String, dynamic>> newCompanyNames,
  }) async {
    final prevIds = prevCompanyNames.map((m) => (m['id'] as String?)?.trim() ?? '').where((id) => id.isNotEmpty).toSet();
    final newIds = newCompanyNames.map((m) => (m['id'] as String?)?.trim() ?? '').where((id) => id.isNotEmpty).toSet();

    final toAdd = newIds.difference(prevIds);
    final toRemove = prevIds.difference(newIds);

    final companiesColl = FirestoreService.to.getWorkspaceCompaniesCollection(workspaceId);

    // Apply additions
    for (final compId in toAdd) {
      try {
        await companiesColl.doc(compId).update({
          'associatedCustomerIds': FieldValue.arrayUnion([customerDocId]),
        });
      } catch (e) {
        print('⚠️ Failed to add link for company $compId: $e');
      }
    }

    // Apply removals
    for (final compId in toRemove) {
      try {
        await companiesColl.doc(compId).update({
          'associatedCustomerIds': FieldValue.arrayRemove([customerDocId]),
        });
      } catch (e) {
        print('⚠️ Failed to remove link for company $compId: $e');
      }
    }
  }

  Future<void> _propagateCustomerName({
    required String workspaceId,
    required String customerDocId,
    required String newName,
  }) async {
    try {
      // Update cards
      final cardsColl = FirestoreService.to.getWorkspaceCardsCollection(workspaceId);
      final cardsQs = await cardsColl.where('customerId', isEqualTo: customerDocId).get();
      for (final doc in cardsQs.docs) {
        try {
          await doc.reference.update({'customer': newName});
        } catch (e) {
          print('⚠️ Failed to update card ${doc.id} customer name: $e');
        }
      }
      // Update documents
      final docsColl = FirestoreService.to.getWorkspaceDocumentsCollection(workspaceId);
      final docsQs = await docsColl.where('customerId', isEqualTo: customerDocId).get();
      for (final doc in docsQs.docs) {
        try {
          await doc.reference.update({'customer': newName});
        } catch (e) {
          print('⚠️ Failed to update document ${doc.id} customer name: $e');
        }
      }
    } catch (e) {
      print('⚠️ Propagate customer name failed: $e');
    }
  }


  // Add new customer
  Future<void> addCustomer(String workspaceId, Customer customer) async {
    if (!_can('customer:create')) {
      errorMessage.value = 'Permission denied: customer:create';
      return;
    }
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Add customer and get doc id
      final newId = await _customerRepository.addCustomer(workspaceId, customer);

      // Two-way link with companies
      await _addCustomerToCompanies(
        workspaceId: workspaceId,
        customerDocId: newId,
        companyNames: customer.companyNames,
      );

      // Sync to Algolia for search functionality
      try {
        final customerWithId = customer.copyWith(id: newId);
        await AlgoliaCustomerSyncService.syncCustomerToAlgolia(customerWithId);
        print('✅ Customer synced to Algolia for search: ${customer.name}');
      } catch (e) {
        print('⚠️ Failed to sync customer to Algolia: $e');
        // Continue - don't let Algolia sync failure break customer creation
      }

      // Optimistically update total count
      totalCustomersCount.value = (totalCustomersCount.value + 1).clamp(0, 1 << 31);

      // Increment customers usage (shared pool)
      try { await QuotaUsageService.incrementUsed(workspaceId, 'customers', delta: 1); } catch (_) {}
    } catch (e) {
      errorMessage.value = 'Failed to add customer: $e';
      // Optionally refresh total count on failure next time
    } finally {
      isLoading.value = false;
    }
  }

  // Update customer
  Future<void> updateCustomer(String workspaceId, Customer customer) async {
    if (!_can('customer:edit:all')) {
      errorMessage.value = 'Permission denied: customer:edit:all';
      return;
    }
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Load previous customer to compare
      Customer? prev;
      try {
        prev = await _customerRepository.getCustomer(workspaceId, customer.id);
      } catch (_) {
        prev = customers.firstWhereOrNull((c) => c.id == customer.id);
      }

      // Update customer document
      await _customerRepository.updateCustomer(workspaceId, customer);

      // Sync company links if we have previous data
      if (prev != null) {
        await _syncCustomerCompanyLinksOnUpdate(
          workspaceId: workspaceId,
          customerDocId: customer.id,
          prevCompanyNames: prev.companyNames,
          newCompanyNames: customer.companyNames,
        );

        // If name changed, propagate to cards and documents
        if ((prev.name.trim()) != (customer.name.trim())) {
          await _propagateCustomerName(
            workspaceId: workspaceId,
            customerDocId: customer.id,
            newName: customer.name.trim(),
          );
        }
      }

      // Sync to Algolia for search functionality
      try {
        await AlgoliaCustomerSyncService.syncCustomerToAlgolia(customer);
        print('✅ Customer updated in Algolia for search: ${customer.name}');
      } catch (e) {
        print('⚠️ Failed to sync customer update to Algolia: $e');
        // Continue - don't let Algolia sync failure break customer update
      }
    } catch (e) {
      errorMessage.value = 'Failed to update customer: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Delete customer
  Future<void> deleteCustomer(String workspaceId, String customerId) async {
    if (!_can('customer:delete')) {
      errorMessage.value = 'Permission denied: customer:delete';
      return;
    }
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _customerRepository.deleteCustomer(workspaceId, customerId);

      // Remove from Algolia search index
      try {
        await AlgoliaCustomerSyncService.syncCustomerDeletionToAlgolia(customerId);
        print('✅ Customer removed from Algolia search index: $customerId');
      } catch (e) {
        print('⚠️ Failed to remove customer from Algolia: $e');
        // Continue - don't let Algolia sync failure break customer deletion
      }

      // Optionally: clean up company links (arrayRemove)
      try {
        final existing = customers.firstWhereOrNull((c) => c.id == customerId);
        if (existing != null) {
          await _syncCustomerCompanyLinksOnUpdate(
            workspaceId: workspaceId,
            customerDocId: customerId,
            prevCompanyNames: existing.companyNames,
            newCompanyNames: const [],
          );
        }
      } catch (_) {}

      // Optimistically update total count
      totalCustomersCount.value = (totalCustomersCount.value - 1).clamp(0, 1 << 31);

      // Decrement customers usage (shared pool)
      try { await QuotaUsageService.decrementUsed(workspaceId, 'customers', delta: 1); } catch (_) {}
    } catch (e) {
      errorMessage.value = 'Failed to delete customer: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Get customer count
  int get customerCount => customers.length;

  // Get filtered customer count
  int get filteredCustomerCount => filteredCustomers.length;

  // Switch to a different workspace
  Future<void> switchWorkspace(String workspaceId) async {
    try {
      print('🔄 Starting workspace switch to: $workspaceId');
      
      // Clear existing customer lists immediately to prevent old data showing
      customers.clear();
      filteredCustomers.clear();
      totalCustomersCount.value = 0;
      
      // Cancel any existing subscriptions to prevent data conflicts
      await _customersSub?.cancel();
      _customersSub = null;
      
      // Update workspace ID only after clearing data
      currentWorkspaceId.value = workspaceId;
      
      print('📊 Current board: ${Get.find<BoardController>().currentBoardId.value}');
      print('📈 Customer count after clear: ${customers.length}');

      // Update last active workspace ID in user document
      try {
        await _repository.updateUserLastActiveWorkspaceId(currentUserId.value, workspaceId);
        print('✅ Last active workspace ID updated');
      } catch (e) {
        print('⚠️ Failed to update last active workspace ID: $e');
        // Don't throw error, continue with workspace switch
      }

      // Load data for the new workspace
      await loadCustomers(workspaceId);
      await loadCustomerSources(workspaceId);
      await _loadCompaniesIndex(workspaceId);
      
      print('📈 Final customer count: ${customers.length}');
    } catch (e) {
      print('❌ Failed to switch workspace: $e');
      errorMessage.value = 'Failed to switch workspace';
    }
  }

  void _subscribeWorkspaceQuota(String workspaceId) {
    print('[CustomersController] subscribe quota for workspaceId=$workspaceId');
    if (workspaceId.isEmpty) {
      customersQuotaUsed.value = 0;
      customersQuotaLimit.value = -2; // unknown
      usersQuotaUsed.value = 0;
      usersQuotaLimit.value = -2;
      return;
    }
    _workspaceQuotaSub?.cancel();
    _workspaceQuotaSub = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .snapshots()
        .listen((snap) {
      print('[CustomersController] quota snapshot received exists=${snap.exists}');
      if (!snap.exists) {
        customersQuotaUsed.value = 0;
        customersQuotaLimit.value = -2; // unknown
        usersQuotaUsed.value = 0;
        usersQuotaLimit.value = -2;
        return;
      }
      final data = snap.data() ?? {};
      final quotaRaw = data['quota'];
      if (quotaRaw is! Map<String, dynamic>) {
        print('[CustomersController] quota missing or not a map: $quotaRaw');
        customersQuotaUsed.value = 0;
        customersQuotaLimit.value = -2; // unknown
        usersQuotaUsed.value = 0;
        usersQuotaLimit.value = -2;
        return;
      }
      final quota = quotaRaw;

      int parseInt(dynamic v, {int fallback = 0}) {
        if (v is int) return v;
        if (v is double) return v.toInt();
        if (v is String) return int.tryParse(v) ?? fallback;
        return fallback;
      }

      Map<String, int> extract(String key) {
        int used = 0; int limit = -1; // unlimited default
        final entry = quota[key];
        if (entry is Map) {
          used = parseInt(entry['used']);
          limit = parseInt(entry['limit'] ?? entry['max'], fallback: -1);
          if ((entry['limit'] ?? entry['max']) == null) limit = -1;
        } else if (entry is int || entry is double || entry is String) {
          limit = parseInt(entry, fallback: -1);
        }
        final usedContainer = quota['used'];
        if (usedContainer is Map) {
          final alt = usedContainer[key];
            used = alt == null ? used : parseInt(alt, fallback: used);
        }
        if (used < 0) used = 0;
        return {'used': used, 'limit': limit};
      }

      final customersData = extract('customers');
      final usersData = extract('users');
      customersQuotaUsed.value = customersData['used']!;
      customersQuotaLimit.value = customersData['limit']!;
      usersQuotaUsed.value = usersData['used']!;
      usersQuotaLimit.value = usersData['limit']!;
      print('[CustomersController] quota customers used=${customersQuotaUsed.value} limit=${customersQuotaLimit.value}');
      print('[CustomersController] quota users used=${usersQuotaUsed.value} limit=${usersQuotaLimit.value}');
    }, onError: (e) {
      print('⚠️ Quota subscription error: $e');
    });
  }

  int get customersDisplayUsed {
    // If Firestore quota used seems stale (lower than actual loaded customers), prefer the higher value.
    final repoUsed = customersQuotaUsed.value;
    final actual = customerCount;
    if (repoUsed < actual) return actual;
    return repoUsed;
  }

  double get customersQuotaProgress {
    final limit = customersQuotaLimit.value;
    final used = customersQuotaUsed.value;
    if (limit <= 0) return 0; // unlimited/unknown
    return (used / limit).clamp(0, 1).toDouble();
  }

  bool get isCustomersQuotaFull {
    final limit = customersQuotaLimit.value;
    if (limit == -1) return false; // unlimited
    if (limit <= 0) return false; // unknown
    return customersQuotaUsed.value >= limit;
  }

  bool get isUsersQuotaFull {
    final limit = usersQuotaLimit.value;
    if (limit == -1) return false;
    if (limit <= 0) return false;
    return usersQuotaUsed.value >= limit;
  }

  /// Search customers using Algolia (alternative to local search)
  void searchWithAlgolia(String query) async {
    if (query.trim().isEmpty) {
      useAlgoliaSearch.value = false;
      _filterCustomers();
      return;
    }

    try {
      useAlgoliaSearch.value = true;
      
      // Search with Algolia
      final searchStream = AlgoliaSearchService.searchCustomers(
        query: query,
        workspaceId: currentWorkspaceId.value,
        hitsPerPage: 100,
      );
      
      // Listen to search results
      searchStream.listen(
        (response) {
          final hits = response.hits;
          final results = hits.map((hit) {
            try {
              final data = Map<String, dynamic>.from(hit);
              data['id'] = hit['objectID'] ?? '';
              return Customer.fromMap(data, data['id']);
            } catch (e) {
              print('❌ Error parsing customer from Algolia: $e');
              return null;
            }
          }).where((customer) => customer != null).cast<Customer>().toList();
          
          // Apply permission filtering to results
          _applyPermissionFiltering(results);
          isSearching.value = false;
          
          print('🔍 Algolia search results: ${results.length} customers found for query: "$query"');
          
          // Debug: Show matching customers with their company names
          if (results.isNotEmpty) {
            for (final customer in results.take(3)) { // Show first 3 results
              final companyNames = customer.companyNames.map((c) => c['value']?.toString() ?? '').where((name) => name.isNotEmpty).join(', ');
              print('  📋 ${customer.name} (${customer.customId}) - Companies: $companyNames');
            }
          }
        },
        onError: (error) {
          print('❌ Algolia search error: $error');
          // Fallback to local search
          useAlgoliaSearch.value = false;
          isSearching.value = false;
          _filterCustomers();
        },
      );
      
    } catch (e) {
      print('❌ Failed to search with Algolia: $e');
      useAlgoliaSearch.value = false;
      isSearching.value = false;
      _filterCustomers();
    }
  }

  /// Apply permission filtering to search results
  void _applyPermissionFiltering(List<Customer> searchResults) {
    final isOwner = MobilePermissionsService.to.isOwner;
    final canViewAll = MobilePermissionsService.to.can('customer:view:all');
    final canViewAssigned = MobilePermissionsService.to.can('customer:view:assigned');
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    List<Customer> baseList;
    if (isOwner || canViewAll) {
      baseList = searchResults;
    } else if (canViewAssigned && userId.isNotEmpty) {
      baseList = searchResults.where((c) => c.assignees.contains(userId)).toList();
    } else {
      baseList = [];
    }
    
    filteredCustomers.value = baseList;
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    searchController.dispose();
    _customersSub?.cancel();
    _workspaceQuotaSub?.cancel();
    _authSub?.cancel();
    super.onClose();
  }
}
