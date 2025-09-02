import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../controller/board_controller.dart';

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
  final BoardController _controller = Get.find<BoardController>();
  
  // Form controllers
  final TextEditingController _jobIdController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _hashtagController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  
  // Form state
  String _selectedLane = '';
  String _selectedAssignee = '';
  String _selectedCustomer = '';
  String _selectedCompany = 'none';
  String _selectedStatus = 'Pending';
  DateTime? _expectedClosingDate;
  bool _isLoading = false;
  
  // Available options
  List<Map<String, dynamic>> _availableLanes = [];
  List<Map<String, dynamic>> _availableAssignees = [];
  List<Map<String, dynamic>> _availableCustomers = [];
  List<Map<String, dynamic>> _availableCompanies = [];
  
  // Status options
  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'Pending', 'label': 'Pending', 'icon': Icons.schedule},
    {'value': 'In Progress', 'label': 'In Progress', 'icon': Icons.schedule},
    {'value': 'Done', 'label': 'Done', 'icon': Icons.check},
    {'value': 'Cancelled', 'label': 'Cancelled', 'icon': Icons.close},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData().then((_) {
      setState(() {});
    });
  }

  Future<void> _initializeData() async {
    // Load card data
    _jobIdController.text = widget.card.customId;
    _titleController.text = widget.card.title;
    _detailsController.text = widget.card.description;
    _selectedLane = widget.card.laneId;
    _selectedAssignee = widget.card.assignedTo;
    _selectedCustomer = widget.card.customer;
    _selectedStatus = widget.card.status;
    _expectedClosingDate = widget.card.dueDate;
    
    // Load available options
    await _loadAvailableOptions();
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
      
      // Validate selected company exists in available companies
      if (_selectedCompany.isNotEmpty) {
        final companyExists = _availableCompanies.any((company) => company['id'] == _selectedCompany);
        if (!companyExists) {
          print('⚠️ Selected company $_selectedCompany not found in available companies, resetting to none');
          _selectedCompany = 'none';
        }
      }
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
        _availableAssignees = [];
        _selectedAssignee = '';
        return;
      }

      print('🔄 Loading users for workspace: $workspaceId');
      
      // Get users from the workspace - data is already properly formatted from repository
      final users = await _controller.getWorkspaceUsers(workspaceId);
      _availableAssignees = users;
      
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
              icon: const Icon(Icons.visibility_outlined, color: Colors.black54),
              onSelected: (value) {
                // Add watcher functionality will be implemented later
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'add_watcher',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Add a watcher'),
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
            _buildCoreDetails(),
            const SizedBox(height: 24),
            _buildStatusSection(),
            const SizedBox(height: 24),
            _buildDetailsSection(),
            const SizedBox(height: 24),
            _buildExpenseItemsSection(),
            const SizedBox(height: 24),
            _buildRelatedDocumentsSection(),
            const SizedBox(height: 24),
            _buildTodoListSection(),
            const SizedBox(height: 24),
            _buildAttachedFilesSection(),
            const SizedBox(height: 24),
            _buildHistorySection(),
            const SizedBox(height: 24),
            _buildCommentsSection(),
            const SizedBox(height: 100), // Space for bottom buttons
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildCoreDetails() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job ID Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tag,
                    color: AppTheme.primaryOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Job ID',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  _jobIdController.text.isEmpty ? 'Auto-generated' : _jobIdController.text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Job Card Title Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Job Card Title',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter job title',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            
            // Lane Section
            const Text(
              'Lane',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLane.isNotEmpty && _availableLanes.any((lane) => lane['id'] == _selectedLane) 
                     ? _selectedLane : null,
              decoration: InputDecoration(
                hintText: 'Select lane',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            const SizedBox(height: 16),
            
            // Hashtag
            const Text(
              'Hashtag',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _hashtagController,
              decoration: InputDecoration(
                hintText: 'e.g. #Urgent #FollowUp',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            
            // Assignee
            const Text(
              'Assignee *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedAssignee.isNotEmpty && _availableAssignees.any((assignee) => assignee['id'] == _selectedAssignee) 
                     ? _selectedAssignee : null,
              decoration: InputDecoration(
                hintText: 'Select an assignee',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE1E5E9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.primaryOrange, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              isExpanded: true,
              items: _availableAssignees.map((assignee) {
                return DropdownMenuItem<String>(
                  value: assignee['id'],
                  child: Text(
                    assignee['name'],
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
            const SizedBox(height: 16),
            
            // Customer
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCustomer.isNotEmpty && _availableCustomers.any((customer) => customer['id'] == _selectedCustomer) 
                           ? _selectedCustomer 
                           : null,
                    decoration: const InputDecoration(
                      labelText: 'Customer',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
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
                        _selectedCustomer = value ?? '';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48, // Match dropdown height
                  child: ElevatedButton.icon(
                                    onPressed: () {
                  // Add new customer functionality will be implemented later
                },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Company
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCompany.isNotEmpty && _availableCompanies.any((company) => company['id'] == _selectedCompany) 
                           ? _selectedCompany 
                           : null,
                    decoration: const InputDecoration(
                      labelText: 'Company',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
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
                        _selectedCompany = value ?? '';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48, // Match dropdown height
                  child: ElevatedButton.icon(
                                    onPressed: () {
                  // Add new company functionality will be implemented later
                },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Expected Closing Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _expectedClosingDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _expectedClosingDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expected Closing Date',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _expectedClosingDate != null
                      ? '${_expectedClosingDate!.day}/${_expectedClosingDate!.month}/${_expectedClosingDate!.year}'
                      : 'Select a date',
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            
            // Rich Text Editor Toolbar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.format_bold), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_italic), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_underline), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.strikethrough_s), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.superscript), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.subscript), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.link), onPressed: () {}),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.format_align_left), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_align_center), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_align_right), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_size), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_size), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_size), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_list_bulleted), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_list_numbered), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.format_quote), onPressed: () {}),
                  ],
                ),
              ),
            ),
            
            // Rich Text Editor Content
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
              ),
              child: TextField(
                controller: _detailsController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Enter details...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
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

  Widget _buildAttachedFilesSection() {
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
                  'Attached Files',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Add File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
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
                  Expanded(flex: 3, child: Text('File Name', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Uploaded At', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No attachments uploaded yet',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
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
      // Create updated card
      final updatedCard = widget.card.copyWith(
        title: _titleController.text.trim(),
        description: _detailsController.text.trim(),
        customId: _jobIdController.text.trim(),
        status: _selectedStatus,
        assignedTo: _selectedAssignee,
        customer: _selectedCustomer,
        laneId: _selectedLane,
        dueDate: _expectedClosingDate,
        updatedAt: DateTime.now(),
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

  @override
  void dispose() {
    _jobIdController.dispose();
    _titleController.dispose();
    _hashtagController.dispose();
    _detailsController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
