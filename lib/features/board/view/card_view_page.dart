import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/dialog_utils.dart';
import '../../../domain/entities/job_card.dart';
import '../controller/board_controller.dart';
import 'card_detail_page.dart'; // For edit functionality
import '../../../data/services/mobile_permissions_service.dart';

class CardViewPage extends StatefulWidget {
  final JobCard card;

  const CardViewPage({
    super.key,
    required this.card,
  });

  @override
  State<CardViewPage> createState() => _CardViewPageState();
}

class _CardViewPageState extends State<CardViewPage> {
  final BoardController _controller = Get.find<BoardController>();
  
  // Current card data (will be updated from controller)
  late JobCard _currentCard;
  bool _isLoading = false;
  
  // Available options (for display names)
  List<Map<String, dynamic>> _availableCustomers = [];
  List<Map<String, dynamic>> _availableCompanies = [];
  List<Map<String, dynamic>> _availableUsers = [];
  List<Map<String, dynamic>> _availableLanes = [];

  @override
  void initState() {
    super.initState();
    _currentCard = widget.card;
    _initializeData().then((_) {
      setState(() {});
    });
  }

  Future<void> _initializeData() async {
    // Load available options for display names
    await _loadAvailableOptions();
    
    // Refresh card data from controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _refreshCardData();
      });
    });
  }

  Future<void> _loadAvailableOptions() async {
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
    
    // Load lanes
    final lanes = _controller.lanes;
    _availableLanes = lanes.map((lane) => {
      'id': lane.id,
      'name': lane.title,
    }).toList();
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
      _availableUsers = users;
      
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
        print('🔄 CardViewPage._refreshCardData - Refreshing card data');
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
        print('⚠️ CardViewPage._getLatestCardData - Controller not ready or no workspace selected');
        return null;
      }
      
      final lanes = _controller.lanes;
      if (lanes.isEmpty) {
        print('⚠️ CardViewPage._getLatestCardData - No lanes available yet');
        return null;
      }
      
      for (final lane in lanes) {
        final card = lane.cards.firstWhereOrNull((c) => c.id == widget.card.id);
        if (card != null) {
          print('✅ CardViewPage._getLatestCardData - Found card: ${card.title}');
          return card;
        }
      }
      
      print('⚠️ CardViewPage._getLatestCardData - Card not found in any lane');
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

  // Helper methods to get display names
  String _getAssigneeName(String assigneeId) {
    final user = _availableUsers.firstWhereOrNull((user) => user['id'] == assigneeId);
    return user?['name'] ?? assigneeId;
  }

  String _getLaneName(String laneId) {
    final lane = _availableLanes.firstWhereOrNull((lane) => lane['id'] == laneId);
    return lane?['name'] ?? laneId;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (_controller.isInitialized.value && _controller.currentWorkspaceId.value.isNotEmpty) {
        try {
          _updateCurrentCard();
        } catch (e) {
          print('❌ Error in CardViewPage build: $e');
        }
      }
      
      return Scaffold(
        appBar: AppBar(
          title: const Text('Job Card Details'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            // Edit button
            if (MobilePermissionsService.to.isOwner ||
                MobilePermissionsService.to.can('jobcard:edit:all'))
              IconButton(
                onPressed: () {
                  Get.to(() => CardDetailPage(card: _currentCard));
                },
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Card',
              ),
            // Action menu
            PopupMenuButton<String>(
              onSelected: (value) => _handleAction(value),
              itemBuilder: (context) => [
                if (MobilePermissionsService.to.isOwner ||
                    MobilePermissionsService.to.can('jobcard:create'))
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
                if (MobilePermissionsService.to.isOwner ||
                    MobilePermissionsService.to.can('jobcard:delete:all'))
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
                    _buildTitleSection(),
                    const SizedBox(height: 16),
                    _buildBoardLaneSection(),
                    const SizedBox(height: 16),
                    _buildStatusSection(),
                    const SizedBox(height: 16),
                    _buildCardInfoSection(),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _currentCard.customId.isNotEmpty ? _currentCard.customId : 'JB-${_currentCard.id.substring(0, 8)}',
            style: const TextStyle(fontSize: 14),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _currentCard.title,
            style: const TextStyle(fontSize: 14),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Current Board',
                  style: TextStyle(fontSize: 14),
                ),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getLaneName(_currentCard.laneId),
                  style: const TextStyle(fontSize: 14),
                ),
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
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _currentCard.hashtags.isNotEmpty
              ? Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _currentCard.hashtags.map((hashtag) {
                    return Chip(
                      label: Text('#${hashtag['text']}'),
                      backgroundColor: Color(int.parse(hashtag['color'].replaceFirst('#', '0xff'))),
                      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                )
              : Text(
                  _currentCard.hashtag?.isNotEmpty == true ? _currentCard.hashtag! : 'No hashtags',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
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
          'Assignee',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.orange[100],
                child: Text(
                  _getAssigneeName(_currentCard.assignedTo).isNotEmpty 
                                              ? _getAssigneeName(_currentCard.assignedTo)[0].toUpperCase() 
                      : '?',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getAssigneeName(_currentCard.assignedTo),
                style: const TextStyle(fontSize: 14),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green[100],
                child: Text(
                  _currentCard.customer.isNotEmpty ? _currentCard.customer[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _currentCard.customer.isNotEmpty ? _currentCard.customer : 'No customer',
                style: TextStyle(
                  fontSize: 14,
                  color: _currentCard.customer.isNotEmpty ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _currentCard.company?['value']?.toString() ?? 'None',
            style: TextStyle(
              fontSize: 14,
              color: _currentCard.company?.isNotEmpty == true ? Colors.black : Colors.grey,
            ),
          ),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                _currentCard.dueDate != null
                    ? '${_currentCard.dueDate!.day}/${_currentCard.dueDate!.month}/${_currentCard.dueDate!.year}'
                    : 'No date set',
                style: TextStyle(
                  fontSize: 14,
                  color: _currentCard.dueDate != null ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    Color getStatusColor(String status) {
      switch (status.toLowerCase()) {
        case 'pending':
          return Colors.orange;
        case 'in progress':
          return Colors.blue;
        case 'done':
          return Colors.green;
        case 'cancelled':
          return Colors.grey;
        default:
          return Colors.grey;
      }
    }

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: getStatusColor(_currentCard.status),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _currentCard.status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Card Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Date Range', _getDateRange()),
        _buildInfoRow('Job ID', _currentCard.customId.isNotEmpty ? _currentCard.customId : 'JB-${_currentCard.id.substring(0, 8)}'),
        _buildInfoRow('Status', _currentCard.status),
        _buildInfoRow('Created Date', _formatDate(_currentCard.createdAt)),
        _buildInfoRow('Assignee', _getAssigneeName(_currentCard.assignedTo)),
        _buildInfoRow('Company', _currentCard.company?['value']?.toString() ?? '-'),
        _buildInfoRow('Customer Interest', _currentCard.customerInterest ?? '-'),
        _buildInfoRow('Collaborators', _getCollaboratorsNames()),
        _buildInfoRow('Customer', _currentCard.customer.isNotEmpty ? _currentCard.customer : '-'),
        _buildInfoRow('Hashtags', _getHashtagsText()),
        _buildInfoRow('Priority', _currentCard.priority ?? '-'),
        _buildInfoRow('Grand Total', _getGrandTotal()),
        _buildInfoRow('Net Total', _getNetTotal()),
        _buildInfoRow('Total (before discount)', _getTotalBeforeDiscount()),
        _buildInfoRow('Total (after discount)', _getTotalAfterDiscount()),
        _buildInfoRow('Total (before VAT)', _getTotalBeforeVAT()),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: value == '-' ? Colors.grey : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateRange() {
    if (_currentCard.dueDate != null) {
      final startDate = _currentCard.createdAt;
      final endDate = _currentCard.dueDate!;
      return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
    }
    return '-';
  }

  String _getCollaboratorsNames() {
    if (_currentCard.collaborators.isEmpty) return '-';
    return _currentCard.collaborators
        .map((collaboratorId) => _getAssigneeName(collaboratorId))
        .join(', ');
  }

  String _getHashtagsText() {
    if (_currentCard.hashtags.isEmpty) return '-';
    return _currentCard.hashtags
        .map((hashtag) => '#${hashtag['text'] ?? hashtag['id'] ?? ''}')
        .join(', ');
  }

  String _getGrandTotal() {
    if (_currentCard.expenses.isEmpty) return '-';
    final total = _currentCard.expenses.fold<double>(
      0.0,
      (sum, expense) => sum + (expense['pricePerUnit'] ?? 0.0),
    );
    return '\$${total.toStringAsFixed(2)}';
  }

  String _getNetTotal() {
    if (_currentCard.expenses.isEmpty) return '-';
    final total = _currentCard.expenses.fold<double>(
      0.0,
      (sum, expense) => sum + (expense['pricePerUnit'] ?? 0.0),
    );
    return '\$${total.toStringAsFixed(2)}';
  }

  String _getTotalBeforeDiscount() {
    if (_currentCard.expenses.isEmpty) return '-';
    final total = _currentCard.expenses.fold<double>(
      0.0,
      (sum, expense) => sum + (expense['pricePerUnit'] ?? 0.0),
    );
    return '\$${total.toStringAsFixed(2)}';
  }

  String _getTotalAfterDiscount() {
    if (_currentCard.expenses.isEmpty) return '-';
    return '-'; // TODO: Implement discount calculation
  }

  String _getTotalBeforeVAT() {
    if (_currentCard.expenses.isEmpty) return '-';
    return '-'; // TODO: Implement VAT calculation
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getTodoListText() {
    if (_currentCard.todos.isEmpty) return 'No to-do items';
    
    final completedCount = _currentCard.todos.where((todo) => todo['completed'] == true).length;
    final totalCount = _currentCard.todos.length;
    
    return '$completedCount/$totalCount completed';
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
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _currentCard.description.isNotEmpty ? _currentCard.description : 'No description',
            style: TextStyle(
              fontSize: 14,
              color: _currentCard.description.isNotEmpty ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Expense Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              'Total: \$${_currentCard.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green[600],
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: const Center(
            child: Text(
              'No expense items',
              style: TextStyle(color: Colors.grey),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              _getTodoListText(),
              style: const TextStyle(color: Colors.grey),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: const Center(
            child: Text(
              'No attachments',
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
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue[100],
                    child: const Icon(Icons.add, size: 14, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Card created',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          _formatDateTime(_currentCard.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_currentCard.updatedAt != _currentCard.createdAt) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.green[100],
                      child: const Icon(Icons.edit, size: 14, color: Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Card updated',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _formatDateTime(_currentCard.updatedAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              _currentCard.notes.isNotEmpty 
                  ? '${_currentCard.notes.length} comments'
                  : 'No comments yet',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  void _showDeleteConfirmation() async {
    final confirmed = await DialogUtils.showDeleteConfirmDialog(
      context: context,
      title: 'Delete Card',
      content: 'Are you sure you want to delete "${_currentCard.title}"? This action cannot be undone.',
    );

    if (confirmed == true) {
      _deleteCard();
    }
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

      // Create a duplicate card
      final duplicateCard = JobCard(
        id: '',
        title: '${_currentCard.title} (Copy)',
        description: _currentCard.description,
        assignedTo: _currentCard.assignedTo,
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

      // Navigate back to previous page
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
}
