import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/firestore_repository.dart';
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
        // Use the first workspace as default
        final firstWorkspace = workspaces.first;
        currentWorkspaceId.value = firstWorkspace['id'] as String;
        
        print('✅ User initialized with workspace: ${firstWorkspace['name']}');
        
        // Load data for the selected workspace
        await loadCustomers(currentWorkspaceId.value);
        await loadCustomerSources(currentWorkspaceId.value);
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

  // Filter customers based on search query
  void _filterCustomers() {
    if (searchQuery.value.isEmpty) {
      filteredCustomers.value = customers;
    } else {
      filteredCustomers.value = customers.where((customer) {
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
        
        return customer.name.toLowerCase().contains(query) ||
               customer.customId.toLowerCase().contains(query) ||
               emailMatch ||
               phoneMatch;
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

  // Add new customer
  Future<void> addCustomer(String workspaceId, Customer customer) async {
    if (!_can('customer:create')) {
      errorMessage.value = 'Permission denied: customer:create';
      return;
    }
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      await _customerRepository.addCustomer(workspaceId, customer);
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
      
      await _customerRepository.updateCustomer(workspaceId, customer);
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
      
      // Load data for the new workspace
      await loadCustomers(workspaceId);
      await loadCustomerSources(workspaceId);
    } catch (e) {
      print('❌ Failed to switch workspace: $e');
      errorMessage.value = 'Failed to switch workspace';
    }
  }
}
