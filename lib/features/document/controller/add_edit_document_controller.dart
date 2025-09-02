import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../domain/entities/customer.dart';
import '../../../core/services/workspace_members_service.dart';
import '../../../core/services/id_generation_service.dart';

class AddEditQuotationController extends GetxController {
  final String? quotationId;
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Customer loading state
  bool _isLoadingCustomers = false;
  bool get isLoadingCustomers => _isLoadingCustomers;

  // User and workspace
  String? _currentUserId;
  String? _currentWorkspaceId;

  // Customer section
  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  String? _selectedCustomerId;
  String? get selectedCustomerId => _selectedCustomerId;

  Customer? get selectedCustomer =>
      _customers.firstWhereOrNull((c) => c.id == _selectedCustomerId);

  // Get customer display name with custom ID
  String getCustomerDisplayName(Customer customer) {
    if (customer.customId.isNotEmpty) {
      return '${customer.name}';
    }
    return customer.name;
  }

  // Filter customers by search term
  List<Customer> getFilteredCustomers(String searchTerm) {
    if (searchTerm.isEmpty) return _customers;

    return _customers.where((customer) {
      final name = customer.name.toLowerCase();
      final customId = customer.customId.toLowerCase();
      final search = searchTerm.toLowerCase();

      return name.contains(search) || customId.contains(search);
    }).toList();
  }

  String? _selectedCompanyId;
  String? get selectedCompanyId => _selectedCompanyId;

  // Get company display name
  String getCompanyDisplayName(Map<String, dynamic> company) {
    final name = company['value'] ?? '';
    final label = company['label'] ?? '';

    if (label.isNotEmpty && label != 'Main') {
      return '$name ($label)';
    }
    return name;
  }

  // Get selected company data
  Map<String, dynamic>? get selectedCompanyData {
    if (_selectedCustomerId == null || _selectedCompanyId == null) return null;

    final customer = selectedCustomer;
    if (customer == null) return null;

    return customer.companyNames.firstWhereOrNull(
      (company) => company['id'] == _selectedCompanyId,
    );
  }

  // Controllers for customer fields
  final TextEditingController customerAddressController =
      TextEditingController();
  final TextEditingController customerPostalCodeController =
      TextEditingController();
  final TextEditingController customerNationalIdController =
      TextEditingController();
  final TextEditingController customerPhoneController = TextEditingController();
  final TextEditingController customerEmailController = TextEditingController();

  // Seller section
  final TextEditingController sellerNameController = TextEditingController();
  final TextEditingController sellerPhoneController = TextEditingController();
  final TextEditingController jobNameController = TextEditingController();
  final TextEditingController refIdController = TextEditingController();
  
  // Seller/Assignee management
  List<String> _selectedSellerIds = [];
  List<WorkspaceMember> _availableAssignees = [];
  bool _isLoadingAssignees = false;
  
  List<String> get selectedSellerIds => _selectedSellerIds;
  List<WorkspaceMember> get availableAssignees => _availableAssignees;
  bool get isLoadingAssignees => _isLoadingAssignees;

  DateTime? _documentDate;
  DateTime? get documentDate => _documentDate;

  DateTime? _validUntilDate;
  DateTime? get validUntilDate => _validUntilDate;

  // Product section
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> get products => _products;
  
  // Product database data
  List<Map<String, dynamic>> _availableProducts = [];
  List<Map<String, dynamic>> get availableProducts => _availableProducts;
  bool _isLoadingProducts = false;
  bool get isLoadingProducts => _isLoadingProducts;

  // More options section
  List<String> _selectedPaymentMethods = [];
  List<String> get selectedPaymentMethods => _selectedPaymentMethods;

  final List<String> availablePaymentMethods = [
    'เงินสด',
    'โอนเงิน',
    'บัตรเครดิต',
    'เช็ค',
  ];

  final TextEditingController notesController = TextEditingController();

  bool _includeSignature = false;
  bool get includeSignature => _includeSignature;

  // Document status
  String _documentStatus = 'DRAFT';
  String get documentStatus => _documentStatus;

  // Summary section
  bool _isVatEnabled = false;
  bool get isVatEnabled => _isVatEnabled;

  bool _isWhtEnabled = false;
  bool get isWhtEnabled => _isWhtEnabled;

  final TextEditingController whtPercentageController = TextEditingController();

  // Product controllers map
  final Map<String, Map<String, TextEditingController>> _productControllers =
      {};

  AddEditQuotationController({this.quotationId});

  @override
  void onInit() {
    super.onInit();
    _initializeUserAndWorkspace();
    _initializeForm();
  }

  @override
  void onClose() {
    // Dispose all controllers
    customerAddressController.dispose();
    customerPostalCodeController.dispose();
    customerNationalIdController.dispose();
    customerPhoneController.dispose();
    customerEmailController.dispose();
    sellerNameController.dispose();
    sellerPhoneController.dispose();
    jobNameController.dispose();
    refIdController.dispose();
    notesController.dispose();
    whtPercentageController.dispose();

    // Dispose product controllers
    for (final controllers in _productControllers.values) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }

