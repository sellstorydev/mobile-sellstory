import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../controller/board_controller.dart';
import '../widgets/hashtag_selection_modal.dart';

class CardDetailPage extends StatefulWidget {
  final JobCard card;

  const CardDetailPage({
    super.key,
    required this.card,
  });

  @override
  State<CardDetailPage> createState() => _CardDetailPageState();
}

class _CardDetailPageState extends State<CardDetailPage> {
  final BoardController _controller = Get.find<BoardController>();
  
  // Form controllers
  final TextEditingController _jobIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _assigneeController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  
  // Hashtag state
  List<Map<String, dynamic>> _selectedHashtags = [];
  
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
  
  // Current card data (will be updated from controller)
  late JobCard _currentCard;

  @override
  void initState() {
    super.initState();
    _currentCard = widget.card;
    _initializeData().then((_) {
      setState(() {});
    });
  }

  Future<void> _initializeData() async {
    // Initialize form with current card data
    _jobIdController.text = _currentCard.customId.isNotEmpty ? _currentCard.customId : 'JB-${_currentCard.id.substring(0, 8)}';
    _titleController.text = _currentCard.title;
    _assigneeController.text = _currentCard.assignee;
    
    // Initialize hashtags from current card
    _initializeHashtags();
    _detailsController.text = _currentCard.description;
    _selectedStatus = _currentCard.status;
    _expectedClosingDate = _currentCard.dueDate;
    
    // Load available options
    await _loadAvailableOptions();
    
    // Set current values from card
    _selectedLane = _currentCard.laneId;
    
    // Find and set customer
    final customerMatch = _availableCustomers.firstWhereOrNull(
      (customer) => customer['name'] == _currentCard.customer
    );
    if (customerMatch != null) {
      _selectedCustomer = customerMatch['id'];
    }
    
    // Find and set company
    final companyMatch = _availableCompanies.firstWhereOrNull(
      (company) => company['name'] == _currentCard.company
    );
    if (companyMatch != null) {
      _selectedCompany = companyMatch['id'];
    }
    
    // Refresh card data from controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _refreshCardData();
      });
    });
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
      
      // Set current board from the card's data
      final currentCard = _currentCard;
      if (currentCard.boardId.isNotEmpty && _availableBoards.any((board) => board['id'] == currentCard.boardId)) {
        _selectedBoard = currentCard.boardId;
      } else if (_controller.currentBoardId.value.isNotEmpty) {
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
      
      print('✅ Companies loaded: ${_availableCompanies.length - 1} companies');
    } catch (e) {
      print('❌ Failed to load companies: $e');
      _availableCompanies = [
        {'id': 'none', 'name': 'None'},
      ];
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
      
      // Set current lane from the card's data
      if (_currentCard.laneId.isNotEmpty && _availableLanes.any((lane) => lane['id'] == _currentCard.laneId)) {
        _selectedLane = _currentCard.laneId;
        print('✅ Set lane from card data: $_selectedLane');
      } else if (_availableLanes.isNotEmpty) {
        _selectedLane = _availableLanes.first['id'];
        print('✅ Set first lane as default: $_selectedLane');
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

  // Refresh card data from controller
  void _refreshCardData() {
    try {
      final latestCard = _getLatestCardData();
      if (latestCard != null) {
        print('🔄 CardDetailPage._refreshCardData - Refreshing card data');
        setState(() {
          _currentCard = latestCard;
        });
      }
    } catch (e) {
      print('❌ Error refreshing card data: $e');
    }
  }

  // Helper method to get the latest card data from controller
  JobCard? _getLatestCardData() {
    try {
      if (!_controller.isInitialized.value || _controller.currentWorkspaceId.value.isEmpty) {
        print('⚠️ CardDetailPage._getLatestCardData - Controller not ready or no workspace selected');
        return null;
      }
      
      final lanes = _controller.lanes;
      if (lanes.isEmpty) {
        print('⚠️ CardDetailPage._getLatestCardData - No lanes available yet');
        return null;
      }
      
      for (final lane in lanes) {
        final card = lane.cards.firstWhereOrNull((c) => c.id == widget.card.id);
        if (card != null) {
          print('✅ CardDetailPage._getLatestCardData - Found card: ${card.title}');
          return card;
        }
      }
      
      print('⚠️ CardDetailPage._getLatestCardData - Card not found in any lane');
      return null;
    } catch (e) {
      print('❌ Error getting latest card data: $e');
      return null;
    }
  }

  // Update current card data from controller
  void _updateCurrentCard() {
    final latestCard = _getLatestCardData();
    if (latestCard != null && latestCard != _currentCard) {
      setState(() {
        _currentCard = latestCard;
      });
    }
  }

  @override
  void dispose() {
    _jobIdController.dispose();
    _titleController.dispose();
    _assigneeController.dispose();
    _detailsController.dispose();
    _commentController.dispose();
    super.dispose();
  }
  
  void _initializeHashtags() {
    // Parse existing hashtag string into hashtag objects
    if (_currentCard.hashtag?.isNotEmpty == true) {
      final hashtagText = _currentCard.hashtag!;
      final hashtags = hashtagText
          .split(RegExp(r'[,\s]+'))
          .where((tag) => tag.isNotEmpty)
          .map((tag) => tag.trim().replaceFirst('#', ''))
          .where((tag) => tag.isNotEmpty)
          .toList();
      
      _selectedHashtags = hashtags.asMap().entries.map((entry) {
        final colors = ['#f97316', '#3b82f6', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4', '#84cc16', '#f472b6', '#6b7280'];
        return {
          'id': 'existing_${entry.key}',
          'text': entry.value,
          'color': colors[entry.key % colors.length],
        };
      }).toList();
    }
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isInitialized.value && _controller.currentWorkspaceId.value.isNotEmpty) {
        try {
          _updateCurrentCard();
        } catch (e) {
          print('❌ Error in CardDetailPage build: $e');
        }
      }
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Job Card'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            // Action menu
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(value),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      const Icon(Icons.copy, size: 20),
                      const SizedBox(width: 12),
                      const Text('Duplicate Card'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      const Text('Delete Card', style: TextStyle(color: Colors.red)),
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
            ? const Center(child: CircularProgressIndicator())
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
    });
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
            hintText: 'Job ID',
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
                  hintText: 'Enter job details...',
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
            onPressed: _isLoading ? null : _saveChanges,
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

  void _handleAction(String action) {
    switch (action) {
      case 'duplicate':
        _duplicateCard();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Card'),
          content: Text('Are you sure you want to delete "${_currentCard.title}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCard();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if workspace is selected
      if (_controller.currentWorkspaceId.value.isEmpty) {
        throw Exception('No workspace selected. Please select a workspace first.');
      }

      print('🔄 CardDetailPage._deleteCard - Deleting card:');
      print('  - Card ID: ${_currentCard.id}');
      print('  - Workspace ID: ${_controller.currentWorkspaceId.value}');
      print('  - Card Title: ${_currentCard.title}');

      await _controller.deleteCard(_currentCard.id);
      
      Get.snackbar(
        'Success',
        'Card deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate back to board page directly
      Get.until((route) => route.isFirst);
    } catch (e) {
      print('❌ Error deleting card: $e');
      Get.snackbar(
        'Error',
        'Failed to delete card: ${e.toString()}',
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

  Future<void> _duplicateCard() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if workspace is selected
      if (_controller.currentWorkspaceId.value.isEmpty) {
        throw Exception('No workspace selected. Please select a workspace first.');
      }

      print('🔄 CardDetailPage._duplicateCard - Creating duplicate card:');
      print('  - Original Card ID: ${_currentCard.id}');
      print('  - Workspace ID: ${_controller.currentWorkspaceId.value}');
      print('  - Original Title: ${_currentCard.title}');

      // Create a duplicate card
      final duplicateCard = JobCard(
        id: '',
        title: '${_currentCard.title} (Copy)',
        description: _currentCard.description,
        assignee: _currentCard.assignee,
        status: _currentCard.status,
        customId: '',
        dueDate: _currentCard.dueDate,
        badges: _currentCard.badges,
        amount: _currentCard.amount,
        laneId: _currentCard.laneId,
        boardId: _currentCard.boardId,
        workspaceId: _currentCard.workspaceId,
        order: _currentCard.order,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customer: _currentCard.customer,
        updatedByDisplayName: _currentCard.updatedByDisplayName,
        customerId: _currentCard.customerId,
        company: _currentCard.company,
        hashtag: _currentCard.hashtag,
        expenses: _currentCard.expenses,
        todos: _currentCard.todos,
        notes: _currentCard.notes,
        watchers: _currentCard.watchers,
        customFields: _currentCard.customFields,
        createdBy: _currentCard.createdBy,
        updatedBy: _currentCard.updatedBy,
      );

      await _controller.createCard(duplicateCard);

      Get.snackbar(
        'Success',
        'Card duplicated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Navigate back to previous page (preserves bottom navigation)
      Get.back();
    } catch (e) {
      print('❌ Error duplicating card: $e');
      Get.snackbar(
        'Error',
        'Failed to duplicate card: ${e.toString()}',
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

  Future<void> _saveChanges() async {
    // Validate required fields
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

    if (_assigneeController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Assignee is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_selectedCustomer.isEmpty) {
      Get.snackbar(
        'Error',
        'Customer is required',
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
      print('🔄 CardDetailPage._saveChanges - Original card data:');
      print('  - Custom ID: ${_currentCard.customId}');
      print('  - Title: ${_currentCard.title}');
      print('  - Status: ${_currentCard.status}');
      
      print('🔄 CardDetailPage._saveChanges - Form data:');
      print('  - Custom ID: ${_jobIdController.text.trim()}');
      print('  - Title: ${_titleController.text.trim()}');
      print('  - Status: $_selectedStatus');
      
      // Create updated card
      final updatedCard = _currentCard.copyWith(
        title: _titleController.text.trim(),
        description: _detailsController.text.trim(),
        assignee: _assigneeController.text.trim(),
        customer: _selectedCustomer.isNotEmpty ? _availableCustomers.firstWhere((c) => c['id'] == _selectedCustomer)['name'] : '',
        company: _selectedCompany != 'none' ? _availableCompanies.firstWhere((c) => c['id'] == _selectedCompany)['name'] : null,
        hashtag: _selectedHashtags.isNotEmpty ? _selectedHashtags.map((h) => '#${h['text']}').join(' ') : null,
        status: _selectedStatus,
        laneId: _selectedLane,
        dueDate: _expectedClosingDate,
        updatedAt: DateTime.now(),
      );

      print('🔄 CardDetailPage._saveChanges - Updated card data:');
      print('  - Custom ID: ${updatedCard.customId}');
      print('  - Title: ${updatedCard.title}');
      print('  - Status: ${updatedCard.status}');

      // Update card using controller
      await _controller.updateCard(updatedCard);

      setState(() {
        _isLoading = false;
      });

      // Refresh card data after successful update
      _refreshCardData();

      Get.snackbar(
        'Success',
        'Card updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Error updating card: $e');

      Get.snackbar(
        'Error',
        'Failed to update card: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}