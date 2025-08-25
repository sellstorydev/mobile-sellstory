import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';

import '../../../domain/entities/job_card.dart';
import '../controller/board_controller.dart';

class CreateCardPage extends StatefulWidget {
  final String? laneId;
  final String? boardId;
  final String? workspaceId;

  const CreateCardPage({
    super.key,
    this.laneId,
    this.boardId,
    this.workspaceId,
  });

  @override
  State<CreateCardPage> createState() => _CreateCardPageState();
}

class _CreateCardPageState extends State<CreateCardPage> {
  final BoardController _controller = Get.find<BoardController>();
  
  // Form controllers
  final TextEditingController _jobIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final TextEditingController _assigneeController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  
  // Form state
  String _selectedBoard = '';
  String _selectedLane = '';
  String _selectedCustomer = '';
  String _selectedCompany = 'none';
  String _selectedStatus = 'Pending';
  DateTime? _expectedClosingDate;
  bool _isLoading = false;
  
  // Available options
  List<Map<String, dynamic>> _availableBoards = [];
  List<Map<String, dynamic>> _availableLanes = [];
  List<Map<String, dynamic>> _availableCustomers = [];
  List<Map<String, dynamic>> _availableCompanies = [];
  List<Map<String, dynamic>> _availableUsers = [];
  