    super.onClose();
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        Get.snackbar(
          'ข้อผิดพลาด',
          'กรุณาเข้าสู่ระบบก่อน',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      _currentUserId = currentUser.uid;
      print('👤 Initializing quotation page with user: $_currentUserId');

      // Get user's workspaces
      print('📋 Fetching user workspaces...');
      final workspaces = await _repository.getUserWorkspaces(_currentUserId!);

      print('📋 User workspaces loaded: ${workspaces.length} workspaces');

      if (workspaces.isNotEmpty) {
        // Use the first workspace as default
        final firstWorkspace = workspaces.first;
        _currentWorkspaceId = firstWorkspace['id'] as String;

        print(
          '✅ Quotation page initialized with workspace: ${firstWorkspace['name']}',
        );

        // Load customers, workspace members, and products, then initialize form
        await _loadCustomers();
        await _loadWorkspaceMembers();
        await loadProducts();
        _initializeForm();
      } else {
        print('⚠️ No workspaces found for user: $_currentUserId');
        Get.snackbar(
          'ข้อผิดพลาด',
          'ไม่พบเวิร์กสเปซสำหรับผู้ใช้นี้',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเริ่มต้นระบบได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _loadCustomers() async {
    try {
      if (_currentWorkspaceId != null) {
        _setCustomerLoading(true);

        // Load customers from Firebase path: workspaces/{WorkspaceId}/customers/{Customer Uids}
        final customersSnapshot = await FirebaseFirestore.instance
            .collection('workspaces')
            .doc(_currentWorkspaceId)
            .collection('customers')
            .get();

        if (customersSnapshot.docs.isNotEmpty) {
          _customers = customersSnapshot.docs.map((doc) {
            try {
              final data = doc.data();
              print('📋 Processing customer document: ${doc.id}');
              print('📋 Customer data keys: ${data.keys.toList()}');

              // Helper function to safely convert to list
              List<Map<String, dynamic>> safeListConversion(dynamic value) {
                if (value == null) return [];
                if (value is List) {
                  return value
                      .map(
                        (item) => item is Map<String, dynamic>
                            ? item
                            : <String, dynamic>{},
                      )
                      .toList();
                }
                print(
                  '⚠️ Expected list but got: ${value.runtimeType} for value: $value',
                );
                return [];
              }

              List<String> safeStringListConversion(dynamic value) {
                if (value == null) return [];
                if (value is List) {
                  return value.map((item) => item?.toString() ?? '').toList();
                }
                print(
                  '⚠️ Expected string list but got: ${value.runtimeType} for value: $value',
                );
                return [];
              }

              final customer = Customer(
                id: doc.id,
                name: data['name']?.toString() ?? '',
                prefix: data['prefix']?.toString() ?? '',
                gender: data['gender']?.toString() ?? '',
                age: data['age']?.toString() ?? '',
                customerType: data['customerType']?.toString() ?? 'Customer',
                emails: safeListConversion(data['emails']),
                phones: safeListConversion(data['phones']),
                companyNames: safeListConversion(data['companyNames']),
                nationalId: data['nationalId']?.toString() ?? '',
                address: data['address']?.toString() ?? '',
                source: data['source']?.toString() ?? '',
                hashtags: safeListConversion(data['hashtags']),
                assignees: safeStringListConversion(data['assignees']),
                customId: data['customId']?.toString() ?? '',
                workspaceId:
                    data['workspaceId']?.toString() ?? _currentWorkspaceId!,
                createdAt: DateTime.fromMillisecondsSinceEpoch(
                  data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
                ),
                updatedAt: DateTime.fromMillisecondsSinceEpoch(
                  data['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
                ),
                createdBy: data['createdBy']?.toString() ?? '',
                updatedBy: data['updatedBy']?.toString() ?? '',
              );

              print(
                '✅ Successfully created customer: ${customer.name} with ${customer.companyNames.length} companies',
              );
              return customer;
            } catch (e) {
              print('❌ Error processing customer document ${doc.id}: $e');
              print('❌ Document data: ${doc.data()}');
              // Return a default customer to prevent the entire operation from failing
              return Customer(
                id: doc.id,
                name: 'Error Loading Customer',
                prefix: '',
                gender: '',
                age: '',
                customerType: 'Customer',
                emails: [],
                phones: [],
                companyNames: [],
                nationalId: '',
                address: '',
                source: '',
                hashtags: [],
                assignees: [],
                customId: '',
                workspaceId: _currentWorkspaceId!,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                createdBy: '',
                updatedBy: '',
              );
            }
          }).toList();

          print('✅ Loaded ${_customers.length} customers from Firebase');
        } else {
          print('⚠️ No customers found in workspace: $_currentWorkspaceId');
          _customers = [];
        }

        update();
      }
    } catch (e) {
      print('❌ Failed to load customers: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถโหลดข้อมูลลูกค้าได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _customers = [];
    } finally {
      _setCustomerLoading(false);
    }
  }

  void _initializeForm() {
    try {
      // Set default dates
      _documentDate = DateTime.now();
      _validUntilDate = DateTime.now().add(const Duration(days: 30));

      // Set default WHT percentage
      whtPercentageController.text = '3';

      // No default products - start with empty list
      _products = [];

      // Add listeners to customer and seller controllers for real-time validation
      _addFormControllerListeners();

      update();
    } catch (e) {
      print('❌ Failed to initialize form: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเริ่มต้นฟอร์มได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Add listeners to form controllers for real-time validation
  void _addFormControllerListeners() {
    try {
      // Add listeners to customer and seller controllers
      customerAddressController.addListener(() => update());
      customerPostalCodeController.addListener(() => update());
      customerNationalIdController.addListener(() => update());
      customerPhoneController.addListener(() => update());
      customerEmailController.addListener(() => update());
      
      sellerNameController.addListener(() => update());
      sellerPhoneController.addListener(() => update());
      jobNameController.addListener(() => update());
      refIdController.addListener(() => update());
    } catch (e) {
      print('❌ Failed to add form controller listeners: $e');
    }
  }

  // Force refresh UI for validation updates
  void refreshValidation() {
    update();
  }

  void _setLoading(bool loading) {
    try {
      _isLoading = loading;
      update();
    } catch (e) {
      print('❌ Failed to set loading state: $e');
    }
  }

  void _setCustomerLoading(bool loading) {
    try {
      _isLoadingCustomers = loading;
      update();
    } catch (e) {
      print('❌ Failed to set customer loading state: $e');
    }
  }

  // Customer section methods
  void onCustomerChanged(String? customerId) {
    try {
      _selectedCustomerId = customerId;
      _selectedCompanyId = null;

      // Auto-fill customer information if customer is selected
      if (customerId != null) {
        final customer = _customers.firstWhereOrNull((c) => c.id == customerId);
        if (customer != null) {
          // Auto-fill customer fields from Firebase data
          customerAddressController.text = customer.address;
          customerPostalCodeController.text =
              customer.nationalId; // Using nationalId as postal code for now
          customerNationalIdController.text = customer.nationalId;

          // Get first phone number if available
          if (customer.phones.isNotEmpty) {
            final firstPhone = customer.phones.first;
            customerPhoneController.text = firstPhone['value'] ?? '';
          } else {
            customerPhoneController.text = '';
          }

          // Get first email if available
          if (customer.emails.isNotEmpty) {
            final firstEmail = customer.emails.first;
            customerEmailController.text = firstEmail['value'] ?? '';
          } else {
            customerEmailController.text = '';
          }

          // Auto-fill seller from first assignee
          if (customer.assignees.isNotEmpty) {
            final firstAssigneeId = customer.assignees.first;
            _selectedSellerIds = [firstAssigneeId];
            
            // Update seller name controller for display
            sellerNameController.text = 'Assignee ID: $firstAssigneeId';
            
            // Load assignee details if available
            _loadAssigneeDetails(firstAssigneeId);
          } else {
            // Clear seller selection if no assignees
            _selectedSellerIds.clear();
            sellerNameController.clear();
          }

          print('✅ Auto-filled customer data for: ${customer.name}');
        }
      } else {
        // Clear customer information
        customerAddressController.clear();
        customerPostalCodeController.clear();
        customerNationalIdController.clear();
        customerPhoneController.clear();
        customerEmailController.clear();
        
        // Clear seller selection
        _selectedSellerIds.clear();
        sellerNameController.clear();
      }

      // Force update to refresh UI validation
      update();
    } catch (e) {
      print('❌ Failed to change customer: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนลูกค้าได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void onCompanyChanged(String? companyId) {
    try {
      _selectedCompanyId = companyId;

      // Auto-fill company information if company is selected
      if (companyId != null) {
        final companyData = selectedCompanyData;
        if (companyData != null) {
          // You can add company-specific auto-fill logic here
          // For example, if you have company address, tax ID, etc.
          print('✅ Selected company: ${getCompanyDisplayName(companyData)}');
        }
      }

      update();
    } catch (e) {
      print('❌ Failed to change company: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนบริษัทได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Seller/Assignee section methods
  void onSellerAssigneesChanged(List<String> assigneeIds) {
    try {
      _selectedSellerIds = assigneeIds;
      
      if (assigneeIds.isNotEmpty) {
        final assigneeId = assigneeIds.first;
        final assignee = _availableAssignees.firstWhereOrNull((a) => a.uid == assigneeId);
        if (assignee != null) {
          sellerNameController.text = assignee.displayName;
          // Note: phone number would need to be loaded separately from user data
        }
      } else {
        sellerNameController.clear();
        sellerPhoneController.clear();
      }
      
      update();
    } catch (e) {
      print('❌ Failed to change seller assignees: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนผู้ขายได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Load assignee details from workspace members
  Future<void> _loadAssigneeDetails(String assigneeId) async {
    try {
      if (_currentWorkspaceId == null) return;
      
      // Load workspace members if not already loaded
      if (_availableAssignees.isEmpty) {
        await _loadWorkspaceMembers();
      }
      
      // Find the assignee in available members
      final assignee = _availableAssignees.firstWhereOrNull((a) => a.uid == assigneeId);
      if (assignee != null) {
        sellerNameController.text = assignee.displayName;
        // Note: phone number would need to be loaded separately from user data
      }
    } catch (e) {
      print('❌ Failed to load assignee details: $e');
    }
  }

  // Load workspace members for assignee selection
  Future<void> _loadWorkspaceMembers() async {
    try {
      if (_currentWorkspaceId == null) return;
      
      _setAssigneesLoading(true);
      
      // Load actual workspace members from the service
      final workspaceMembersService = Get.find<WorkspaceMembersService>();
      _availableAssignees = await workspaceMembersService.getWorkspaceMembers(_currentWorkspaceId!);
      
      print('✅ Loaded ${_availableAssignees.length} workspace members');
      
      _setAssigneesLoading(false);
      update();
    } catch (e) {
      _setAssigneesLoading(false);
      print('❌ Failed to load workspace members: $e');
    }
  }

  void _setAssigneesLoading(bool loading) {
    _isLoadingAssignees = loading;
  }
  
  // Load products from database
  Future<void> loadProducts() async {
    try {
      if (_currentWorkspaceId == null) return;
      
      _setProductsLoading(true);
      
      // Load products from Firebase path: workspaces/{WorkspaceId}/products/{Product UIDs}
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(_currentWorkspaceId)
          .collection('products')
          .get();
      
      if (productsSnapshot.docs.isNotEmpty) {
        _availableProducts = productsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name']?.toString() ?? '',
            'description': data['description']?.toString() ?? '',
            'price': data['price']?.toDouble() ?? 0.0,
            'unit': data['unit']?.toString() ?? 'ชิ้น',
            'sku': data['sku']?.toString() ?? '',
            'imageUrl': data['imageUrl']?.toString() ?? '',
            'status': data['status']?.toString() ?? '',
          };
        }).toList();
        
        print('✅ Loaded ${_availableProducts.length} products from Firebase');
      } else {
        print('⚠️ No active products found in workspace: $_currentWorkspaceId');
        _availableProducts = [];
      }
      
      update();
    } catch (e) {
      print('❌ Failed to load products: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถโหลดข้อมูลสินค้าได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _availableProducts = [];
    } finally {
      _setProductsLoading(false);
    }
  }
  
  void _setProductsLoading(bool loading) {
    _isLoadingProducts = loading;
    update();
  }

  // Seller section methods
  void onDocumentDateChanged(DateTime? date) {
    try {
      _documentDate = date;
      update();
    } catch (e) {
      print('❌ Failed to change document date: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนวันที่เอกสารได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void onValidUntilDateChanged(DateTime? date) {
    try {
      _validUntilDate = date;
      update();
    } catch (e) {
      print('❌ Failed to change valid until date: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนวันที่ยืนราคาได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }



  void addProduct() {
    try {
      // Check if previous product has required fields filled
      if (_products.isNotEmpty) {
        final lastProductIndex = _products.length - 1;
        if (!_isProductComplete(lastProductIndex)) {
          Get.snackbar(
            'คำเตือน',
            'กรุณากรอกข้อมูลสินค้าปัจจุบันให้ครบถ้วนก่อนเพิ่มสินค้าใหม่',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }
      }

      final productId = DateTime.now().millisecondsSinceEpoch.toString();
      final product = {
        'id': productId,
        'name': '',
        'description': '',
        'quantity': 1,
        'unit': 'ชิ้น',
        'pricePerUnit': 0.0,
        'discount': 0.0,
      };

      _products.add(product);

      // Create controllers for this product
      _productControllers[productId] = {
        'name': TextEditingController(),
        'description': TextEditingController(),
        'quantity': TextEditingController(text: '1'),
        'unit': TextEditingController(text: 'ชิ้น'),
        'pricePerUnit': TextEditingController(text: '0'),
        'discount': TextEditingController(text: '0'),
      };

      // Add listeners to all required field controllers for real-time validation
      _addProductControllerListeners(productId);

      update();
    } catch (e) {
      print('❌ Failed to add product: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเพิ่มสินค้าได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Add listeners to product controllers for real-time validation
  void _addProductControllerListeners(String productId) {
    try {
      final controllers = _productControllers[productId];
      if (controllers == null) return;

      // Add listeners to required fields
      controllers['name']?.addListener(() => update());
      controllers['quantity']?.addListener(() => update());
      controllers['unit']?.addListener(() => update());
      controllers['pricePerUnit']?.addListener(() => update());
    } catch (e) {
      print('❌ Failed to add product controller listeners: $e');
    }
  }

  // Check if a product has all required fields filled
  bool _isProductComplete(int index) {
    try {
      if (index < 0 || index >= _products.length) return false;
      
      final productId = _products[index]['id'];
      if (!_productControllers.containsKey(productId)) return false;
      
      final controllers = _productControllers[productId]!;
      
      // Required fields: name, quantity, unit, pricePerUnit
      final name = controllers['name']?.text.trim() ?? '';
      final quantity = controllers['quantity']?.text.trim() ?? '';
      final unit = controllers['unit']?.text.trim() ?? '';
      final pricePerUnit = controllers['pricePerUnit']?.text.trim() ?? '';
      
      // Check if all required fields are filled
      if (name.isEmpty || quantity.isEmpty || unit.isEmpty || pricePerUnit.isEmpty) {
        return false;
      }
      
      // Check if quantity and price are valid numbers
      final quantityValue = double.tryParse(quantity);
      final priceValue = double.tryParse(pricePerUnit);
      
      if (quantityValue == null || priceValue == null || quantityValue <= 0 || priceValue < 0) {
        return false;
      }
      
      return true;
    } catch (e) {
      print('❌ Failed to check product completion: $e');
      return false;
    }
  }

  // Check if all products have required fields filled
  bool get areAllProductsComplete {
    try {
      if (_products.isEmpty) return true; // No products means complete
      
      for (int i = 0; i < _products.length; i++) {
        if (!_isProductComplete(i)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      print('❌ Failed to check all products completion: $e');
      return false;
    }
  }

  // Add products from database selection
  void addProductsFromDatabase(List<Map<String, dynamic>> selectedProducts) {
    try {
      for (final product in selectedProducts) {
        final productId = DateTime.now().millisecondsSinceEpoch.toString();
        final newProduct = {
          'id': productId,
          'name': product['name'] ?? '',
          'description': product['description'] ?? '',
          'quantity': 1,
          'unit': product['unit'] ?? 'ชิ้น',
          'pricePerUnit': (product['price'] ?? 0.0).toDouble(),
          'discount': 0.0,
        };

        _products.add(newProduct);

        // Create controllers for this product
        _productControllers[productId] = {
          'name': TextEditingController(text: newProduct['name']),
          'description': TextEditingController(text: newProduct['description']),
          'quantity': TextEditingController(text: '1'),
          'unit': TextEditingController(text: newProduct['unit']),
          'pricePerUnit': TextEditingController(text: newProduct['pricePerUnit'].toString()),
          'discount': TextEditingController(text: '0'),
        };

        // Add listeners to all required field controllers for real-time validation
        _addProductControllerListeners(productId);
      }

      update();
      
      Get.snackbar(
        'สำเร็จ',
        'เพิ่มสินค้า ${selectedProducts.length} รายการแล้ว',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Failed to add products from database: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเพิ่มสินค้าจากฐานข้อมูลได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }



  void removeProduct(int index) {
    try {
      if (index >= 0 && index < _products.length) {
        final product = _products[index];
        final productId = product['id'];

        // Dispose controllers
        if (_productControllers.containsKey(productId)) {
          for (final controller in _productControllers[productId]!.values) {
            controller.dispose();
          }
          _productControllers.remove(productId);
        }

        _products.removeAt(index);
        update();
      }
    } catch (e) {
      print('❌ Failed to remove product: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถลบสินค้าได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  TextEditingController getProductController(int index, String field) {
    try {
      if (index >= 0 && index < _products.length) {
        final productId = _products[index]['id'];
        if (_productControllers.containsKey(productId)) {
          return _productControllers[productId]![field] ??
              TextEditingController();
        }
      }
      return TextEditingController();
    } catch (e) {
      print('❌ Failed to get product controller: $e');
      return TextEditingController();
    }
  }

  // More options section methods
  void onPaymentMethodsChanged(List<String> methods) {
    try {
      _selectedPaymentMethods = methods;
      update();
    } catch (e) {
      print('❌ Failed to change payment methods: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนช่องทางการชำระเงินได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void onIncludeSignatureChanged(bool? value) {
    try {
      if (value != null) {
        _includeSignature = value;
        update();
      }
    } catch (e) {
      print('❌ Failed to change signature inclusion: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนการรวมลายเซ็นได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Summary section methods
  void onVatEnabledChanged(bool? value) {
    try {
      if (value != null) {
        _isVatEnabled = value;
        update();
      }
    } catch (e) {
      print('❌ Failed to change VAT enabled: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนการเปิดใช้งาน VAT ได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void onWhtEnabledChanged(bool? value) {
    try {
      if (value != null) {
        _isWhtEnabled = value;
        update();
      }
    } catch (e) {
      print('❌ Failed to change WHT enabled: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนการเปิดใช้งาน WHT ได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Document status methods
  void onDocumentStatusChanged(String? status) {
    try {
      if (status != null) {
        _documentStatus = status;
        update();
      }
    } catch (e) {
      print('❌ Failed to change document status: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนสถานะเอกสารได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Calculation methods
  double get subtotal {
    try {
      return _products.fold(0.0, (sum, product) {
        final quantity =
            double.tryParse(
              getProductController(_products.indexOf(product), 'quantity').text,
            ) ??
            0;
        final pricePerUnit =
            double.tryParse(
              getProductController(
                _products.indexOf(product),
                'pricePerUnit',
              ).text,
            ) ??
            0;
        return sum + (quantity * pricePerUnit);
      });
    } catch (e) {
      print('❌ Failed to calculate subtotal: $e');
      return 0.0;
    }
  }

  double get totalDiscount {
    try {
      return _products.fold(0.0, (sum, product) {
        final discount =
            double.tryParse(
              getProductController(_products.indexOf(product), 'discount').text,
            ) ??
            0;
        return sum + discount;
      });
    } catch (e) {
      print('❌ Failed to calculate total discount: $e');
      return 0.0;
    }
  }

  double get afterDiscount => subtotal - totalDiscount;

  double get vatAmount => _isVatEnabled ? afterDiscount * 0.07 : 0.0;

  double get afterVat => afterDiscount + vatAmount;

  double get whtAmount {
    try {
      if (!_isWhtEnabled) return 0.0;
      final percentage = double.tryParse(whtPercentageController.text) ?? 3.0;
      return afterVat * (percentage / 100);
    } catch (e) {
      print('❌ Failed to calculate WHT amount: $e');
      return 0.0;
    }
  }

  double get netTotal => afterVat - whtAmount;

  // Validate customer data
  bool get isCustomerDataValid {
    if (_selectedCustomerId == null) return false;

    final customer = selectedCustomer;
    if (customer == null) return false;

    // Check if customer has required information
    if (customer.name.isEmpty) return false;

    return true;
  }

  // Get customer statistics
  Map<String, dynamic> get customerStats {
    final totalCustomers = _customers.length;
    final customersWithCompanies = _customers
        .where((c) => c.companyNames.isNotEmpty)
        .length;
    final customersWithPhones = _customers
        .where((c) => c.phones.isNotEmpty)
        .length;
    final customersWithEmails = _customers
        .where((c) => c.emails.isNotEmpty)
        .length;

    return {
      'total': totalCustomers,
      'withCompanies': customersWithCompanies,
      'withPhones': customersWithPhones,
      'withEmails': customersWithEmails,
    };
  }

  // Save quotation
  Future<void> saveQuotation() async {
    try {
      _setLoading(true);

      // Validate required fields
      if (!isCustomerDataValid) {
        Get.snackbar(
          'ข้อผิดพลาด',
          'กรุณาเลือกลูกค้าที่มีข้อมูลครบถ้วน',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Check if all products have required fields filled
      if (_products.isNotEmpty && !areAllProductsComplete) {
        Get.snackbar(
          'ข้อผิดพลาด',
          'กรุณากรอกข้อมูลสินค้าทั้งหมดให้ครบถ้วน (ชื่อ, จำนวน, หน่วย, ราคา)',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      if (_currentWorkspaceId == null || _currentUserId == null) {
        Get.snackbar(
          'ข้อผิดพลาด',
          'ไม่สามารถระบุผู้ใช้หรือเวิร์กสเปซได้',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Generate document number for new quotations
      String? docNo;
      if (quotationId == null) {
        try {
          final idService = Get.find<IdGenerationService>();
          docNo = await idService.generateQuotationDocNo(_currentWorkspaceId!);
          print('📝 Generated document number: $docNo');
        } catch (e) {
          print('❌ Failed to generate document number: $e');
          // Fallback to timestamp-based number
          docNo = 'QT-${DateTime.now().millisecondsSinceEpoch}';
        }
      }

            // Prepare quotation data
      final quotationData = {
        'type': 'QT',
        'docNo': docNo ?? 'QT-${DateTime.now().millisecondsSinceEpoch}', // Use generated number or fallback
        'status': _documentStatus,
                'invoiceType': 'full', // Add invoice type field for future use
        'installmentNumber': 1, // Add installment number field
        'totalInstallments': 1, // Add total installments field
        'totalAmountFromQuotation': netTotal, // Add total amount from quotation field
        'customerId': _selectedCustomerId,
        'companyId': _selectedCompanyId,
        'customerAddress': customerAddressController.text,
        'customerPostalCode': customerPostalCodeController.text,
        'customerNationalId': customerNationalIdController.text,
        'customerPhone': customerPhoneController.text,
        'customerEmail': customerEmailController.text,
        'customer': selectedCustomer != null ? {
          'id': selectedCustomer!.id,
          'address': customerAddressController.text,
          'updatedBy': _currentUserId!,
          'gender': 'Unknown',
                  'hashtags': [
          {
            'id': 'quotation',
            'text': 'ใบเสนอราคา',
            'color': '#3b82f6',
          },
        ],
        'prefix': '',
        'phones': customerPhoneController.text.isNotEmpty ? [
          {
            'value': customerPhoneController.text,
            'id': 'phone-${DateTime.now().millisecondsSinceEpoch}',
            'label': 'Main',
          },
        ] : [],
          'assignees': _selectedSellerIds,
          'customId': selectedCustomer!.customId,
          'emails': customerEmailController.text.isNotEmpty ? [
            {
              'value': customerEmailController.text,
              'id': 'email-${DateTime.now().millisecondsSinceEpoch}',
              'label': 'Main',
            },
          ] : [],
          'createdAt': selectedCustomer!.createdAt,
          'customerType': 'Customer',
          'nationalId': customerNationalIdController.text,
          'createdBy': _currentUserId!,
          'name': selectedCustomer!.name,
          'age': 'Unknown',
          'workspaceId': _currentWorkspaceId!,
          'source': '',
          'companyNames': selectedCustomer!.companyNames,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'customFields': [],
          'customerInterest': 'medium', // Add customer interest field
        } : null,
        'boardName': 'Quotations Board', // Add board name field
        'lane': 'Draft', // Add lane field
        'priority': 'medium', // Add priority field
        'dueDate': _validUntilDate?.millisecondsSinceEpoch, // Add due date field
        'todos': [], // Add todos field
        'description': notesController.text, // Add description field
        'title': 'ใบเสนอราคา - ${selectedCustomer?.name ?? 'ลูกค้าใหม่'}', // Add title field
        'customId': docNo ?? 'QT-${DateTime.now().millisecondsSinceEpoch}', // Add custom ID field
        'sellerName': sellerNameController.text,
        'sellerPhone': sellerPhoneController.text,
        'seller': _selectedSellerIds.isNotEmpty ? {
          'uid': _selectedSellerIds.first,
          'email': 'user@example.com', // TODO: Get actual user email
          'photoURL': null,
          'language': 'en',
          'workspaces': [
            {
              'id': _currentWorkspaceId!,
              'name': 'Workspace', // TODO: Get actual workspace name
              'role': 'member',
            },
          ],
                  'viewSettings': {
          'customerProfileCardsConfig_${_currentWorkspaceId}': {
            'customId': {
              'order': 0,
              'isVisible': true,
            },
            'title': {
              'order': 1,
              'isVisible': true,
            },
            'boardName': {
              'order': 2,
              'isVisible': true,
            },
            'status': {
              'order': 3,
              'isVisible': true,
            },
            'lane': {
              'order': 4,
              'isVisible': true,
            },
            'dueDate': {
              'order': 5,
              'isVisible': true,
            },
            'assignee': {
              'order': 6,
              'isVisible': true,
            },
            'customerInterest': {
              'order': 7,
              'isVisible': true,
            },
            'customer': {
              'order': 8,
              'isVisible': true,
            },
            'company': {
              'order': 9,
              'isVisible': true,
            },
            'hashtags': {
              'order': 10,
              'isVisible': true,
            },
            'priority': {
              'order': 11,
              'isVisible': true,
            },
            'grandTotal': {
              'order': 12,
              'isVisible': true,
            },
            'netTotal': {
              'order': 13,
              'isVisible': true,
            },
            'totalAmountBeforeDiscount': {
              'order': 14,
              'isVisible': true,
            },
            'totalAmountAfterDiscount': {
              'order': 15,
              'isVisible': true,
            },
            'totalAmountBeforeVat': {
              'order': 16,
              'isVisible': true,
            },
            'description': {
              'order': 17,
              'isVisible': true,
            },
            'todos': {
              'order': 18,
              'isVisible': true,
            },
          },
        },
        'displayName': sellerNameController.text,
          'lastDeviceId': 'Unknown',
          'lastPlatform': 'android',
          'fcmToken': '',
          'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
          'customId': '',
          'lastActiveWorkspaceId': _currentWorkspaceId!,
          'phoneNumber': sellerPhoneController.text,
          'docPhoneNumber': sellerPhoneController.text,
          'docDisplayName': sellerNameController.text,
                  'notificationSettings': {
          'quietHours': {
            'enabled': false,
            'startTime': '22:00',
            'endTime': '08:00',
            'days': [1, 2, 3, 4, 5, 6, 7],
          },
          'onComment': {
            'enabled': true,
            'web': true,
            'mobilePush': true,
            'email': 'off',
          },
          'onStatusChange': {
            'enabled': true,
            'email': 'off',
            'mobilePush': true,
            'web': true,
          },
          'onDueDateReminder': {
            'enabled': true,
            'notifyAtTime': '09:00',
            'email': 'off',
            'web': true,
            'mobilePush': true,
          },
          'onTodoReminder': {
            'enabled': true,
            'remindBeforeMinutes': 15,
            'mobilePush': true,
            'web': true,
            'email': 'off',
          },
          'onCardAssignment': {
            'enabled': true,
            'mobilePush': false,
            'web': true,
            'email': 'off',
          },
          'onTagged': {
            'enabled': true,
            'web': true,
            'mobilePush': true,
            'email': 'off',
          },
          'onApprovalRequest': {
            'enabled': true,
            'mobilePush': true,
            'web': true,
            'email': 'off',
          },
          'onApprovalDecision': {
            'enabled': true,
            'web': true,
            'mobilePush': true,
            'email': 'off',
          },
          'onNewChatReceived': {
            'enabled': true,
            'email': 'off',
            'web': true,
            'mobilePush': true,
          },
          'onChatAssigned': {
            'enabled': true,
            'email': 'off',
            'web': true,
            'mobilePush': true,
          },
          'onAddedToWorkspace': {
            'enabled': true,
            'web': true,
            'mobilePush': true,
            'email': 'off',
          },
          'digestSettings': {
            'frequency': 'daily',
          },
        },
        'role': 'member',
        'updatedAt': DateTime.now().toIso8601String(),
        } : null,
        'jobName': jobNameController.text,
        'refId': refIdController.text,
        'documentDate': _documentDate?.millisecondsSinceEpoch,
        'validUntil': _validUntilDate?.millisecondsSinceEpoch,
        'dueDate': _validUntilDate?.millisecondsSinceEpoch, // Use validUntil as dueDate
        'project': {
          'name': jobNameController.text,
          'refId': refIdController.text,
          'company': selectedCompanyData != null ? {
            'id': selectedCompanyData!['id'],
            'name': selectedCompanyData!['name'] ?? selectedCompanyData!['value'] ?? '',
          } : null,
        },
        'products': _products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return {
            'id': product['id'],
            'name': getProductController(index, 'name').text,
            'description': getProductController(index, 'description').text,
            'quantity':
                double.tryParse(getProductController(index, 'quantity').text) ??
                0,
            'unit': getProductController(index, 'unit').text,
            'pricePerUnit':
                double.tryParse(
                  getProductController(index, 'pricePerUnit').text,
                ) ??
                0,
            'discount':
                double.tryParse(getProductController(index, 'discount').text) ??
                0,
          };
        }).toList(),
        'items': _products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          return {
            'id': product['id'],
            'name': getProductController(index, 'name').text,
            'description': getProductController(index, 'description').text,
            'quantity':
                double.tryParse(getProductController(index, 'quantity').text) ??
                0,
            'unit': getProductController(index, 'unit').text,
            'pricePerUnit':
                double.tryParse(
                  getProductController(index, 'pricePerUnit').text,
                ) ??
                0,
            'discount':
                double.tryParse(getProductController(index, 'discount').text) ??
                0,
          };
        }).toList(),
        'paymentMethods': _selectedPaymentMethods,
        'paymentStatus': 'unpaid', // Add payment status field
        'receiptFor': 'invoice', // Add receipt for field
        'paymentDate': DateTime.now().millisecondsSinceEpoch, // Add payment date field
        'notes': notesController.text,
        'includeSignature': _includeSignature,
        'signatureAssignments': {}, // TODO: Add signature assignments if needed
        'relatedDocuments': [], // Add related documents field
        'isVatEnabled': _isVatEnabled,
        'isWhtEnabled': _isWhtEnabled,
        'whtPercentage': double.tryParse(whtPercentageController.text) ?? 3.0,
        'withholdingTaxPercentage': double.tryParse(whtPercentageController.text) ?? 3.0, // Add withholdingTaxPercentage field
        'subtotal': subtotal,
        'totalAmountBeforeDiscount': subtotal, // Add totalAmountBeforeDiscount field
        'totalDiscount': totalDiscount,
        'discount': totalDiscount, // Add discount field (alias for totalDiscount)
        'afterDiscount': afterDiscount,
        'totalAmountAfterDiscount': afterDiscount, // Add totalAmountAfterDiscount field
        'shippingCost': 0.0, // TODO: Add shipping cost field if needed
        'depositAmount': 0.0, // TODO: Add deposit amount field if needed
        'deductedDeposit': 0.0, // TODO: Add deducted deposit field if needed
        'vatAmount': vatAmount,
        'totalAmountBeforeVat': afterDiscount, // Add totalAmountBeforeVat field
        'afterVat': afterVat,
        'whtAmount': whtAmount,
        'netTotal': netTotal,
        'grandTotal': netTotal, // Add grandTotal field
        'whtPercentage': double.tryParse(whtPercentageController.text) ?? 3.0, // Add whtPercentage field
        'workspaceId': _currentWorkspaceId!,
        'createdBy': _currentUserId!,
        'updatedBy': _currentUserId!,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'activityLog': [
          {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'userId': _currentUserId!,
            'userDisplayName': 'User', // TODO: Get actual user display name
            'action': quotationId != null ? 'Updated' : 'Created',
            'details': quotationId != null 
                ? 'Updated quotation ${quotationId}' 
                : 'Created quotation ${docNo ?? 'QT-${DateTime.now().millisecondsSinceEpoch}'}',
          },
        ],
        'company': selectedCompanyData != null ? {
          'associatedCustomerIds': [selectedCustomer!.id],
          'branch': '',
          'emails': customerEmailController.text.isNotEmpty ? [
            {
              'value': customerEmailController.text,
              'id': 'email-${DateTime.now().millisecondsSinceEpoch}',
              'label': 'Main',
            },
          ] : [],
          'website': '',
          'district': '',
          'postalCode': customerPostalCodeController.text,
                  'hashtags': [
          {
            'id': 'company',
            'text': 'บริษัท',
            'color': '#10b981',
          },
        ],
        'workspaceId': _currentWorkspaceId!,
        'phones': customerPhoneController.text.isNotEmpty ? [
          {
            'value': customerPhoneController.text,
            'id': 'phone-${DateTime.now().millisecondsSinceEpoch}',
            'label': 'Main',
          },
        ] : [],
          'taxId': '',
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'subdistrict': '',
          'province': '',
          'customId': selectedCompanyData!['customId'] ?? '',
          'updatedBy': _currentUserId!,
          'country': '',
          'createdBy': _currentUserId!,
          'id': selectedCompanyData!['id'],
          'addressLine1': customerAddressController.text,
          'name': selectedCompanyData!['name'] ?? selectedCompanyData!['value'] ?? '',
        } : null,
        'jobCardId': refIdController.text.isNotEmpty ? refIdController.text : null, // Use refId as jobCardId if available
        'approval': {
          'status': 'pending',
          'requestedAt': DateTime.now().millisecondsSinceEpoch,
          'requestedBy': _currentUserId!,
        },
        'depositInfo': {
          'amount': 0.0,
          'percentage': 0.0,
          'isRequired': false,
        },
        'invoicingPlan': [],
        'depositDeducted': false,
        'approvers': [], // Add approvers field
      };

      // Save to Firestore
      if (quotationId != null) {
        // Update existing quotation
        await _repository.updateDocument(
          workspaceId: _currentWorkspaceId!,
          documentId: quotationId!,
          documentData: quotationData,
        );
        print('📝 Updated quotation: $quotationId');
      } else {
        // Create new quotation
        final newDocumentId = await _repository.createDocument(
          workspaceId: _currentWorkspaceId!,
          documentData: quotationData,
        );
        print('📝 Created new quotation with ID: $newDocumentId');
      }

      Get.snackbar(
        'สำเร็จ',
        quotationId != null
            ? 'อัปเดตใบเสนอราคาเรียบร้อย'
            : 'สร้างใบเสนอราคาเรียบร้อย',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Get.back();
    } catch (e) {
      print('❌ Failed to save quotation: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถบันทึกใบเสนอราคาได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _setLoading(false);
    }
  }
}
