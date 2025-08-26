import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/hashtag_service.dart';
import '../../../core/widgets/hashtag_input_field.dart';
import '../../../domain/entities/customer.dart';
import '../controller/customers_controller.dart';
import 'add_edit_customer_page.dart';

class CustomerDetailPage extends StatefulWidget {
  final Customer customer;

  const CustomerDetailPage({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final HashtagService _hashtagService = HashtagService();
  final CustomersController _controller = Get.find<CustomersController>();
  List<HashtagOption> _availableHashtags = [];
  bool _isLoadingHashtags = true;
  
  // Current customer data that can be updated
  Customer? _currentCustomer;
  
  // Worker to manage the customer updates listener
  Worker? _customerUpdateListener;

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

  String _formatCompanyNames(List<Map<String, dynamic>> companyNames) {
    if (companyNames.isEmpty) return '';
    return companyNames
        .where((company) => company['value'] != null && company['value'].toString().trim().isNotEmpty)
        .map((company) => company['value'].toString())
        .join(', ');
  }

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _loadHashtags();
    _listenToCustomerUpdates();
  }

  @override
  void dispose() {
    // Dispose the customer update listener to prevent memory leaks
    _customerUpdateListener?.dispose();
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
          IconButton(
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
        ],
      ),
      body: SingleChildScrollView(
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
                _buildInfoRow('ชื่อบริษัท', _formatCompanyNames(_currentCustomer!.companyNames)),
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

  Widget _buildAssigneesDisplay() {
    final assignees = _currentCustomer!.assignees;
    
    if (!_hasValidAssignees()) {
      return _buildInfoRow('ผู้รับผิดชอบ', 'ไม่ระบุ');
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
              children: assignees.map((assigneeId) {
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
                    assigneeId, // TODO: Get user display name from service
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
}


