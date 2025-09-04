import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';

import '../../../domain/entities/job_card.dart';
import '../controller/board_controller.dart';
import '../widgets/hashtag_selection_modal.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../data/services/firestore_service.dart';

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
  final TextEditingController _assigneeController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  
  // Hashtag state
  List<Map<String, dynamic>> _selectedHashtags = [];
  
  // Todo state
  List<Map<String, dynamic>> _todoItems = [];
  
  // Form state

  String _selectedLane = '';
  String _selectedCustomer = '';
  String _selectedCompany = 'none';
  String _selectedCustomerInterest = 'เริ่มต้น';
  String _selectedStatus = 'Pending';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  
  // Multi-select for collaborators and watchers
  List<String> _selectedCollaborators = [];
  List<String> _selectedWatchers = [];
  
  // Available options

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

  // Customer Interest options
  final List<String> _customerInterestOptions = [
    'เริ่มต้น',
    'น้อย (Low)',
    'กลาง (Medium)',
    'มาก (High)',
  ];



  @override
  void initState() {
    super.initState();
    print('🔄 CreateCardPage.initState - Page opened');
    print('  - Received laneId: ${widget.laneId}');
    print('  - Received boardId: ${widget.boardId}');
    print('  - Received workspaceId: ${widget.workspaceId}');
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
      print('✅ Set default lane from parameter: $_selectedLane');
    } else {
      print('⚠️ No laneId parameter provided');
    }
  }

  Future<void> _loadAvailableOptions() async {
    // Load lanes for current board
    final currentBoardId = _controller.currentBoardId.value;
    if (currentBoardId.isNotEmpty) {
      await _loadLanesForBoard(currentBoardId);
    }
    



    // Load users from current workspace
    await _loadWorkspaceUsers();
    
          // Load customers from Firestore
      try {
        print('🔄 Loading customers from Firestore...');
        final customers = await _controller.getCustomers();
        
        // Deduplicate customers by ID to prevent dropdown issues and ensure data consistency
        final customerMap = <String, Map<String, dynamic>>{};
        for (final customer in customers) {
          if (customer.id.isNotEmpty && !customerMap.containsKey(customer.id)) {
            customerMap[customer.id] = {
              'id': customer.id,
              'name': customer.name.isNotEmpty ? customer.name : 'Unknown Customer',
              'customId': customer.customId ?? '',
            };
          }
        }
        _availableCustomers = customerMap.values.toList();
        
        // Clear invalid customer if current customer is not in available customers
        if (_selectedCustomer.isNotEmpty && !_availableCustomers.any((customer) => customer['id'] == _selectedCustomer)) {
          _selectedCustomer = '';
          _selectedCompany = 'none';
        }
        
        print('✅ Customers loaded: ${_availableCustomers.length} customers');
      } catch (e) {
        print('❌ Failed to load customers: $e');
        _availableCustomers = [];
        // Clear customer and company on error
        _selectedCustomer = '';
        _selectedCompany = 'none';
      }
    
    // Companies will be loaded when customer is selected
    _availableCompanies = [
      {'id': 'none', 'name': 'None'},
    ];
    _selectedCompany = 'none';
  }

  Future<void> _loadLanesForBoard(String boardId) async {
    if (boardId.isEmpty) {
      print('⚠️ No board ID provided for loading lanes');
      _availableLanes = [];
      return;
    }
    
    try {
      print('🔄 Loading lanes for board: $boardId');
      final lanes = await _controller.getLanesByBoardId(boardId);
      
      _availableLanes = lanes.map((lane) => {
        'id': lane.id,
        'name': lane.title,
      }).toList();
      
      print('✅ Lanes loaded for board $boardId: ${_availableLanes.length} lanes');
      
      // Update selected lane based on available lanes
      if (widget.laneId != null && _availableLanes.any((lane) => lane['id'] == widget.laneId)) {
        _selectedLane = widget.laneId!;
        print('✅ Kept pre-selected lane: $_selectedLane');
      } else if (_selectedLane.isEmpty && _availableLanes.isNotEmpty) {
        _selectedLane = _availableLanes.first['id'];
        print('✅ Set first lane as default: $_selectedLane');
      } else if (!_availableLanes.any((lane) => lane['id'] == _selectedLane)) {
        _selectedLane = _availableLanes.isNotEmpty ? _availableLanes.first['id'] : '';
        print('✅ Reset to first available lane: $_selectedLane');
      }
    } catch (e) {
      print('❌ Failed to load lanes for board $boardId: $e');
      _availableLanes = [];
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
      
      // Get users from the workspace - data is already properly formatted from repository
      final users = await _controller.getWorkspaceUsers(workspaceId);
      
      // Deduplicate users by ID to prevent dropdown issues and ensure data consistency
      final userMap = <String, Map<String, dynamic>>{};
      for (final user in users) {
        final userId = user['id']?.toString();
        if (userId != null && userId.isNotEmpty && !userMap.containsKey(userId)) {
          // Ensure user has required fields
          userMap[userId] = {
            'id': userId,
            'name': user['name'] ?? user['displayName'] ?? 'Unknown User',
            'displayName': user['displayName'] ?? user['name'] ?? 'Unknown User',
            'email': user['email'] ?? '',
          };
        }
      }
      _availableUsers = userMap.values.toList();
      
      // Clear invalid assignee if current assignee is not in available users
      if (_assigneeController.text.isNotEmpty && !_availableUsers.any((user) => user['id'] == _assigneeController.text)) {
        _assigneeController.text = '';
      }
      
      print('✅ Loaded ${_availableUsers.length} users for workspace');
    } catch (e) {
      print('❌ Failed to load workspace users: $e');
      _availableUsers = [];
      // Clear assignee on error
      _assigneeController.text = '';
    }
  }

  Future<void> _loadCompaniesForCustomer(String customerId) async {
    try {
      print('🔄 Loading companies for customer: $customerId');
      
      // Get customer details to access companyNames
      final customers = await _controller.getCustomers();
      final customer = customers.firstWhereOrNull((c) => c.id == customerId);
      
      if (customer != null && customer.companyNames != null) {
        final companyMap = <String, Map<String, dynamic>>{};
        companyMap['none'] = {'id': 'none', 'name': 'None'};
        
        for (final company in customer.companyNames!) {
          companyMap[company['id']] = {
            'id': company['id'],
            'name': company['label'],
            'value': company['value'],
          };
        }
        
        setState(() {
          _availableCompanies = companyMap.values.toList();
          _selectedCompany = 'none';
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

  String? _getValidAssigneeValue() {
    if (_assigneeController.text.isEmpty) return null;
    
    // Check if the current assignee value exists in available users
    final isValidAssignee = _availableUsers.any((user) => user['id'] == _assigneeController.text);
    if (!isValidAssignee) {
      // Clear invalid assignee
      _assigneeController.text = '';
      return null;
    }
    
    return _assigneeController.text;
  }

  String? _getValidCustomerValue() {
    if (_selectedCustomer.isEmpty) return null;
    
    // Check if the current customer value exists in available customers
    final isValidCustomer = _availableCustomers.any((customer) => customer['id'] == _selectedCustomer);
    if (!isValidCustomer) {
      // Clear invalid customer
      _selectedCustomer = '';
      return null;
    }
    
    return _selectedCustomer;
  }

  String? _getValidCompanyValue() {
    if (_selectedCompany.isEmpty) return null;
    
    // Check if the current company value exists in available companies
    final isValidCompany = _availableCompanies.any((company) => company['id'] == _selectedCompany);
    if (!isValidCompany) {
      // Clear invalid company
      _selectedCompany = 'none';
      return null;
    }
    
    return _selectedCompany;
  }

  Future<void> _showTodoTemplates() async {
    try {
      final currentBoardId = _controller.currentBoardId.value;
      final currentWorkspaceId = _controller.currentWorkspaceId.value;
      if (currentBoardId.isEmpty || currentWorkspaceId.isEmpty) {
        _showError('No board or workspace selected');
        return;
      }

      // Get todo templates from Firestore directly
      final firestoreService = Get.find<FirestoreService>();
      final boardsCollection = firestoreService.getWorkspaceBoardsCollection(currentWorkspaceId);
      final boardDocRef = boardsCollection.doc(currentBoardId);
      final boardData = await firestoreService.getDocument(boardDocRef);
      
      if (boardData == null || boardData['todoTemplates'] == null || (boardData['todoTemplates'] as List).isEmpty) {
        _showError('No todo templates available for this board');
        return;
      }

      final todoTemplates = boardData['todoTemplates'] as List;

      // Show template selection dialog
      final selectedTemplate = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Todo Template'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: todoTemplates.length,
              itemBuilder: (context, index) {
                final template = todoTemplates[index];
                return ListTile(
                  title: Text(template['name'] ?? 'Unnamed Template'),
                  onTap: () => Navigator.of(context).pop(template),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (selectedTemplate != null && selectedTemplate['todos'] != null) {
        // Apply the selected template
        final todos = selectedTemplate['todos'] as List;
        setState(() {
          for (final todo in todos) {
            _todoItems.add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'text': todo['title'] ?? '',
              'isCompleted': false,
              'dueDate': null,
              'duration': null,
              'endTime': null,
              'controller': TextEditingController(text: todo['title'] ?? ''),
            });
          }
        });
        
        Get.snackbar(
          'Success',
          'Todo template applied successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('❌ Error showing todo templates: $e');
      _showError('Failed to load todo templates: ${e.toString()}');
    }
  }

  void _generateJobId() {
    // Job ID will be auto-generated by the server with proper counter

  }

  @override
  void dispose() {
    print('🔄 CreateCardPage.dispose - Page being disposed');
    
    // Dispose todo controllers
    for (var todo in _todoItems) {
      todo['controller']?.dispose();
    }
    
    _jobIdController.dispose();
    _titleController.dispose();
    _assigneeController.dispose();
    _detailsController.dispose();
    super.dispose();
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

  Future<void> _saveCard() async {
    if (!(MobilePermissionsService.to.isOwner ||
        MobilePermissionsService.to.can('jobcard:create')))
    {
      _showError('You do not have permission to create cards');
      return;
    }
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
      String assigneeDisplayName = '';
      if (_assigneeController.text.trim().isNotEmpty) {
        final selectedUser = _availableUsers.firstWhereOrNull(
          (user) => user['id'] == _assigneeController.text.trim()
        );
        assigneeId = selectedUser?['id'] ?? _assigneeController.text.trim();
        assigneeDisplayName = selectedUser?['displayName'] ?? selectedUser?['name'] ?? _assigneeController.text.trim();
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

      // Prepare company data in correct format
      Map<String, dynamic>? companyData;
      if (_selectedCompany != 'none') {
        final selectedCompany = _availableCompanies.firstWhereOrNull(
          (c) => c['id'] == _selectedCompany
        );
        if (selectedCompany != null) {
          companyData = {
            'id': selectedCompany['id'],
            'label': selectedCompany['name'],
            'value': selectedCompany['value'] ?? selectedCompany['name'],
          };
        }
      }

      // Prepare todos data in correct format
      final todosData = _todoItems.map((todo) => {
        'id': 'todo-${todo['id']}', // Add 'todo-' prefix to match correct structure
        'title': todo['text'] ?? '',
        'completed': todo['isCompleted'] ?? false,
        'dueDate': todo['dueDate']?.millisecondsSinceEpoch,
        'mentions': [],
      }).toList();

      final card = JobCard(
        id: '', // Will be generated by Firestore
        title: _titleController.text.trim(),
        description: _detailsController.text.trim(),
        assignedTo: assigneeId,
        status: _selectedStatus,
        customId: '', // Will be auto-generated with counter
        dueDate: null, // Not using dueDate anymore
        startDate: _startDate,
        endDate: _endDate,
        badges: _selectedHashtags.map((h) => h['text'] as String).toList(),
        amount: 0.0,
        laneId: _selectedLane.isNotEmpty ? _selectedLane : '',
        boardId: currentBoardId,
        workspaceId: currentWorkspaceId,
        order: 0, // Will be set by the system
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customer: customerName,
        updatedByDisplayName: assigneeDisplayName, // Use assignee display name
        customerId: _selectedCustomer.isNotEmpty ? _selectedCustomer : null,
        company: companyData, // Store company as object with id, label, value
        customerInterest: _selectedCustomerInterest,
        hashtag: _selectedHashtags.isNotEmpty ? _selectedHashtags.map((h) => '#${h['text']}').join(' ') : null,
        hashtags: _selectedHashtags,
        expenses: [],
        todos: todosData,
        notes: [],
        collaborators: _selectedCollaborators,
        watchers: _selectedWatchers.isNotEmpty ? _selectedWatchers : [currentUserId], // Add creator as watcher if none selected
        customFields: [],
        createdBy: currentUserId,
        updatedBy: currentUserId,
      );

      // Add card using controller with full card data
      print('🔄 CreateCardPage._saveCard - Creating card...');
      print('  - Title: "${card.title}"');
      print('  - Assignee ID: "${card.assignedTo}"');
      print('  - UpdatedByDisplayName: "${card.updatedByDisplayName}"');
      print('  - Available Users Count: ${_availableUsers.length}');
      if (_availableUsers.isNotEmpty) {
        print('  - First User Example: ${_availableUsers.first}');
      }
      final cardId = await _controller.createCard(card);

      print('✅ Card created successfully with ID: $cardId');

      // Show success message and navigate back immediately
      Get.snackbar(
        'Success',
        'Job Card created successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );

      print('🔄 CreateCardPage._saveCard - Navigating back...');
      
      // Reset loading state before navigation
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Navigate back immediately after success
        Navigator.of(context).pop();
        print('✅ CreateCardPage._saveCard - Navigation completed');
      } else {
        print('⚠️ CreateCardPage._saveCard - Widget not mounted, cannot navigate');
      }
    } catch (e) {
      print('❌ CreateCardPage._saveCard - Error: $e');
      
      // Only show error and keep page open if there's an error
      if (mounted) {
        _showError('Failed to create card: ${e.toString()}');
        setState(() {
          _isLoading = false;
        });
      }
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
                                      _buildLaneSection(),
                  const SizedBox(height: 16),
                  _buildHashtagSection(),
                  const SizedBox(height: 16),
                  _buildAssigneeSection(),
                  const SizedBox(height: 16),
                  _buildCustomerSection(),
                  const SizedBox(height: 16),
                  _buildCompanySection(),
                  const SizedBox(height: 16),
                  _buildCustomerInterestSection(),
                  const SizedBox(height: 16),
                  _buildExpectedClosingDateSection(),
                  const SizedBox(height: 16),
                  _buildStatusSection(),
                  const SizedBox(height: 16),
                  _buildCollaboratorsSection(),
                  const SizedBox(height: 16),
                  _buildWatchersSection(),
                  const SizedBox(height: 16),
                  _buildDetailsSection(),
                  const SizedBox(height: 16),
                  _buildTodoListSection(),
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
          enabled: false, // Disable the field
          decoration: const InputDecoration(
            hintText: 'auto-generated',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            fillColor: Color(0xFFF5F5F5), // Light gray background for disabled state
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
        InkWell(
          onTap: _openHashtagModal,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _selectedHashtags.isEmpty
                ? const Text(
                    'Tap to select hashtags...',
                    style: TextStyle(color: Colors.grey),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedHashtags.map((hashtag) {
                      return Chip(
                        label: Text('#${hashtag['text']}'),
                        backgroundColor: Color(int.parse(hashtag['color'].replaceFirst('#', '0xff'))),
                        labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
          ),
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
          value: _getValidAssigneeValue(),
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
                user['name'] ?? user['displayName'] ?? user['id'] ?? 'Unknown User',
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
                value: _getValidCustomerValue(),
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
                    _selectedCompany = 'none'; // Reset company selection
                  });
                  // Load companies for selected customer
                  if (value != null && value.isNotEmpty) {
                    _loadCompaniesForCustomer(value);
                  }
                },
              ),
            ),
            // const SizedBox(width: 8),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // New customer functionality will be implemented later
            //   },
            //   icon: const Icon(Icons.add, size: 16),
            //   label: const Text('New'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppTheme.primaryOrange,
            //     foregroundColor: Colors.white,
            //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(6),
            //     ),
            //   ),
            // ),
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
                value: _getValidCompanyValue(),
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
            // const SizedBox(width: 8),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // New company functionality will be implemented later
            //   },
            //   icon: const Icon(Icons.add, size: 16),
            //   label: const Text('New'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: AppTheme.primaryOrange,
            //     foregroundColor: Colors.white,
            //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(6),
            //     ),
            //   ),
            // ),
          ],
        ),
      ],
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
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectStartDate(context),
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
                          _startDate != null
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Start Date',
                          style: TextStyle(
                            color: _startDate != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => _selectEndDate(context),
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
                          _endDate != null
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'End Date',
                          style: TextStyle(
                            color: _endDate != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
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
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
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
                      final user = _availableUsers.firstWhereOrNull((u) => u['id'] == userId);
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
                  items: _availableUsers
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
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
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
                      final user = _availableUsers.firstWhereOrNull((u) => u['id'] == userId);
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
                  items: _availableUsers
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

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
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
            onPressed: _isLoading ||
                    !(MobilePermissionsService.to.isOwner ||
                      MobilePermissionsService.to.can('jobcard:create'))
                ? null
                : _saveCard,
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
          _clearAllTimes(index); // Clear existing times first
          await _setDueDateTime(index);
          break;
        case 'duration':
          _clearAllTimes(index); // Clear existing times first
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
    
    // Calculate end time based on current time + duration
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
        // Calculate and store the end time
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }



}
