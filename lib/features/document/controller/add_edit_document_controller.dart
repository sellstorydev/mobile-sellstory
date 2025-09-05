import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sellstory/features/document/view/quotations_list_page.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../domain/entities/customer.dart';
import '../../../core/services/workspace_members_service.dart';
import '../../../core/services/id_generation_service.dart';
import '../view/document_center_page.dart';

class AddEditDocumentController extends GetxController {
  final String? documentId;
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

  // Template section
  List<Map<String, dynamic>> _availableTemplates = [];
  List<Map<String, dynamic>> get availableTemplates => _availableTemplates;
  String? _selectedTemplateId;
  String? get selectedTemplateId => _selectedTemplateId;
  bool _isLoadingTemplates = false;
  bool get isLoadingTemplates => _isLoadingTemplates;
  
  // Dynamic product fields from template
  List<Map<String, dynamic>> _templateProductFields = [];
  List<Map<String, dynamic>> get templateProductFields => _templateProductFields;

  // Signature management
  List<Map<String, dynamic>> _availableSignatures = [];
  List<Map<String, dynamic>> get availableSignatures => _availableSignatures;

  bool _isLoadingSignatures = false;
  bool get isLoadingSignatures => _isLoadingSignatures;

  Map<String, String> _selectedSignatures = {}; // signatureRoleName -> signatureId
  Map<String, String> get selectedSignatures => _selectedSignatures;

  List<Map<String, dynamic>> _templateSignatureFields = [];
  List<Map<String, dynamic>> get templateSignatureFields => _templateSignatureFields;

  // Company seal management
  List<Map<String, dynamic>> _availableCompanySeals = [];
  List<Map<String, dynamic>> get availableCompanySeals => _availableCompanySeals;

  bool _isLoadingCompanySeals = false;
  bool get isLoadingCompanySeals => _isLoadingCompanySeals;

  String? _selectedCompanySealId;
  String? get selectedCompanySealId => _selectedCompanySealId;

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

  // Available document statuses
  List<String> get availableStatuses => [
    'DRAFT',
    'SENT',
    'PENDING_APPROVAL',
    'APPROVED',
    'REJECTED',
    'VOID',
    'INVOICED',
    'FULLY_PAID',
    'PARTIAL_PAID',
    'PAID',
    'OVERDUE',
  ];

  // Summary section
  bool _isVatEnabled = false;
  bool get isVatEnabled => _isVatEnabled;

  bool _isWhtEnabled = false;
  bool get isWhtEnabled => _isWhtEnabled;

  bool _isEndOfBillDiscountEnabled = false;
  bool get isEndOfBillDiscountEnabled => _isEndOfBillDiscountEnabled;

  final TextEditingController whtPercentageController = TextEditingController();
  final TextEditingController endOfBillDiscountController = TextEditingController();

  // Product controllers map
  final Map<String, Map<String, TextEditingController>> _productControllers =
      {};

  AddEditDocumentController({this.documentId});

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
    endOfBillDiscountController.dispose();

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
      print('👤 Initializing document page with user: $_currentUserId');

      // Get user's workspaces
      print('📋 Fetching user workspaces...');
      final workspaces = await _repository.getUserWorkspaces(_currentUserId!);

      print('📋 User workspaces loaded: ${workspaces.length} workspaces');

      if (workspaces.isNotEmpty) {
        // Use the first workspace as default
        final firstWorkspace = workspaces.first;
        _currentWorkspaceId = firstWorkspace['id'] as String;

        print(
          '✅ Document page initialized with workspace: ${firstWorkspace['name']}',
        );

        // Load customers, workspace members, products, and templates, then initialize form
        await _loadCustomers();
        await _loadWorkspaceMembers();
        await loadProducts();
        await loadTemplates();
        await loadSignatures();
        await loadCompanySeals();
        
        // If editing existing document, load its data
        if (documentId != null) {
          await loadExistingDocument();
        } else {
          _initializeForm();
        }
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
      
      // Initialize default product fields
      _resetToDefaultProductFields();

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

  // Load templates from database
  Future<void> loadTemplates() async {
    try {
      if (_currentWorkspaceId == null) return;
      
      _setTemplatesLoading(true);
      
      // Load templates from Firebase path: workspaces/{WorkspaceId}/quotationTemplates/{Template UIDs}
      final templatesSnapshot = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(_currentWorkspaceId)
          .collection('quotationTemplates')
          .get();
      
      if (templatesSnapshot.docs.isNotEmpty) {
        _availableTemplates = templatesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name']?.toString() ?? 'Unknown Template',
            'description': data['description']?.toString() ?? '',
            'createdAt': data['createdAt'],
            'updatedAt': data['updatedAt'],
            'fullData': data, // Store full template data for field extraction
          };
        }).toList();
        
        print('✅ Loaded ${_availableTemplates.length} templates from Firebase');
      } else {
        print('⚠️ No templates found in workspace: $_currentWorkspaceId');
        _availableTemplates = [];
      }
      
