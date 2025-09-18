import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../data/services/upload_service.dart';
import '../../../domain/entities/board.dart';
import '../../../domain/entities/lane.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../controller/board_controller.dart';
import '../widgets/hashtag_selection_modal.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../document/view/create_document_from_card_page.dart';
import '../../document/view/add_edit_document_page.dart';
import '../../../core/services/notifications_service.dart';
import 'package:html_editor_enhanced/html_editor.dart';

class EditCardPage extends StatefulWidget {
  final JobCard card;

  const EditCardPage({super.key, required this.card});

  @override
  State<EditCardPage> createState() => _EditCardPageState();
}

class _EditCardPageState extends State<EditCardPage> {
  // Permission helpers
  bool _can(String code) {
    try {
      return MobilePermissionsService.to.can(code);
    } catch (_) {
      return false;
    }
  }

  bool get _isAssignee {
    final uid = _controller.currentUserId.value.isNotEmpty
        ? _controller.currentUserId.value
        : (FirebaseAuth.instance.currentUser?.uid ?? '');
    return uid.isNotEmpty && uid == widget.card.assignedTo;
  }

  bool get _canView =>
      _can('jobcard:view:all') ||
      (_can('jobcard:view:assigned') && _isAssignee);
  bool get _canEditAll => _can('jobcard:edit:all');
  bool get _canEditAssigned => _can('jobcard:edit:assigned') && _isAssignee;
  bool get _canEditAny => _canEditAll || _canEditAssigned;
  bool get _canMove => _can('jobcard:move');
  bool get _canDelete =>
      _can('jobcard:delete:all') ||
      (_can('jobcard:delete:assigned') && _isAssignee);
  bool get _canArchive => (_canEditAny && _can('jobcard:edit:field:status'));
  bool get _canEditAttachments =>
      _canEditAny && _can('jobcard:edit:field:attachments');
  bool get _canEditNotes => _canEditAny && _can('jobcard:edit:field:notes');

