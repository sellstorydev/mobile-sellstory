import 'package:flutter/material.dart';
import '../../board/view/card_view_page.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/hashtag_service.dart';
import '../../../core/services/workspace_members_service.dart';
import '../../../core/widgets/hashtag_input_field.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/job_card.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../controller/customers_controller.dart';
import 'add_edit_customer_page.dart';
import '../../../core/widgets/permission_guard.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPage({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> with SingleTickerProviderStateMixin {
  final HashtagService _hashtagService = HashtagService();
  final WorkspaceMembersService _workspaceMembersService = WorkspaceMembersService();
  final CustomersController _controller = Get.find<CustomersController>();
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  List<HashtagOption> _availableHashtags = [];
  List<WorkspaceMember> _workspaceMembers = [];
  bool _isLoadingHashtags = true;
  bool _isLoadingMembers = true;
  
  // Current customer data that can be updated
  Customer? _currentCustomer;
  
  // Worker to manage the customer updates listener
  Worker? _customerUpdateListener;
  
  // Tab controller
  late TabController _tabController;
  
  // Job cards data
  Stream<List<JobCard>>? _jobCardsStream;
  int _jobCardCount = 0;
  int _todoCount = 0;
  List<JobCard> _jobCards = [];
  bool _jobCardsLoading = true;
  StreamSubscription<List<JobCard>>? _jobCardsSub;

  // Helper methods to check for valid data
  bool _hasValidEmails() {
    final customer = _currentCustomer ?? widget.customer;
    return customer.emails.isNotEmpty && 
           customer.emails.any((email) => 
             email['value'] != null && 
             email['value'].toString().trim().isNotEmpty
           );
  }

  bool _hasValidPhones() {
    final customer = _currentCustomer ?? widget.customer;
    return customer.phones.isNotEmpty && 
           customer.phones.any((phone) => 
             phone['value'] != null && 
             phone['value'].toString().trim().isNotEmpty
           );
  }

  bool _hasValidCompanies() {
    final customer = _currentCustomer ?? widget.customer;
    return customer.companyNames.isNotEmpty && 
           customer.companyNames.any((company) => 
             company['value'] != null && 
             company['value'].toString().trim().isNotEmpty
           );
  }

  bool _hasValidHashtags() {
    final customer = _currentCustomer ?? widget.customer;
    return customer.hashtags.isNotEmpty && 
           customer.hashtags.any((hashtag) => 
             hashtag['id'] != null && 
             hashtag['id'].toString().trim().isNotEmpty
           );
  }

  bool _hasValidAssignees() {
    final customer = _currentCustomer ?? widget.customer;
    return customer.assignees.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _tabController = TabController(length: 6, vsync: this);
    _loadHashtags();
    _loadWorkspaceMembers();
    _listenToCustomerUpdates();
    _initJobCardsStream();
  }

  void _initJobCardsStream() {
    // Get current workspace ID
    final workspaceId = _controller.currentWorkspaceId.value.isNotEmpty 
        ? _controller.currentWorkspaceId.value 
        : widget.customer.workspaceId;
    
    // Initialize the job cards stream for this customer
    _jobCardsStream = _repository.getCardsForCustomerStream(workspaceId, widget.customer.id);
    
    // Listen to job cards stream to update counts
    _jobCardsSub = _jobCardsStream?.listen((jobCards) {
      if (!mounted) return;
      int todoCount = 0;
      for (final jobCard in jobCards) {
        todoCount += jobCard.todos.length;
      }

      setState(() {
        _jobCards = jobCards;
        _jobCardsLoading = false;
        _jobCardCount = jobCards.length;
        _todoCount = todoCount;
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        _jobCardsLoading = false; // stop infinite loading even on error
      });
    });
  }

  @override
  void dispose() {
    // Dispose the customer update listener to prevent memory leaks
    _customerUpdateListener?.dispose();
  _jobCardsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _listenToCustomerUpdates() {
    // Listen to customer updates from the controller
    _customerUpdateListener = ever(_controller.customers, (customers) {
      if (customers.isNotEmpty && mounted) {
        // Find the updated customer by ID
        final updatedCustomer = customers.firstWhere(
          (customer) => customer.id == widget.customer.id,
          orElse: () => widget.customer,
        );
        
        if (updatedCustomer != _currentCustomer) {
          setState(() {
            _currentCustomer = updatedCustomer;
          });
        }
      }
    });
  }

  Future<void> _loadHashtags() async {
    try {
      // Use controller to get current workspace ID
      final workspaceId = _controller.currentWorkspaceId.value.isNotEmpty 
          ? _controller.currentWorkspaceId.value 
          : widget.customer.workspaceId;
      
      print('Loading hashtags for workspace: $workspaceId');
      final hashtags = await _hashtagService.getWorkspaceHashtags(workspaceId);
      print('Loaded ${hashtags.length} hashtags');
      setState(() {
        _availableHashtags = hashtags;
        _isLoadingHashtags = false;
      });
    } catch (e) {
      print('Error loading hashtags: $e');
      setState(() {
        _isLoadingHashtags = false;
      });
    }
  }

  Future<void> _loadWorkspaceMembers() async {
    try {
      // Use controller to get current workspace ID
      final workspaceId = _controller.currentWorkspaceId.value.isNotEmpty 
          ? _controller.currentWorkspaceId.value 
          : widget.customer.workspaceId;
      
      print('Loading workspace members for workspace: $workspaceId');
      final members = await _workspaceMembersService.getWorkspaceMembers(workspaceId);
      print('Loaded ${members.length} workspace members');
      setState(() {
        _workspaceMembers = members;
        _isLoadingMembers = false;
      });
    } catch (e) {
      print('Error loading workspace members: $e');
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: Text('รายละเอียดลูกค้า'),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          PermissionGuard(
            permission: 'customer:edit:all',
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddEditCustomerPage(
                      customer: _currentCustomer,
                      customerSources: _controller.customerSources,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              tooltip: 'แก้ไขลูกค้า',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Existing customer info section (scrollable)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Card
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  
                  // Customer Information
                  _buildInfoSection('ข้อมูลลูกค้า', [
                    _buildInfoRow('รหัสลูกค้า', _currentCustomer!.customId),
                    _buildInfoRow('ชื่อ', '${_currentCustomer!.prefix} ${_currentCustomer!.name}'),
                    _buildInfoRow('เพศ', _currentCustomer!.gender),
                    _buildInfoRow('อายุ', '${_currentCustomer!.age} ปี'),
                    _buildInfoRow('ประเภท', _currentCustomer!.customerType),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  // Contact Information
                  _buildInfoSection('ข้อมูลติดต่อ', [
                    _buildEmailsDisplay(),
                    _buildPhonesDisplay(),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  // Company Information
                  if (_hasValidCompanies()) ...[
                    _buildInfoSection('ข้อมูลบริษัท', [
                      _buildCompanyNamesDisplay(),
                    ]),
                    const SizedBox(height: 16),
                  ],
                  
                  // Additional Information
                  _buildInfoSection('ข้อมูลเพิ่มเติม', [
                    if (_currentCustomer!.nationalId.isNotEmpty)
                      _buildInfoRow('เลขบัตรประชาชน', _currentCustomer!.nationalId),
                    if (_currentCustomer!.address.isNotEmpty)
                      _buildInfoRow('ที่อยู่', _currentCustomer!.address),
                    if (_currentCustomer!.source.isNotEmpty)
                      _buildInfoRow('แหล่งที่มา', _currentCustomer!.source),
                    _buildHashtagDisplay(), // Always show hashtag section
                    if (_hasValidAssignees())
                       _buildAssigneesDisplay(),
                  ]),
                  
                  const SizedBox(height: 16),
                  
                  // System Information
                  _buildInfoSection('ข้อมูลระบบ', [
                    _buildInfoRow('สร้างเมื่อ', _formatDate(_currentCustomer!.createdAt)),
                    _buildInfoRow('อัปเดตล่าสุด', _formatDate(_currentCustomer!.updatedAt)),
                  ]),
                ],
              ),
            ),
          ),
          
          // Tab Bar and TabBarView (new section)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Tab Bar
                Container(
                  color: AppTheme.backgroundWhite,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryOrange,
                    labelColor: AppTheme.primaryOrange,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    isScrollable: true,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(text: 'Job card ($_jobCardCount)'),
                      Tab(text: 'สิ่งที่ต้องทำ ($_todoCount)'),
                      Tab(text: 'ประวัติ (0)'),
                      Tab(text: 'คลังเอกสาร (0)'),
                      Tab(text: 'โน๊ต (0)'),
                      Tab(text: 'เอกสารการขาย (0)'),
                    ],
                  ),
                ),
                
                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Job Card Tab
                      _buildJobCardTab(),
                      
                      // สิ่งที่ต้องทำ Tab
                      _buildTodoTab(),
                      
                      // ประวัติ Tab
                      _buildHistoryTab(),
                      
                      // คลังเอกสาร Tab
                      _buildDocumentTab(),
                      
                      // โน๊ต Tab
                      _buildNoteTab(),
                      
                      // เอกสารการขาย Tab
                      _buildSalesDocumentTab(),
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

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Image
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
            child: Icon(
              Icons.person,
              size: 40,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: 16),
          
          // Name
          Text(
            '${_currentCustomer!.prefix} ${_currentCustomer!.name}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Customer ID
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentCustomer!.customId,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Customer Type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _currentCustomer!.customerType == 'Customer' 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentCustomer!.customerType,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _currentCustomer!.customerType == 'Customer' 
                    ? Colors.green
                    : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagDisplay() {
    // Get hashtag objects directly from the list
    final hashtagObjects = _currentCustomer!.hashtags;
    
    print('=== Hashtag Display Debug ===');
    print('Customer hashtags data: $hashtagObjects');
    print('Hashtags type: ${hashtagObjects.runtimeType}');
    print('Hashtags length: ${hashtagObjects.length}');
    print('Is loading hashtags: $_isLoadingHashtags');
    print('Available hashtags count: ${_availableHashtags.length}');
    
    // Debug: Show available hashtag IDs
    if (_availableHashtags.isNotEmpty) {
      print('Available hashtag IDs: ${_availableHashtags.map((h) => h.id).toList()}');
    }
    
    if (_isLoadingHashtags) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                'แฮชแท็ก',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasValidHashtags()) {
      print('No valid hashtags found, showing "ไม่ระบุ"');
      return _buildInfoRow('แฮชแท็ก', 'ไม่ระบุ');
    }

    // Convert hashtag objects to HashtagOption for display
    final List<HashtagOption> selectedHashtags = [];
    
    for (int i = 0; i < hashtagObjects.length; i++) {
      try {
        final hashtagObj = hashtagObjects[i];
        print('Processing hashtag object $i: $hashtagObj');
        
        // Handle the hashtag object structure: {color, id, text}
        final hashtagId = hashtagObj['id'] as String? ?? '';
        final hashtagText = hashtagObj['text'] as String? ?? '';
        final hashtagColor = hashtagObj['color'] as String? ?? '#ef4444';
        
        print('Parsed hashtag $i - ID: $hashtagId, Text: $hashtagText, Color: $hashtagColor');
        
        final hashtagOption = _availableHashtags.firstWhere(
          (hashtag) => hashtag.id == hashtagId,
          orElse: () => HashtagOption(
            id: hashtagId,
            name: hashtagText,
            color: hashtagColor,
            totalUsage: 0,
            enabled: true,
            scopes: {},
          ),
        );
        
        selectedHashtags.add(hashtagOption);
        print('✅ Added hashtag: ${hashtagOption.name}');
      } catch (e) {
        print('❌ Error processing hashtag $i: $e');
        // Continue with other hashtags
      }
    }
    
    print('Final selected hashtags count: ${selectedHashtags.length}');
    
    if (selectedHashtags.isEmpty) {
      print('No hashtags processed successfully, showing fallback');
      return _buildInfoRow('แฮชแท็ก', 'ไม่ระบุ');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'แฮชแท็ก',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: selectedHashtags.map((hashtag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _parseColor(hashtag.color),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '#${hashtag.name}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      // Handle different color formats
      String cleanColor = colorString.trim();
      
      // If it's already a hex color with #
      if (cleanColor.startsWith('#')) {
        // Ensure it's 6 digits (RGB) or 8 digits (ARGB)
        if (cleanColor.length == 7) {
          // RGB format: #RRGGBB -> 0xFFRRGGBB
          return Color(int.parse('0xFF${cleanColor.substring(1)}'));
        } else if (cleanColor.length == 9) {
          // ARGB format: #AARRGGBB -> 0xAARRGGBB
          return Color(int.parse('0x${cleanColor.substring(1)}'));
        }
      }
      
      // If it's a hex color without #
      if (cleanColor.length == 6) {
        // RGB format: RRGGBB -> 0xFFRRGGBB
        return Color(int.parse('0xFF$cleanColor'));
      } else if (cleanColor.length == 8) {
        // ARGB format: AARRGGBB -> 0xAARRGGBB
        return Color(int.parse('0x$cleanColor'));
      }
      
      // If it's a number (already in int format)
      if (int.tryParse(cleanColor) != null) {
        return Color(int.parse(cleanColor));
      }
      
      // Fallback to default color
      return AppTheme.primaryOrange;
    } catch (e) {
      print('Error parsing color: $colorString - $e');
      return AppTheme.primaryOrange;
    }
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmailsDisplay() {
    final emails = _currentCustomer!.emails;
    
    if (!_hasValidEmails()) {
      return _buildInfoRow('อีเมล', 'ไม่ระบุ');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'อีเมล',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: emails.where((email) => 
                email['value'] != null && 
                email['value'].toString().trim().isNotEmpty
              ).map((email) {
                final label = email['label'] as String? ?? 'Work';
                final value = email['value'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$label: $value',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhonesDisplay() {
    final phones = _currentCustomer!.phones;
    
    if (!_hasValidPhones()) {
      return _buildInfoRow('เบอร์โทร', 'ไม่ระบุ');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'เบอร์โทร',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: phones.where((phone) => 
                phone['value'] != null && 
                phone['value'].toString().trim().isNotEmpty
              ).map((phone) {
                final label = phone['label'] as String? ?? 'Work';
                final value = phone['value'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '$label: $value',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyNamesDisplay() {
    final companyNames = _currentCustomer!.companyNames;
    
    if (!_hasValidCompanies()) {
      return _buildInfoRow('ชื่อบริษัท', 'ไม่ระบุ');
    }

    // Get company names from the object structure
    final List<String> companyNameList = [];
    for (final company in companyNames) {
      final companyName = company['value'] as String? ?? '';
      if (companyName.trim().isNotEmpty) {
        companyNameList.add(companyName);
      }
    }

    if (companyNameList.isEmpty) {
      return _buildInfoRow('ชื่อบริษัท', 'ไม่ระบุ');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'ชื่อบริษัท',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: companyNameList.map((companyName) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssigneesDisplay() {
    final assignees = _currentCustomer!.assignees;
    
    if (!_hasValidAssignees()) {
      return _buildInfoRow('ผู้รับผิดชอบ', 'ไม่ระบุ');
    }

    if (_isLoadingMembers) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                'ผู้รับผิดชอบ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ),
      );
    }

    // Get display names for assignee IDs
    final List<String> assigneeNames = [];
    for (final assigneeId in assignees) {
      final member = _workspaceMembers.firstWhere(
        (member) => member.uid == assigneeId,
        orElse: () => WorkspaceMember(
          uid: assigneeId,
          email: '',
          displayName: assigneeId, // Fallback to ID if member not found
          permission: 'member',
        ),
      );
      assigneeNames.add(member.displayName);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              'ผู้รับผิดชอบ',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: assigneeNames.map((displayName) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryOrange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Tab content builders
  Widget _buildJobCardTab() {
    if (_jobCardsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_jobCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มี Job Card สำหรับลูกค้านี้',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _jobCards.length,
          itemBuilder: (context, index) {
            final jobCard = _jobCards[index];
            return _buildJobCardItem(jobCard);
          },
        ),
      ),
    );
  }
  
  Widget _buildJobCardItem(JobCard jobCard) {
    return InkWell(
      onTap: () => Get.to(() => CardViewPage(card: jobCard)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jobCard.customId.isNotEmpty ? jobCard.customId : jobCard.id,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(jobCard.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    jobCard.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(jobCard.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              jobCard.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (jobCard.assignedTo.isNotEmpty) ...[
                        _buildJobCardDetailRow(
                          Icons.person_outline,
                          'ผู้รับผิดชอบ',
                          _getAssigneeName(jobCard.assignedTo),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (jobCard.customerInterest?.isNotEmpty == true) ...[
                        _buildJobCardDetailRow(
                          Icons.favorite_outline,
                          'ความสนใจ',
                          jobCard.customerInterest!,
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (jobCard.dueDate != null) ...[
                        _buildJobCardDetailRow(
                          Icons.calendar_today_outlined,
                          'กำหนดส่ง',
                          _formatDate(jobCard.dueDate!),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (jobCard.hashtags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: jobCard.hashtags.map((hashtag) {
                  final hashtagText = hashtag['text'] as String? ?? hashtag['id'] as String? ?? '';
                  final hashtagColor = hashtag['color'] as String? ?? '';
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _parseColor(hashtagColor).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _parseColor(hashtagColor).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '#$hashtagText',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _parseColor(hashtagColor),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildJobCardDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return Colors.green;
      case 'in progress':
      case 'doing':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'on hold':
        return Colors.orange;
      default:
        return AppTheme.textSecondary;
    }
  }
  
  String _getAssigneeName(String assigneeId) {
    final member = _workspaceMembers.firstWhere(
      (member) => member.uid == assigneeId,
      orElse: () => WorkspaceMember(
        uid: assigneeId,
        email: '',
        displayName: assigneeId, // Fallback to ID if member not found
        permission: 'member',
      ),
    );
    return member.displayName;
  }

  Widget _buildTodoTab() {
    if (_jobCardsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Collect all todos from cached job cards
    final allTodos = <Map<String, dynamic>>[];
    for (final jobCard in _jobCards) {
      for (final todo in jobCard.todos) {
        final todoWithContext = Map<String, dynamic>.from(todo);
        todoWithContext['jobCardId'] = jobCard.id;
        todoWithContext['jobCardTitle'] = jobCard.title;
        todoWithContext['jobCardCustomId'] = jobCard.customId.isNotEmpty ? jobCard.customId : jobCard.id;
        allTodos.add(todoWithContext);
      }
    }

    if (allTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.checklist_outlined,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มี To-Do สำหรับลูกค้านี้',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundGrey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: allTodos.length,
          itemBuilder: (context, index) {
            final todo = allTodos[index];
            return _buildTodoItem(todo);
          },
        ),
      ),
    );
  }
  
  Widget _buildTodoItem(Map<String, dynamic> todo) {
    final isCompleted = todo['completed'] as bool? ?? false;
    final todoTitle = todo['title'] as String? ?? '';
    final dueDate = todo['dueDate'];
    final jobCardTitle = todo['jobCardTitle'] as String? ?? '';
    final jobCardCustomId = todo['jobCardCustomId'] as String? ?? '';
    
    // Parse HTML title to plain text
    String plainTitle = todoTitle;
    try {
      // Simple HTML tag removal - you might want to use a proper HTML parser
      plainTitle = todoTitle.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (plainTitle.isEmpty) {
        plainTitle = 'Untitled To-Do';
      }
    } catch (e) {
      plainTitle = 'Untitled To-Do';
    }
    
    DateTime? todoDate;
    if (dueDate != null) {
      try {
        if (dueDate is int) {
          todoDate = DateTime.fromMillisecondsSinceEpoch(dueDate);
        }
      } catch (e) {
        // Handle date parsing error
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with completion status and job card info
          Row(
            children: [
              // Completion checkbox
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: isCompleted ? Colors.green : AppTheme.textSecondary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // Job Card info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'จาก Job Card: $jobCardCustomId',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (jobCardTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        jobCardTitle,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'เสร็จแล้ว' : 'ยังไม่เสร็จ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Todo title
          Text(
            plainTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              decorationColor: AppTheme.textSecondary,
            ),
          ),
          
          // Due date
          if (todoDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'กำหนดส่ง: ${_formatDate(todoDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Container(
      color: AppTheme.backgroundGrey,
      child: Center(
        child: Text(
          'ประวัติ\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTab() {
    return Container(
      color: AppTheme.backgroundGrey,
      child: Center(
        child: Text(
          'คลังเอกสาร\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildNoteTab() {
    return Container(
      color: AppTheme.backgroundGrey,
      child: Center(
        child: Text(
          'โน๊ต\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSalesDocumentTab() {
    return Container(
      color: AppTheme.backgroundGrey,
      child: Center(
        child: Text(
          'เอกสารการขาย\n(Coming Soon)',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

