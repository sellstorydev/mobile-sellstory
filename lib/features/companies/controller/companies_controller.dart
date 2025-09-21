import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/quota_usage_service.dart';
import '../../../domain/entities/company.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../core/services/id_generation_service.dart';
import '../../board/controller/board_controller.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../core/services/algolia_company_sync_service.dart';
import '../../../core/services/algolia_search_service.dart';


class CompaniesController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  final IdGenerationService _idService = IdGenerationService();

  // Observable states
  final RxList<Company> companies = <Company>[].obs;
  final RxList<Company> filteredCompanies = <Company>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearching = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString currentWorkspaceId = ''.obs;

  // Search controller and timer for debouncing
  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounceTimer;

  // Quota (use customers key to cover both individual and company records)
  final RxInt customersQuotaUsed = 0.obs;
  final RxInt customersQuotaLimit = (-2).obs; // -1 unlimited, -2 unknown
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _workspaceQuotaSub;

  // Getters
  int get filteredCompanyCount => filteredCompanies.length;
  int get companyCount => companies.length;

  int get customersDisplayUsed {
    final repoUsed = customersQuotaUsed.value;
    final actual = companyCount; // prefer actual if higher for UX
    if (repoUsed < actual) return actual;
    return repoUsed;
  }

  bool get isCustomersQuotaFull {
    final limit = customersQuotaLimit.value;
    if (limit == -1) return false; // unlimited
    if (limit <= 0) return false; // unknown -> fail-open
    return customersQuotaUsed.value >= limit;
  }

  @override
  void onInit() {
    super.onInit();
    // Listen to search query changes
    ever(searchQuery, (_) => _filterCompanies());
    ever(companies, (_) => _filterCompanies());

    // Try to initialize workspace from BoardController if available
    if (Get.isRegistered<BoardController>()) {
      try {
        final board = Get.find<BoardController>();
        if (board.currentWorkspaceId.value.isNotEmpty) {
          currentWorkspaceId.value = board.currentWorkspaceId.value;
        }
      } catch (_) {}
    }
  }

  void _subscribeWorkspaceQuota(String workspaceId) {
    try {
      _workspaceQuotaSub?.cancel();
    } catch (_) {}
    customersQuotaUsed.value = 0;
    customersQuotaLimit.value = -2;
    if (workspaceId.isEmpty) return;

    _workspaceQuotaSub = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) {
        customersQuotaUsed.value = 0;
        customersQuotaLimit.value = -2;
        return;
      }
      final data = snap.data() ?? {};
      final quotaData = data['quota'];
      final quota = quotaData is Map 
          ? Map<String, dynamic>.from(quotaData) 
          : <String, dynamic>{};

      int asInt(dynamic v, {int fallback = 0}) {
        if (v is int) return v;
        if (v is double) return v.toInt();
        if (v is String) return int.tryParse(v) ?? fallback;
        return fallback;
      }

      Map<String, int> extractCustomers() {
        int used = 0; int limit = -1;
        dynamic entry = quota['customers'];
        if (entry is Map) {
          used = asInt(entry['used']);
          final rawLimit = entry['limit'] ?? entry['max'];
          limit = rawLimit == null ? -1 : asInt(rawLimit, fallback: -1);
        } else if (entry is int || entry is double || entry is String) {
          limit = asInt(entry, fallback: -1);
        }
        final usedContainer = quota['used'];
        if (usedContainer is Map) {
          final alt = usedContainer['customers'];
          if (alt != null) used = asInt(alt, fallback: used);
        }
        if (used < 0) used = 0;
        return {'used': used, 'limit': limit};
      }

      final cu = extractCustomers();
      customersQuotaUsed.value = cu['used'] ?? 0;
      customersQuotaLimit.value = cu['limit'] ?? -1;
    }, onError: (_) {
      // fail-open
    });
  }

  /// Load companies for a specific workspace
  Future<void> loadCompanies(String workspaceId) async {
    if (workspaceId.isEmpty) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      currentWorkspaceId.value = workspaceId;

      _subscribeWorkspaceQuota(workspaceId);

      final result = await _repository.getCompanies(workspaceId);
      companies.value = result;
    } catch (e) {
      errorMessage.value = 'ไม่สามารถโหลดข้อมูลบริษัทได้: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  /// Search and filter companies
  void setSearchQuery(String query) {
    searchQuery.value = query.trim().toLowerCase();
  }

  void onSearchChanged(String query) {
    // Cancel previous timer if exists
    _searchDebounceTimer?.cancel();
    
    searchQuery.value = query;
    
    // If query is empty, reset search immediately
    if (query.trim().isEmpty) {
      isSearching.value = false;
      _filterCompanies();
      return;
    }
    
    // Debounce search for 500ms to avoid too many API calls while typing
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      triggerAlgoliaSearch(query.trim());
    });
  }

  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
    isSearching.value = false;
    _filterCompanies();
  }

  void _filterCompanies() {
    if (searchQuery.value.isEmpty) {
      filteredCompanies.value = companies.toList();
      return;
    }

    final query = searchQuery.value.toLowerCase();
    filteredCompanies.value = companies.where((company) {
      // Search in company name
      if (company.name.toLowerCase().contains(query)) return true;

      // Search in tax ID
      if (company.taxId.toLowerCase().contains(query)) return true;

      // Search in branch
      if (company.branch.toLowerCase().contains(query)) return true;

      // Search in emails
      for (final email in company.emails) {
        if ((email['value'] ?? '').toString().toLowerCase().contains(query)) {
          return true;
        }
      }

      // Search in phones
      for (final phone in company.phones) {
        if ((phone['value'] ?? '').toString().toLowerCase().contains(query)) {
          return true;
        }
      }

      // Search in website
      if (company.website.toLowerCase().contains(query)) return true;

      return false;
    }).toList();
  }

  bool _can(String permission) =>
      MobilePermissionsService.to.isOwner || MobilePermissionsService.to.can(permission);

  /// Create a new company
  Future<bool> createCompany(Company company) async {
    if (!_can('company:create')) {
      errorMessage.value = 'Permission denied: company:create';
      return false;
    }
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Ensure workspace id is set
      if (currentWorkspaceId.value.isEmpty && Get.isRegistered<BoardController>()) {
        try {
          final board = Get.find<BoardController>();
          currentWorkspaceId.value = board.currentWorkspaceId.value;
        } catch (_) {}
      }
      if (currentWorkspaceId.value.isEmpty) {
        throw Exception('ไม่พบ Workspace ปัจจุบัน');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ไม่พบข้อมูลผู้ใช้');

      // Generate custom ID
      final customId = await _idService.generateCompanyId(currentWorkspaceId.value);

      final newCompany = company.copyWith(
        customId: customId,
        createdBy: user.uid,
        updatedBy: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create company and get the generated document ID
      final companyId = await _repository.createCompany(currentWorkspaceId.value, newCompany);

      // Sync to Algolia after successful creation with the actual document ID
      try {
        final companyWithId = newCompany.copyWith(id: companyId);
        await AlgoliaCompanySyncService.syncCompanyToAlgolia(companyWithId);
      } catch (e) {
        // Log but don't fail the operation if Algolia sync fails
        print('⚠️ Failed to sync company to Algolia: $e');
      }

      // Reload companies
      await loadCompanies(currentWorkspaceId.value);

      // Increment customers shared usage (companies share the customers pool)
      try { await QuotaUsageService.incrementUsed(currentWorkspaceId.value, 'customers', delta: 1); } catch (_) {}

      return true;
    } catch (e) {
      errorMessage.value = 'ไม่สามารถสร้างบริษัทได้: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing company
  Future<bool> updateCompany(Company company) async {
    if (!_can('company:edit:all')) {
      errorMessage.value = 'Permission denied: company:edit:all';
      return false;
    }
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (currentWorkspaceId.value.isEmpty && Get.isRegistered<BoardController>()) {
        try {
          final board = Get.find<BoardController>();
          currentWorkspaceId.value = board.currentWorkspaceId.value;
        } catch (_) {}
      }
      if (currentWorkspaceId.value.isEmpty) {
        throw Exception('ไม่พบ Workspace ปัจจุบัน');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ไม่พบข้อมูลผู้ใช้');

      final updatedCompany = company.copyWith(
        updatedBy: user.uid,
        updatedAt: DateTime.now(),
      );

      await _repository.updateCompany(currentWorkspaceId.value, updatedCompany);

      // Sync to Algolia after successful update
      try {
        await AlgoliaCompanySyncService.syncCompanyToAlgolia(updatedCompany);
      } catch (e) {
        // Log but don't fail the operation if Algolia sync fails
        print('⚠️ Failed to sync company update to Algolia: $e');
      }

      // Update local list
      final index = companies.indexWhere((c) => c.id == company.id);
      if (index != -1) {
        companies[index] = updatedCompany;
      }

      return true;
    } catch (e) {
      errorMessage.value = 'ไม่สามารถอัปเดตบริษัทได้: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete a company
  Future<bool> deleteCompany(String companyId) async {
    if (!_can('company:delete')) {
      errorMessage.value = 'Permission denied: company:delete';
      return false;
    }
    try {
      isLoading.value = true;
      errorMessage.value = '';

      if (currentWorkspaceId.value.isEmpty && Get.isRegistered<BoardController>()) {
        try {
          final board = Get.find<BoardController>();
          currentWorkspaceId.value = board.currentWorkspaceId.value;
        } catch (_) {}
      }
      if (currentWorkspaceId.value.isEmpty) {
        throw Exception('ไม่พบ Workspace ปัจจุบัน');
      }

      await _repository.deleteCompany(currentWorkspaceId.value, companyId);

      // Sync deletion to Algolia after successful deletion
      try {
        await AlgoliaCompanySyncService.syncCompanyDeletionToAlgolia(companyId, currentWorkspaceId.value);
      } catch (e) {
        // Log but don't fail the operation if Algolia sync fails
        print('⚠️ Failed to sync company deletion to Algolia: $e');
      }

      // Remove from local list
      companies.removeWhere((c) => c.id == companyId);

      // Decrement customers shared usage
      try { await QuotaUsageService.decrementUsed(currentWorkspaceId.value, 'customers', delta: 1); } catch (_) {}

      return true;
    } catch (e) {
      errorMessage.value = 'ไม่สามารถลบบริษัทได้: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get company by ID
  Company? getCompanyById(String companyId) {
    try {
      return companies.firstWhere((c) => c.id == companyId);
    } catch (e) {
      return null;
    }
  }

  /// Link customer to company
  Future<bool> linkCustomerToCompany(String companyId, String customerId) async {
    try {
      if (currentWorkspaceId.value.isEmpty && Get.isRegistered<BoardController>()) {
        try {
          final board = Get.find<BoardController>();
          currentWorkspaceId.value = board.currentWorkspaceId.value;
        } catch (_) {}
      }
      if (currentWorkspaceId.value.isEmpty) {
        throw Exception('ไม่พบ Workspace ปัจจุบัน');
      }

      await _repository.linkCustomerToCompany(
        currentWorkspaceId.value,
        companyId,
        customerId,
      );

      // Reload companies to reflect changes
      await loadCompanies(currentWorkspaceId.value);
      return true;
    } catch (e) {
      errorMessage.value = 'ไม่สามารถเชื่อมโยงลูกค้ากับบริษัทได้: ${e.toString()}';
      return false;
    }
  }

  /// Unlink customer from company
  Future<bool> unlinkCustomerFromCompany(String companyId, String customerId) async {
    try {
      if (currentWorkspaceId.value.isEmpty && Get.isRegistered<BoardController>()) {
        try {
          final board = Get.find<BoardController>();
          currentWorkspaceId.value = board.currentWorkspaceId.value;
        } catch (_) {}
      }
      if (currentWorkspaceId.value.isEmpty) {
        throw Exception('ไม่พบ Workspace ปัจจุบัน');
      }

      await _repository.unlinkCustomerFromCompany(
        currentWorkspaceId.value,
        companyId,
        customerId,
      );

      // Reload companies to reflect changes
      await loadCompanies(currentWorkspaceId.value);
      return true;
    } catch (e) {
      errorMessage.value = 'ไม่สามารถยกเลิกการเชื่อมโยงลูกค้ากับบริษัทได้: ${e.toString()}';
      return false;
    }
  }

  /// Trigger Algolia search for companies
  Future<void> triggerAlgoliaSearch(String query) async {
    if (query.trim().isEmpty) {
      // If query is empty, reset to show all companies with current filters
      isSearching.value = false;
      filteredCompanies.value = companies.toList();
      return;
    }
    
    isSearching.value = true;
    _searchWithAlgolia(query.trim());
  }

  Future<void> _searchWithAlgolia(String query) async {
    try {
      if (currentWorkspaceId.value.isEmpty) {
        isSearching.value = false;
        return;
      }
      
      final searchStream = AlgoliaSearchService.searchCompanies(
        query: query,
        workspaceId: currentWorkspaceId.value,
        hitsPerPage: 50,
      );
      
      // Listen to search results
      searchStream.listen(
        (response) {
          final hits = response.hits;
          final algoliaResults = <Company>[];
          
          // Convert Algolia results to Company objects
          for (final hit in hits) {
            try {
              // Find the company in our local list by ID
              final companyId = hit['objectID'] as String?;
              if (companyId != null) {
                final company = companies.firstWhere(
                  (c) => c.id == companyId,
                  orElse: () => throw StateError('Company not found'),
                );
                algoliaResults.add(company);
              }
            } catch (e) {
              print('⚠️ Failed to convert Algolia hit to Company: $e');
            }
          }
          
          // Update the filtered companies with search results
          filteredCompanies.value = algoliaResults;
          isSearching.value = false;
          print('🔍 Algolia search results: ${algoliaResults.length} companies found');
        },
        onError: (error) {
          print('❌ Algolia search error: $error');
          // Fallback to local search
          isSearching.value = false;
          setSearchQuery(query);
        },
      );
      
    } catch (e) {
      print('❌ Failed to search with Algolia: $e');
      isSearching.value = false;
      // Fallback to local search
      setSearchQuery(query);
    }
  }

  /// Sync all companies to Algolia (for initial population)
  Future<void> syncAllCompaniesToAlgolia() async {
    try {
      isLoading.value = true;
      
      if (companies.isEmpty) {
        print('⚠️ No companies to sync to Algolia');
        return;
      }
      
      print('🔄 Starting bulk sync of ${companies.length} companies to Algolia...');
      
      // Create a list of companies with their workspace ID set
      final allCompanies = companies.map((company) {
        return company.copyWith(workspaceId: currentWorkspaceId.value);
      }).toList();
      
      await AlgoliaCompanySyncService.syncMultipleCompanies(allCompanies);
      
      print('✅ Successfully synced ${companies.length} companies to Algolia');
      
    } catch (e) {
      print('❌ Failed to sync companies to Algolia: $e');
      errorMessage.value = 'ไม่สามารถซิงค์ข้อมูลบริษัทกับ Algolia ได้: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _workspaceQuotaSub?.cancel();
    _searchDebounceTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
