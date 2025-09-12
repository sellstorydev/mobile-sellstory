import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../data/services/firestore_service.dart';
import '../../../domain/entities/customer.dart';
import '../../../data/services/mobile_permissions_service.dart';

class CustomersController extends GetxController {
  final CustomerRepository _customerRepository;
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();

  // Observable variables
  final RxList<Customer> customers = <Customer>[].obs;
  final RxList<Customer> filteredCustomers = <Customer>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxList<String> customerSources = <String>[].obs;

  // User and workspace management
  final RxString currentUserId = ''.obs;
  final RxString currentWorkspaceId = ''.obs;
  final RxList<Map<String, dynamic>> userWorkspaces = <Map<String, dynamic>>[].obs;

  // Companies index for search (companyId -> { name, taxId })
  final Map<String, Map<String, String>> _companyIndex = {};

  CustomersController(this._customerRepository);

  bool _can(String permission) =>
      MobilePermissionsService.to.isOwner || MobilePermissionsService.to.can(permission);

  @override
  void onInit() {
    super.onInit();
    // Listen to search query changes
    ever(searchQuery, (_) => _filterCustomers());

    // Initialize with current user
    _initializeWithCurrentUser();
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

  // Load customers for a workspace
  Future<void> loadCustomers(String workspaceId) async {
    print(workspaceId);
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Get customers stream for real-time updates
      _customerRepository.getCustomersStream(workspaceId).listen((customersList) {
        print(customersList);
        customers.value = customersList;
        _filterCustomers();
      });
    } catch (e) {
      errorMessage.value = 'Failed to load customers: $e';
    } finally {
      isLoading.value = false;
    }
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

  // Clear search
  void clearSearch() {
    searchQuery.value = '';
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
    } catch (e) {
      errorMessage.value = 'Failed to add customer: $e';
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
      currentWorkspaceId.value = workspaceId;
      print('🔄 Switched to workspace: $workspaceId');

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
    } catch (e) {
      print('❌ Failed to switch workspace: $e');
      errorMessage.value = 'Failed to switch workspace';
    }
  }
}
