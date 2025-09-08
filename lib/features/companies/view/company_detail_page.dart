import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/customer.dart';
import '../controller/companies_controller.dart';
import '../../customers/controller/customers_controller.dart';
import 'add_edit_company_page.dart';
import '../../../core/widgets/permission_guard.dart';
import '../../customers/view/customer_detail_page.dart';

class CompanyDetailPage extends StatefulWidget {
  final Company company;

  const CompanyDetailPage({
    super.key,
    required this.company,
  });

  @override
  State<CompanyDetailPage> createState() => _CompanyDetailPageState();
}

class _CompanyDetailPageState extends State<CompanyDetailPage> {
  final CompaniesController _companiesController = Get.find<CompaniesController>();
  CustomersController? _customersController; // made nullable

  Company? _currentCompany;
  List<Customer> _associatedCustomers = [];
  bool _isLoadingCustomers = false;

  @override
  void initState() {
    super.initState();
    _currentCompany = widget.company;

    // Try to get an existing CustomersController (don't instantiate here)
    if (Get.isRegistered<CustomersController>()) {
      _customersController = Get.find<CustomersController>();
    }

    _loadAssociatedCustomers();
  }

  Future<void> _loadAssociatedCustomers() async {
    if (_currentCompany == null || _currentCompany!.associatedCustomerIds.isEmpty) {
      setState(() {
        _associatedCustomers = [];
        _isLoadingCustomers = false;
      });
      return;
    }

    // No customers controller available, skip gracefully
    if (_customersController == null) {
      setState(() {
        _associatedCustomers = [];
        _isLoadingCustomers = false;
      });
      return;
    }

    setState(() {
      _isLoadingCustomers = true;
    });

    try {
      final workspaceId = _currentCompany!.workspaceId;
      if (_customersController!.customers.isEmpty) {
        await _customersController!.loadCustomers(workspaceId);
      }

      final associatedCustomers = _customersController!.customers
          .where((c) => _currentCompany!.associatedCustomerIds.contains(c.id))
          .toList();

      setState(() {
        _associatedCustomers = associatedCustomers;
      });
    } catch (_) {
      setState(() {
        _associatedCustomers = [];
      });
    } finally {
      setState(() {
        _isLoadingCustomers = false;
      });
    }
  }

  Future<void> _launchPhone() async {
    try {
      final company = _currentCompany ?? widget.company;
      final first = company.phones.firstWhere(
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
      final company = _currentCompany ?? widget.company;
      final first = company.emails.firstWhere(
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

  Future<void> _launchWebsite() async {
    try {
      final company = _currentCompany ?? widget.company;
      final website = company.website.trim();
      if (website.isEmpty) return;

      String url = website;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final company = _currentCompany ?? widget.company;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          company.name.isNotEmpty ? company.name : 'รายละเอียดบริษัท',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'แก้ไข',
            icon: const Icon(Icons.edit, color: AppTheme.primaryOrange),
            onPressed: () async {
              guardAction(context, 'company:edit:all', () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditCompanyPage(company: company),
                  ),
                );

                if (result == true) {
                  // Try to refresh local view with updated company
                  final updated = _companiesController.getCompanyById(company.id);
                  if (updated != null && mounted) {
                    setState(() {
                      _currentCompany = updated;
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
              const SizedBox(height: 5),
              _buildCompanyDetailsTile(),
              const SizedBox(height: 0),
              _buildAssociatedCustomersTile(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSummary() {
    final company = _currentCompany ?? widget.company;

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
              Icons.business,
              color: AppTheme.primaryOrange,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            company.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF1F2937),
              letterSpacing: 0.2,
            ),
          ),
          if (company.branch.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(25),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'สาขา ${company.branch}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopInfoSection() {
    final company = _currentCompany ?? widget.company;

    final List<Widget> rows = [];

    if (company.customId.isNotEmpty) {
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.badge, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'รหัสบริษัท: ${company.customId}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ));
    }

    if (company.taxId.isNotEmpty) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 4));
      rows.add(Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'เลขประจำตัวผู้เสียภาษี: ${company.taxId}',
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

    final company = _currentCompany ?? widget.company;
    final hasWebsite = company.website.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          circleIcon(Icons.phone, _launchPhone),
          const SizedBox(width: 20),
          circleIcon(Icons.email, _launchEmail),
          if (hasWebsite) ...[
            const SizedBox(width: 20),
            circleIcon(Icons.language, _launchWebsite),
          ],
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

    final company = _currentCompany ?? widget.company;

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
          cell('ลูกค้าที่เชื่อมโยง', '${company.associatedCustomerIds.length} คน'),
          Container(
            width: 0.5,
            height: 60,
            color: const Color(0xFFE5E7EB),
          ),
          cell('งานทั้งหมด', '0 งาน'),
          Container(
            width: 0.5,
            height: 60,
            color: const Color(0xFFE5E7EB),
          ),
          cell('ยอดขายรวม', '฿0.00', valueColor: const Color(0xFF10B981)),
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

  Widget _buildCompanyDetailsTile() {
    final company = _currentCompany ?? widget.company;

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
              Icons.business,
              color: AppTheme.primaryOrange,
              size: 18,
            ),
          ),

          title: const Text(
            'ข้อมูลบริษัท',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1F2937),
              letterSpacing: 0.2,
            ),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade500,
            size: 20,
          ),
          children: [
            _buildCompanyDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyDetails() {
    final company = _currentCompany ?? widget.company;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info
          _buildDetailRow('ชื่อบริษัท', company.name),
          if (company.branch.isNotEmpty)
            _buildDetailRow('สาขา', company.branch),
          if (company.taxId.isNotEmpty)
            _buildDetailRow('เลขประจำตัวผู้เสียภาษี', company.taxId),
          if (company.website.isNotEmpty)
            _buildDetailRow('เว็บไซต์', company.website),

          // Address
          if (company.fullAddress.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow('ที่อยู่', company.fullAddress),
          ],

          // Emails
          if (company.emails.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildContactSection('อีเมล', company.emails),
          ],

          // Phones
          if (company.phones.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildContactSection('เบอร์โทร', company.phones),
          ],
        ],
      ),
    );
  }

  Widget _buildAssociatedCustomersTile() {
    final company = _currentCompany ?? widget.company;

    return _tileWrapper(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people,
              color: Colors.blue,
              size: 18,
            ),
          ),
          title: Text(
            'ลูกค้าที่เชื่อมโยง (${company.associatedCustomerIds.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Color(0xFF1F2937),
              letterSpacing: 0.2,
            ),
          ),
          trailing: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade500,
            size: 20,
          ),
          children: [
            _buildAssociatedCustomersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssociatedCustomersList() {
    if (_isLoadingCustomers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppTheme.primaryOrange),
        ),
      );
    }

    if (_associatedCustomers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'ไม่มีลูกค้าที่เชื่อมโยง',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _associatedCustomers.map((customer) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomerDetailPage(customer: customer),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppTheme.primaryOrange,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          if (customer.customId.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'รหัส: ${customer.customId}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
}