  void _showNoPermission() {
    Get.snackbar(
      'Permission denied',
      "You don't have permission to perform this action",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // Popup menu actions
  void _onCopy() {
    Get.snackbar(
      'Copy',
      'Copy functionality will be available soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _onMove() {
    if (!_canMove) {
      _showNoPermission();
      return;
    }
    _showMoveCardDialog();
  }

  void _onArchive() {
    if (!_canArchive) {
      _showNoPermission();
      return;
    }
    // Show confirmation dialog
    Get.dialog(
      AlertDialog(
        title: const Text('Archive Card'),
        content: Text(
          'Are you sure you want to archive "${widget.card.title}"?\n\nArchived cards will be hidden from the board but can be restored later.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog first
              await _archiveCard();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveCard() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Update card status to "Archived"
      final updatedCard = widget.card.copyWith(
        status: 'Archived',
        updatedAt: DateTime.now(),
      );

      await _controller.updateCard(updatedCard);

      Get.snackbar(
        'Success',
        'Card archived successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Close edit page and go back to board
      Navigator.of(context).pop();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to archive card: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDeletePermanently() {
    if (!_canDelete) {
      _showNoPermission();
      return;
    }
    // Show confirmation dialog
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Card'),
        content: Text(
          'Are you sure you want to permanently delete "${widget.card.title}"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog first
              await _deleteCard();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _controller.deleteCard(widget.card.id);

      Get.snackbar(
        'Success',
        'Card deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Close edit page and go back to board
      Navigator.of(context).pop();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete card: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  final BoardController _controller = Get.find<BoardController>();
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();

  // Form controllers
  final TextEditingController _jobIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  // HTML Editor controller
  final HtmlEditorController _htmlEditorController = HtmlEditorController();

  // Current user information
  Map<String, dynamic>? _currentUserInfo;

  // Hashtag state (same as create page)
  List<Map<String, dynamic>> _selectedHashtags = [];

  // Todo state
  List<Map<String, dynamic>> _todoItems = [];

  // Product state
  List<Map<String, dynamic>> _productItems = [];

  // Template and columns state
  List<Map<String, dynamic>> _quotationTemplates = [];
  String? _selectedTemplateId;
  Map<String, dynamic>? _selectedTemplateData; // เก็บข้อมูล template ที่เลือกทั้งหมด
  List<Map<String, dynamic>> _visibleColumns = [];

  // VAT and discount state
  bool _isVatEnabled = false;
  Map<String, dynamic>? _additionalDiscount;
  double _withholdingTaxPercentage = 0.0;

  // Form state
  String _selectedLane = '';
  String _selectedAssignee = '';
  String _selectedCustomer = '';
  String _selectedCompany = 'none';
  String _selectedCustomerInterest = 'เริ่มต้น';
  String _selectedStatus = 'Pending';
  DateTime? _expectedClosingDate;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  // Multi-select for collaborators and watchers
  List<String> _selectedCollaborators = [];
  List<String> _selectedWatchers = [];

  // Notes data
  List<Map<String, dynamic>> _notes = [];

  // Related documents data
  List<Map<String, dynamic>> _relatedDocuments = [];
  bool _isLoadingRelatedDocuments = false;

  // Attachments data
  List<Map<String, dynamic>> _attachments = [];

  // Available options
  List<Map<String, dynamic>> _availableLanes = [];
  List<Map<String, dynamic>> _availableAssignees = [];
  List<Map<String, dynamic>> _availableCustomers = [];
  List<Map<String, dynamic>> _availableCompanies = [];
  List<Map<String, dynamic>> _availableUsers = [];

  // Status options
  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'Pending', 'label': 'Pending', 'icon': Icons.schedule},
    {'value': 'In Progress', 'label': 'In Progress', 'icon': Icons.schedule},
    {'value': 'Done', 'label': 'Done', 'icon': Icons.check},
    {'value': 'Cancelled', 'label': 'Cancelled', 'icon': Icons.close},
  ];

  // Document status options for Related Documents
  final List<Map<String, dynamic>> _documentStatusOptions = [
    {'value': 'DRAFT', 'label': 'ร่าง'},
    {'value': 'APPROVED', 'label': 'อนุมัติแล้ว'},
    {'value': 'PENDING_APPROVAL', 'label': 'รออนุมัติ'},
    {'value': 'SENT_FOR_APPROVAL', 'label': 'ส่งอนุมัติ'},
    {'value': 'CANCELLED', 'label': 'ยกเลิก'},
    {'value': 'REJECTED', 'label': 'ปฏิเสธ'},
    {'value': 'INVOICED', 'label': 'ออกใบแจ้งหนี้แล้ว'},
    {'value': 'FULLY_PAID', 'label': 'ชำระครบแล้ว'},
  ];

  // Customer Interest options (same as create page)
  final List<String> _customerInterestOptions = [
    'เริ่มต้น',
    'น้อย (Low)',
    'กลาง (Medium)',
    'มาก (High)',
  ];

  // Add history/comment toggle state variable
  bool _showHistory = true; // true = History, false = Comment

  @override
  void initState() {
    super.initState();
    _initializeData().then((_) {
      setState(() {});
    });
  }

  Future<void> _initializeData() async {
    // Load current user information
    await _loadCurrentUserInfo();

    // Load card data
    _jobIdController.text = widget.card.customId;
    _titleController.text = widget.card.title;
    _detailsController.text = widget.card.description;

    // Wait for HTML editor to be ready before setting content
    await Future.delayed(const Duration(milliseconds: 500));

    // Remove manual setText since initialText in HtmlEditorOptions handles it

    _selectedLane = widget.card.laneId;
    _selectedAssignee = widget.card.assignedTo;
    _selectedCustomer =
        widget.card.customerId ?? ''; // ใช้ customerId แทน customer
    _selectedCompany =
        widget.card.company?['id'] ?? 'none'; // Initialize company from JobCard
    _selectedCustomerInterest =
        (widget.card.customerInterest?.isNotEmpty ?? false)
        ? widget.card.customerInterest!
        : 'เริ่มต้น';
    _selectedStatus = widget.card.status;
    _startDate = widget.card.startDate;
    _endDate = widget.card.endDate;

    // Initialize hashtags (same as create page)
    _selectedHashtags = List<Map<String, dynamic>>.from(widget.card.hashtags);

    // Initialize todos
    _todoItems = List<Map<String, dynamic>>.from(widget.card.todos.map((todo) {
      // Handle title field from Firestore data structure
      final titleText = todo['title'] ?? todo['text'] ?? '';
      return {
        'id': todo['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'text': titleText,
        'isCompleted': todo['isCompleted'] ?? todo['completed'] ?? false,
        'dueDate': todo['dueDate'] != null ? DateTime.fromMillisecondsSinceEpoch(todo['dueDate']) : null,
        'duration': todo['duration'],
        'endTime': todo['endTime'] != null ? DateTime.fromMillisecondsSinceEpoch(todo['endTime']) : null,
        'controller': TextEditingController(text: titleText),
      };
    }));

    // Initialize collaborators and watchers
    _selectedCollaborators = List<String>.from(widget.card.collaborators);
    _selectedWatchers = List<String>.from(widget.card.watchers);

    // Initialize notes
    _notes = List<Map<String, dynamic>>.from(widget.card.notes);

    // Initialize attachments
    _attachments = List<Map<String, dynamic>>.from(widget.card.attachments);

    // Initialize related documents list as empty, will be loaded from Firestore
    _relatedDocuments = [];

    // Load detailed related documents information from Firestore
    await _loadRelatedDocumentsDetails();

    // Initialize product items from Firestore subcollection expenses first; fallback to embedded card.expenses
    await _loadExpensesFromFirestore();

    // Load product images from database
    await _loadProductImages();

    // Initialize VAT and discount settings
    _isVatEnabled = widget.card.isVatEnabled;
    _additionalDiscount = widget.card.additionalDiscount;
    _withholdingTaxPercentage = widget.card.withholdingTaxPercentage.toDouble();

    // Initialize template selection from card data
    _selectedTemplateId = widget.card.quotationTemplateId;
    print('🎯 Card quotationTemplateId: ${widget.card.quotationTemplateId}');

    // Load available options
    await _loadAvailableOptions();

    // Load quotation templates
    await _loadQuotationTemplates();

    // โหลด companies ของ customer ที่เลือกไว้
    if (_selectedCustomer.isNotEmpty && _selectedCustomer != 'none') {
      await _loadCompaniesForCustomer(_selectedCustomer);
    }
  }

  Future<void> _loadExpensesFromFirestore() async {
    try {
      final workspaceId = widget.card.workspaceId;
      final cardId = widget.card.id;
      if (workspaceId.isEmpty || cardId.isEmpty) {
        // Fallback to embedded expenses on card
        _productItems = List<Map<String, dynamic>>.from(
          widget.card.expenses.map(
            (expense) => {
              'id': expense['id'],
              'productId': expense['productId'],
              'name': expense['name'],
              'description': expense['description'] ?? '',
              'quantity': (expense['quantity'] ?? 0).toDouble(),
              'unit': expense['unit'] ?? 'item',
              'price': (expense['pricePerUnit'] ?? expense['price'] ?? 0)
                  .toDouble(),
              'pricePerUnit': (expense['pricePerUnit'] ?? expense['price'] ?? 0)
                  .toDouble(),
              'discount': (expense['discount'] ?? 0).toDouble(),
              'discountType': expense['discountType'] ?? 'percentage',
              'customInputs': expense['customInputs'] ?? {},
              'image': null,
              'order': expense['order'] ?? 0,
            },
          ),
        );
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('cards')
          .doc(cardId)
          .collection('expenses')
          .get();

      if (snapshot.docs.isEmpty) {
        // Fallback to embedded expenses when subcollection empty
        _productItems = List<Map<String, dynamic>>.from(
          widget.card.expenses.map(
            (expense) => {
              'id': expense['id'],
              'productId': expense['productId'],
              'name': expense['name'],
              'description': expense['description'] ?? '',
              'quantity': (expense['quantity'] ?? 0).toDouble(),
              'unit': expense['unit'] ?? 'item',
              'price': (expense['pricePerUnit'] ?? expense['price'] ?? 0)
                  .toDouble(),
              'pricePerUnit': (expense['pricePerUnit'] ?? expense['price'] ?? 0)
                  .toDouble(),
              'discount': (expense['discount'] ?? 0).toDouble(),
              'discountType': expense['discountType'] ?? 'percentage',
              'customInputs': expense['customInputs'] ?? {},
              'image': null,
              'order': expense['order'] ?? 0,
            },
          ),
        );
        return;
      }

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'id': doc.id,
          'productId': data['productId'],
          'name': data['name'] ?? '',
          'description': data['description'] ?? '',
          'quantity': (data['quantity'] ?? 0).toDouble(),
          'unit': data['unit'] ?? 'item',
          'pricePerUnit': (data['pricePerUnit'] ?? data['price'] ?? 0)
              .toDouble(),
          'price': (data['pricePerUnit'] ?? data['price'] ?? 0).toDouble(),
          'discount': (data['discount'] ?? 0).toDouble(),
          'discountType': data['discountType'] ?? 'percentage',
          'customInputs': (data['customInputs'] is Map)
              ? Map<String, dynamic>.from(data['customInputs'])
              : <String, dynamic>{},
          'image': null,
          'order': data['order'] ?? 0,
        };
      }).toList();

      // Sort by order if available
      items.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

      setState(() {
        _productItems = List<Map<String, dynamic>>.from(items);
      });
    } catch (e) {
      print('❌ Failed to load expenses subcollection: $e');
      // Fallback to embedded expenses
      _productItems = List<Map<String, dynamic>>.from(
        widget.card.expenses.map(
          (expense) => {
            'id': expense['id'],
            'productId': expense['productId'],
            'name': expense['name'],
            'description': expense['description'] ?? '',
            'quantity': (expense['quantity'] ?? 0).toDouble(),
            'unit': expense['unit'] ?? 'item',
            'price': (expense['pricePerUnit'] ?? expense['price'] ?? 0)
                .toDouble(),
            'pricePerUnit': (expense['pricePerUnit'] ?? expense['price'] ?? 0)
                .toDouble(),
            'discount': (expense['discount'] ?? 0).toDouble(),
            'discountType': expense['discountType'] ?? 'percentage',
            'customInputs': expense['customInputs'] ?? {},
            'image': null,
            'order': expense['order'] ?? 0,
          },
        ),
      );
    }
  }

  Future<void> _loadAvailableOptions() async {
    // Load lanes
    final lanes = _controller.lanes;
    _availableLanes = lanes
        .map((lane) => {'id': lane.id, 'name': lane.title})
        .toList();

    // Validate selected lane exists in available lanes
    if (_selectedLane.isNotEmpty) {
      final laneExists = _availableLanes.any(
        (lane) => lane['id'] == _selectedLane,
      );
      if (!laneExists) {
        print(
          '⚠️ Selected lane $_selectedLane not found in available lanes, resetting',
        );
        _selectedLane = '';
      }
    }

    // Load assignees from workspace users
    await _loadWorkspaceUsers();

    // Load customers from Firestore
    try {
      print('🔄 Loading customers from Firestore...');
      final customers = await _controller.getCustomers();

      // Deduplicate customers by ID to prevent dropdown issues
      final customerMap = <String, Map<String, dynamic>>{};
      for (final customer in customers) {
        if (!customerMap.containsKey(customer.id)) {
          customerMap[customer.id] = {
            'id': customer.id,
            'name': customer.name,
            'customId': customer.customId,
          };
        }
      }
      _availableCustomers = customerMap.values.toList();

      print('✅ Customers loaded: ${_availableCustomers.length} customers');

      // Validate selected customer exists in available customers
      if (_selectedCustomer.isNotEmpty) {
        final customerExists = _availableCustomers.any(
          (customer) => customer['id'] == _selectedCustomer,
        );
        if (!customerExists) {
          print(
            '⚠️ Selected customer $_selectedCustomer not found in available customers, resetting',
          );
          _selectedCustomer = '';
        }
      }
    } catch (e) {
      print('❌ Failed to load customers: $e');
      _availableCustomers = [];
      _selectedCustomer = '';
    }

    // Initialize company selection if customer is already selected
    if (_selectedCustomer.isNotEmpty) {
      await _loadCompaniesForCustomer(_selectedCustomer);
    } else {
      // Initialize with default "None" option
      _availableCompanies = [
        {'id': 'none', 'name': 'None'},
      ];
      _selectedCompany = 'none';
    }
  }

  Future<void> _loadWorkspaceUsers() async {
    try {
      final workspaceId = _controller.currentWorkspaceId.value;
      if (workspaceId.isEmpty) {
        print('⚠️ No workspace selected for loading users');
        _availableAssignees = [];
        _selectedAssignee = '';
        return;
      }

      print('🔄 Loading users for workspace: $workspaceId');

      // Get users from the workspace - data is already properly formatted from repository
      final users = await _controller.getWorkspaceUsers(workspaceId);

      // Deduplicate users by ID to prevent dropdown issues
      final userMap = <String, Map<String, dynamic>>{};
      for (final user in users) {
        if (!userMap.containsKey(user['id'])) {
          userMap[user['id']] = user;
        }
      }
      _availableAssignees = userMap.values.toList();

      print('✅ Loaded ${_availableAssignees.length} users for workspace');

      // Validate selected assignee exists in available assignees
      if (_selectedAssignee.isNotEmpty) {
        final assigneeExists = _availableAssignees.any(
          (assignee) => assignee['id'] == _selectedAssignee,
        );
        if (!assigneeExists) {
          print(
            '⚠️ Selected assignee $_selectedAssignee not found in available assignees, resetting',
          );
          _selectedAssignee = '';
        }
      }
    } catch (e) {
      print('❌ Failed to load workspace users: $e');
      _availableAssignees = [];
      _selectedAssignee = '';
    }
  }

  Future<void> _loadCompaniesForCustomer(String customerId) async {
    try {
      print('🔄 Loading companies for customer: $customerId');

      // Get customer details to access companyNames
      final customers = await _controller.getCustomers();
      final customer = customers.firstWhereOrNull((c) => c.id == customerId);

      if (customer != null && customer.companyNames.isNotEmpty) {
        final companyMap = <String, Map<String, dynamic>>{};
        companyMap['none'] = {'id': 'none', 'name': 'None'};

        for (final company in customer.companyNames) {
          companyMap[company['id']] = {
            'id': company['id'],
            'name': company['value'], // ใช้ value แทน label เพื่อแสดงชื่อสั้นๆ
            'value': company['value'],
          };
        }

        setState(() {
          _availableCompanies = companyMap.values.toList();
          // ถ้า company ปัจจุบันไม่มีในรายการใหม่ ให้รีเซ็ต
          if (_selectedCompany != 'none' &&
              !_availableCompanies.any((c) => c['id'] == _selectedCompany)) {
            _selectedCompany = 'none';
          }
        });

        print(
          '✅ Companies loaded for customer: ${_availableCompanies.length - 1} companies',
        );
      } else {
        setState(() {
          _availableCompanies = [
            {'id': 'none', 'name': 'None'},
          ];
          _selectedCompany = 'none';
        });
        print('⚠️ No companies found for customer');
      }
    } catch (e) {
      print('❌ Failed to load companies for customer: $e');
      setState(() {
        _availableCompanies = [
          {'id': 'none', 'name': 'None'},
        ];
        _selectedCompany = 'none';
      });
    }
  }

  Future<void> _loadProductImages() async {
    try {
      final workspaceId = _controller.currentWorkspaceId.value;
      if (workspaceId.isEmpty || _productItems.isEmpty) return;

      print('🔄 Loading product images for ${_productItems.length} products');

      final firestore = FirebaseFirestore.instance;

      // Load images for each product
      for (int i = 0; i < _productItems.length; i++) {
        final productId = _productItems[i]['productId'];
        if (productId != null && productId.isNotEmpty) {
          try {
            final productDoc = await firestore
                .collection('workspaces/$workspaceId/products')
                .doc(productId)
                .get();

            if (productDoc.exists) {
              final productData = productDoc.data()!;
              setState(() {
                _productItems[i]['image'] = productData['imageUrl'];
              });
            }
          } catch (e) {
            print('❌ Failed to load image for product $productId: $e');
          }
        }
      }

      print('✅ Product images loaded successfully');
    } catch (e) {
      print('❌ Failed to load product images: $e');
    }
  }

  Future<void> _loadQuotationTemplates() async {
    try {
      // Always use the card's workspace to load its templates
      final workspaceId = widget.card.workspaceId;
      if (workspaceId.isEmpty) {
        print('⚠️ No workspace selected for loading templates');
        return;
      }

      print('🔄 Loading quotation templates for workspace: $workspaceId');

    // Use Firebase service to get templates
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('quotationTemplates')
          .get();

      final List<Map<String, dynamic>> templates = [];

      // ไม่เพิ่ม "None" option - ต้องเลือก template เสมอ
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tableComponent = _findTableComponent(data);

        templates.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unnamed Template',
          'columns': tableComponent?['columns'] ?? _getDefaultColumns(),
          'data': data,
        });
      }

      setState(() {
        _quotationTemplates = templates;
        
        // ตรวจสอบ quotationTemplateId จาก card
        if (_selectedTemplateId != null && _selectedTemplateId!.isNotEmpty) {
          // ตรวจสอบว่า template ที่เลือกมีอยู่จริงใน list หรือไม่
          final templateExists = templates.any((t) => t['id'] == _selectedTemplateId);
          if (!templateExists && templates.isNotEmpty) {
            // ถ้าไม่พบ template ที่ระบุ ให้เลือก template แรก
            _selectedTemplateId = templates.first['id'];
            print('⚠️ Template not found, selected first template: $_selectedTemplateId');
          }
        } else if (templates.isNotEmpty) {
          // ถ้าไม่มี quotationTemplateId ให้เลือก template แรก
          _selectedTemplateId = templates.first['id'];
          print('📋 No templateId in card, selected first template: $_selectedTemplateId');
        }
        
        _updateVisibleColumns();
      });

      print('✅ Loaded ${templates.length} quotation templates');
      print('🎯 Selected template: $_selectedTemplateId');
      if (_selectedTemplateId != null && _selectedTemplateId != 'none') {
        final template = _quotationTemplates.firstWhereOrNull(
          (t) => t['id'] == _selectedTemplateId,
        );
        if (template != null) {
          final columns = template['columns'] as List<dynamic>? ?? [];
          print('📋 Template columns count: ${columns.length}');
          for (final column in columns) {
            if (column is Map<String, dynamic>) {
              print(
                '  - ${column['label']} (${column['type']}) - visible: ${column['isVisible']}',
              );
            }
          }
        }
      }
    } catch (e) {
      print('❌ Failed to load quotation templates: $e');
      // Set default state - สร้าง template เปล่าถ้าไม่มี
      setState(() {
        _quotationTemplates = [
          {'id': 'default', 'name': 'Default Template', 'columns': _getDefaultColumns()},
        ];
        _selectedTemplateId = 'default';
        _updateVisibleColumns();
      });
    }
  }

  Map<String, dynamic>? _findTableComponent(Map<String, dynamic> templateData) {
    // Search in body components, prefer index 1 if it is a table (matches web)
    final body = templateData['body'];
    if (body != null && body['components'] != null) {
      final comps = body['components'];
      if (comps is List && comps.length > 1) {
        final second = comps[1];
        if (second is Map && second['type'] == 'table') {
          return Map<String, dynamic>.from(second);
        }
      }
      for (final component in comps) {
        if (component is Map && component['type'] == 'table') {
          return Map<String, dynamic>.from(component);
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _getDefaultColumns() {
    return [
      {
        'id': 'img',
        'label': 'Img',
        'type': 'image',
        'isVisible': true,
        'width': '60px',
        'order': 0,
      },
      {
        'id': 'name',
        'label': 'Product/Service',
        'type': 'product_field',
        'sourceField': 'name',
        'isVisible': true,
        'width': '3',
        'order': 1,
      },
      {
        'id': 'quantity',
        'label': 'Qty/Unit',
        'type': 'predefined',
        'predefinedField': 'quantity',
        'isVisible': true,
        'width': '2',
        'order': 2,
      },
      {
        'id': 'pricePerUnit',
        'label': 'Price/Unit',
        'type': 'product_field',
        'sourceField': 'pricePerUnit',
        'isVisible': true,
        'width': '2',
        'order': 3,
      },
      {
        'id': 'discount',
        'label': 'Discount',
        'type': 'predefined',
        'predefinedField': 'discount',
        'isVisible': true,
        'width': '2',
        'order': 4,
      },
      {
        'id': 'total',
        'label': 'Total',
        'type': 'predefined',
        'predefinedField': 'line_total',
        'isVisible': true,
        'width': '2',
        'order': 5,
      },
    ];
  }

  void _updateVisibleColumns() {
    print('🔄 Updating visible columns for template: $_selectedTemplateId');

    if (_selectedTemplateId == null) {
      _visibleColumns = _getDefaultColumns();
      print('📋 No template selected, using default columns: ${_visibleColumns.length} columns');
    } else {
      final template = _quotationTemplates.firstWhereOrNull(
        (t) => t['id'] == _selectedTemplateId,
      );
      if (template != null) {
        final columns = List<Map<String, dynamic>>.from(
          template['columns'] ?? [],
        );
        print('📋 Template found with ${columns.length} total columns');

        // Sort by order
        columns.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

        // Filter only visible columns
        _visibleColumns = columns
            .where((col) => col['isVisible'] == true)
            .toList();
        print('📋 Filtered to ${_visibleColumns.length} visible columns:');
        for (final col in _visibleColumns) {
          print(
            '  - ${col['label']} (${col['type']}) - order: ${col['order']}',
          );
        }
      } else {
        _visibleColumns = _getDefaultColumns();
        print('📋 Template not found, using default columns');
      }
    }
  }

  void _onTemplateChanged(String? templateId) {
    setState(() {
      _selectedTemplateId = templateId;

      // เก็บข้อมูล template ที่เลือกทั้งหมด
      final template = _quotationTemplates.firstWhereOrNull(
        (t) => t['id'] == _selectedTemplateId,
      );

      if (template == null || _selectedTemplateId == null) {
        // ไม่มี template ที่เลือก: เคลียร์ข้อมูล template
        _selectedTemplateData = null;
        // No template selected: clear customInputs to avoid showing stale values
        for (int i = 0; i < _productItems.length; i++) {
          _productItems[i]['customInputs'] = <String, dynamic>{};
        }
        print('🎯 Template cleared: $_selectedTemplateId');
      } else {
        // เก็บข้อมูล template ทั้งหมดในตัวแปร _selectedTemplateData
        _selectedTemplateData = Map<String, dynamic>.from(template);
        print('🎯 Template selected and saved: ${template['name']} (ID: $_selectedTemplateId)');
        print('📋 Template data saved with keys: ${_selectedTemplateData?.keys.toList()}');
        
        // สร้าง product table จากข้อมูล template และเก็บ template ID ไว้
        _createProductsFromTemplate(template);
        
        final columns = List<Map<String, dynamic>>.from(template['columns'] ?? const []);
        // Consider only user_input columns; build map id -> column for access to prefillSourceField
        final Map<String, Map<String, dynamic>> userInputCols = {};
        for (final col in columns) {
          if ((col['type'] ?? '') == 'user_input') {
            final id = (col['id'] ?? '').toString();
            if (id.isNotEmpty) {
              userInputCols[id] = Map<String, dynamic>.from(col);
            }
          }
        }

        print('🔗 Found ${userInputCols.length} user input columns in template');
        userInputCols.forEach((id, col) {
          print('  - Column ID: $id, Label: ${col['label']}');
        });

        // เก็บข้อมูลจาก expense เดิมไว้ก่อนการ mapping ใหม่
        print('💾 Preserving existing expense data before template mapping');
        final originalExpenses = List<Map<String, dynamic>>.from(widget.card.expenses);

        // ล้างค่าใน customInputs ของทุก product items ก่อนการ mapping ใหม่
        print('🧹 Clearing all customInputs before new template mapping');
        for (int i = 0; i < _productItems.length; i++) {
          _productItems[i]['customInputs'] = <String, dynamic>{};
        }

        // อัปเดต customInputs ของแต่ละ product item ให้ตรงกับ template columns ใหม่
        for (int i = 0; i < _productItems.length; i++) {
          final product = _productItems[i];
          final Map<String, dynamic> newCi = <String, dynamic>{};

          // หา expense เดิมที่ตรงกัน (ถ้ามี)
          Map<String, dynamic>? matchingExpense;
          if (i < originalExpenses.length) {
            matchingExpense = originalExpenses[i];
          }

          // สร้าง customInputs ใหม่ตาม template columns
          userInputCols.forEach((id, col) {
            String value = '';
            
            // ตรวจสอบว่ามีข้อมูลเดิมที่ตรงกับ column ID นี้หรือไม่
            if (matchingExpense != null && 
                matchingExpense['customInputs'] != null &&
                matchingExpense['customInputs'][id] != null) {
              value = matchingExpense['customInputs'][id].toString();
              print('  ✅ Preserved existing value for $id (${col['label']}): $value');
            } else {
              print('  📝 Set empty value for new template column $id (${col['label']})');
            }
            
            newCi[id] = value;
          });

          product['customInputs'] = newCi;
          // เก็บ template ID ในแต่ละ product item สำหรับการ mapping
          product['templateId'] = _selectedTemplateId;
        }
      }

      _updateVisibleColumns();
    });
  }

  void _createProductsFromTemplate(Map<String, dynamic> template) {
    try {
      print('🏗️ Creating products from template: ${template['name']}');
      print('📋 Using existing expenses data: ${widget.card.expenses.length} items');
      
      // ล้าง product items ที่มีอยู่ก่อน
      _productItems.clear();
      
      // ใช้ข้อมูลจาก card expenses แทนการสร้างใหม่
      final expenses = widget.card.expenses;
      
      if (expenses.isNotEmpty) {
        print('📊 Found ${expenses.length} expense items in card data');
        
        // สร้าง product items จากข้อมูล expenses พร้อม template mapping
        for (int index = 0; index < expenses.length; index++) {
          final expense = expenses[index];
          
          // สร้าง product item จากข้อมูล expense
          final productItem = {
            'id': expense['id'] ?? 'exp-${DateTime.now().millisecondsSinceEpoch}-$index',
            'productId': expense['productId'] ?? '',
            'name': expense['name'] ?? 'Product ${index + 1}',
            'description': expense['description'] ?? '',
            'quantity': (expense['quantity'] ?? 1).toInt(),
            'unit': expense['unit'] ?? 'item',
            'pricePerUnit': (expense['pricePerUnit'] ?? expense['price'] ?? 0).toInt(),
            'discount': (expense['discount'] ?? 0).toInt(),
            'discountType': expense['discountType'] ?? 'percentage',
            // ล้าง customInputs (จะถูก map ใหม่ใน _onTemplateChanged)
            'customInputs': <String, dynamic>{},
            'templateId': _selectedTemplateId, // เก็บ template ID สำหรับ mapping
            'image': expense['image'],
            'order': expense['order'] ?? index,
          };
          
          _productItems.add(productItem);
          
          print('✅ Mapped expense to product item:');
          print('  - Name: ${productItem['name']}');
          print('  - Quantity: ${productItem['quantity']}');
          print('  - Price: ${productItem['pricePerUnit']}');
          print('  - CustomInputs: cleared for new template mapping');
        }
        
        print('✅ Created ${_productItems.length} product items from card expenses');
      } else {
        print('📝 No expenses found in card, creating empty product item');
        
        // ถ้าไม่มี expenses ให้สร้าง product item เปล่า
        final emptyProduct = {
          'id': 'template-product-${DateTime.now().millisecondsSinceEpoch}',
          'productId': '',
          'name': '',
          'description': '',
          'quantity': 1,
          'unit': 'item',
          'pricePerUnit': 0,
          'discount': 0,
          'discountType': 'percentage',
          'customInputs': <String, dynamic>{},
          'templateId': _selectedTemplateId,
          'image': null,
        };
        _productItems.add(emptyProduct);
        print('📋 Created empty product item with template ID');
      }
      
    } catch (e) {
      print('❌ Error creating products from template: $e');
      // สร้าง product item เปล่าในกรณีเกิดข้อผิดพลาด
      if (_productItems.isEmpty) {
        final fallbackProduct = {
          'id': 'fallback-product-${DateTime.now().millisecondsSinceEpoch}',
          'productId': '',
          'name': '',
          'description': '',
          'quantity': 1,
          'unit': 'item',
          'pricePerUnit': 0,
          'discount': 0,
          'discountType': 'percentage',
          'customInputs': <String, dynamic>{},
          'templateId': _selectedTemplateId,
          'image': null,
        };
        _productItems.add(fallbackProduct);
      }
    }
  }

  List<Widget> _buildHeaderColumns() {
    List<Widget> headers = [];

    for (final column in _visibleColumns) {
      Widget headerWidget;

      // Determine flex based on column width
      int flex = 2; // default
      String? widthStr = column['width'];
      if (widthStr != null) {
        if (widthStr.contains('%')) {
          // Convert percentage to flex
          final percentage = int.tryParse(widthStr.replaceAll('%', '')) ?? 20;
          flex = (percentage / 10).round().clamp(1, 6);
        } else if (widthStr.contains('px')) {
          // Fixed width columns get smaller flex
          flex = 1;
        } else {
          // Plain number as flex
          flex = int.tryParse(widthStr) ?? 2;
        }
      }

      // Handle special columns
      if (column['id'] == 'img' || column['type'] == 'image') {
        headerWidget = const SizedBox(
          width: 50,
          child: Text(
            '',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        );
      } else {
        // Determine text alignment
        TextAlign textAlign = TextAlign.left;
        if (column['align'] == 'center') {
          textAlign = TextAlign.center;
        } else if (column['align'] == 'right') {
          textAlign = TextAlign.right;
        }

        headerWidget = Expanded(
          flex: flex,
          child: Text(
            column['label'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.deepOrange,
            ),
            textAlign: textAlign,
          ),
        );
      }

      headers.add(headerWidget);
    }

    return headers;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Ensure end date is not before start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Job Card')),
        body: const Center(
          child: Text('You do not have permission to view this card.'),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Edit Job Card',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _onCopy();
                  break;
                case 'move':
                  _onMove();
                  break;
                case 'archive':
                  _onArchive();
                  break;
                case 'delete':
                  _onDeletePermanently();
                  break;
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[];
              items.add(
                PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: const [
                      Icon(Icons.copy, size: 18),
                      SizedBox(width: 8),
                      Text('Copy'),
                    ],
                  ),
                ),
              );
              if (_canMove) {
                items.add(
                  PopupMenuItem(
                    value: 'move',
                    child: Row(
                      children: const [
                        Icon(Icons.open_with, size: 18),
                        SizedBox(width: 8),
                        Text('Move'),
                      ],
                    ),
                  ),
                );
              }
              if (_canArchive) {
                items.add(
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: const [
                        Icon(Icons.archive, size: 18),
                        SizedBox(width: 8),
                        Text('Archive'),
                      ],
                    ),
                  ),
                );
              }
              if (_canDelete) {
                items.add(
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: const [
                        Icon(Icons.delete_forever, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Delete Permanently',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return items;
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            _buildSectionCard(
              title: 'Basic Information',
              icon: Icons.info_outline,
              color: Colors.blue,
              children: [
                _buildJobIdSection(),
                const SizedBox(height: 20),
                _buildTitleSection(),
                const SizedBox(height: 20),
                _buildLaneSection(),
              ],
            ),
            const SizedBox(height: 24),

            // Assignment Section
            _buildSectionCard(
              title: 'Assignment & Tags',
              icon: Icons.assignment_ind,
              color: Colors.purple,
              children: [
                _buildHashtagSection(),
                const SizedBox(height: 20),
                _buildAssigneeSection(),
                const SizedBox(height: 20),
                _buildCollaboratorsSection(),
                const SizedBox(height: 20),
                _buildWatchersSection(),
              ],
            ),
            const SizedBox(height: 24),

            // Customer Information Section
            _buildSectionCard(
              title: 'Customer Information',
              icon: Icons.business,
              color: Colors.green,
              children: [
                _buildCustomerSection(),
                const SizedBox(height: 20),
                _buildCustomerInterestSection(),
              ],
            ),
            const SizedBox(height: 24),

            // Product Section
            _buildSectionCard(
              title: 'Products & Services',
              icon: Icons.shopping_cart,
              color: Colors.deepOrange,
              children: [_buildProductSection()],
            ),
            const SizedBox(height: 24),

            // Related Documents Section
            _buildSectionCard(
              title: 'Related Documents',
              icon: Icons.description,
              color: Colors.purple,
              children: [_buildRelatedDocumentsSection()],
            ),
            const SizedBox(height: 24),

            // Content Section
            _buildSectionCard(
              title: 'Content & Details',
              icon: Icons.edit_document,
              color: Colors.indigo,
              children: [_buildDetailsSection()],
            ),
            const SizedBox(height: 24),

            // Content & Tasks Section  
            _buildSectionCard(
              title: 'Content & Tasks',
              icon: Icons.task_alt,
              color: Colors.purple,
              children: [_buildTodoListSection()],
            ),
            const SizedBox(height: 24),

            // Timeline & Status Section
            _buildSectionCard(
              title: 'Timeline & Status',
              icon: Icons.schedule,
              color: Colors.orange,
              children: [
                _buildExpectedClosingDateSection(),
                const SizedBox(height: 20),
                _buildStatusChipsSection(),
              ],
            ),
            const SizedBox(height: 24),

            // Attached Files Section
            _buildSectionCard(
              title: 'Attached Files',
              icon: Icons.attach_file,
              color: Colors.teal,
              children: [_buildAttachedFilesContent()],
            ),
            const SizedBox(height: 24),

            // History & Comments Section
            _buildHistoryCommentSection(),
            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildExpectedClosingDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.teal[700]),
            const SizedBox(width: 8),
            const Text(
              'Expected Closing Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectStartDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.teal[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.teal[50],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.today, size: 16, color: Colors.teal[700]),
                          const SizedBox(width: 6),
                          Text(
                            'Start Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Select start date',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward,
                size: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _selectEndDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _endDate != null
                          ? Colors.teal[300]!
                          : Colors.grey[300]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: _endDate != null ? Colors.teal[50] : Colors.grey[50],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event,
                            size: 16,
                            color: _endDate != null
                                ? Colors.teal[700]
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: _endDate != null
                                  ? Colors.teal[700]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Select end date',
                        style: TextStyle(
                          fontSize: 16,
                          color: _endDate != null
                              ? Colors.black87
                              : Colors.grey[500],
                          fontWeight: _endDate != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag, size: 18, color: Colors.orange[700]),
            const SizedBox(width: 6),
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[50],
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _statusOptions.map((status) {
              final isSelected = _selectedStatus == status['value'];
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = status['value'];
                    });
                  },
                  icon: Icon(status['icon'], size: 16),
                  label: Text(
                    status['label'],
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? AppTheme.primaryOrange : Colors.white,
                    foregroundColor: isSelected ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryOrange : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    elevation: isSelected ? 2 : 0,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: _statusOptions.map((status) {
                final isSelected = _selectedStatus == status['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status['icon'],
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(status['label']),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryOrange,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedStatus = status['value'];
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expense Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Add Custom'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Img',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Product/Service',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Qty/Unit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Price/Unit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Discount',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No expense items added yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            // Create Quotation Button
            ElevatedButton.icon(
              onPressed: _createDocument,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Quotation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                textStyle: const TextStyle(fontSize: 12),
                elevation: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_isLoadingRelatedDocuments)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_relatedDocuments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No related documents yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),
          )
        else
          // Documents Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        child: Text(
                          'Doc No.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Job Card',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Seller',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Valid Until',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Table Rows
                ...List.generate(_relatedDocuments.length, (index) {
                  return _buildDocumentRow(_relatedDocuments[index], index);
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentRow(Map<String, dynamic> document, int index) {
    final documentData = document['data'] as Map<String, dynamic>? ?? {};
    final documentId = document['id'] ?? '';
    final documentType = document['type'] ?? 'QT'; // Default to QT from backup data
    final createdAt = document['createdAt'] ?? '';
    
    // Extract data from document based on actual structure
    final docNumber = document['docNo'] ?? documentData['docNo'] ?? documentId.substring(0, 8);
    final jobCardId = widget.card.customId;
    
    // Handle seller information - check multiple possible fields
    String seller = 'N/A';
    if (documentData['seller'] != null) {
      if (documentData['seller'] is Map) {
        seller = documentData['seller']['displayName'] ?? 
                documentData['seller']['name'] ?? 
                documentData['sellerName'] ?? 'N/A';
      }
    } else {
      seller = documentData['sellerName'] ?? 
              documentData['createdBy'] ?? 
              documentData['createdByDisplayName'] ?? 'N/A';
    }
    
    // Handle total amount - check multiple possible fields
    final totalAmount = documentData['grandTotal'] ?? 
                       documentData['netTotal'] ?? 
                       documentData['totalAmount'] ?? 
                       documentData['total'] ?? 0;
    
    final status = documentData['status'] ?? 'DRAFT';
    final validUntil = documentData['validUntil'] ?? documentData['dueDate'] ?? '';
    
    // Convert timestamps to readable format
    String createdDate = '';
    if (createdAt != null && createdAt != '') {
      try {
        if (createdAt is int) {
          final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
          createdDate = '${date.day}/${date.month}/${date.year}';
        } else if (createdAt is String && createdAt.isNotEmpty) {
          final date = DateTime.parse(createdAt);
          createdDate = '${date.day}/${date.month}/${date.year}';
        }
      } catch (e) {
        createdDate = createdAt.toString();
      }
    }
    
    String validUntilDate = '';
    if (validUntil != null && validUntil != '') {
      try {
        if (validUntil is int) {
          final date = DateTime.fromMillisecondsSinceEpoch(validUntil);
          validUntilDate = '${date.day}/${date.month}/${date.year}';
        } else if (validUntil is String && validUntil.isNotEmpty) {
          final date = DateTime.parse(validUntil);
          validUntilDate = '${date.day}/${date.month}/${date.year}';
        }
      } catch (e) {
        validUntilDate = validUntil.toString();
      }
    }
    
    return InkWell(
      onTap: status == 'NOT_FOUND' ? null : () => viewDocument(document),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: index < _relatedDocuments.length - 1 
                ? BorderSide(color: Colors.grey[200]!)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            // Doc No.
            SizedBox(
              width: 50,
              child: Text(
                docNumber,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
          
          // Type
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _getDocumentIcon(documentType),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getDocumentTypeLabel(documentType),
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // Job Card
          Expanded(
            flex: 3,
            child: Text(
              jobCardId,
              style: const TextStyle(fontSize: 12, color: Colors.blue),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          
          // Seller
          Expanded(
            flex: 2,
            child: Text(
              seller,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          
          // Date
          Expanded(
            flex: 2,
            child: Text(
              createdDate,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          
          // Valid Until
          Expanded(
            flex: 2,
            child: Text(
              validUntilDate,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          
          // Amount
          Expanded(
            flex: 2,
            child: Text(
              '฿${_formatNumber(totalAmount)}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // Status Dropdown
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getDocumentStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getDocumentStatusColor(status),
                  width: 1,
                ),
              ),
              child: status == 'NOT_FOUND'
                ? Center(
                    child: Text(
                      'ไม่พบเอกสาร',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getDocumentStatusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: status,
                      isDense: true,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: 10,
                        color: _getDocumentStatusColor(status),
                        fontWeight: FontWeight.w500,
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: _getDocumentStatusColor(status),
                      ),
                      items: _documentStatusOptions.map((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'],
                          child: Text(
                            option['label'],
                            style: TextStyle(
                              fontSize: 10,
                              color: _getDocumentStatusColor(option['value']),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null && newStatus != status) {
                          _updateDocumentStatus(documentId, newStatus);
                        }
                      },
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 8),
          
          // More Menu
          SizedBox(
            width: 40,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, size: 18, color: Colors.grey[600]),
              onSelected: (value) {
                switch (value) {
                  case 'download':
                    _downloadDocument(document);
                    break;
                  case 'duplicate':
                    _duplicateDocument(document);
                    break;
                  case 'edit':
                    _editDocument(document);
                    break;
                  case 'delete':
                    _deleteDocument(document);
                    break;
                }
              },
              itemBuilder: (context) => status == 'NOT_FOUND' 
                ? [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('ลบอ้างอิง', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ]
                : [
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('ดาวน์โหลด', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('คัดลอก', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text('แก้ไข', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('ลบ', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  String _getDocumentTypeLabel(String type) {
    switch (type) {
      case 'quotation':
      case 'QT': // Support QT type from backup data
        return 'ใบเสนอราคา';
      case 'invoice':
      case 'INV':
        return 'ใบแจ้งหนี้';
      case 'receipt':
      case 'REC':
        return 'ใบเสร็จ';
      case 'purchase_order':
      case 'PO':
        return 'ใบสั่งซื้อ';
      default:
        return 'เอกสาร';
    }
  }

  Widget _getDocumentIcon(String docType) {
    IconData iconData;
    Color iconColor;

    switch (docType) {
      case 'quotation':
      case 'QT': // Support QT type from backup data
        iconData = Icons.request_quote;
        iconColor = Colors.orange;
        break;
      case 'invoice':
      case 'INV':
        iconData = Icons.receipt;
        iconColor = Colors.green;
        break;
      case 'receipt':
      case 'REC':
        iconData = Icons.receipt_long;
        iconColor = Colors.blue;
        break;
      case 'purchase_order':
      case 'PO':
        iconData = Icons.shopping_cart;
        iconColor = Colors.purple;
        break;
      default:
        iconData = Icons.description;
        iconColor = Colors.grey;
    }

    return Icon(iconData, color: iconColor, size: 24);
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildAttachedFilesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add File Button
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          child: ElevatedButton.icon(
            onPressed: _canEditAttachments ? _addFile : null,
            icon: const Icon(Icons.attach_file, size: 18),
            label: const Text('Add File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Files Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'File Name',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Uploaded By',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Uploaded At',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Actions',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),

        // Files Content
        if (_attachments.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Column(
              children: _attachments.map((attachment) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFileIcon(attachment['filename'] ?? ''),
                        color: Colors.blue[600],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              attachment['name'] ??
                                  attachment['filename'] ??
                                  'Unknown file',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _formatFileSize(attachment['size'] ?? 0),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.download, size: 18),
                            onPressed: () => _downloadFile(attachment),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteAttachment(attachment),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No attachments uploaded yet',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _addFile() async {
    if (!_canEditAttachments) {
      _showNoPermission();
      return;
    }
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _isLoading = true;
          });

          await _uploadAndAddAttachment(File(file.path!), file.name, file.size);
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadAndAddAttachment(
    File file,
    String fileName,
    int? fileSize,
  ) async {
    try {
      // Import UploadService
      final uploadService = Get.find<UploadService>();

      // Get current user info
      if (_currentUserInfo == null) {
        await _loadCurrentUserInfo();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final workspaceId = _controller.currentWorkspaceId.value;
      final cardId = widget.card.id;

      // Upload file to Firebase Storage
      final downloadUrl = await uploadService.uploadFile(
        file: file,
        workspaceId: workspaceId,
        chatroomId:
            'cards/$cardId', // Use cards/cardId as chatroomId for card attachments
        onProgress: (progress) {
          // You can add progress indicator here if needed
        },
      );

      // Create attachment object with correct id format
      final attachment = {
        'id': 'workspaces/$workspaceId/cards/$cardId/$timestamp-$fileName',
        'name': fileName,
        'filename': fileName,
        'url': downloadUrl,
        'uploadedAt': timestamp,
        'uploadedBy': _currentUserInfo?['uid'] ?? '',
        'size': fileSize ?? 0,
      };

      // Add to local attachments list
      setState(() {
        _attachments.add(attachment);
      });

      // Update card in database immediately
      await _updateCardAttachments();

      Get.snackbar(
        'Success',
        'File uploaded successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _updateCardAttachments() async {
    try {
      final updatedCard = widget.card.copyWith(
        attachments: _attachments,
        updatedAt: DateTime.now(),
      );

      await _controller.updateCard(updatedCard);
    } catch (e) {
      print('Failed to update card attachments: $e');
    }
  }

  IconData _getFileIcon(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _downloadFile(Map<String, dynamic> attachment) {
    // TODO: Implement download functionality
    Get.snackbar(
      'Download',
      'Download functionality will be available soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _deleteAttachment(Map<String, dynamic> attachment) {
    if (!_canEditAttachments) {
      _showNoPermission();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attachment'),
        content: Text(
          'Are you sure you want to delete "${attachment['name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeleteAttachment(attachment);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteAttachment(Map<String, dynamic> attachment) async {
    try {
      setState(() {
        _attachments.removeWhere((item) => item['id'] == attachment['id']);
      });

      await _updateCardAttachments();

      Get.snackbar(
        'Success',
        'Attachment deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete attachment: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _showMoveCardDialog() {
    showDialog(
      context: context,
      builder: (context) => _MoveCardDialog(
        currentBoardId: widget.card.boardId,
        currentLaneId: widget.card.laneId,
        cardId: widget.card.id,
        onMoveCard: _moveCard,
      ),
    );
  }

  Future<void> _moveCard(String targetBoardId, String targetLaneId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Determine old/new lane names for notification context
      final oldLaneId = widget.card.laneId;
      final oldLaneName = _availableLanes.firstWhereOrNull((l) => l['id'] == oldLaneId)?['name'] ?? oldLaneId;
      final newLaneName = _availableLanes.firstWhereOrNull((l) => l['id'] == targetLaneId)?['name'] ?? targetLaneId;

      // Update card with new boardId and laneId before moving
      final updatedCard = widget.card.copyWith(
        boardId: targetBoardId,
        laneId: targetLaneId,
        updatedAt: DateTime.now(),
      );

      // Update card in repository first
      await _controller.updateCard(updatedCard);

      // Then perform the move operation
      await _controller.onMoveCard(
        cardId: widget.card.id,
        fromLaneId: widget.card.laneId,
        toLaneId: targetLaneId,
        toIndex: 0, // Move to top of target lane
      );

      // Notify watchers/collaborators/assignee about lane change
      final recipients = _collectNotifyRecipients(excludeUserId: _currentUserInfo?['uid']);
      if (recipients.isNotEmpty) {
        try {
          await NotificationsService.to.notifyStatusChange(
            userIds: recipients,
            cardId: widget.card.id,
            boardId: targetBoardId,
            oldStatus: oldLaneName,
            newStatus: newLaneName,
            workspaceId: _controller.currentWorkspaceId.value,
            workspaceName: _controller.currentWorkspaceName.value,
            createdBy: _currentUserInfo?['uid'],
          );
        } catch (_) {}
      }

      Get.snackbar(
        'Success',
        'Card moved successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Close edit page and go back to board with refresh signal
      Navigator.of(context).pop(true); // true = card was moved, need refresh
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to move card: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Build History/Comment toggle section
  Widget _buildHistoryCommentSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Toggle buttons
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showHistory = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _showHistory
                            ? Colors.grey[300]
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        'History',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _showHistory
                              ? Colors.black87
                              : Colors.grey[600],
                          fontWeight: _showHistory
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showHistory = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: !_showHistory ? Colors.blue : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Comment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_showHistory
                              ? Colors.white
                              : Colors.grey[600],
                          fontWeight: !_showHistory
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Container(
            height: 300,
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: _showHistory
                ? _buildHistoryContent()
                : _buildCommentContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'bew kiw created card Job Card Title in lane In Progress',
            style: TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text('1 day ago', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCommentContent() {
    return Column(
      children: [
        // Display existing comments
        Expanded(
          child: _notes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.comment, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No comments yet',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    final isReply = note['parentId'] != null;

                    return Container(
                      margin: EdgeInsets.only(
                        bottom: 16,
                        left: isReply ? 40 : 0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue,
                            child: Text(
                              (note['userDisplayName'] ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      note['userDisplayName'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatTimestamp(note['timestamp']),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _stripHtmlTags(note['text'] ?? ''),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (!isReply) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _showReplyDialog(note['id']),
                                    child: const Text(
                                      'Reply',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        // Add comment input at bottom
        Container(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  enabled: _canEditNotes,
                  decoration: InputDecoration(
                    hintText: 'Add a comment',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    fillColor: Colors.grey[50],
                    filled: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _canEditNotes ? _addComment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper methods for comments
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _stripHtmlTags(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  void _showReplyDialog(String parentId) {
    if (!_canEditNotes) {
      _showNoPermission();
      return;
    }
    final TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reply to Comment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: replyController,
          decoration: InputDecoration(
            hintText: 'Type your reply...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 3,
          minLines: 3,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (replyController.text.trim().isNotEmpty) {
                _addReply(parentId, replyController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Reply',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      // Get current user from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Load user information from Firestore
        _currentUserInfo = await _repository.getCurrentUserInfo(
          currentUser.uid,
        );
        print('🔄 Current user loaded: ${_currentUserInfo?['displayName']}');
      }
    } catch (e) {
      print('❌ Failed to load current user info: $e');
      // Set fallback user info
      _currentUserInfo = {
        'uid': 'unknown-user',
        'displayName': 'Current User',
        'email': '',
        'photoURL': null,
      };
    }
  }

  void _addComment() async {
    if (!_canEditNotes) {
      _showNoPermission();
      return;
    }
    if (_commentController.text.trim().isEmpty) return;

    final newComment = {
      'id': 'note-${DateTime.now().millisecondsSinceEpoch}',
      'userId': _currentUserInfo?['uid'] ?? 'unknown-user',
      'userDisplayName': _currentUserInfo?['displayName'] ?? 'Current User',
      'userPhotoURL': _currentUserInfo?['photoURL'],
      'text': '<p>${_commentController.text.trim()}</p>',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'mentions': [],
      'cardId': widget.card.id,
      'cardTitle': widget.card.title,
      'type': 'text',
    };

    // Optimistic update - add to local state first
    setState(() {
      _notes.add(newComment);
      _commentController.clear();
    });

    try {
      // Save to Firestore immediately
      await _repository.addNoteToCard(
        _controller.currentWorkspaceId.value,
        widget.card.id,
        newComment,
      );
      print('✅ Comment saved to Firestore successfully');

      // Notify watchers/collaborators/assignee
      final recipients = _collectNotifyRecipients(excludeUserId: _currentUserInfo?['uid']);
      if (recipients.isNotEmpty) {
        try {
          await NotificationsService.to.notifyComment(
            userIds: recipients,
            commenterName: _currentUserInfo?['displayName'] ?? 'Someone',
            cardId: widget.card.id,
            boardId: widget.card.boardId,
            workspaceId: _controller.currentWorkspaceId.value,
            workspaceName: _controller.currentWorkspaceName.value,
            createdBy: _currentUserInfo?['uid'],
          );
        } catch (_) {}
      }
    } catch (e) {
      print('❌ Failed to save comment to Firestore: $e');
      // Remove from local state if failed
      setState(() {
        _notes.removeWhere((note) => note['id'] == newComment['id']);
      });

      Get.snackbar(
        'Error',
        'Failed to save comment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _addReply(String parentId, String replyText) async {
    if (!_canEditNotes) {
      _showNoPermission();
      return;
    }
    final newReply = {
      'id': 'note-${DateTime.now().millisecondsSinceEpoch}',
      'userId': _currentUserInfo?['uid'] ?? 'unknown-user',
      'userDisplayName': _currentUserInfo?['displayName'] ?? 'Current User',
      'userPhotoURL': _currentUserInfo?['photoURL'],
      'text': '<p>$replyText</p>',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'mentions': [],
      'parentId': parentId,
      'cardId': widget.card.id,
      'cardTitle': widget.card.title,
      'type': 'text',
    };

    // Optimistic update - add to local state first
    setState(() {
      _notes.add(newReply);
    });

    try {
      // Save to Firestore immediately
      await _repository.addNoteToCard(
        _controller.currentWorkspaceId.value,
        widget.card.id,
        newReply,
      );
      print('✅ Reply saved to Firestore successfully');

      // Notify watchers/collaborators/assignee
      final recipients = _collectNotifyRecipients(excludeUserId: _currentUserInfo?['uid']);
      if (recipients.isNotEmpty) {
        try {
          await NotificationsService.to.notifyComment(
            userIds: recipients,
            commenterName: _currentUserInfo?['displayName'] ?? 'Someone',
            cardId: widget.card.id,
            boardId: widget.card.boardId,
            workspaceId: _controller.currentWorkspaceId.value,
            workspaceName: _controller.currentWorkspaceName.value,
            createdBy: _currentUserInfo?['uid'],
          );
        } catch (_) {}
      }
    } catch (e) {
      print('❌ Failed to save reply to Firestore: $e');
      // Remove from local state if failed
      setState(() {
        _notes.removeWhere((note) => note['id'] == newReply['id']);
      });

      Get.snackbar(
        'Error',
        'Failed to save reply. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Save and Cancel buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  List<String> _collectNotifyRecipients({String? excludeUserId}) {
    final set = <String>{};
    if (_selectedAssignee.isNotEmpty) set.add(_selectedAssignee);
    for (final c in _selectedCollaborators) {
      if (c.isNotEmpty) set.add(c);
    }
    for (final w in _selectedWatchers) {
      if (w.isNotEmpty) set.add(w);
    }
    if (excludeUserId != null && excludeUserId.isNotEmpty) {
      set.remove(excludeUserId);
    }
    return set.toList();
  }

  Future<void> _saveChanges() async {
    if (!_canEditAny) {
      _showNoPermission();
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Title is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Determine original vs new values for notifications
      final originalAssignee = widget.card.assignedTo;
      final originalStatus = widget.card.status;
      final originalLaneId = widget.card.laneId;
      final originalLaneName = _availableLanes.firstWhereOrNull((l) => l['id'] == originalLaneId)?['name'] ?? originalLaneId;

      // Get assignee details for updatedByDisplayName
      String assigneeDisplayName = '';
      if (_selectedAssignee.isNotEmpty) {
        final selectedUser = _availableAssignees.firstWhereOrNull(
          (user) => user['id'] == _selectedAssignee,
        );
        assigneeDisplayName =
            selectedUser?['displayName'] ??
            selectedUser?['name'] ??
            _selectedAssignee;
      }

      // Get customer name if selected
      String customerName = '';
      if (_selectedCustomer.isNotEmpty) {
        final selectedCustomer = _availableCustomers.firstWhereOrNull(
          (c) => c['id'] == _selectedCustomer,
        );
        customerName = selectedCustomer?['name'] ?? '';
      }

      // Prepare todos data in correct format
      final todosData = _todoItems
          .map(
            (todo) => {
              'id': 'todo-${todo['id']}',
              'title':
                  '<p><span style="color: rgb(2, 8, 23); font-size: 24px;"><strong><em>${todo['text'] ?? ''}</em></strong></span></p>',
              'completed': todo['isCompleted'] ?? false,
              'dueDate': _normalizeEpoch(todo['dueDate']),
              'mentions': [],
            },
          )
          .toList();

      // Format description as HTML from HTML editor
      String htmlDescription = '';
      final editorContent = await _htmlEditorController.getText();
      if (editorContent.isNotEmpty) {
        htmlDescription = editorContent;
      }

      // Prepare expenses data from product items
      final expensesData = _productItems
          .map(
            (product) => {
              'id': product['id'],
              'productId': product['productId'],
              'name': product['name'],
              'description': product['description'] ?? '',
              'quantity': (product['quantity'] ?? 0).toInt(),
              'unit': product['unit'],
              'pricePerUnit': (product['pricePerUnit'] ?? product['price'] ?? 0)
                  .toInt(), // Use pricePerUnit field first, fallback to price
              'discount': (product['discount'] ?? 0).toInt(),
              'discountType': product['discountType'],
              'customInputs': product['customInputs'] ?? {}, // Include custom inputs
            },
          )
          .toList();

  // Create updated card
      final updatedCard = widget.card.copyWith(
        title: _titleController.text.trim(),
        description: htmlDescription, // Use HTML formatted description
        customId: _jobIdController.text.trim(),
        status: _selectedStatus,
        assignedTo: _selectedAssignee,
        customer: customerName, // Store customer name, not ID
        customerId: _selectedCustomer.isNotEmpty ? _selectedCustomer : null,
        customerInterest: _selectedCustomerInterest,
        laneId: _selectedLane,
        dueDate: _expectedClosingDate,
        startDate: _startDate,
        endDate: _endDate,
        hashtag: _selectedHashtags.isNotEmpty
            ? _selectedHashtags.map((h) => '#${h['text']}').join(' ')
            : null,
        hashtags: _selectedHashtags,
        todos: todosData,
        collaborators: _selectedCollaborators,
        watchers: _selectedWatchers,
        attachments: _attachments,
        expenses: expensesData, // Include expenses
        isVatEnabled: _isVatEnabled, // Include VAT setting
        additionalDiscount: _additionalDiscount, // Include additional discount
        withholdingTaxPercentage:
            _withholdingTaxPercentage, // Include withholding tax
        quotationTemplateId: _selectedTemplateId, // เก็บ template ID ที่เลือก
        updatedAt: DateTime.now(),
        updatedByDisplayName: assigneeDisplayName,
      );

      // Update card in repository
      await _controller.updateCard(updatedCard);

      // Persist expenses to Firestore subcollection for real-time sync with document page
      try {
        final firestore = FirebaseFirestore.instance;
        final ws = widget.card.workspaceId;
        final cardId = widget.card.id;
        if (ws.isNotEmpty && cardId.isNotEmpty) {
          final coll = firestore
              .collection('workspaces')
              .doc(ws)
              .collection('cards')
              .doc(cardId)
              .collection('expenses');

          // Overwrite strategy: delete existing docs then add current items
          final existing = await coll.get();
          for (final d in existing.docs) {
            await d.reference.delete();
          }
          int order = 0;
          for (final item in _productItems) {
            final docId = (item['id']?.toString().isNotEmpty ?? false)
                ? item['id'].toString()
                : 'exp-${DateTime.now().millisecondsSinceEpoch}-$order';
            final data = {
              'productId': item['productId'],
              'name': item['name'],
              'description': item['description'] ?? '',
              'quantity': (item['quantity'] ?? 0).toInt(),
              'unit': item['unit'] ?? 'item',
              'pricePerUnit': (item['pricePerUnit'] ?? item['price'] ?? 0)
                  .toInt(),
              'discount': (item['discount'] ?? 0).toInt(),
              'discountType': item['discountType'] ?? 'percentage',
              'customInputs': item['customInputs'] ?? <String, dynamic>{},
              'order': order,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            };
            await coll.doc(docId).set(data);
            order++;
          }
          print('✅ Expenses subcollection synced (${_productItems.length} items)');
        }
      } catch (e) {
        print('⚠️ Failed to sync expenses subcollection: $e');
      }

      Get.snackbar(
        'Success',
        'Card updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      Navigator.of(context).pop();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update card: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int? _normalizeEpoch(dynamic value) {
    if (value == null) return null;
    if (value is int) return value; // already epoch
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return null;
  }

  /// Navigate to create quotation page with job card data
  Future<void> _createDocument() async {
    if (widget.card.expenses.isEmpty) {
      Get.snackbar(
        'No Products',
        'Please add products or services before creating a quotation.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Debug: Print selected template ID
    print('🎯 EditCardPage - selected templateId: $_selectedTemplateId');

    // Navigate to CreateDocumentFromCardPage with selected template
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDocumentFromCardPage(
          jobCard: widget.card,
          templateId: _selectedTemplateId,
        ),
      ),
    );

    // If quotation was created successfully, refresh the related documents
    if (result == true) {
      print('🔄 EditCardPage - Quotation created successfully, refreshing related documents');
      await _loadRelatedDocumentsDetails();
    }
  }

  // Hashtag section methods (copied from create page)
  Widget _buildHashtagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tag, size: 18, color: Colors.purple[700]),
            const SizedBox(width: 6),
            const Text(
              'Hashtags',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _openHashtagModal,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: _selectedHashtags.isEmpty
                ? Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Tap to select hashtags...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Selected (${_selectedHashtags.length})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedHashtags.map((hashtag) {
                          return Chip(
                            label: Text(
                              '#${hashtag['text']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: Color(
                              int.parse(
                                hashtag['color'].replaceFirst('#', '0xff'),
                              ),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.edit, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to edit selection',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobIdSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job ID',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _jobIdController,
          enabled: true,
          decoration: const InputDecoration(
            hintText: 'Enter Job ID',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            fillColor: Colors.white,
            filled: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Card Title',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Enter job title',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLaneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lane',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value:
              _selectedLane.isNotEmpty &&
                  _availableLanes.any((lane) => lane['id'] == _selectedLane)
              ? _selectedLane
              : null,
          decoration: const InputDecoration(
            hintText: 'Select lane',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: _availableLanes.map((lane) {
            return DropdownMenuItem<String>(
              value: lane['id'],
              child: Text(
                lane['name'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLane = value ?? '';
            });
          },
        ),
      ],
    );
  }

  Widget _buildAssigneeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assignee *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value:
              _selectedAssignee.isNotEmpty &&
                  _availableAssignees.any(
                    (assignee) => assignee['id'] == _selectedAssignee,
                  )
              ? _selectedAssignee
              : null,
          decoration: const InputDecoration(
            hintText: 'Select an assignee',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: _availableAssignees.map((assignee) {
            return DropdownMenuItem<String>(
              value: assignee['id'],
              child: Text(
                assignee['name'] ?? assignee['id'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAssignee = value ?? '';
            });
          },
        ),
      ],
    );
  }

  Widget _buildCollaboratorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Collaborators',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE1E5E9)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              // Selected collaborators chips
              if (_selectedCollaborators.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedCollaborators.map((userId) {
                      final user = _availableAssignees.firstWhereOrNull(
                        (u) => u['id'] == userId,
                      );
                      final userName = user?['name'] ?? userId;
                      return Chip(
                        label: Text(userName),
                        onDeleted: () {
                          setState(() {
                            _selectedCollaborators.remove(userId);
                          });
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                      );
                    }).toList(),
                  ),
                ),
              // Add collaborator button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add Collaborator',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: _availableAssignees
                      .where(
                        (user) => !_selectedCollaborators.contains(user['id']),
                      )
                      .map((user) {
                        return DropdownMenuItem<String>(
                          value: user['id'],
                          child: Text(user['name'] ?? user['id']),
                        );
                      })
                      .toList(),
                  onChanged: (value) {
                    if (value != null &&
                        !_selectedCollaborators.contains(value)) {
                      setState(() {
                        _selectedCollaborators.add(value);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWatchersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Watchers',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE1E5E9)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              // Selected watchers chips
              if (_selectedWatchers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _selectedWatchers.map((userId) {
                      final user = _availableAssignees.firstWhereOrNull(
                        (u) => u['id'] == userId,
                      );
                      final userName = user?['name'] ?? userId;
                      return Chip(
                        label: Text(userName),
                        onDeleted: () {
                          setState(() {
                            _selectedWatchers.remove(userId);
                          });
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                      );
                    }).toList(),
                  ),
                ),
              // Add watcher button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<String>(
                  value: null,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add Watcher',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  items: _availableAssignees
                      .where((user) => !_selectedWatchers.contains(user['id']))
                      .map((user) {
                        return DropdownMenuItem<String>(
                          value: user['id'],
                          child: Text(user['name'] ?? user['id']),
                        );
                      })
                      .toList(),
                  onChanged: (value) {
                    if (value != null && !_selectedWatchers.contains(value)) {
                      setState(() {
                        _selectedWatchers.add(value);
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCustomer.isNotEmpty ? _selectedCustomer : null,
          decoration: const InputDecoration(
            hintText: 'Select customer',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: _availableCustomers.map((customer) {
            return DropdownMenuItem<String>(
              value: customer['id'],
              child: Text(
                customer['name'] ?? customer['id'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCustomer = value ?? '';
            });

            // Load companies for selected customer
            if (value != null && value.isNotEmpty) {
              _loadCompaniesForCustomer(value);
            } else {
              setState(() {
                _availableCompanies = [
                  {'id': 'none', 'name': 'None'},
                ];
                _selectedCompany = 'none';
              });
            }
          },
        ),
        const SizedBox(height: 20),
        // Company Section
        const Text(
          'Company',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value:
              _selectedCompany.isNotEmpty &&
                  _availableCompanies.any((c) => c['id'] == _selectedCompany)
              ? _selectedCompany
              : null,
          decoration: const InputDecoration(
            hintText: 'Select company',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: _availableCompanies.map((company) {
            return DropdownMenuItem<String>(
              value: company['id'],
              child: Text(
                company['name'] ?? company['id'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCompany = value ?? 'none';
            });
          },
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Details',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HtmlEditor(
            controller: _htmlEditorController,
            htmlEditorOptions: HtmlEditorOptions(
              hint: 'Enter job details...',
              shouldEnsureVisible: true,
              initialText: widget.card.description.isNotEmpty ? widget.card.description : '',
            ),
            htmlToolbarOptions: const HtmlToolbarOptions(
              toolbarPosition: ToolbarPosition.aboveEditor,
              toolbarType: ToolbarType.nativeScrollable,
              defaultToolbarButtons: [
                StyleButtons(style: false),
                FontSettingButtons(fontName: false, fontSize: false, fontSizeUnit: false),
                FontButtons(bold: true, italic: true, underline: true, clearAll: false, strikethrough: false, superscript: false, subscript: false),
                ColorButtons(foregroundColor: false, highlightColor: false),
                ListButtons(ul: true, ol: true, listStyles: false),
                ParagraphButtons(textDirection: false, lineHeight: false, caseConverter: false),
                InsertButtons(link: false, picture: false, audio: false, video: false, hr: false, table: false),
                OtherButtons(fullscreen: false, codeview: false, undo: true, redo: true, help: false),
              ],
            ),
            otherOptions: const OtherOptions(
              height: 150,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'To-Do List',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _showTodoTemplates,
              icon: const Icon(Icons.description, size: 16),
              label: const Text('Apply Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addTodoItem,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Todo items list
        if (_todoItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text(
                'No to-do items yet. Add one to get started!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Column(
            children: _todoItems.asMap().entries.map((entry) {
              final index = entry.key;
              final todo = entry.value;
              return _buildTodoItem(index, todo);
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTodoItem(int index, Map<String, dynamic> todo) {
    final TextEditingController controller = todo['controller'];
    final DateTime? dueDate = todo['dueDate'];
    final DateTime? endTime = todo['endTime'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Checkbox for todo completion
              Checkbox(
                value: todo['isCompleted'] ?? false,
                onChanged: (bool? value) {
                  setState(() {
                    todo['isCompleted'] = value ?? false;
                  });
                },
                activeColor: AppTheme.primaryOrange,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              
              // Input field
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'Enter todo item...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onChanged: (value) {
                    todo['text'] = value;
                  },
                  style: TextStyle(
                    decoration: (todo['isCompleted'] ?? false) 
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                    color: (todo['isCompleted'] ?? false) 
                      ? Colors.grey[600] 
                      : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Set time button with indicator
              Container(
                decoration: BoxDecoration(
                  color: (dueDate != null || endTime != null) 
                    ? Colors.green 
                    : Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  onPressed: () => _setTodoTime(index),
                  icon: Icon(
                    (dueDate != null || endTime != null) 
                      ? Icons.schedule_send 
                      : Icons.access_time, 
                    color: Colors.white, 
                    size: 20
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
              const SizedBox(width: 8),
              
              // Delete button
              Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  onPressed: () => _removeTodoItem(index),
                  icon: const Icon(Icons.delete, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            ],
          ),
          
          // Show time information if any is set
          if (dueDate != null || endTime != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: Column(
                children: [
                  // Due date
                  if (dueDate != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.today, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${_formatDateTime(dueDate)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Duration/End Time
                  if (endTime != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 16, color: Colors.green[700]),
                          const SizedBox(width: 4),
                          Text(
                            'End: ${_formatDateTime(endTime)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Todo methods
  void _addTodoItem() {
    setState(() {
      _todoItems.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': '',
        'isCompleted': false,
        'dueDate': null,
        'duration': null,
        'endTime': null,
        'controller': TextEditingController(),
      });
    });
  }

  void _removeTodoItem(int index) {
    setState(() {
      // Dispose controller to prevent memory leaks
      _todoItems[index]['controller']?.dispose();
      _todoItems.removeAt(index);
    });
  }

  void _setTodoTime(int index) async {
    if (!mounted) return;
    
    // Show options dialog first
    final String? timeOption = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Todo Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current time status
            if (_todoItems[index]['dueDate'] != null ||
                _todoItems[index]['endTime'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current: ${_getCurrentTimeType(index)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getCurrentTimeValue(index),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Time options
            ListTile(
              leading: Icon(
                Icons.today, 
                color: _todoItems[index]['dueDate'] != null ? Colors.green : Colors.blue
              ),
              title: Text(
                'Set Due Date & Time',
                style: TextStyle(
                  fontWeight: _todoItems[index]['dueDate'] != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: _todoItems[index]['dueDate'] != null 
                ? Text('Currently set', style: TextStyle(color: Colors.green[700]))
                : null,
              onTap: () => Navigator.of(context).pop('datetime'),
            ),
            ListTile(
              leading: Icon(
                Icons.schedule, 
                color: _todoItems[index]['endTime'] != null ? Colors.green : Colors.green
              ),
              title: Text(
                'Set Duration',
                style: TextStyle(
                  fontWeight: _todoItems[index]['endTime'] != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: _todoItems[index]['endTime'] != null 
                ? Text('Currently set', style: TextStyle(color: Colors.green[700]))
                : null,
              onTap: () => Navigator.of(context).pop('duration'),
            ),
            if (_todoItems[index]['dueDate'] != null ||
                _todoItems[index]['endTime'] != null)
              const Divider(),
            if (_todoItems[index]['dueDate'] != null ||
                _todoItems[index]['endTime'] != null)
              ListTile(
                leading: const Icon(Icons.clear, color: Colors.red),
                title: const Text('Clear All Times'),
                onTap: () => Navigator.of(context).pop('clear'),
              ),
          ],
        ),
      ),
    );

    if (timeOption != null && mounted) {
      switch (timeOption) {
        case 'datetime':
          _clearAllTimes(index);
          await _setDueDateTime(index);
          break;
        case 'duration':
          _clearAllTimes(index);
          await _setDuration(index);
          break;
        case 'clear':
          _clearAllTimes(index);
          break;
      }
    }
  }

  Future<void> _setDueDateTime(int index) async {
    if (!mounted) return;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _todoItems[index]['dueDate'] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _todoItems[index]['dueDate'] != null 
          ? TimeOfDay.fromDateTime(_todoItems[index]['dueDate'])
          : TimeOfDay.now(),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          _todoItems[index]['dueDate'] = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _setDuration(int index) async {
    if (!mounted) return;
    
    final DateTime now = DateTime.now();
    final int? currentDuration = _todoItems[index]['duration'];
    final DateTime? endTime = currentDuration != null 
      ? now.add(Duration(minutes: currentDuration))
      : null;
    
    final TextEditingController durationController = TextEditingController(
      text: currentDuration?.toString() ?? '',
    );
    
    final int? duration = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (endTime != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'End time: ${_formatDateTime(endTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration (minutes)',
                hintText: 'Enter duration in minutes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quick select:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildDurationChip('15 min', 15, durationController, now),
                _buildDurationChip('30 min', 30, durationController, now),
                _buildDurationChip('1 hour', 60, durationController, now),
                _buildDurationChip('2 hours', 120, durationController, now),
                _buildDurationChip('4 hours', 240, durationController, now),
                _buildDurationChip('8 hours', 480, durationController, now),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(durationController.text);
              Navigator.of(context).pop(value);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );

    durationController.dispose();

    if (duration != null && mounted) {
      setState(() {
        _todoItems[index]['duration'] = duration;
        _todoItems[index]['endTime'] = now.add(Duration(minutes: duration));
      });
    }
  }

  Widget _buildDurationChip(String label, int minutes, TextEditingController controller, DateTime now) {
    final DateTime endTime = now.add(Duration(minutes: minutes));
    return ActionChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          Text(
            '→ ${_formatDateTime(endTime)}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
      onPressed: () {
        controller.text = minutes.toString();
      },
      backgroundColor: Colors.blue[50],
      labelStyle: TextStyle(color: Colors.blue[700]),
    );
  }

  void _clearAllTimes(int index) {
    setState(() {
      _todoItems[index]['dueDate'] = null;
      _todoItems[index]['duration'] = null;
      _todoItems[index]['endTime'] = null;
    });
  }

  String _getCurrentTimeType(int index) {
    if (_todoItems[index]['dueDate'] != null) {
      return 'Due Date & Time';
    } else if (_todoItems[index]['endTime'] != null) {
      return 'Duration';
    }
    return 'None';
  }

  String _getCurrentTimeValue(int index) {
    if (_todoItems[index]['dueDate'] != null) {
      return _formatDateTime(_todoItems[index]['dueDate']);
    } else if (_todoItems[index]['endTime'] != null) {
      return _formatDateTime(_todoItems[index]['endTime']);
    }
    return '';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showTodoTemplates() {
    // Implementation for todo templates
  }

  Widget _buildProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and template selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Product Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            // Template dropdown and buttons row
            Row(
              children: [
                // Template Dropdown
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepOrange, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedTemplateId,
                      hint: const Text('Select Template'),
                      items: _quotationTemplates.map((template) {
                        return DropdownMenuItem<String>(
                          value: template['id'],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              template['name'],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        print('🔄 Template dropdown changed: $value');
                        final selectedTemplate = _quotationTemplates.firstWhereOrNull((t) => t['id'] == value);
                        if (selectedTemplate != null) {
                          print('📋 Selected template: ${selectedTemplate['name']}');
                        }
                        _onTemplateChanged(value);
                      },
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.deepOrange,
                      ),
                      iconSize: 20,
                      style: const TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _addCustomProduct,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Add Custom'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepOrange,
                    side: const BorderSide(
                      color: Colors.deepOrange,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Product table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange[50]!, Colors.orange[50]!],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: Colors.deepOrange[200]!),
          ),
          child: Row(children: _buildHeaderColumns()),
        ),

        // Product items list
        _buildProductItems(),

        // Summary section
        _buildProductSummary(),
      ],
    );
  }

  Widget _buildProductItems() {
    if (_productItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepOrange[50],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 48,
                  color: Colors.deepOrange[300],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No products added yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click "Add Product" to start adding products or services',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _productItems.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey[300]),
        itemBuilder: (context, index) {
          final product = _productItems[index];
          return _buildProductRow(product, index);
        },
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _buildProductCells(product, index),
      ),
    );
  }

  List<Widget> _buildProductCells(Map<String, dynamic> product, int index) {
    List<Widget> cells = [];

    for (final column in _visibleColumns) {
      Widget cellWidget = _buildProductCell(column, product, index);
      cells.add(cellWidget);
    }

    // Always add delete button at the end
    cells.add(
      GestureDetector(
        onTap: () => _deleteProduct(index),
        child: Icon(Icons.close, size: 16, color: Colors.red[400]),
      ),
    );

    return cells;
  }

  Widget _buildProductCell(
    Map<String, dynamic> column,
    Map<String, dynamic> product,
    int index,
  ) {
    // Determine flex based on column width
    int flex = 2; // default
    String? widthStr = column['width'];
    if (widthStr != null) {
      if (widthStr.contains('%')) {
        final percentage = int.tryParse(widthStr.replaceAll('%', '')) ?? 20;
        flex = (percentage / 10).round().clamp(1, 6);
      } else if (widthStr.contains('px')) {
        flex = 1;
      } else {
        flex = int.tryParse(widthStr) ?? 2;
      }
    }

    // Handle special columns
    if (column['id'] == 'img' || column['type'] == 'image') {
      return SizedBox(
        width: 50,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: product['image'] != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    product['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[400],
                        size: 20,
                      );
                    },
                  ),
                )
              : Icon(Icons.image, color: Colors.grey[400], size: 20),
        ),
      );
    }

    // Get field key based on column type and sourceField
    String fieldKey = _getFieldKey(column);

    // Handle different column types
    switch (column['type']) {
      case 'product_field':
        return _buildEditableCell(flex, product, fieldKey, column, index);

      case 'predefined':
        return _buildPredefinedCell(flex, product, column, index);

      case 'user_input':
        return _buildUserInputCell(flex, product, column, index);

      default:
        return _buildDisplayCell(
          flex,
          product[fieldKey]?.toString() ?? '',
          column,
        );
    }
  }

  String _getFieldKey(Map<String, dynamic> column) {
    // For user_input columns, use prefillSourceField if available, otherwise use column id
    if (column['type'] == 'user_input') {
      return column['prefillSourceField'] ??
          column['id'] ??
          'user_field_${column['id']}';
    }

    if (column['sourceField'] != null) {
      return column['sourceField'];
    }

    switch (column['predefinedField']) {
      case 'quantity':
        return 'quantity';
      case 'line_total':
        return 'total';
      case 'discount':
        return 'discount';
      default:
        return column['id'] ?? '';
    }
  }

  Widget _buildEditableCell(
    int flex,
    Map<String, dynamic> product,
    String fieldKey,
    Map<String, dynamic> column,
    int index,
  ) {
    // Special handling for unit field combined with quantity
    if (fieldKey == 'quantity' && column['predefinedField'] == 'quantity') {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: [
              TextFormField(
                initialValue: (product['quantity'] ?? 0)
                    .toDouble()
                    .toInt()
                    .toString(),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  setState(() {
                    _productItems[index]['quantity'] =
                        double.tryParse(value) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 2),
              TextFormField(
                initialValue: product['unit'] ?? 'item',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
                textAlign: TextAlign.center,
                onChanged: (value) {
                  setState(() {
                    _productItems[index]['unit'] = value;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    // Regular editable fields
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextFormField(
          initialValue: _getInitialValue(product, fieldKey),
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          keyboardType: _getKeyboardType(fieldKey),
          textAlign: _getTextAlign(column),
          onChanged: (value) {
            setState(() {
              if (fieldKey == 'pricePerUnit') {
                _productItems[index]['pricePerUnit'] =
                    double.tryParse(value) ?? 0;
                if (_productItems[index]['price'] != null) {
                  _productItems[index]['price'] = double.tryParse(value) ?? 0;
                }
              } else if (fieldKey == 'quantity') {
                _productItems[index]['quantity'] = double.tryParse(value) ?? 0;
              } else {
                _productItems[index][fieldKey] = value;
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildPredefinedCell(
    int flex,
    Map<String, dynamic> product,
    Map<String, dynamic> column,
    int index,
  ) {
    final predefinedField = column['predefinedField'];

    switch (predefinedField) {
      case 'quantity':
        return _buildEditableCell(flex, product, 'quantity', column, index);

      case 'discount':
        return Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                TextFormField(
                  initialValue: (product['discount'] ?? 0)
                      .toDouble()
                      .toInt()
                      .toString(),
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: (value) {
                    setState(() {
                      _productItems[index]['discount'] =
                          double.tryParse(value) ?? 0;
                    });
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _productItems[index]['discountType'] = 'percentage';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: product['discountType'] == 'percentage'
                              ? Colors.orange
                              : Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          border: Border.all(
                            color: product['discountType'] == 'percentage'
                                ? Colors.orange
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontSize: 12,
                            color: product['discountType'] == 'percentage'
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _productItems[index]['discountType'] = 'amount';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: product['discountType'] == 'amount'
                              ? Colors.orange
                              : Colors.grey[200],
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          border: Border.all(
                            color: product['discountType'] == 'amount'
                                ? Colors.orange
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          '฿',
                          style: TextStyle(
                            fontSize: 12,
                            color: product['discountType'] == 'amount'
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      case 'line_total':
        return Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '฿${_formatPrice(_calculateItemTotal(product))}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        );

      default:
        return _buildDisplayCell(
          flex,
          product[predefinedField]?.toString() ?? '',
          column,
        );
    }
  }

  Widget _buildDisplayCell(
    int flex,
    String value,
    Map<String, dynamic> column,
  ) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          value,
          style: const TextStyle(fontSize: 14),
          textAlign: _getTextAlign(column),
        ),
      ),
    );
  }

  Widget _buildUserInputCell(
    int flex,
    Map<String, dynamic> product,
    Map<String, dynamic> column,
    int index,
  ) {
    // Always store/read user_input under customInputs[column.id]
    final String columnId = (column['id'] ?? '').toString();

    // Ensure customInputs map exists
    product['customInputs'] ??= <String, dynamic>{};
    final Map<String, dynamic> customInputs =
        (product['customInputs'] as Map).cast<String, dynamic>();

    // Determine initial value: only from existing customInputs (no prefill here)
    String initial = '';
    if (customInputs.containsKey(columnId) &&
        (customInputs[columnId]?.toString().isNotEmpty ?? false)) {
      initial = customInputs[columnId].toString();
    }

    print('🔧 Building user input cell:');
    print('  - Column ID: $columnId');
    print('  - Product customInputs: ${customInputs}');
    print('  - Initial value: "$initial"');

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextFormField(
          key: Key('${product['id']}_${columnId}_${_selectedTemplateId}'), // ใช้ key เพื่อ force rebuild เมื่อเปลี่ยน template
          initialValue: initial,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14),
          textAlign: _getTextAlign(column),
          onChanged: (value) {
            setState(() {
              product['customInputs'][columnId] = value;
            });
          },
        ),
      ),
    );
  }

  String _getInitialValue(Map<String, dynamic> product, String fieldKey) {
    final value = product[fieldKey];
    if (value == null) return '';

    if (fieldKey == 'pricePerUnit' ||
        fieldKey == 'price' ||
        fieldKey == 'quantity') {
      return value.toDouble().toInt().toString();
    }

    return value.toString();
  }

  TextInputType _getKeyboardType(String fieldKey) {
    if (fieldKey == 'pricePerUnit' ||
        fieldKey == 'price' ||
        fieldKey == 'quantity' ||
        fieldKey == 'discount') {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  TextAlign _getTextAlign(Map<String, dynamic> column) {
    switch (column['align']) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  Widget _buildProductSummary() {
    final subtotal = _calculateSubtotal();
    final itemDiscount = _calculateTotalDiscount();
    final subtotalAfterItemDiscount = subtotal - itemDiscount;

    // Calculate additional discount
    double additionalDiscountAmount = 0.0;
    if (_additionalDiscount != null &&
        (_additionalDiscount!['value'] ?? 0) > 0) {
      if (_additionalDiscount!['type'] == 'percentage') {
        additionalDiscountAmount =
            subtotalAfterItemDiscount *
            ((_additionalDiscount!['value'] ?? 0).toDouble() / 100);
      } else {
        additionalDiscountAmount = (_additionalDiscount!['value'] ?? 0)
            .toDouble();
      }
    }

    final totalAmount = subtotalAfterItemDiscount - additionalDiscountAmount;
    final vat = _isVatEnabled ? _calculateVAT(totalAmount) : 0.0;
    final grandTotal = totalAmount + vat;

    // Calculate withholding tax
    final withholdingTax = (_withholdingTaxPercentage > 0)
        ? grandTotal * (_withholdingTaxPercentage / 100)
        : 0.0;
    final finalAmount = grandTotal - withholdingTax;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', subtotal),

          // Additional Discount Row with Toggle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Switch(
                      value:
                          (_additionalDiscount != null &&
                          (_additionalDiscount!['value'] ?? 0) > 0),
                      onChanged: (value) {
                        setState(() {
                          if (value) {
                            _additionalDiscount = {
                              'value': 97,
                              'type': 'percentage',
                            };
                          } else {
                            _additionalDiscount = null;
                          }
                        });
                      },
                      activeColor: Colors.orange,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Discount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (_additionalDiscount != null &&
                    (_additionalDiscount!['value'] ?? 0) > 0) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          initialValue: (_additionalDiscount!['value'] ?? 0)
                              .toString(),
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          onChanged: (value) {
                            setState(() {
                              _additionalDiscount!['value'] =
                                  double.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _additionalDiscount!['type'] = 'percentage';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _additionalDiscount!['type'] == 'percentage'
                                    ? Colors.orange
                                    : Colors.grey[200],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                                border: Border.all(
                                  color:
                                      _additionalDiscount!['type'] ==
                                          'percentage'
                                      ? Colors.orange
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                'เปอร์เซ็น',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      _additionalDiscount!['type'] ==
                                          'percentage'
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _additionalDiscount!['type'] = 'amount';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _additionalDiscount!['type'] == 'amount'
                                    ? Colors.orange
                                    : Colors.grey[200],
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                border: Border.all(
                                  color:
                                      _additionalDiscount!['type'] == 'amount'
                                      ? Colors.orange
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                'บาท',
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      _additionalDiscount!['type'] == 'amount'
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '฿0.00',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),

          _buildSummaryRow('Total Amount', totalAmount),

          // VAT Row with Toggle
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Switch(
                      value: _isVatEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isVatEnabled = value;
                        });
                      },
                      activeColor: Colors.orange,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'VAT (7%)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  '฿${_formatPrice(vat)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),
          _buildSummaryRow(
            'Grand Total:',
            grandTotal,
            isBold: true,
            fontSize: 16,
          ),

          // Withholding Tax Row with Checkbox and Input
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _withholdingTaxPercentage > 0,
                      onChanged: (value) {
                        setState(() {
                          _withholdingTaxPercentage = value == true ? 3.0 : 0.0;
                        });
                      },
                      activeColor: Colors.orange,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const Text(
                      'หัก ณ ที่จ่าย',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (_withholdingTaxPercentage > 0) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: TextFormField(
                          initialValue: _withholdingTaxPercentage
                              .toInt()
                              .toString(),
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (value) {
                            setState(() {
                              _withholdingTaxPercentage =
                                  double.tryParse(value) ?? 0;
                            });
                          },
                        ),
                      ),
                      const Text('%', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 16),
                      Text(
                        '(฿${_formatPrice(withholdingTax)})',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '฿0.00',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ),

          if (_withholdingTaxPercentage > 0) ...[
            const Divider(),
            _buildSummaryRow(
              'ยอดชำระสุทธิ:',
              finalAmount,
              isBold: true,
              fontSize: 16,
              color: Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isNegative = false,
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? Colors.black87,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}฿${_formatPrice(amount)}',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? (isBold ? Colors.deepOrange : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInterestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Interest',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCustomerInterest,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: _customerInterestOptions.map((interest) {
            return DropdownMenuItem<String>(
              value: interest,
              child: Text(interest),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCustomerInterest = value!;
            });
          },
        ),
      ],
    );
  }

  void _openHashtagModal() {
    showDialog(
      context: context,
      builder: (context) => HashtagSelectionModal(
        selectedHashtags: _selectedHashtags,
        onHashtagsSelected: (selectedHashtags) {
          setState(() {
            _selectedHashtags = selectedHashtags;
          });
        },
      ),
    );
  }

  // Product management methods
  void _addProduct() {
    _showProductSelectionDialog();
  }

  Future<void> _showProductSelectionDialog() async {
    final selectedProducts = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (context) => _ProductSelectionDialog(
        workspaceId: _controller.currentWorkspaceId.value,
      ),
    );

    if (selectedProducts != null && selectedProducts.isNotEmpty) {
      setState(() {
        for (final product in selectedProducts) {
          // Create new product item for table
          final newItem = {
            'id':
                'exp-${DateTime.now().millisecondsSinceEpoch}-${product['id']}',
            'productId': product['id'],
            'name': product['name'],
            'description': product['description'] ?? '',
            'quantity': 1.0,
            'unit': product['unit'] ?? 'item',
            'price': (product['price'] ?? 0).toDouble(),
            'pricePerUnit': (product['price'] ?? 0).toDouble(),
            'discount': 0.0,
            'discountType': 'amount',
            'image': product['imageUrl'],
          };

          // Add dynamic customInputs for user_input columns based on current template
          for (final column in _visibleColumns) {
            if (column['type'] == 'user_input') {
              final String columnId = (column['id'] ?? '').toString();
              final String? prefillField =
                  (column['prefillSourceField'] as String?)?.trim();
              newItem['customInputs'] ??= <String, dynamic>{};
              // Prefill from product data if available
              newItem['customInputs'][columnId] = prefillField != null &&
                      prefillField.isNotEmpty
                  ? (product[prefillField]?.toString() ?? '')
                  : '';
            }
          }

          _productItems.add(newItem);
        }
      });
    }
  }

  void _addCustomProduct() {
    setState(() {
      // Create empty custom product item
      final newItem = {
        'id': 'custom-${DateTime.now().millisecondsSinceEpoch}',
        'productId': null, // No product ID for custom items
        'name': '', // Empty name to be filled by user
        'description': '', // Empty description
        'quantity': 1.0,
        'unit': 'item',
        'price': 0.0,
        'pricePerUnit': 0.0,
        'discount': 0.0,
        'discountType': 'amount',
        'image': null, // No image for custom items
      };

      // Add dynamic customInputs for user_input columns based on current template
      for (final column in _visibleColumns) {
        if (column['type'] == 'user_input') {
          final String columnId = (column['id'] ?? '').toString();
          newItem['customInputs'] ??= <String, dynamic>{};
          final Map<String, dynamic> ci =
              (newItem['customInputs'] as Map).cast<String, dynamic>();
          ci[columnId] = '';
          newItem['customInputs'] = ci;
        }
      }

      _productItems.add(newItem);
    });

    // Show a helpful message
    Get.snackbar(
      'Custom Product Added',
      'Empty product row added. You can now edit the details.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  // Load related documents details
  Future<void> _loadRelatedDocumentsDetails() async {
    try {
      setState(() {
        _isLoadingRelatedDocuments = true;
      });

      final firestore = FirebaseFirestore.instance;
      final workspaceId = widget.card.workspaceId;
      final cardId = widget.card.id;

      if (workspaceId.isEmpty) {
        print('⚠️ Missing workspaceId for loading related documents');
        return;
      }

      // Get fresh card data from Firestore to get latest relatedDocuments
      final cardSnapshot = await firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('cards')
          .doc(cardId)
          .get();

      List<Map<String, dynamic>> cardRelatedDocuments = [];
      
      if (cardSnapshot.exists) {
        final cardData = cardSnapshot.data()!;
        
        // Extract relatedDocuments from fresh card data
        final relatedDocsRaw = cardData['relatedDocuments'];
        if (relatedDocsRaw != null && relatedDocsRaw is List) {
          cardRelatedDocuments = List<Map<String, dynamic>>.from(
            relatedDocsRaw.map((doc) => Map<String, dynamic>.from(doc))
          );
        }
      } else {
        // Fallback to widget card data if Firestore fetch fails
        cardRelatedDocuments = widget.card.relatedDocuments;
      }
      
      if (cardRelatedDocuments.isEmpty) {
        print('ℹ️ No related documents found in card');
        setState(() {
          _relatedDocuments = [];
          _isLoadingRelatedDocuments = false;
        });
        return;
      }

      List<Map<String, dynamic>> detailedDocuments = [];

      // Loop through each related document ID and fetch detailed data
      for (var relatedDoc in cardRelatedDocuments) {
        try {
          final documentId = relatedDoc['id'] ?? '';
          final docNo = relatedDoc['docNo'] ?? '';
          final docType = relatedDoc['type'] ?? 'QT';

          if (documentId.isEmpty) {
            print('⚠️ Missing document ID in related document');
            continue;
          }

          print('🔍 Loading document: $documentId ($docNo)');

          // Get detailed document data from workspace documents collection
          final documentSnapshot = await firestore
              .collection('workspaces')
              .doc(workspaceId)
              .collection('documents')
              .doc(documentId)
              .get();

          if (documentSnapshot.exists) {
            final documentData = documentSnapshot.data()!;

            detailedDocuments.add({
              'id': documentId,
              'type': docType,
              'docNo': docNo,
              'data': documentData,
              'createdAt': documentData['createdAt'] ?? DateTime.now().toIso8601String(),
            });
            
            print('✅ Loaded document: $docNo (${documentData['type'] ?? docType})');
          } else {
            print('⚠️ Document $documentId not found in workspace documents');
            
            // Add placeholder data for missing documents
            detailedDocuments.add({
              'id': documentId,
              'type': docType,
              'docNo': docNo,
              'data': {
                'status': 'NOT_FOUND',
                'docNo': docNo,
                'type': docType,
              },
              'createdAt': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          print('❌ Error loading document: $e');
        }
      }

      setState(() {
        _relatedDocuments = detailedDocuments;
        _isLoadingRelatedDocuments = false;
      });

      print('✅ Loaded ${detailedDocuments.length} related documents');
    } catch (e) {
      print('❌ Error loading related documents: $e');
      setState(() {
        _isLoadingRelatedDocuments = false;
      });
    }
  }

  // Related Documents management methods
  Future<void> _updateDocumentStatus(String documentId, String newStatus) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final workspaceId = widget.card.workspaceId;

      // Update status in documents collection
      await firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('documents')
          .doc(documentId)
          .update({
        'status': newStatus,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Reload related documents to reflect changes
      await _loadRelatedDocumentsDetails();

      Get.snackbar(
        'Success',
        'Document status updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update document status: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _downloadDocument(Map<String, dynamic> document) {
    // TODO: Implement download functionality
    Get.snackbar(
      'Download',
      'Download functionality will be available soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _duplicateDocument(Map<String, dynamic> document) {
    // TODO: Implement duplicate functionality
    Get.snackbar(
      'Duplicate',
      'Duplicate functionality will be available soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _editDocument(Map<String, dynamic> document) {
    final documentId = document['id'] as String?;
    final documentType = document['type'] ?? 'QT';
    
    if (documentId != null && documentId.isNotEmpty) {
      Get.to(() => AddEditDocumentPage(
        documentType: documentType,
        documentId: documentId,
      ));
    } else {
      Get.snackbar(
        'Error',
        'Cannot open document: Invalid document ID',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// View document in edit page (similar to quotation_list_page.dart)
  void viewDocument(Map<String, dynamic> document) {
    final documentId = document['id'] as String?;
    final documentType = document['type'] ?? 'QT';
    
    if (documentId != null && documentId.isNotEmpty) {
      Get.to(() => AddEditDocumentPage(
        documentType: documentType,
        documentId: documentId,
      ));
    } else {
      Get.snackbar(
        'Error',
        'Cannot open document: Invalid document ID',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _deleteDocument(Map<String, dynamic> document) {
    final documentId = document['id'] ?? '';
    final docNo = document['docNo'] ?? 'N/A';
    final documentData = document['data'] as Map<String, dynamic>? ?? {};
    final status = documentData['status'] ?? 'DRAFT';
    
    final isNotFound = status == 'NOT_FOUND';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isNotFound ? 'ลบอ้างอิงเอกสาร' : 'ลบเอกสาร'),
        content: Text(isNotFound 
          ? 'คุณแน่ใจหรือไม่ที่จะลบอ้างอิงเอกสาร $docNo?\n\nเอกสารนี้ไม่พบในระบบแล้ว จะลบเฉพาะอ้างอิงออกจากการ์ดนี้'
          : 'คุณแน่ใจหรือไม่ที่จะลบเอกสาร $docNo?\n\nการลบนี้จะลบเอกสารออกจากระบบอย่างถาวร และไม่สามารถย้อนกลับได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performDeleteDocument(documentId, '');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(isNotFound ? 'ลบอ้างอิง' : 'ลบ'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteDocument(String documentId, String relatedDocId) async {
    try {
      final workspaceId = _controller.currentWorkspaceId.value;
      final cardId = widget.card.id;
      
      // Check if this document has NOT_FOUND status
      final document = _relatedDocuments.firstWhere(
        (doc) => doc['id'] == documentId,
        orElse: () => {},
      );
      final documentData = document['data'] as Map<String, dynamic>? ?? {};
      final status = documentData['status'] ?? 'DRAFT';
      
      print('🗑️ Deleting document: $documentId, Status: $status');
      
      // Step 1: Delete from documents collection (if document exists)
      if (status != 'NOT_FOUND') {
        print('🗑️ Deleting from /documents collection...');
        await _repository.deleteDocument(
          workspaceId: workspaceId,
          documentId: documentId,
        );
        print('✅ Deleted from /documents collection');
      } else {
        print('ℹ️ Skipping /documents deletion - document has NOT_FOUND status');
      }
      
      // Step 2: Update card's relatedDocuments field in Firestore directly
      print('🗑️ Removing reference from card relatedDocuments...');
      
      final firestore = FirebaseFirestore.instance;
      final cardRef = firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('cards')
          .doc(cardId);
      
      // Get current card data
      final cardSnapshot = await cardRef.get();
      if (cardSnapshot.exists) {
        final cardData = cardSnapshot.data()!;
        final currentRelatedDocs = List<Map<String, dynamic>>.from(
          cardData['relatedDocuments'] ?? []
        );
        
        // Remove the document with matching ID
        final originalCount = currentRelatedDocs.length;
        currentRelatedDocs.removeWhere((doc) => doc['id'] == documentId);
        final newCount = currentRelatedDocs.length;
        
        print('🗑️ Removed ${originalCount - newCount} reference(s) from relatedDocuments');
        
        // Update the card in Firestore
        await cardRef.update({
          'relatedDocuments': currentRelatedDocs,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('✅ Updated card relatedDocuments in Firestore');
      }

      // Step 3: Reload related documents to reflect changes
      print('🔄 Reloading related documents...');
      await _loadRelatedDocumentsDetails();

      Get.snackbar(
        'Success',
        status == 'NOT_FOUND' ? 'Document reference removed successfully' : 'Document deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete document: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Color _getDocumentStatusColor(String status) {
    switch (status) {
      case 'DRAFT':
        return Colors.grey;
      case 'APPROVED':
        return Colors.green;
      case 'PENDING_APPROVAL':
        return Colors.orange;
      case 'SENT_FOR_APPROVAL':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      case 'REJECTED':
        return Colors.red;
      case 'INVOICED':
        return Colors.purple;
      case 'FULLY_PAID':
        return Colors.green.shade700;
      case 'NOT_FOUND':
        return Colors.red.shade300;
      default:
        return Colors.grey;
    }
  }

  void _deleteProduct(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _productItems.removeAt(index);
              });
              Navigator.of(context).pop();
              Get.snackbar(
                'Success',
                'Product deleted successfully',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Calculation methods
  double _calculateItemTotal(Map<String, dynamic> product) {
    final quantity = (product['quantity'] ?? 0).toDouble();
    final price = (product['pricePerUnit'] ?? product['price'] ?? 0).toDouble();
    final discount = (product['discount'] ?? 0).toDouble();
    final discountType = product['discountType'] ?? 'amount';

    final subtotal = quantity * price;

    if (discountType == 'percentage') {
      return subtotal - (subtotal * discount / 100);
    } else {
      return subtotal - discount;
    }
  }

  double _calculateSubtotal() {
    return _productItems.fold(0.0, (sum, product) {
      final quantity = (product['quantity'] ?? 0).toDouble();
      final price = (product['pricePerUnit'] ?? product['price'] ?? 0)
          .toDouble();
      return sum + (quantity * price);
    });
  }

  double _calculateTotalDiscount() {
    return _productItems.fold(0.0, (sum, product) {
      final quantity = (product['quantity'] ?? 0).toDouble();
      final price = (product['pricePerUnit'] ?? product['price'] ?? 0)
          .toDouble();
      final discount = (product['discount'] ?? 0).toDouble();
      final discountType = product['discountType'] ?? 'amount';

      final subtotal = quantity * price;

      if (discountType == 'percentage') {
        return sum + (subtotal * discount / 100);
      } else {
        return sum + discount;
      }
    });
  }

  double _calculateVAT(double amount) {
    return amount * 0.07; // 7% VAT
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toInt().toString();
    } else {
      return price.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _jobIdController.dispose();
    _titleController.dispose();
    _detailsController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}

class _MoveCardDialog extends StatefulWidget {
  final String currentBoardId;
  final String currentLaneId;
  final String cardId;
  final Function(String boardId, String laneId) onMoveCard;

  const _MoveCardDialog({
    required this.currentBoardId,
    required this.currentLaneId,
    required this.cardId,
    required this.onMoveCard,
  });

  @override
  State<_MoveCardDialog> createState() => _MoveCardDialogState();
}

class _MoveCardDialogState extends State<_MoveCardDialog> {
  final BoardController _controller = Get.find<BoardController>();

  String _selectedBoardId = '';
  String _selectedLaneId = '';
  List<Board> _availableBoards = [];
  List<Lane> _availableLanes = [];
  bool _isLoading = true;
  bool _isLoadingLanes = false;

  @override
  void initState() {
    super.initState();
    _selectedBoardId = widget.currentBoardId;
    _selectedLaneId = widget.currentLaneId;
    _loadBoards();
  }

  Future<void> _loadBoards() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final workspaceId = _controller.currentWorkspaceId.value;
      final boards = await _controller.getBoardsForWorkspace(workspaceId);

      setState(() {
        _availableBoards = boards;
        _isLoading = false;
      });

      // Load lanes for current selected board
      if (_selectedBoardId.isNotEmpty) {
        await _loadLanesForBoard(_selectedBoardId);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Failed to load boards: $e');
    }
  }

  Future<void> _loadLanesForBoard(String boardId) async {
    try {
      setState(() {
        _isLoadingLanes = true;
        _availableLanes = [];
        _selectedLaneId = '';
      });

      // Get lanes for the selected board from repository
      final boardLanes = await _controller.getLanesByBoardId(boardId);

      setState(() {
        _availableLanes = boardLanes;
        _isLoadingLanes = false;
        // Reset lane selection if current lane is not available in selected board
        if (!_availableLanes.any((lane) => lane.id == _selectedLaneId)) {
          _selectedLaneId = _availableLanes.isNotEmpty
              ? _availableLanes.first.id
              : '';
        }
      });
    } catch (e) {
      print('Failed to load lanes: $e');
      setState(() {
        _availableLanes = [];
        _selectedLaneId = '';
        _isLoadingLanes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Move Card',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select a new board and lane for this card',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Board Selection
              const Text(
                'Board',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFF7F39), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBoardId.isNotEmpty
                        ? _selectedBoardId
                        : null,
                    hint: const Text('Select Board'),
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    items: _availableBoards.map((board) {
                      return DropdownMenuItem<String>(
                        value: board.id,
                        child: Text(board.name),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _selectedBoardId = value;
                        });
                        await _loadLanesForBoard(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Lane Selection
              const Text(
                'Lane',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              if (_isLoadingLanes)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading lanes...'),
                    ],
                  ),
                )
              else if (_availableLanes.isEmpty && _selectedBoardId.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red[300]!, width: 1),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.red[50],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No lanes available in this board',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLaneId.isNotEmpty
                          ? _selectedLaneId
                          : null,
                      hint: const Text('Select Lane'),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: _availableLanes.map((lane) {
                        return DropdownMenuItem<String>(
                          value: lane.id,
                          child: Text(lane.title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLaneId = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _canMoveCard() ? _performMove : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7F39),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Move Card'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canMoveCard() {
    return _selectedBoardId.isNotEmpty &&
        _selectedLaneId.isNotEmpty &&
        _availableLanes.isNotEmpty && // Check if lanes are available
        !_isLoading &&
        !_isLoadingLanes && // Check if lanes are still loading
        !(_selectedBoardId == widget.currentBoardId &&
            _selectedLaneId == widget.currentLaneId);
  }

  void _performMove() {
    Navigator.of(context).pop();
    widget.onMoveCard(_selectedBoardId, _selectedLaneId);
  }
}

// Product Selection Dialog
class _ProductSelectionDialog extends StatefulWidget {
  final String workspaceId;

  const _ProductSelectionDialog({required this.workspaceId});

  @override
  State<_ProductSelectionDialog> createState() =>
      _ProductSelectionDialogState();
}

class _ProductSelectionDialogState extends State<_ProductSelectionDialog> {
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  Set<String> _selectedProductIds = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final querySnapshot = await firestore
          .collection('workspaces/${widget.workspaceId}/products')
          .where('showInCatalog', isEqualTo: true)
          .get();

      final products = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'price': data['price'] ?? 0,
          'unit': data['unit'] ?? 'item',
          'imageUrl': data['imageUrl'],
          'sku': data['sku'] ?? '',
          'description': data['description'] ?? '',
        };
      }).toList();

      // Sort products by name in Dart instead of Firestore
      products.sort(
        (a, b) => (a['name'] as String).compareTo(b['name'] as String),
      );

      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });

      print('✅ Products loaded successfully: ${products.length} products');
    } catch (e) {
      print('❌ Failed to load products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          final name = (product['name'] ?? '').toLowerCase();
          final sku = (product['sku'] ?? '').toLowerCase();
          return name.contains(query) || sku.contains(query);
        }).toList();
      }
    });
  }

  void _toggleProduct(String productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  List<Map<String, dynamic>> _getSelectedProducts() {
    return _allProducts
        .where((product) => _selectedProductIds.contains(product['id']))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'เพิ่มสินค้า',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ชื่อ,รายละเอียด,Hashtag,สินค้า',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepOrange[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.deepOrange[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.deepOrange),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products list section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'รายการสินค้า',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (_selectedProductIds.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'เลือกแล้ว ${_selectedProductIds.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.deepOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Products list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'ไม่พบสินค้า',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final isSelected = _selectedProductIds.contains(
                          product['id'],
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _toggleProduct(product['id']),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.deepOrange
                                      : Colors.grey[300]!,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected
                                    ? Colors.deepOrange[50]
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        _toggleProduct(product['id']),
                                    activeColor: Colors.deepOrange,
                                  ),

                                  // Product image
                                  Container(
                                    width: 60,
                                    height: 60,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: product['imageUrl'] != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              product['imageUrl'],
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.image,
                                                      color: Colors.grey[400],
                                                      size: 30,
                                                    );
                                                  },
                                            ),
                                          )
                                        : Icon(
                                            Icons.image,
                                            color: Colors.grey[400],
                                            size: 30,
                                          ),
                                  ),

                                  // Product details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '฿${(product['price'] ?? 0).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Pagination (if needed)
            const SizedBox(height: 16),

            // Bottom buttons
            Row(
              children: [
                Text(
                  '< 1 >',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _selectedProductIds.isNotEmpty
                      ? () => Navigator.of(context).pop(_getSelectedProducts())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'confirm'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