  // Status options
  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'Pending', 'label': 'Pending', 'icon': Icons.schedule},
    {'value': 'In Progress', 'label': 'In Progress', 'icon': Icons.schedule},
    {'value': 'Done', 'label': 'Done', 'icon': Icons.schedule},
    {'value': 'Cancelled', 'label': 'Cancelled', 'icon': Icons.schedule},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData().then((_) {
      setState(() {});
    });
  }

  Future<void> _initializeData() async {
    // Set default values
    _titleController.text = 'New Card';
    _assigneeController.text = '';
    
    // Generate default job ID
    _generateJobId();
    
    // Load available options
    await _loadAvailableOptions();
    
    // Set default lane if provided
    if (widget.laneId != null) {
      _selectedLane = widget.laneId!;
    }
  }

  Future<void> _loadAvailableOptions() async {
    // Load boards - use current workspace board
    _availableBoards = [
      {'id': 'current-board', 'name': 'Current Board'},
    ];
    _selectedBoard = 'current-board';
    
    // Load lanes
    final lanes = _controller.lanes;
    _availableLanes = lanes.map((lane) => {
      'id': lane.id,
      'name': lane.title,
    }).toList();
    
    // Set first lane as default if no lane is selected
    if (_selectedLane.isEmpty && _availableLanes.isNotEmpty) {
      _selectedLane = _availableLanes.first['id'];
    }
    
    // Load users from current workspace
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
    } catch (e) {
      print('❌ Failed to load customers: $e');
      _availableCustomers = [];
    }
    
    // Load companies from Firestore
    try {
      print('🔄 Loading companies from Firestore...');
      final companies = await _controller.getCompanies();
      
      // Deduplicate companies by ID to prevent dropdown issues
      final companyMap = <String, Map<String, dynamic>>{};
      companyMap['none'] = {'id': 'none', 'name': 'None'};
      
      for (final company in companies) {
        if (!companyMap.containsKey(company.id)) {
          companyMap[company.id] = {
            'id': company.id,
            'name': company.name,
          };
        }
      }
      _availableCompanies = companyMap.values.toList();
      _selectedCompany = 'none';
      
      print('✅ Companies loaded: ${_availableCompanies.length - 1} companies');
    } catch (e) {
      print('❌ Failed to load companies: $e');
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
        _availableUsers = [];
        return;
      }

      print('🔄 Loading users for workspace: $workspaceId');
      
      // Get users from the workspace
      final users = await _controller.getWorkspaceUsers(workspaceId);
      
      // Map users and remove duplicates based on uid
      final userMap = <String, Map<String, dynamic>>{};
      for (final user in users) {
        final uid = user['uid'] as String? ?? '';
        if (uid.isNotEmpty && !userMap.containsKey(uid)) {
          userMap[uid] = {
            'id': uid,
            'name': user['displayName'] ?? user['email'] ?? 'Unknown User',
            'email': user['email'] ?? '',
          };
        }
      }
      _availableUsers = userMap.values.toList();
      
      print('✅ Loaded ${_availableUsers.length} users for workspace');
    } catch (e) {
      print('❌ Failed to load workspace users: $e');
      _availableUsers = [];
    }
  }

  void _generateJobId() {
    // Job ID will be auto-generated by the server with proper counter

  }

  @override
  void dispose() {
    _jobIdController.dispose();
    _titleController.dispose();
    _hashtagController.dispose();
    _assigneeController.dispose();
    _detailsController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expectedClosingDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        _expectedClosingDate = picked;
      });
    }
  }

  Future<void> _saveCard() async {
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      _showError('Job Card Title is required');
      return;
    }

    if (_assigneeController.text.trim().isEmpty) {
      _showError('Assignee is required');
      return;
    }

    if (_selectedCustomer.isEmpty) {
      _showError('Customer is required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the card with full data structure mapped to DTB.md
      final currentUserId = _controller.currentUserId.value.isNotEmpty ? _controller.currentUserId.value : 'mobile-user';
      final currentWorkspaceId = widget.workspaceId ?? _controller.currentWorkspaceId.value;
      final currentBoardId = _controller.currentBoardId.value;
      
      // Get selected assignee details
      String assigneeId = '';
      if (_assigneeController.text.trim().isNotEmpty) {
        final selectedUser = _availableUsers.firstWhereOrNull(
          (user) => user['id'] == _assigneeController.text.trim()
        );
        assigneeId = selectedUser?['id'] ?? _assigneeController.text.trim();
      }
      
      // Get customer name if selected
      String customerName = '';
      if (_selectedCustomer.isNotEmpty) {
        final selectedCustomer = _availableCustomers.firstWhereOrNull(
          (c) => c['id'] == _selectedCustomer
        );
        customerName = selectedCustomer?['name'] ?? '';
      }
      
      // Get company name if selected
      String? companyName;
      if (_selectedCompany != 'none' && _selectedCompany.isNotEmpty) {
        final selectedCompany = _availableCompanies.firstWhereOrNull(
          (c) => c['id'] == _selectedCompany
        );
        companyName = selectedCompany?['name'];
      }

      final card = JobCard(
        id: '', // Will be generated by Firestore
        title: _titleController.text.trim(),
        description: _detailsController.text.trim(),
        assignee: assigneeId,
        status: _selectedStatus,
        customId: '', // Will be auto-generated with counter
        dueDate: _expectedClosingDate,
        badges: _hashtagController.text.trim().isNotEmpty ? [_hashtagController.text.trim()] : [],
        amount: 0.0,
        laneId: _selectedLane.isNotEmpty ? _selectedLane : '',
        boardId: currentBoardId,
        workspaceId: currentWorkspaceId,
        order: 0, // Will be set by the system
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customer: customerName,
        updatedByDisplayName: '',
        customerId: _selectedCustomer.isNotEmpty ? _selectedCustomer : null,
        company: companyName,
        hashtag: _hashtagController.text.trim().isNotEmpty ? _hashtagController.text.trim() : null,
        expenses: [],
        todos: [],
        notes: [],
        watchers: [currentUserId], // Add creator as watcher
        customFields: [],
        createdBy: currentUserId,
        updatedBy: currentUserId,
      );

      // Add card using controller with full card data
      print('🔄 CreateCardPage._saveCard - Creating card...');
      print('  - Title: "${card.title}"');
      print('  - Title Length: ${card.title.length}');
      print('  - Title Controller Text: "${_titleController.text}"');
      print('  - Title Controller Text Length: ${_titleController.text.length}');
      final cardId = await _controller.createCard(card);

      print('✅ Card created successfully with ID: $cardId');

      // Show success message
      Get.snackbar(
        'Success',
        'Job Card created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      print('🔄 CreateCardPage._saveCard - Navigating back...');
      
      // Wait a moment for the snackbar to show, then navigate back
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate back to previous page (preserves bottom navigation)
      Get.back();
      
      print('✅ CreateCardPage._saveCard - Navigation completed');
    } catch (e) {
      print('❌ CreateCardPage._saveCard - Error: $e');
      _showError('Failed to create card: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Job Card'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Action menu
          PopupMenuButton<String>(
            onSelected: (value) {
              // Add watcher functionality will be implemented later
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'add_watcher',
                child: Row(
                  children: [
                    const Icon(Icons.visibility_outlined, size: 20),
                    const SizedBox(width: 12),
                    const Text('Add a watcher'),
                  ],
                ),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.more_vert),
            ),
          ),
          // Close button
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildJobIdSection(),
                  const SizedBox(height: 16),
                  _buildTitleSection(),
                  const SizedBox(height: 16),
                  _buildBoardLaneSection(),
                  const SizedBox(height: 16),
                  _buildHashtagSection(),
                  const SizedBox(height: 16),
                  _buildAssigneeSection(),
                  const SizedBox(height: 16),
                  _buildCustomerSection(),
                  const SizedBox(height: 16),
                  _buildCompanySection(),
                  const SizedBox(height: 16),
                  _buildExpectedClosingDateSection(),
                  const SizedBox(height: 16),
                  _buildStatusSection(),
                  const SizedBox(height: 16),
                  _buildDetailsSection(),
                  const SizedBox(height: 16),
                  _buildExpenseItemsSection(),
                  const SizedBox(height: 16),
                  _buildTodoListSection(),
                  const SizedBox(height: 16),
                  _buildAttachedFilesSection(),
                  const SizedBox(height: 16),
                  _buildHistorySection(),
                  const SizedBox(height: 16),
                  _buildCommentsSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
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
          decoration: const InputDecoration(
            hintText: 'auto-generated',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBoardLaneSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Board',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedBoard.isNotEmpty && _availableBoards.any((board) => board['id'] == _selectedBoard) 
                       ? _selectedBoard 
                       : null,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                isExpanded: true,
                items: _availableBoards.map((board) {
                  return DropdownMenuItem<String>(
                    value: board['id'],
                    child: Text(
                      board['name'],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBoard = value!;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
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
                       ? _selectedLane 
                       : null,
                decoration: const InputDecoration(
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
                    _selectedLane = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHashtagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hashtag',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _hashtagController,
          decoration: const InputDecoration(
            hintText: 'e.g. #Urgent #FollowUp',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
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
          value: _assigneeController.text.isNotEmpty && _availableUsers.any((user) => user['id'] == _assigneeController.text) 
                 ? _assigneeController.text 
                 : null,
          decoration: const InputDecoration(
            hintText: 'Select an assignee',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          isExpanded: true,
          items: _availableUsers.map((user) {
            return DropdownMenuItem<String>(
              value: user['id'],
              child: Text(
                user['name'],
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _assigneeController.text = value ?? '';
            });
          },
        ),
      ],
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCustomer.isNotEmpty && _availableCustomers.any((customer) => customer['id'] == _selectedCustomer) 
                       ? _selectedCustomer 
                       : null,
                decoration: const InputDecoration(
                  hintText: 'Select a customer',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                isExpanded: true,
                items: _availableCustomers.map((customer) {
                  return DropdownMenuItem<String>(
                    value: customer['id'],
                    child: Text(
                      customer['name'],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCustomer = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // New customer functionality will be implemented later
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New'),
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
      ],
    );
  }

  Widget _buildCompanySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Company',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
                             child: DropdownButtonFormField<String>(
                 value: _selectedCompany.isNotEmpty && _availableCompanies.any((company) => company['id'] == _selectedCompany) 
                        ? _selectedCompany 
                        : null,
                 decoration: const InputDecoration(
                   border: OutlineInputBorder(),
                   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                 ),
                 isExpanded: true,
                 items: _availableCompanies.map((company) {
                   return DropdownMenuItem<String>(
                     value: company['id'],
                     child: Text(
                       company['name'],
                       overflow: TextOverflow.ellipsis,
                       style: const TextStyle(fontSize: 14),
                     ),
                   );
                 }).toList(),
                 onChanged: (value) {
                   setState(() {
                     _selectedCompany = value!;
                   });
                 },
               ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // New company functionality will be implemented later
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New'),
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
      ],
    );
  }

  Widget _buildExpectedClosingDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expected Closing Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _expectedClosingDate != null
                        ? '${_expectedClosingDate!.day}/${_expectedClosingDate!.month}/${_expectedClosingDate!.year}'
                        : 'Select a date',
                    style: TextStyle(
                      color: _expectedClosingDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _statusOptions.map((status) {
            final isSelected = _selectedStatus == status['value'];
            return ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatus = status['value'];
                });
              },
              icon: Icon(status['icon'], size: 16),
              label: Text(status['label']),
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? AppTheme.primaryOrange : Colors.grey[300],
                foregroundColor: isSelected ? Colors.white : Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            );
          }).toList(),
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
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              // Toolbar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.format_bold), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.format_italic), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.format_underline), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.format_strikethrough), onPressed: () {}),
                      const VerticalDivider(),
                      IconButton(icon: const Icon(Icons.format_align_left), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.format_align_center), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.format_align_right), onPressed: () {}),
                      const VerticalDivider(),
                      IconButton(icon: const Icon(Icons.format_list_bulleted), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.format_list_numbered), onPressed: () {}),
                    ],
                  ),
                ),
              ),
              // Text area
              TextField(
                controller: _detailsController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: 'Captured screenshot',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Expense Items',
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
              onPressed: () {
                // Add product functionality will be implemented later
              },
              icon: const Icon(Icons.shopping_cart, size: 16),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Add custom functionality will be implemented later
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Custom'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            children: [
              Expanded(child: Text('Img', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Product/Service', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Qty/Unit', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Price/Unit', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
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
              onPressed: () {
                // Apply template functionality will be implemented later
              },
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
              onPressed: () {
                // Add item functionality will be implemented later
              },
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
        ),
      ],
    );
  }

  Widget _buildAttachedFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attached Files',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () {
            // Add file functionality will be implemented later
          },
          icon: const Icon(Icons.upload_file, size: 16),
          label: const Text('Add File'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            children: [
              Expanded(child: Text('File Name', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Uploaded At', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              'No attachments uploaded yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Center(
            child: Text(
              'No activity for this card yet.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Write a comment...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  prefixIcon: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey,
                    child: Text('b', style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Post comment functionality will be implemented later
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text('Post'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Save'),
          ),
        ),
      ],
    );
  }
}
