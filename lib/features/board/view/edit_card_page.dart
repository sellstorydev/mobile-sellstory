import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../data/services/upload_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../controller/board_controller.dart';
import '../widgets/hashtag_selection_modal.dart';
import '../../../data/repositories/firestore_repository.dart';

class EditCardPage extends StatefulWidget {
  final JobCard card;

  const EditCardPage({
    super.key,
    required this.card,
  });

  @override
  State<EditCardPage> createState() => _EditCardPageState();
}

class _EditCardPageState extends State<EditCardPage> {
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
    Get.snackbar(
      'Move',
      'Move functionality will be available soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _onArchive() {
    Get.snackbar(
      'Archive',
      'Archive functionality will be available soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _onDeletePermanently() {
    Get.snackbar(
      'Delete Permanently',
      'Delete functionality will be available soon',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
  final BoardController _controller = Get.find<BoardController>();
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  
  // Form controllers
  final TextEditingController _jobIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  
  // Current user information
  Map<String, dynamic>? _currentUserInfo;
  
  // Hashtag state (same as create page)
  List<Map<String, dynamic>> _selectedHashtags = [];
  
  // Todo state 
  List<Map<String, dynamic>> _todoItems = [];
  
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
    _selectedLane = widget.card.laneId;
    _selectedAssignee = widget.card.assignedTo;
    _selectedCustomer = widget.card.customerId ?? ''; // ใช้ customerId แทน customer
    _selectedCompany = widget.card.company?['id'] ?? 'none'; // Initialize company from JobCard
    _selectedCustomerInterest = (widget.card.customerInterest?.isNotEmpty ?? false) ? widget.card.customerInterest! : 'เริ่มต้น';
    _selectedStatus = widget.card.status;
    _startDate = widget.card.startDate;
    _endDate = widget.card.endDate;
    
    // Initialize hashtags (same as create page)
    _selectedHashtags = List<Map<String, dynamic>>.from(widget.card.hashtags);
    
    // Initialize todos
    _todoItems = List<Map<String, dynamic>>.from(widget.card.todos);
    
    // Initialize collaborators and watchers
    _selectedCollaborators = List<String>.from(widget.card.collaborators);
    _selectedWatchers = List<String>.from(widget.card.watchers);
    
    // Initialize notes
    _notes = List<Map<String, dynamic>>.from(widget.card.notes);
    
    // Initialize attachments
    _attachments = List<Map<String, dynamic>>.from(widget.card.attachments);
    
    // Load available options
    await _loadAvailableOptions();
    
    // โหลด companies ของ customer ที่เลือกไว้
    if (_selectedCustomer.isNotEmpty && _selectedCustomer != 'none') {
      await _loadCompaniesForCustomer(_selectedCustomer);
    }
  }

  Future<void> _loadAvailableOptions() async {
    // Load lanes
    final lanes = _controller.lanes;
    _availableLanes = lanes.map((lane) => {
      'id': lane.id,
      'name': lane.title,
    }).toList();
    
    // Validate selected lane exists in available lanes
    if (_selectedLane.isNotEmpty) {
      final laneExists = _availableLanes.any((lane) => lane['id'] == _selectedLane);
      if (!laneExists) {
        print('⚠️ Selected lane $_selectedLane not found in available lanes, resetting');
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
        final customerExists = _availableCustomers.any((customer) => customer['id'] == _selectedCustomer);
        if (!customerExists) {
          print('⚠️ Selected customer $_selectedCustomer not found in available customers, resetting');
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
        final assigneeExists = _availableAssignees.any((assignee) => assignee['id'] == _selectedAssignee);
        if (!assigneeExists) {
          print('⚠️ Selected assignee $_selectedAssignee not found in available assignees, resetting');
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
          if (_selectedCompany != 'none' && !_availableCompanies.any((c) => c['id'] == _selectedCompany)) {
            _selectedCompany = 'none';
          }
        });
        
        print('✅ Companies loaded for customer: ${_availableCompanies.length - 1} companies');
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
          return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'Edit Job Card',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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
              itemBuilder: (context) => [
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
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete_forever, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
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

            // Content Section
            _buildSectionCard(
              title: 'Content & Details',
              icon: Icons.edit_document,
              color: Colors.indigo,
              children: [
                _buildDetailsSection(),
              ],
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
              children: [
                _buildAttachedFilesContent(),
              ],
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
                          Icon(
                            Icons.today,
                            size: 16,
                            color: Colors.teal[700],
                          ),
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
                    border: Border.all(color: _endDate != null ? Colors.teal[300]! : Colors.grey[300]!),
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
                            color: _endDate != null ? Colors.teal[700] : Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'End Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: _endDate != null ? Colors.teal[700] : Colors.grey[600],
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
                          color: _endDate != null ? Colors.black87 : Colors.grey[500],
                          fontWeight: _endDate != null ? FontWeight.w600 : FontWeight.normal,
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
            const SizedBox(width: 8),
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
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _statusOptions.map((status) {
            final isSelected = _selectedStatus == status['value'];
            Color chipColor;
            Color textColor;
            
            // Set colors based on status
            switch (status['value']) {
              case 'Pending':
                chipColor = isSelected ? Colors.grey[400]! : Colors.grey[100]!;
                textColor = isSelected ? Colors.white : Colors.grey[700]!;
                break;
              case 'In Progress':
                chipColor = isSelected ? Colors.orange : Colors.orange[100]!;
                textColor = isSelected ? Colors.white : Colors.orange[800]!;
                break;
              case 'Done':
                chipColor = isSelected ? Colors.green : Colors.green[100]!;
                textColor = isSelected ? Colors.white : Colors.green[800]!;
                break;
              case 'Cancelled':
                chipColor = isSelected ? Colors.red : Colors.red[100]!;
                textColor = isSelected ? Colors.white : Colors.red[800]!;
                break;
              default:
                chipColor = Colors.grey[100]!;
                textColor = Colors.grey[700]!;
            }
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedStatus = status['value'];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status['icon'],
                      size: 16,
                      color: textColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status['label'],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
                  Expanded(flex: 1, child: Text('Img', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 3, child: Text('Product/Service', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Qty/Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Price/Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
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
                  'Related Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Create Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
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
                  Expanded(flex: 2, child: Text('Doc No', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No related documents found',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoListSection() {
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
                  'To-Do List',
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
                      icon: const Icon(Icons.description),
                      label: const Text('Apply Template'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No to-do items yet. Add one to get started!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
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
            onPressed: _addFile,
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
              Expanded(flex: 3, child: Text(
                'File Name',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              )),
              Expanded(flex: 2, child: Text(
                'Uploaded By',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              )),
              Expanded(flex: 2, child: Text(
                'Uploaded At',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              )),
              Expanded(flex: 1, child: Text(
                'Actions',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                textAlign: TextAlign.center,
              )),
            ],
          ),
        ),
        
        // Files Content
        if (_attachments.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
            ),
            child: Column(
              children: _attachments.map((attachment) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 0.5,
                      ),
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
                              attachment['name'] ?? attachment['filename'] ?? 'Unknown file',
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
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
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
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
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
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _addFile() async {
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

  Future<void> _uploadAndAddAttachment(File file, String fileName, int? fileSize) async {
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
        chatroomId: 'cards/$cardId', // Use cards/cardId as chatroomId for card attachments
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
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attachment'),
        content: Text('Are you sure you want to delete "${attachment['name']}"?'),
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

  Widget _buildHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            
            // History items
            const ListTile(
              leading: Icon(Icons.history, color: Colors.grey),
              title: Text('bew kiw updated field Title from New Card to New Cardo.'),
              subtitle: Text('less than a minute ago'),
            ),
            const ListTile(
              leading: Icon(Icons.history, color: Colors.grey),
              title: Text('bew kiw created this card in To Do.'),
              subtitle: Text('about 1 hour ago'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            
            // Comment input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // Comment functionality will be implemented later
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Post'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Text(
              'less than a minute ago Updated by bew kiw',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
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
            color: Colors.grey.withOpacity(0.1),
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
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _showHistory ? Colors.grey[300] : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        'History',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _showHistory ? Colors.black87 : Colors.grey[600],
                          fontWeight: _showHistory ? FontWeight.w600 : FontWeight.normal,
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
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                          color: !_showHistory ? Colors.white : Colors.grey[600],
                          fontWeight: !_showHistory ? FontWeight.w600 : FontWeight.normal,
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
            child: _showHistory ? _buildHistoryContent() : _buildCommentContent(),
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
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'bew kiw created card Job Card Title in lane In Progress',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            '1 day ago',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
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
                      Icon(
                        Icons.comment,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No comments yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                onPressed: _addComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Post',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
    final TextEditingController replyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Reply to Comment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: replyController,
          decoration: InputDecoration(
            hintText: 'Type your reply...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        _currentUserInfo = await _repository.getCurrentUserInfo(currentUser.uid);
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
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
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
      // Get assignee details
      String assigneeDisplayName = '';
      if (_selectedAssignee.isNotEmpty) {
        final selectedUser = _availableAssignees.firstWhereOrNull(
          (user) => user['id'] == _selectedAssignee
        );
        assigneeDisplayName = selectedUser?['displayName'] ?? selectedUser?['name'] ?? _selectedAssignee;
      }
      
      // Get customer name if selected
      String customerName = '';
      if (_selectedCustomer.isNotEmpty) {
        final selectedCustomer = _availableCustomers.firstWhereOrNull(
          (c) => c['id'] == _selectedCustomer
        );
        customerName = selectedCustomer?['name'] ?? '';
      }

      // Prepare todos data in correct format
      final todosData = _todoItems.map((todo) => {
        'id': 'todo-${todo['id']}',
        'title': '<p><span style="color: rgb(2, 8, 23); font-size: 24px;"><strong><em>${todo['text'] ?? ''}</em></strong></span></p>',
        'completed': todo['isCompleted'] ?? false,
        'dueDate': _normalizeEpoch(todo['dueDate']),
        'mentions': [],
      }).toList();

      // Format description as HTML
      String htmlDescription = '';
      if (_detailsController.text.trim().isNotEmpty) {
        htmlDescription = '<p><strong>${_detailsController.text.trim()}</strong></p>';
      }

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
        hashtag: _selectedHashtags.isNotEmpty ? _selectedHashtags.map((h) => '#${h['text']}').join(' ') : null,
        hashtags: _selectedHashtags,
        todos: todosData,
        collaborators: _selectedCollaborators,
        watchers: _selectedWatchers,
        attachments: _attachments,
        updatedAt: DateTime.now(),
        updatedByDisplayName: assigneeDisplayName,
      );

      // Update card in repository
      await _controller.updateCard(updatedCard);

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
                      Icon(Icons.add_circle_outline, size: 20, color: Colors.grey[600]),
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
                          Icon(Icons.check_circle, size: 16, color: Colors.purple[700]),
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
                            backgroundColor: Color(int.parse(hashtag['color'].replaceFirst('#', '0xff'))),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
          value: _selectedLane.isNotEmpty && _availableLanes.any((lane) => lane['id'] == _selectedLane) 
                 ? _selectedLane : null,
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
          value: _selectedAssignee.isNotEmpty && _availableAssignees.any((assignee) => assignee['id'] == _selectedAssignee) 
                 ? _selectedAssignee : null,
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
                      final user = _availableAssignees.firstWhereOrNull((u) => u['id'] == userId);
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: _availableAssignees
                      .where((user) => !_selectedCollaborators.contains(user['id']))
                      .map((user) {
                    return DropdownMenuItem<String>(
                      value: user['id'],
                      child: Text(user['name'] ?? user['id']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && !_selectedCollaborators.contains(value)) {
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
                      final user = _availableAssignees.firstWhereOrNull((u) => u['id'] == userId);
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: _availableAssignees
                      .where((user) => !_selectedWatchers.contains(user['id']))
                      .map((user) {
                    return DropdownMenuItem<String>(
                      value: user['id'],
                      child: Text(user['name'] ?? user['id']),
                    );
                  }).toList(),
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
          value: _selectedCompany.isNotEmpty && _availableCompanies.any((c) => c['id'] == _selectedCompany) 
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
        TextFormField(
          controller: _detailsController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter job details',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
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
            color: Colors.black.withOpacity(0.05),
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
              color: color.withOpacity(0.1),
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

  @override
  void dispose() {
    _jobIdController.dispose();
    _titleController.dispose();
    _detailsController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
