import 'package:get/get.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../domain/entities/customer.dart';

class CustomersController extends GetxController {
  final CustomerRepository _customerRepository;
  
  // Observable variables
  final RxList<Customer> customers = <Customer>[].obs;
  final RxList<Customer> filteredCustomers = <Customer>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString errorMessage = ''.obs;
  final RxList<String> customerSources = <String>[].obs;

  CustomersController(this._customerRepository);

  @override
  void onInit() {
    super.onInit();
    // Listen to search query changes
    ever(searchQuery, (_) => _filterCustomers());
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
        return customer.name.toLowerCase().contains(query) ||
               customer.customId.toLowerCase().contains(query) ||
               customer.emails.toLowerCase().contains(query) ||
               customer.phones.contains(query);
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
}


