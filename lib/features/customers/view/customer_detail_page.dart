import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/workspace_members_service.dart';
import '../../../domain/entities/customer.dart';
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

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final WorkspaceMembersService _workspaceMembersService = WorkspaceMembersService();
  final CustomersController _controller = Get.find<CustomersController>();
  List<WorkspaceMember> _workspaceMembers = [];

  // Current customer data that can be updated
  Customer? _currentCustomer;

  // Worker to manage the customer updates listener
  Worker? _customerUpdateListener;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _loadWorkspaceMembers();
    _listenToCustomerUpdates();
  }

  @override
  void dispose() {
    _customerUpdateListener?.dispose();
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
      return Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Center(
              child: Icon(
                icon,
                color: AppTheme.primaryOrange,
                size: 24,
              ),
            ),
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

  Widget _tileWrapper({required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPrimaryPersonTile() {
    final customer = _currentCustomer ?? widget.customer;

    return _tileWrapper(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppTheme.primaryOrange,
              size: 18,
            ),
          ),
          title: Text(
            '${customer.prefix.isNotEmpty ? '${customer.prefix} ' : ''}${customer.name}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1F2937),
              letterSpacing: 0.2,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: customer.customerType == 'Customer'
                        ? Colors.green.withAlpha(25)
                        : Colors.orange.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    customer.customerType,
                    style: TextStyle(
                      fontSize: 10,
                      color: customer.customerType == 'Customer'
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  customer.customId,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade500,
            size: 20,
          ),
          children: [
            _buildCustomerDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails() {
    final customer = _currentCustomer ?? widget.customer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info
          _buildDetailRow('เพศ', customer.gender),
          _buildDetailRow('อายุ', customer.age.isNotEmpty ? '${customer.age} ปี' : 'ไม่ระบุ'),
          _buildDetailRow('เลขบัตรประชาชน', customer.nationalId.isNotEmpty ? customer.nationalId : 'ไม่ระบุ'),
          _buildDetailRow('แหล่งที่มา', customer.source),

          if (customer.address.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow('ที่อยู่', customer.address),
          ],

          // Emails
          if (customer.emails.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildContactSection('อีเมล', customer.emails),
          ],

          // Phones
          if (customer.phones.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildContactSection('เบอร์โทร', customer.phones),
          ],

          // Assignees
          if (customer.assignees.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAssigneesSection(customer.assignees),
          ],

          // Companies
          if (customer.companyNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCompaniesSection(customer.companyNames),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(String title, List<Map<String, dynamic>> contacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        ...contacts.map((contact) {
          final label = contact['label']?.toString() ?? '';
          final value = contact['value']?.toString() ?? '';
          if (value.isEmpty) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAssigneesSection(List<String> assignees) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ผู้รับผิดชอบ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: assignees.map((assigneeId) {
            // Find member name from assignee ID
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                member.displayName,
                style: const TextStyle(
                  color: AppTheme.primaryOrange,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCompaniesSection(List<Map<String, dynamic>> companies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'บริษัท',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: companies.map((company) {
            final name = company['value']?.toString() ?? '';
            if (name.isEmpty) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
            child: const Icon(
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
          IconButton(
            tooltip: 'แก้ไข',
            icon: const Icon(Icons.edit, color: AppTheme.primaryOrange),
            onPressed: () async {
              guardAction(context, 'customer:edit:all', () async {
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
                  // Try to refresh local view with updated customer
                  final updated = _controller.getCustomerById(customer.id);
                  if (updated != null && mounted) {
                    setState(() {
                      _currentCustomer = updated;
                    });
                  }
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildHeaderSummary(),
              const SizedBox(height: 8),
              _buildTopInfoSection(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildSummaryBar(),
              const SizedBox(height: 12),
              _buildPrimaryPersonTile(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
