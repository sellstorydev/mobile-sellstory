import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/entities/company.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../core/services/id_generation_service.dart';
import '../../board/controller/board_controller.dart';

class CompaniesController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  final IdGenerationService _idService = IdGenerationService();

  // Observable states
  final RxList<Company> companies = <Company>[].obs;
  final RxList<Company> filteredCompanies = <Company>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString currentWorkspaceId = ''.obs;

  // Getters
  int get filteredCompanyCount => filteredCompanies.length;

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

  /// Load companies for a specific workspace
  Future<void> loadCompanies(String workspaceId) async {
    if (workspaceId.isEmpty) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';
      currentWorkspaceId.value = workspaceId;

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

  void clearSearch() {
    searchQuery.value = '';
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

  /// Create a new company
  Future<bool> createCompany(Company company) async {
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


      await _repository.createCompany(currentWorkspaceId.value, newCompany);

      // Reload companies
      await loadCompanies(currentWorkspaceId.value);

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

      // Remove from local list
      companies.removeWhere((c) => c.id == companyId);

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
      errorMessage.value = 'ไม่สามารถยกเลิกการเชื่อมโยงลูกค้ากับบริษัทได��: ${e.toString()}';
      return false;
    }
  }
}