      update();
    } catch (e) {
      print('❌ Failed to load templates: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถโหลดข้อมูลเทมเพลตได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _availableTemplates = [];
    } finally {
      _setTemplatesLoading(false);
    }
  }
  
  void _setTemplatesLoading(bool loading) {
    _isLoadingTemplates = loading;
    update();
  }

  // Load signatures from company profile
  Future<void> loadSignatures() async {
    try {
      if (_currentWorkspaceId == null) return;
      
      _setSignaturesLoading(true);
      
      // Load signatures from Firebase path: workspaces/{WorkspaceId}/companyProfile.docSettings.signatures
      final workspaceDoc = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(_currentWorkspaceId)
          .get();
      
      if (workspaceDoc.exists) {
        final workspaceData = workspaceDoc.data();
        final companyProfile = workspaceData?['companyProfile'] as Map<String, dynamic>?;
        final docSettings = companyProfile?['docSettings'] as Map<String, dynamic>?;
        final signatures = docSettings?['signatures'] as List<dynamic>?;
        
        if (signatures != null && signatures.isNotEmpty) {
          _availableSignatures = signatures.map((signature) {
            if (signature is Map<String, dynamic>) {
              return {
                'id': signature['id']?.toString() ?? '',
                'name': signature['name']?.toString() ?? '',
                'ownerName': signature['ownerName']?.toString() ?? '',
                'position': signature['position']?.toString() ?? '',
                'url': signature['url']?.toString() ?? '',
              };
            }
            return <String, dynamic>{};
          }).where((signature) => signature.isNotEmpty).toList();
          
          print('✅ Loaded ${_availableSignatures.length} signatures from workspace profile');
        } else {
          print('⚠️ No signatures found in workspace profile: $_currentWorkspaceId');
          _availableSignatures = [];
        }
      } else {
        print('⚠️ Workspace document not found: $_currentWorkspaceId');
        _availableSignatures = [];
      }
      
      update();
    } catch (e) {
      print('❌ Failed to load signatures: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถโหลดข้อมูลลายเซ็นได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _availableSignatures = [];
    } finally {
      _setSignaturesLoading(false);
    }
  }
  
  void _setSignaturesLoading(bool loading) {
    _isLoadingSignatures = loading;
    update();
  }

  // Load company seals from workspace profile
  Future<void> loadCompanySeals() async {
    try {
      if (_currentWorkspaceId == null) return;
      _setCompanySealsLoading(true);
      final workspaceDoc = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(_currentWorkspaceId)
          .get();
      if (workspaceDoc.exists) {
        final workspaceData = workspaceDoc.data();
        final companyProfile = workspaceData?['companyProfile'] as Map<String, dynamic>?;
        final docSettings = companyProfile?['docSettings'] as Map<String, dynamic>?;
        final companySeals = docSettings?['companySeals'] as List<dynamic>?;
        if (companySeals != null && companySeals.isNotEmpty) {
          _availableCompanySeals = companySeals.map((seal) {
            if (seal is Map<String, dynamic>) {
              return {
                'id': seal['id']?.toString() ?? '',
                'name': seal['name']?.toString() ?? '',
                'ownerName': seal['ownerName']?.toString() ?? '',
                'position': seal['position']?.toString() ?? '',
                'url': seal['url']?.toString() ?? '',
              };
            }
            return <String, dynamic>{};
          }).where((seal) => seal.isNotEmpty).toList();
          print('✅ Loaded ${_availableCompanySeals.length} company seals from workspace profile');
        } else {
          print('⚠️ No company seals found in workspace profile: $_currentWorkspaceId');
          _availableCompanySeals = [];
        }
      } else {
        print('⚠️ Workspace document not found: $_currentWorkspaceId');
        _availableCompanySeals = [];
      }
      update();
    } catch (e) {
      print('❌ Failed to load company seals: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถโหลดข้อมูลตรายางบริษัทได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      _availableCompanySeals = [];
    } finally {
      _setCompanySealsLoading(false);
    }
  }

  // Handle signature selection
  void onSignatureChanged(String signatureRoleName, String? signatureId) {
    try {
      if (signatureId != null) {
        _selectedSignatures[signatureRoleName] = signatureId;
        print('✅ Selected signature for role $signatureRoleName: $signatureId');
      } else {
        _selectedSignatures.remove(signatureRoleName);
        print('ℹ️ Removed signature for role $signatureRoleName');
      }
      update();
    } catch (e) {
      print('❌ Failed to change signature: $e');
    }
  }

  // Build signature assignments map for saving to database
  Map<String, String> _buildSignatureAssignments() {
    final Map<String, String> assignments = {};
    
    // Map each template signature field to its selected signature
    for (final signatureField in _templateSignatureFields) {
      final componentId = signatureField['id'] as String?;
      final roleName = signatureField['signatureRoleName'] as String?;
      
      if (componentId != null && roleName != null) {
        final selectedSignatureId = _selectedSignatures[roleName];
        if (selectedSignatureId != null) {
          assignments[componentId] = selectedSignatureId;
          print('✅ Mapping signature component $componentId to signature $selectedSignatureId');
        }
      }
    }
    
    print('📋 Final signature assignments: $assignments');
    return assignments;
  }

  // Company seal methods
  void _setCompanySealsLoading(bool loading) {
    _isLoadingCompanySeals = loading;
    update();
  }

  // Handle company seal selection
  void onCompanySealChanged(String? sealId) {
    try {
      _selectedCompanySealId = sealId;
      print('✅ Selected company seal: $sealId');
      update();
    } catch (e) {
      print('❌ Failed to change company seal: $e');
    }
  }

  // Load existing document data for editing
  Future<void> loadExistingDocument() async {
    try {
      if (documentId == null || _currentWorkspaceId == null) return;
      
      print('📋 Loading existing document: $documentId');
      _setLoading(true);
      
      final documentDoc = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(_currentWorkspaceId)
          .collection('documents')
          .doc(documentId)
          .get();
      
      if (!documentDoc.exists) {
        print('❌ Document not found: $documentId');
        Get.snackbar(
          'ข้อผิดพลาด',
          'ไม่พบเอกสารที่ต้องการแก้ไข',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
      
      final documentData = documentDoc.data()!;
      print('✅ Document data loaded: ${documentData.keys.toList()}');
      
      // Load basic document info
      await _loadDocumentBasicInfo(documentData);
      
      // Load customer data
      await _loadDocumentCustomerInfo(documentData);
      
      // Load seller data
      await _loadDocumentSellerInfo(documentData);
      
      // Load template first (needed for signatures and products)
      await _loadDocumentTemplate(documentData);
      
      // Load products (after template is loaded)
      await _loadDocumentProducts(documentData);
      
      // Load signatures and company seal (after template is loaded)
      await _loadDocumentSignaturesAndSeal(documentData);
      
      // Initialize form with loaded data
      _initializeForm();
      
      print('✅ Existing document loaded successfully');
      update();
      
    } catch (e) {
      print('❌ Failed to load existing document: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถโหลดข้อมูลเอกสารได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _setLoading(false);
    }
  }

  // Load basic document information
  Future<void> _loadDocumentBasicInfo(Map<String, dynamic> documentData) async {
    try {
      // Document status
      final status = documentData['status']?.toString() ?? 'DRAFT';
      _documentStatus = status;
      
      // Document dates
      final createdAt = documentData['createdAt'];
      if (createdAt != null) {
        _documentDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
      }
      
      final validUntil = documentData['validUntil'];
      if (validUntil != null) {
        _validUntilDate = DateTime.fromMillisecondsSinceEpoch(validUntil);
      }
      
      // Notes
      final notes = documentData['notes']?.toString() ?? '';
      notesController.text = notes;
      
      // Job name and ref ID
      final jobName = documentData['jobName']?.toString() ?? '';
      jobNameController.text = jobName;
      
      final refId = documentData['refId']?.toString() ?? '';
      refIdController.text = refId;
      
      // Payment methods
      final paymentMethods = documentData['paymentMethod'] as List<dynamic>?;
      if (paymentMethods != null) {
        _selectedPaymentMethods = paymentMethods
            .map((method) => method.toString())
            .where((method) => method.isNotEmpty)
            .toList();
      }
      
      // VAT and WHT settings
      final isVatEnabled = documentData['isVatEnabled'] ?? false;
      _isVatEnabled = isVatEnabled;
      
      final isWhtEnabled = documentData['isWhtEnabled'] ?? false;
      _isWhtEnabled = isWhtEnabled;
      
      final whtPercentage = documentData['withholdingTaxPercentage']?.toString() ?? '3.0';
      whtPercentageController.text = whtPercentage;
      
      // End-of-bill discount settings
      final discountAmount = documentData['discount'];
      if (discountAmount != null && discountAmount > 0) {
        _isEndOfBillDiscountEnabled = true;
        endOfBillDiscountController.text = discountAmount.toString();
      }
      
      print('✅ Basic document info loaded');
      
    } catch (e) {
      print('❌ Failed to load basic document info: $e');
    }
  }

  // Load customer information from document
  Future<void> _loadDocumentCustomerInfo(Map<String, dynamic> documentData) async {
    try {
      final customerData = documentData['customer'] as Map<String, dynamic>?;
      if (customerData != null) {
        final customerId = customerData['id']?.toString();
        if (customerId != null) {
          _selectedCustomerId = customerId;
          
          // Load customer details into controllers
          final address = customerData['address']?.toString() ?? '';
          customerAddressController.text = address;
          
          final postalCode = customerData['postalCode']?.toString() ?? '';
          customerPostalCodeController.text = postalCode;
          
          final nationalId = customerData['nationalId']?.toString() ?? '';
          customerNationalIdController.text = nationalId;
          
          // Load customer emails and phones
          final emails = customerData['emails'] as List<dynamic>?;
          if (emails != null && emails.isNotEmpty) {
            final firstEmail = emails.first;
            if (firstEmail is Map<String, dynamic>) {
              final emailValue = firstEmail['value']?.toString() ?? '';
              customerEmailController.text = emailValue;
            }
          }
          
          final phones = customerData['phones'] as List<dynamic>?;
          if (phones != null && phones.isNotEmpty) {
            final firstPhone = phones.first;
            if (firstPhone is Map<String, dynamic>) {
              final phoneValue = firstPhone['value']?.toString() ?? '';
              customerPhoneController.text = phoneValue;
            }
          }
          
          // Load company selection
          final companyData = documentData['company'] as Map<String, dynamic>?;
          if (companyData != null) {
            final companyId = companyData['id']?.toString();
            if (companyId != null) {
              _selectedCompanyId = companyId;
            }
          }
        }
      }
      
      print('✅ Customer info loaded');
      
    } catch (e) {
      print('❌ Failed to load customer info: $e');
    }
  }

  // Load seller information from document
  Future<void> _loadDocumentSellerInfo(Map<String, dynamic> documentData) async {
    try {
      final sellerData = documentData['seller'] as Map<String, dynamic>?;
      if (sellerData != null) {
        final sellerId = sellerData['uid']?.toString();
        if (sellerId != null) {
          _selectedSellerIds = [sellerId];
          
          // Load seller details into controllers
          final displayName = sellerData['displayName']?.toString() ?? '';
          sellerNameController.text = displayName;
          
          final phone = sellerData['docPhoneNumber']?.toString() ?? '';
          sellerPhoneController.text = phone;
        }
      }
      
      print('✅ Seller info loaded');
      
    } catch (e) {
      print('❌ Failed to load seller info: $e');
    }
  }

  // Load products from document
  Future<void> _loadDocumentProducts(Map<String, dynamic> documentData) async {
    try {
      final items = documentData['items'] as List<dynamic>?;
      if (items != null && items.isNotEmpty) {
        _products.clear();
        
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            final product = {
              'id': item['id']?.toString() ?? '',
              'name': item['name']?.toString() ?? '',
              'description': item['description']?.toString() ?? '',
              'quantity': item['quantity']?.toString() ?? '',
              'unit': item['unit']?.toString() ?? '',
              'pricePerUnit': item['pricePerUnit']?.toString() ?? '',
              'discount': item['discount']?.toString() ?? '',
            };
            
            _products.add(product);
          }
        }
        
        // Initialize product controllers for loaded products
        _initializeProductControllers();
        
        print('✅ Products loaded: ${_products.length} items');
      }
      
    } catch (e) {
      print('❌ Failed to load products: $e');
    }
  }

  // Load signatures and company seal from document
  Future<void> _loadDocumentSignaturesAndSeal(Map<String, dynamic> documentData) async {
    try {
      // Load signature assignments
      final signatureAssignments = documentData['signatureAssignments'] as Map<String, dynamic>?;
      if (signatureAssignments != null) {
        _selectedSignatures.clear();
        
        // Map component IDs back to role names
        for (final entry in signatureAssignments.entries) {
          final componentId = entry.key;
          final signatureId = entry.value?.toString();
          
          if (signatureId != null) {
            // Find the role name for this component ID
            for (final signatureField in _templateSignatureFields) {
              if (signatureField['id'] == componentId) {
                final roleName = signatureField['signatureRoleName']?.toString();
                if (roleName != null) {
                  _selectedSignatures[roleName] = signatureId;
                  break;
                }
              }
            }
          }
        }
        
        print('✅ Signature assignments loaded: ${_selectedSignatures.length} roles');
      }
      
      // Load company seal
      final companySealId = documentData['companySealId']?.toString();
      if (companySealId != null) {
        _selectedCompanySealId = companySealId;
        print('✅ Company seal loaded: $companySealId');
      }
      
    } catch (e) {
      print('❌ Failed to load signatures and seal: $e');
    }
  }

  // Load template from document
  Future<void> _loadDocumentTemplate(Map<String, dynamic> documentData) async {
    try {
      final templateId = documentData['templateId']?.toString();
      if (templateId != null) {
        _selectedTemplateId = templateId;
        
        // Find and select the template
        final template = _availableTemplates.firstWhereOrNull(
          (t) => t['id'] == templateId,
        );
        
        if (template != null) {
          // Extract signature fields and product fields from template
          _extractSignatureFieldsFromTemplate(template);
          _extractProductFieldsFromTemplate(template);
          print('✅ Template loaded: ${template['name']}');
        }
      }
      
    } catch (e) {
      print('❌ Failed to load template: $e');
    }
  }

  // Initialize product controllers for existing products
  void _initializeProductControllers() {
    try {
      // Clear existing controllers
      for (final controllers in _productControllers.values) {
        for (final controller in controllers.values) {
          controller.dispose();
        }
      }
      _productControllers.clear();
      
      // Create controllers for each product
      for (int i = 0; i < _products.length; i++) {
        final product = _products[i];
        final controllers = <String, TextEditingController>{};
        
        // Create controllers for each field
        controllers['name'] = TextEditingController(text: product['name'] ?? '');
        controllers['description'] = TextEditingController(text: product['description'] ?? '');
        controllers['quantity'] = TextEditingController(text: product['quantity'] ?? '');
        controllers['unit'] = TextEditingController(text: product['unit'] ?? '');
        controllers['pricePerUnit'] = TextEditingController(text: product['pricePerUnit'] ?? '');
        controllers['discount'] = TextEditingController(text: product['discount'] ?? '');
        
        // Add custom field controllers if template has them
        if (_templateProductFields.isNotEmpty) {
          for (final field in _templateProductFields) {
            final fieldId = field['id']?.toString() ?? '';
            if (fieldId.isNotEmpty && !controllers.containsKey(fieldId)) {
              final fieldValue = product[fieldId]?.toString() ?? '';
              controllers[fieldId] = TextEditingController(text: fieldValue);
            }
          }
        }
        
        _productControllers[i.toString()] = controllers;
      }
      
      print('✅ Product controllers initialized for ${_products.length} products');
      
    } catch (e) {
      print('❌ Failed to initialize product controllers: $e');
    }
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
      // Check if template is selected first
      if (_selectedTemplateId == null || _templateProductFields.isEmpty) {
        Get.snackbar(
          'คำเตือน',
          'กรุณาเลือกเทมเพลตก่อนเพิ่มสินค้า',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      final productId = DateTime.now().millisecondsSinceEpoch.toString();
      final product = {
        'id': productId,
        'name': '',
        'description': '',
        'quantity': 1,
        'unit': 'หน่วย',
        'pricePerUnit': 0.0,
        'discount': 0.0,
      };

      _products.add(product);

      // Create controllers for this product based on template fields
      _createProductControllersFromTemplate(productId);

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

  // Create product controllers based on template fields
  void _createProductControllersFromTemplate(String productId) {
    final controllers = <String, TextEditingController>{};
    
    for (final field in _templateProductFields) {
      final fieldId = field['id']?.toString() ?? '';
      final fieldType = field['type']?.toString() ?? '';
      final sourceField = field['sourceField']?.toString() ?? '';
      final predefinedField = field['predefinedField']?.toString() ?? '';
      
      // Determine the actual field key for the controller
      String controllerKey = fieldId;
      
      if (fieldType == 'product_field' && sourceField.isNotEmpty) {
        // Handle nested custom fields like "customFields.multiply"
        if (sourceField.startsWith('customFields.')) {
          controllerKey = sourceField.replaceFirst('customFields.', '');
        } else {
          controllerKey = sourceField;
        }
      } else if (fieldType == 'predefined' && predefinedField.isNotEmpty) {
        controllerKey = predefinedField;
      } else if (fieldType == 'user_input') {
        controllerKey = fieldId;
      }
      
      // Set default values based on field type
      String defaultValue = '';
      if (controllerKey == 'quantity') {
        defaultValue = '1';
      } else if (controllerKey == 'unit') {
        defaultValue = 'หน่วย';
      } else if (controllerKey == 'pricePerUnit') {
        defaultValue = '0';
      } else if (controllerKey == 'discount') {
        defaultValue = '0';
      } else if (field['inputType'] == 'number') {
        defaultValue = '1'; // Default for numeric custom fields
      }
      
      controllers[controllerKey] = TextEditingController(text: defaultValue);
    }
    
    _productControllers[productId] = controllers;
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
      // Check if template is selected first
      if (_selectedTemplateId == null || _templateProductFields.isEmpty) {
        Get.snackbar(
          'คำเตือน',
          'กรุณาเลือกเทมเพลตก่อนเพิ่มสินค้า',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      for (final product in selectedProducts) {
        final productId = DateTime.now().millisecondsSinceEpoch.toString();
        final newProduct = {
          'id': productId,
          'name': product['name'] ?? '',
          'description': product['description'] ?? '',
          'quantity': 1,
          'unit': product['unit'] ?? 'หน่วย',
          'pricePerUnit': (product['price'] ?? 0.0).toDouble(),
          'discount': 0.0,
        };

        _products.add(newProduct);

        // Create controllers for this product based on template fields
        _createProductControllersFromDatabase(productId, newProduct);

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

  // Create product controllers from database with template field mapping
  void _createProductControllersFromDatabase(String productId, Map<String, dynamic> product) {
    final controllers = <String, TextEditingController>{};
    
    for (final field in _templateProductFields) {
      final fieldId = field['id']?.toString() ?? '';
      final fieldType = field['type']?.toString() ?? '';
      final sourceField = field['sourceField']?.toString() ?? '';
      final predefinedField = field['predefinedField']?.toString() ?? '';
      
      // Determine the actual field key for the controller
      String controllerKey = fieldId;
      
      if (fieldType == 'product_field' && sourceField.isNotEmpty) {
        // Handle nested custom fields like "customFields.multiply"
        if (sourceField.startsWith('customFields.')) {
          controllerKey = sourceField.replaceFirst('customFields.', '');
        } else {
          controllerKey = sourceField;
        }
      } else if (fieldType == 'predefined' && predefinedField.isNotEmpty) {
        controllerKey = predefinedField;
      } else if (fieldType == 'user_input') {
        controllerKey = fieldId;
      }
      
      // Set values from database product or defaults
      String fieldValue = '';
      if (controllerKey == 'name') {
        fieldValue = product['name'] ?? '';
      } else if (controllerKey == 'description') {
        fieldValue = product['description'] ?? '';
      } else if (controllerKey == 'quantity') {
        fieldValue = '1';
      } else if (controllerKey == 'unit') {
        fieldValue = product['unit'] ?? 'หน่วย';
      } else if (controllerKey == 'pricePerUnit') {
        fieldValue = (product['pricePerUnit'] ?? 0.0).toString();
      } else if (controllerKey == 'discount') {
        fieldValue = '0';
      } else {
        // Check if this is a custom field from the database
        final customFields = product['customFields'] as Map<String, dynamic>?;
        if (customFields != null && customFields.containsKey(controllerKey)) {
          fieldValue = customFields[controllerKey].toString();
        } else if (field['inputType'] == 'number') {
          fieldValue = '1'; // Default for numeric custom fields
        }
      }
      
      controllers[controllerKey] = TextEditingController(text: fieldValue);
    }
    
    _productControllers[productId] = controllers;
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

  void onEndOfBillDiscountEnabledChanged(bool? value) {
    try {
      if (value != null) {
        _isEndOfBillDiscountEnabled = value;
        if (!value) {
          endOfBillDiscountController.text = '';
        }
        update();
      }
    } catch (e) {
      print('❌ Failed to change end-of-bill discount enabled: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนการเปิดใช้งานส่วนลดท้ายบิลได้: $e',
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

  // Template methods
  void onTemplateChanged(String? templateId) {
    try {
      _selectedTemplateId = templateId;
      
      if (templateId != null) {
        final template = _availableTemplates.firstWhereOrNull((t) => t['id'] == templateId);
        if (template != null) {
          print('✅ Selected template: ${template['name']}');
          _extractProductFieldsFromTemplate(template);
          _extractSignatureFieldsFromTemplate(template);
        }
      } else {
        print('✅ No template selected');
        _resetToDefaultProductFields();
        _templateSignatureFields.clear();
      }
      
      update();
    } catch (e) {
      print('❌ Failed to change template: $e');
      Get.snackbar(
        'ข้อผิดพลาด',
        'ไม่สามารถเปลี่ยนเทมเพลตได้: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  // Extract product fields from template
  void _extractProductFieldsFromTemplate(Map<String, dynamic> template) {
    try {
      _templateProductFields.clear();
      
      final fullData = template['fullData'] as Map<String, dynamic>?;
      if (fullData == null) {
        print('⚠️ No full template data available');
        _resetToDefaultProductFields();
        return;
      }
      
      final body = fullData['body'] as Map<String, dynamic>?;
      if (body == null) {
        print('⚠️ No body section in template');
        _resetToDefaultProductFields();
        return;
      }
      
      final components = body['components'] as List<dynamic>?;
      if (components == null) {
        print('⚠️ No components in template body');
        _resetToDefaultProductFields();
        return;
      }
      
      // Find the first table component
      Map<String, dynamic>? tableComponent;
      for (final component in components) {
        if (component is Map<String, dynamic> && component['type'] == 'table') {
          tableComponent = component;
          break;
        }
      }
      
      if (tableComponent == null) {
        print('⚠️ No table component found in template');
        _resetToDefaultProductFields();
        return;
      }
      
      final columns = tableComponent['columns'] as List<dynamic>?;
      if (columns == null || columns.isEmpty) {
        print('⚠️ No columns found in table component');
        _resetToDefaultProductFields();
        return;
      }
      
      // Extract product fields from columns
      for (final column in columns) {
        if (column is Map<String, dynamic>) {
          final field = {
            'id': column['id']?.toString() ?? '',
            'label': column['label']?.toString() ?? '',
            'type': column['type']?.toString() ?? '',
            'sourceField': column['sourceField']?.toString() ?? '',
            'predefinedField': column['predefinedField']?.toString() ?? '',
            'formula': column['formula']?.toString() ?? '',
            'isVisible': column['isVisible'] ?? true,
            'isEditable': column['isEditable'] ?? true,
            'order': column['order'] ?? 0,
            'width': column['width']?.toString() ?? '',
            'align': column['align']?.toString() ?? 'left',
            'style': column['style'] ?? {},
          };
          
          _templateProductFields.add(field);
        }
      }
      
      // Sort fields by order
      _templateProductFields.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
      
      print('✅ Extracted ${_templateProductFields.length} product fields from template: ${template['name']}');
      print('📋 Fields: ${_templateProductFields.map((f) => '${f['label']} (${f['type']})').toList()}');
      
    } catch (e) {
      print('❌ Failed to extract product fields from template: $e');
      _resetToDefaultProductFields();
    }
  }

  // Extract signature fields from template
  void _extractSignatureFieldsFromTemplate(Map<String, dynamic> template) {
    try {
      _templateSignatureFields.clear();
      
      final fullData = template['fullData'] as Map<String, dynamic>?;
      if (fullData == null) {
        print('⚠️ No full template data available');
        _templateSignatureFields = [];
        return;
      }
      
      final body = fullData['body'] as Map<String, dynamic>?;
      if (body == null) {
        print('⚠️ No body section in template');
        _templateSignatureFields = [];
        return;
      }
      
      final components = body['components'] as List<dynamic>?;
      if (components == null) {
        print('⚠️ No components in template body');
        _templateSignatureFields = [];
        return;
      }
      
      // Find all components with type 'signature'
      for (final component in components) {
        if (component is Map<String, dynamic> && component['type'] == 'signature') {
          final signatureField = {
            'id': component['id']?.toString() ?? '',
            'signatureRoleName': component['signatureRoleName']?.toString() ?? '',
            'x': component['x'] ?? 0,
            'y': component['y'] ?? 0,
            'width': component['width'] ?? 0,
            'height': component['height'] ?? 0,
            'style': component['style'] ?? {},
          };
          
          _templateSignatureFields.add(signatureField);
        }
      }
      
      print('✅ Extracted ${_templateSignatureFields.length} signature fields from template: ${template['name']}');
      print('📋 Signature roles: ${_templateSignatureFields.map((f) => f['signatureRoleName']).toList()}');
      
    } catch (e) {
      print('❌ Failed to extract signature fields from template: $e');
      _templateSignatureFields = [];
    }
  }
  
  // Reset to default product fields
  void _resetToDefaultProductFields() {
    _templateProductFields = [
      {
        'id': 'name',
        'label': 'ชื่อสินค้า/บริการ',
        'type': 'product_field',
        'sourceField': 'name',
        'isVisible': true,
        'isEditable': true,
        'order': 0,
        'width': '40%',
        'align': 'left',
        'style': {'isBold': true},
      },
      {
        'id': 'quantity',
        'label': 'จำนวน',
        'type': 'predefined',
        'predefinedField': 'quantity',
        'isVisible': true,
        'isEditable': true,
        'order': 1,
        'width': '15%',
        'align': 'center',
        'style': {},
      },
      {
        'id': 'unit',
        'label': 'หน่วย',
        'type': 'predefined',
        'predefinedField': 'unit',
        'isVisible': true,
        'isEditable': true,
        'order': 2,
        'width': '15%',
        'align': 'center',
        'style': {},
      },
      {
        'id': 'pricePerUnit',
        'label': 'ราคา/หน่วย',
        'type': 'product_field',
        'sourceField': 'pricePerUnit',
        'isVisible': true,
        'isEditable': true,
        'order': 3,
        'width': '15%',
        'align': 'right',
        'style': {},
      },
      {
        'id': 'discount',
        'label': 'ส่วนลด',
        'type': 'predefined',
        'predefinedField': 'discount',
        'isVisible': true,
        'isEditable': true,
        'order': 4,
        'width': '15%',
        'align': 'right',
        'style': {},
      },
    ];
    
    print('✅ Reset to default product fields');
  }

  // Calculation methods
  double get subtotal {
    try {
      return _products.fold(0.0, (sum, product) {
        final productIndex = _products.indexOf(product);
        
        // Use template-based calculation for line total
        final lineTotal = calculateProductTotal(productIndex);
        
        return sum + lineTotal;
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

  // End-of-bill discount amount
  double get endOfBillDiscountAmount {
    try {
      if (!_isEndOfBillDiscountEnabled) return 0.0;
      return double.tryParse(endOfBillDiscountController.text) ?? 0.0;
    } catch (e) {
      print('❌ Failed to calculate end-of-bill discount: $e');
      return 0.0;
    }
  }

  double get afterDiscount => subtotal - endOfBillDiscountAmount;

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

  // Calculate individual product total based on template formula
  double calculateProductTotal(int productIndex) {
    try {
      // Find the line_total field with formula in template
      final formulaField = _templateProductFields.firstWhere(
        (field) => field['predefinedField'] == 'line_total' && 
                  field['formula'] != null && 
                  (field['formula'] as String).isNotEmpty,
        orElse: () => {},
      );
      
      if (formulaField.isEmpty) {
        // Default calculation if no formula found
        final quantity = double.tryParse(
          getProductController(productIndex, 'quantity').text,
        ) ?? 0;
        final pricePerUnit = double.tryParse(
          getProductController(productIndex, 'pricePerUnit').text,
        ) ?? 0;
        final discount = double.tryParse(
          getProductController(productIndex, 'discount').text,
        ) ?? 0;
        return (quantity * pricePerUnit) - discount;
      }
      
      // Parse and calculate based on formula
      String formula = formulaField['formula'] as String;
      
      // Get all available product values from controllers
      final productId = _products[productIndex]['id'];
      final controllers = _productControllers[productId] ?? {};
      
      // Replace all possible formula variables with actual values
      for (final entry in controllers.entries) {
        final fieldKey = entry.key;
        final controller = entry.value;
        final value = double.tryParse(controller.text) ?? 0;
        
        // Replace standard field variables
        formula = formula.replaceAll('{$fieldKey}', value.toString());
        
        // Replace custom field variables (e.g., {customFields.multiply})
        formula = formula.replaceAll('{customFields.$fieldKey}', value.toString());
      }
      
      // Also handle common standard fields explicitly
      final quantity = double.tryParse(getProductController(productIndex, 'quantity').text) ?? 0;
      final pricePerUnit = double.tryParse(getProductController(productIndex, 'pricePerUnit').text) ?? 0;
      final discount = double.tryParse(getProductController(productIndex, 'discount').text) ?? 0;
      
      formula = formula.replaceAll('{quantity}', quantity.toString());
      formula = formula.replaceAll('{pricePerUnit}', pricePerUnit.toString());
      formula = formula.replaceAll('{discount}', discount.toString());
      
      // Evaluate the formula
      return _evaluateFormula(formula);
      
    } catch (e) {
      print('❌ Failed to calculate product total for index $productIndex: $e');
      return 0.0;
    }
  }
  
  // Simple formula evaluator for basic arithmetic operations
  double _evaluateFormula(String formula) {
    try {
      // Remove spaces
      formula = formula.replaceAll(' ', '');
      
      // Handle basic operations: +, -, *, /
      // This is a simple evaluator for security - only handles basic math
      
      // Split by addition/subtraction (lowest precedence)
      final addSubParts = _splitByOperators(formula, ['+', '-']);
      double result = 0;
      
      for (int i = 0; i < addSubParts.length; i++) {
        final part = addSubParts[i];
        final value = part['value'] ?? '';
        if (part['operator'] == '+' || part['operator'] == null) {
          result += _evaluateMultiplyDivide(value);
        } else if (part['operator'] == '-') {
          result -= _evaluateMultiplyDivide(value);
        }
      }
      
      return result;
    } catch (e) {
      print('❌ Failed to evaluate formula: $formula, error: $e');
      return 0.0;
    }
  }
  
  // Evaluate multiplication and division (higher precedence)
  double _evaluateMultiplyDivide(String expression) {
    final mulDivParts = _splitByOperators(expression, ['*', '/']);
    double result = double.tryParse(mulDivParts[0]['value'] ?? '0') ?? 0;
    
    for (int i = 1; i < mulDivParts.length; i++) {
      final part = mulDivParts[i];
      final value = double.tryParse(part['value'] ?? '0') ?? 0;
      
      if (part['operator'] == '*') {
        result *= value;
      } else if (part['operator'] == '/') {
        if (value != 0) {
          result /= value;
        }
      }
    }
    
    return result;
  }
  
  // Helper method to split expression by operators
  List<Map<String, String?>> _splitByOperators(String expression, List<String> operators) {
    List<Map<String, String?>> parts = [];
    String currentValue = '';
    String? currentOperator;
    
    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      
      if (operators.contains(char)) {
        if (currentValue.isNotEmpty) {
          parts.add({'value': currentValue, 'operator': currentOperator});
          currentValue = '';
          currentOperator = char;
        }
      } else {
        currentValue += char;
      }
    }
    
    // Add the last part
    if (currentValue.isNotEmpty) {
      parts.add({'value': currentValue, 'operator': currentOperator});
    }
    
    return parts;
  }

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

  // Save document
  Future<void> saveDocument() async {
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

      

      if (_currentWorkspaceId == null || _currentUserId == null) {
        Get.snackbar(
          'ข้อผิดพลาด',
          'ไม่สามารถระบุผู้ใช้หรือเวิร์กสเปซได้',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Generate document number for new documents
      String? docNo;
      if (documentId == null) {
        try {
          final idService = Get.find<IdGenerationService>();
          docNo = await idService.generateDocumentDocNo(_currentWorkspaceId!, "quotation");
          print('📝 Generated quotation document number: $docNo');
        } catch (e) {
          print('❌ Failed to generate document number: $e');
        }
      }

            // Prepare document data with correct field mapping
      final documentData = {
        'status': _documentStatus,
        'items': _products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          
          // Build item data based on template fields
          final itemData = <String, dynamic>{
            'id': product['id'],
          };
          
          // Add standard fields first
          final nameController = getProductController(index, 'name');
          if (nameController.text.isNotEmpty) {
            itemData['name'] = nameController.text;
          }
          
          final descriptionController = getProductController(index, 'description');
          if (descriptionController.text.isNotEmpty) {
            itemData['description'] = descriptionController.text;
          }
          
          final quantityController = getProductController(index, 'quantity');
          if (quantityController.text.isNotEmpty) {
            itemData['quantity'] = double.tryParse(quantityController.text) ?? 0;
          }
          
          final unitController = getProductController(index, 'unit');
          if (unitController.text.isNotEmpty) {
            itemData['unit'] = unitController.text;
          }
          
          final priceController = getProductController(index, 'pricePerUnit');
          if (priceController.text.isNotEmpty) {
            itemData['pricePerUnit'] = double.tryParse(priceController.text) ?? 0;
          }
          
          final discountController = getProductController(index, 'discount');
          if (discountController.text.isNotEmpty) {
            itemData['discount'] = double.tryParse(discountController.text) ?? 0;
          }
          
          // Build customFields for product_field types with customFields sourceField and user_input fields
          final customFields = <String, dynamic>{};
          final customInputs = <String, dynamic>{};
          
          for (final field in _templateProductFields) {
            final fieldType = field['type']?.toString() ?? '';
            final sourceField = field['sourceField']?.toString() ?? '';
            final fieldId = field['id']?.toString() ?? '';
            
            if (fieldType == 'product_field' && sourceField.startsWith('customFields.')) {
              // This is a custom field in the product data
              final customFieldKey = sourceField.replaceFirst('customFields.', '');
              final controller = getProductController(index, customFieldKey);
              if (controller.text.isNotEmpty) {
                // Try to parse as number if it's a numeric field
                if (field['inputType'] == 'number') {
                  customFields[customFieldKey] = double.tryParse(controller.text) ?? controller.text;
                } else {
                  customFields[customFieldKey] = controller.text;
                }
              }
            } else if (fieldType == 'user_input') {
              // This is a user input field
              final controller = getProductController(index, fieldId);
              if (controller.text.isNotEmpty) {
                customInputs[fieldId] = controller.text;
              }
            }
          }
          
          // Add customFields to itemData if any exist
          if (customFields.isNotEmpty) {
            itemData['customFields'] = customFields;
          }
          
          // Add customInputs to itemData
          if (customInputs.isNotEmpty) {
            itemData['customInputs'] = customInputs;
          } else {
            itemData['customInputs'] = {};
          }
          
          return itemData;
        }).toList(),
        'discount': endOfBillDiscountAmount,
        'withholdingTaxPercentage': double.tryParse(whtPercentageController.text) ?? 3.0,
        'isVatEnabled': _isVatEnabled,
        'project': {
          'name': jobNameController.text,
          'refId': refIdController.text,
        },
        'seller': _selectedSellerIds.isNotEmpty ? {
          'lastDeviceId': 'BE2A.250530.026.F3', // Use actual device ID from user data
          'fcmTokenUpdatedAt': {
            'seconds': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'nanoseconds': (DateTime.now().microsecondsSinceEpoch % 1000000) * 1000,
          },
          'displayName': sellerNameController.text,
          'fcmToken': '', // Get from user data if available
          'uid': _selectedSellerIds.first,
          'viewSettings': {
            'customerProfileCardsConfig_${_currentWorkspaceId}': {
              'customId': {'order': 0, 'isVisible': true},
              'title': {'order': 1, 'isVisible': true},
              'boardName': {'order': 2, 'isVisible': true},
              'status': {'order': 3, 'isVisible': true},
              'lane': {'order': 4, 'isVisible': true},
              'dueDate': {'order': 5, 'isVisible': true},
              'assignee': {'order': 6, 'isVisible': true},
              'customerInterest': {'order': 7, 'isVisible': true},
              'customer': {'order': 8, 'isVisible': true},
              'company': {'order': 9, 'isVisible': true},
              'hashtags': {'order': 10, 'isVisible': true},
              'priority': {'order': 11, 'isVisible': true},
              'grandTotal': {'order': 12, 'isVisible': true},
              'netTotal': {'order': 13, 'isVisible': true},
              'totalAmountBeforeDiscount': {'order': 14, 'isVisible': true},
              'totalAmountAfterDiscount': {'order': 15, 'isVisible': true},
              'totalAmountBeforeVat': {'order': 16, 'isVisible': true},
              'description': {'order': 17, 'isVisible': true},
              'todos': {'order': 18, 'isVisible': true},
            },
          },
          'email': 'minimark@sellstory.me', // Get from user data
          'lastPlatform': 'android',
          'language': 'en',
          'workspaces': [
            {
              'id': _currentWorkspaceId!,
              'role': 'owner',
              'name': 'Mini Mark\'s Workspace', // Get from user data
            }
          ],
          'photoURL': null,
        } : null,
        'sellerName': sellerNameController.text,
        'sellerPhone': sellerPhoneController.text,
        'notes': notesController.text,
        'signatureAssignments': _buildSignatureAssignments(),
        'companySealId': _selectedCompanySealId,
        'templateId': _selectedTemplateId ?? '',
        'customer': selectedCustomer != null ? {
          'id': selectedCustomer!.id,
          'name': selectedCustomer!.name,
          'address': customerAddressController.text,
          'postalCode': customerPostalCodeController.text,
          'nationalId': customerNationalIdController.text,
          'emails': customerEmailController.text.isNotEmpty ? [
            {
              'label': 'Work',
              'value': customerEmailController.text,
              'id': 'email-initial',
            }
          ] : [],
          'phones': customerPhoneController.text.isNotEmpty ? [
            {
              'label': 'Work',
              'value': customerPhoneController.text,
              'id': 'phone-initial',
            }
          ] : [],
          'companyNames': selectedCustomer!.companyNames,
        } : null,
        'jobName': jobNameController.text,
        'validUntil': _validUntilDate?.millisecondsSinceEpoch,
        'company': selectedCompanyData != null ? {
          'value': selectedCompanyData!['value'] ?? '',
          'id': selectedCompanyData!['id'],
          'label': selectedCompanyData!['label'] ?? 'Main',
        } : null,
        'subtotal': subtotal,
        'grandTotal': netTotal,
        'vatAmount': vatAmount,
        'netTotal': netTotal,
        'whtAmount': whtAmount,
        'docNo': docNo ?? 'EST-${DateTime.now().millisecondsSinceEpoch}',
        'type': 'QT',
        'workspaceId': _currentWorkspaceId!,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'createdBy': _currentUserId!,
        'updatedBy': _currentUserId!,
        'activityLog': [
          {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'userId': _currentUserId!,
            'userDisplayName': 'minimark@sellstory.me', // Get from user data
            'action': documentId != null ? 'Updated' : 'Created',
            'details': documentId != null 
                ? 'Updated quotation ${docNo ?? 'EST-${DateTime.now().millisecondsSinceEpoch}'}' 
                : 'Created quotation ${docNo ?? 'EST-${DateTime.now().millisecondsSinceEpoch}'} directly.',
          },
        ],
      };

      // Save to Firestore
      if (documentId != null) {
        // Update existing document
        await _repository.updateDocument(
          workspaceId: _currentWorkspaceId!,
          documentId: documentId!,
          documentData: documentData,
        );
        print('📝 Updated document: $documentId');
      } else {
        // Create new document
        final newDocumentId = await _repository.createDocument(
          workspaceId: _currentWorkspaceId!,
          documentData: documentData,
        );
        print('📝 Created new document with ID: $newDocumentId');
      }

             // Show success notification with document ID
       final documentNumber = docNo ?? 'EST-${DateTime.now().millisecondsSinceEpoch}';
       final successMessage = documentId != null
           ? 'อัปเดตใบเสนอราคาเรียบร้อย - เลขที่: $documentNumber'
           : 'สร้างใบเสนอราคาเรียบร้อย - เลขที่: $documentNumber';
       
       Get.snackbar(
         'สำเร็จ',
         successMessage,
         backgroundColor: Colors.green,
         colorText: Colors.white,
         duration: Duration(seconds: 4),
         snackPosition: SnackPosition.TOP,
       );

       // Navigate back to document list page
       Get.off(() => const QuotationsListPage());
    } catch (e) {
      print('❌ Failed to save document: $e');
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
