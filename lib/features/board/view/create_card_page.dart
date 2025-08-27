import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';

import '../../../domain/entities/job_card.dart';
import '../controller/board_controller.dart';
import '../widgets/hashtag_selection_modal.dart';

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
  final TextEditingController _commentController = TextEditingController();
  
  // Hashtag state
  List<Map<String, dynamic>> _selectedHashtags = [];
  
  // Todo state
  List<Map<String, dynamic>> _todoItems = [];
  
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
    // Load boards from Firestore
    try {
      print('🔄 Loading boards from Firestore...');
      final boards = await _controller.getBoards();
      
      _availableBoards = boards.map((board) => {
        'id': board.id,
        'name': board.name,
      }).toList();
      
      // Set default board (current board or first available)
      if (_controller.currentBoardId.value.isNotEmpty) {
        _selectedBoard = _controller.currentBoardId.value;
      } else if (_availableBoards.isNotEmpty) {
        _selectedBoard = _availableBoards.first['id'];
      }
      
      print('✅ Boards loaded: ${_availableBoards.length} boards');
      print('📍 Selected board: $_selectedBoard');
    } catch (e) {
      print('❌ Failed to load boards: $e');
      _availableBoards = [];
    }
    
    // Load lanes for selected board
    await _loadLanesForBoard(_selectedBoard);
    

    
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
            'displayName': user['displayName'] ?? user['email'] ?? 'Unknown User', // Add displayName field
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
    print('🔄 CreateCardPage.dispose - Page being disposed');
    
    // Dispose todo controllers
    for (var todo in _todoItems) {
      todo['controller']?.dispose();
    }
    
    _jobIdController.dispose();
    _titleController.dispose();
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

      final card = JobCard(
        id: '', // Will be generated by Firestore
        title: _titleController.text.trim(),
        description: _detailsController.text.trim(),
        assignee: assigneeId,
        status: _selectedStatus,
        customId: '', // Will be auto-generated with counter
        dueDate: _expectedClosingDate,
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
        company: companyName,
        hashtag: _selectedHashtags.isNotEmpty ? _selectedHashtags.map((h) => '#${h['text']}').join(' ') : null,
        hashtags: _selectedHashtags,
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
      print('  - Assignee ID: "${card.assignee}"');
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
                onChanged: (value) async {
                  setState(() {
                    _selectedBoard = value!;
                  });
                  
                  // Load lanes for the newly selected board
                  await _loadLanesForBoard(_selectedBoard);
                  
                  setState(() {
                    // Trigger UI rebuild with new lanes
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
            // const SizedBox(width: 8),
            // ElevatedButton.icon(
            //   onPressed: () {
            //     // Add custom functionality will be implemented later
            //   },
            //   icon: const Icon(Icons.add, size: 16),
            //   label: const Text('Add Custom'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.grey[300],
            //     foregroundColor: Colors.black87,
            //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(6),
            //     ),
            //   ),
            // ),
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
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                      child: Text('b', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
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
                ),
              ),
              const SizedBox(width: 8),
              
              // Add button (save current todo)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  onPressed: () {
                    // Add button functionality - could save or mark as added
                    if (controller.text.trim().isNotEmpty) {
                      // You can add any save logic here
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Todo "${controller.text.trim()}" added!'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
