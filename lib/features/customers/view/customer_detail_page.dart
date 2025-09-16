import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/workspace_members_service.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/job_card.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../controller/customers_controller.dart';
import 'add_edit_customer_page.dart';
import '../../../core/widgets/permission_guard.dart';
import '../../../data/services/mobile_permissions_service.dart';

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
  final WorkspaceMembersService _workspaceMembersService = WorkspaceMembersService();
  final CustomersController _controller = Get.find<CustomersController>();
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  List<WorkspaceMember> _workspaceMembers = [];

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
    _loadWorkspaceMembers();
    _listenToCustomerUpdates();
    _initJobCardsStream();
  }

  bool _isCurrentUserAssigned() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final customer = _currentCustomer ?? widget.customer;
    if (uid == null) return false;
    return customer.assignees.contains(uid);
  }

  bool _canEditCustomer() {
    final svc = MobilePermissionsService.to;
    if (svc.isOwner || svc.can('customer:edit:all')) return true;
    return svc.can('customer:edit:assigned') && _isCurrentUserAssigned();
  }

  bool _canViewAnyJobcard() {
    final svc = MobilePermissionsService.to;
    return svc.isOwner || svc.can('jobcard:view:all') || svc.can('jobcard:view:assigned');
  }

  List<JobCard> _visibleJobcards(List<JobCard> all) {
    final svc = MobilePermissionsService.to;
    if (svc.isOwner || svc.can('jobcard:view:all')) return all;
    if (svc.can('jobcard:view:assigned')) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return const [];
      return all.where((jc) => jc.assignedTo == uid).toList();
    }
    return const [];
  }

  void _recomputeJobcardCounts(List<JobCard> all) {
    final visible = _visibleJobcards(all);
    int todoCount = 0;
    for (final jobCard in visible) {
      todoCount += jobCard.todos.length;
    }
    setState(() {
      _jobCards = all; // keep raw; filter in builders
      _jobCardsLoading = false;
      _jobCardCount = visible.length;
      _todoCount = todoCount;
    });
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
      _recomputeJobcardCounts(jobCards);
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        _jobCardsLoading = false; // stop infinite loading even on error
      });
    });
  }

  @override
  void dispose() {
    _customerUpdateListener?.dispose();
    _jobCardsSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _listenToCustomerUpdates() {
    _customerUpdateListener = ever(_controller.customers, (customers) {
      if (customers.isNotEmpty && mounted) {
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

  Future<void> _loadWorkspaceMembers() async {
    try {
      final workspaceId = _controller.currentWorkspaceId.value.isNotEmpty
          ? _controller.currentWorkspaceId.value
          : widget.customer.workspaceId;

      final members = await _workspaceMembersService.getWorkspaceMembers(workspaceId);
      setState(() {
        _workspaceMembers = members;
      });
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> _launchPhone() async {
    try {
      final customer = _currentCustomer ?? widget.customer;
      final first = customer.phones.firstWhere(
        (p) => (p['value'] ?? '').toString().trim().isNotEmpty,
        orElse: () => {},
      );
      final phone = (first['value'] ?? '').toString().trim();
      if (phone.isEmpty) return;
      final uri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Future<void> _launchEmail() async {
    try {
      final customer = _currentCustomer ?? widget.customer;
      final first = customer.emails.firstWhere(
        (e) => (e['value'] ?? '').toString().trim().isNotEmpty,
        orElse: () => {},
      );
      final email = (first['value'] ?? '').toString().trim();
      if (email.isEmpty) return;
      final uri = Uri(scheme: 'mailto', path: email);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Widget _buildActionButtons() {
    Widget circleIcon(IconData icon, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryOrange,
            size: 24,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          circleIcon(Icons.phone, _launchPhone),
          const SizedBox(width: 40),
          circleIcon(Icons.email, _launchEmail),
        ],
      ),
    );
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'not_specified'.tr,
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

  Widget _buildEmailsDisplay() {
    final customer = _currentCustomer ?? widget.customer;
    if (!_hasValidEmails()) {
      return _buildInfoRow('email'.tr, 'not_specified'.tr);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'email'.tr,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ...customer.emails.where((email) => 
          email['value'] != null && 
          email['value'].toString().trim().isNotEmpty
        ).map((email) {
          final label = email['label']?.toString() ?? '';
          final value = email['value']?.toString() ?? '';
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
      ],
    );
  }

  Widget _buildPhonesDisplay() {
    final customer = _currentCustomer ?? widget.customer;
    if (!_hasValidPhones()) {
      return _buildInfoRow('เบอร์โทร', 'ไม่ระบุ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'เบอร์โทร',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ...customer.phones.where((phone) => 
          phone['value'] != null && 
          phone['value'].toString().trim().isNotEmpty
        ).map((phone) {
          final label = phone['label']?.toString() ?? '';
          final value = phone['value']?.toString() ?? '';
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
      ],
    );
  }

  Widget _buildCompanyNamesDisplay() {
    final customer = _currentCustomer ?? widget.customer;
    if (!_hasValidCompanies()) {
      return _buildInfoRow('บริษัท', 'ไม่ระบุ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'บริษัท',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: customer.companyNames.where((company) => 
            company['value'] != null && 
            company['value'].toString().trim().isNotEmpty
          ).map((company) {
            final name = company['value']?.toString() ?? '';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHashtagDisplay() {
    final customer = _currentCustomer ?? widget.customer;
    if (!_hasValidHashtags()) {
      return _buildInfoRow('แฮชแท็ก', 'ไม่มี');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'แฮชแท็ก',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: customer.hashtags.where((hashtag) => 
            hashtag['id'] != null && 
            hashtag['id'].toString().trim().isNotEmpty
          ).map((hashtag) {
            final text = hashtag['text']?.toString() ?? hashtag['id']?.toString() ?? '';
            final color = hashtag['color']?.toString() ?? '#FF6B35';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _parseColor(color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _parseColor(color).withOpacity(0.3)),
              ),
              child: Text(
                '#$text',
                style: TextStyle(
                  fontSize: 12,
                  color: _parseColor(color),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAssigneesDisplay() {
    final customer = _currentCustomer ?? widget.customer;
    if (!_hasValidAssignees()) {
      return _buildInfoRow('ผู้รับผิดชอบ', 'ไม่มี');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ผู้รับผิดชอบ',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: customer.assignees.map((assigneeId) {
            final member = _workspaceMembers.firstWhere(
              (m) => m.uid == assigneeId,
              orElse: () => WorkspaceMember(
                uid: assigneeId,
                email: '',
                displayName: assigneeId,
                permission: 'member',
              ),
            );
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
              ),
              child: Text(
                member.displayName,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      String hex = colorString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha if not present
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return AppTheme.primaryOrange; // Default color
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year + 543}';
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
            backgroundColor: AppTheme.primaryOrange.withAlpha(25),
            backgroundImage: (_currentCustomer != null && _currentCustomer!.profileImageUrl.isNotEmpty)
                ? NetworkImage(_currentCustomer!.profileImageUrl)
                : null,
            child: (_currentCustomer == null || _currentCustomer!.profileImageUrl.isEmpty)
                ? Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryOrange,
                  )
                : null,
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
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    Widget cell(String title, String value, {Color? valueColor}) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1F2937),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          cell('จำนวนการซื้อซ้ำ', '0 ครั้ง'),
          Container(
            width: 0.5,
            height: 60,
            color: const Color(0xFFE5E7EB),
          ),
          cell('ยอดชำระรวม', '฿0.00', valueColor: const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildHeaderSummary() {
    final customer = _currentCustomer ?? widget.customer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: (customer.profileImageUrl.isNotEmpty)
                ? ClipOval(child: Image.network(customer.profileImageUrl, width: 56, height: 56, fit: BoxFit.cover))
                : const Icon(
                    Icons.person,
                    color: AppTheme.primaryOrange,
                    size: 28,
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            '${customer.prefix.isNotEmpty ? '${customer.prefix} ' : ''}${customer.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF1F2937),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withAlpha(25),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'ลูกค้า',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopInfoSection() {
    final customer = _currentCustomer ?? widget.customer;

    String? firstPhone() {
      try {
        final p = customer.phones.firstWhere(
          (e) => (e['value'] ?? '').toString().trim().isNotEmpty,
          orElse: () => {},
        );
        final v = (p['value'] ?? '').toString().trim();
        return v.isEmpty ? null : v;
      } catch (_) {
        return null;
      }
    }

    String? firstEmail() {
      try {
        final e = customer.emails.firstWhere(
          (m) => (m['value'] ?? '').toString().trim().isNotEmpty,
          orElse: () => {},
        );
        final v = (e['value'] ?? '').toString().trim();
        return v.isEmpty ? null : v;
      } catch (_) {
        return null;
      }
    }

    final phone = firstPhone();
    final email = firstEmail();

    final List<Widget> rows = [];

    if (customer.customId.isNotEmpty) {
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.badge, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'รหัสลูกค้า: ${customer.customId}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ));
    }

    if (phone != null) {
      rows.add(const SizedBox(height: 4));
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              phone,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ));
    }

    if (email != null) {
      rows.add(const SizedBox(height: 4));
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.email, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              email,
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ));
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: rows,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = _currentCustomer ?? widget.customer;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          customer.name.isNotEmpty ? customer.name : 'รายละเอียดลูกค้า',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_canEditCustomer())
            IconButton(
              tooltip: 'แก้ไข',
              icon: const Icon(Icons.edit, color: AppTheme.primaryOrange),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditCustomerPage(
                      customer: customer,
                      customerSources: _controller.customerSources,
                    ),
                  ),
                );

                if (result == true) {
                  final updated = _controller.getCustomerById(customer.id);
                  if (updated != null && mounted) {
                    setState(() {
                      _currentCustomer = updated;
                    });
                  }
                }
              },
            )
          else
            const SizedBox.shrink(),
        ],
      ),
      body: Builder(
        builder: (context) {
          final svc = MobilePermissionsService.to;
          final canAllView = svc.isOwner || svc.can('customer:view:all');
          final canAssignedView = svc.can('customer:view:assigned') && _isCurrentUserAssigned();
          final canView = canAllView || canAssignedView;
          if (!canView) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock_outline, size: 56, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('คุณไม่มีสิทธิ์ดูรายละเอียดลูกค้ารายนี้',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileCard(),
                            const SizedBox(height: 16),
                            _buildInfoSection('ข้อมูลลูกค้า', [
                              _buildInfoRow('รหัสลูกค้า', _currentCustomer!.customId),
                              _buildInfoRow('ชื่อ', '${_currentCustomer!.prefix} ${_currentCustomer!.name}'),
                              _buildInfoRow('เพศ', _currentCustomer!.gender),
                              _buildInfoRow('อายุ', '${_currentCustomer!.age} ปี'),
                              _buildInfoRow('ประเภท', _currentCustomer!.customerType),
                            ]),
                            const SizedBox(height: 16),
                            _buildInfoSection('ข้อมูลติดต่อ', [
                              _buildEmailsDisplay(),
                              _buildPhonesDisplay(),
                            ]),
                            const SizedBox(height: 16),
                            if (_hasValidCompanies()) ...[
                              _buildInfoSection('ข้อมูลบริษัท', [
                                _buildCompanyNamesDisplay(),
                              ]),
                              const SizedBox(height: 16),
                            ],
                            _buildInfoSection('ข้อมูลเพิ่มเติม', [
                              if (_currentCustomer!.nationalId.isNotEmpty)
                                _buildInfoRow('เลขบัตรประชาชน', _currentCustomer!.nationalId),
                              if (_currentCustomer!.address.isNotEmpty)
                                _buildInfoRow('ที่อยู่', _currentCustomer!.address),
                              if (_currentCustomer!.source.isNotEmpty)
                                _buildInfoRow('แหล่งที่มา', _currentCustomer!.source),
                              _buildHashtagDisplay(),
                              if (_hasValidAssignees()) _buildAssigneesDisplay(),
                            ]),
                            const SizedBox(height: 16),
                            _buildInfoSection('ข้อมูลระบบ', [
                              _buildInfoRow('สร้างเมื่อ', _formatDate(_currentCustomer!.createdAt)),
                              _buildInfoRow('อัปเดตล่าสุด', _formatDate(_currentCustomer!.updatedAt)),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarSliverDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppTheme.primaryOrange,
                      labelColor: AppTheme.primaryOrange,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                      isScrollable: true,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(text: 'Job card (' '$_jobCardCount' ')'),
                        Tab(text: 'สิ่งที่ต้องทำ (' '$_todoCount' ')'),
                        const Tab(text: 'ประวัติ (0)'),
                        const Tab(text: 'คลังเอกสาร (0)'),
                        const Tab(text: 'โน๊ต (0)'),
                        const Tab(text: 'เอกสารการขาย (0)'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildJobCardTab(),
                  _buildTodoTab(),
                  _buildHistoryTab(),
                  _buildDocumentTab(),
                  _buildNoteTab(),
                  _buildSalesDocumentTab(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Tab content builders
  Widget _buildJobCardTab() {
    if (_jobCardsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_canViewAnyJobcard()) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('คุณไม่มีสิทธิ์ดู Job Card ของลูกค้ารายนี้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final visible = _visibleJobcards(_jobCards);

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final jobCard = visible[index];
            return _buildJobCardItem(jobCard);
          },
        ),
      ),
    );
  }
  
  Widget _buildJobCardItem(JobCard jobCard) {
    return InkWell(
      onTap: () {
        final svc = MobilePermissionsService.to;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final canAll = svc.isOwner || svc.can('jobcard:view:all');
        final canAssigned = svc.can('jobcard:view:assigned') && (uid != null && jobCard.assignedTo == uid);
        if (canAll || canAssigned) {
          Get.toNamed(AppRoutes.editCard, arguments: jobCard);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('คุณไม่มีสิทธิ์เข้าถึง Job Card นี้')),
          );
        }
      },
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
                    )
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

    if (!_canViewAnyJobcard()) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('คุณไม่มีสิทธิ์ดู To-Do ของลูกค้ารายนี้',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // Collect all todos from visible job cards
    final visible = _visibleJobcards(_jobCards);
    final allTodos = <Map<String, dynamic>>[];
    for (final jobCard in visible) {
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

class _TabBarSliverDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarSliverDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.backgroundWhite,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
