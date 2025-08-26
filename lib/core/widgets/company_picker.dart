import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../services/company_service.dart';
import '../../features/companies/view/add_edit_company_page.dart';

class Company {
  final String id;
  final String name;
  final String customId;
  final List<Map<String, dynamic>> emails;
  final List<Map<String, dynamic>> phones;
  final String taxId;
  final String branch;
  final String addressLine1;
  final String subdistrict;
  final String district;
  final String province;
  final String postalCode;
  final String country;
  final List<Map<String, dynamic>> hashtags;
  final String website;
  final String workspaceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final List<String> associatedCustomerIds;

  Company({
    required this.id,
    required this.name,
    required this.customId,
    required this.emails,
    required this.phones,
    required this.taxId,
    required this.branch,
    required this.addressLine1,
    required this.subdistrict,
    required this.district,
    required this.province,
    required this.postalCode,
    required this.country,
    required this.hashtags,
    required this.website,
    required this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
    required this.associatedCustomerIds,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      customId: map['customId'] ?? '',
      emails: List<Map<String, dynamic>>.from(map['emails'] ?? []),
      phones: List<Map<String, dynamic>>.from(map['phones'] ?? []),
      taxId: map['taxId'] ?? '',
      branch: map['branch'] ?? '',
      addressLine1: map['addressLine1'] ?? '',
      subdistrict: map['subdistrict'] ?? '',
      district: map['district'] ?? '',
      province: map['province'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      hashtags: List<Map<String, dynamic>>.from(map['hashtags'] ?? []),
      website: map['website'] ?? '',
      workspaceId: map['workspaceId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
      associatedCustomerIds: List<String>.from(map['associatedCustomerIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'customId': customId,
      'emails': emails,
      'phones': phones,
      'taxId': taxId,
      'branch': branch,
      'addressLine1': addressLine1,
      'subdistrict': subdistrict,
      'district': district,
      'province': province,
      'postalCode': postalCode,
      'country': country,
      'hashtags': hashtags,
      'website': website,
      'workspaceId': workspaceId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'associatedCustomerIds': associatedCustomerIds,
    };
  }
}

class CompanyPicker extends StatefulWidget {
  final List<Company>? selectedCompanies;
  final Function(List<Company>) onCompaniesChanged;
  final String? label;
  final bool isRequired;
  final bool allowMultiple;
  final String? hintText;

  const CompanyPicker({
    super.key,
    this.selectedCompanies,
    required this.onCompaniesChanged,
    this.label = 'บริษัท',
    this.isRequired = false,
    this.allowMultiple = true,
    this.hintText,
  });

  @override
  State<CompanyPicker> createState() => _CompanyPickerState();
}

class _CompanyPickerState extends State<CompanyPicker> {
  final TextEditingController _searchController = TextEditingController();
  final CompanyService _companyService = CompanyService();
  
  List<Company> _availableCompanies = [];
  List<Company> _filteredCompanies = [];
  List<Company> _selectedCompanies = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _selectedCompanies = widget.selectedCompanies ?? [];
    _loadCompanies();
  }

  @override
  void didUpdateWidget(CompanyPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCompanies != widget.selectedCompanies) {
      setState(() {
        _selectedCompanies = widget.selectedCompanies ?? [];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanies() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get workspace ID from current context
      final workspaceId = 'GkEJ3c6u9QU4utYO6KVZ'; // TODO: Get from context
      final companies = await _companyService.getCompanies(workspaceId);
      
      setState(() {
        _availableCompanies = companies;
        _filteredCompanies = companies;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading companies: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final searchQuery = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = searchQuery.isNotEmpty;
      if (searchQuery.isEmpty) {
        _filteredCompanies = _availableCompanies;
      } else {
        _filteredCompanies = _availableCompanies.where((company) {
          return company.name.toLowerCase().contains(searchQuery) ||
                 company.customId.toLowerCase().contains(searchQuery) ||
                 company.taxId.toLowerCase().contains(searchQuery);
        }).toList();
      }
    });
  }

  void _toggleCompany(Company company) {
    setState(() {
      if (_selectedCompanies.any((c) => c.id == company.id)) {
        _selectedCompanies.removeWhere((c) => c.id == company.id);
      } else {
        if (!widget.allowMultiple) {
          _selectedCompanies.clear();
        }
        _selectedCompanies.add(company);
      }
    });
    widget.onCompaniesChanged(_selectedCompanies);
  }

  void _showCompanyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCompanyPickerModal(),
    );
  }

  void _showAddCompanyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มบริษัทใหม่'),
        content: const Text('คุณต้องการเพิ่มบริษัทใหม่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAddCompany();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddCompany() {
    // Navigate to add company page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditCompanyPage(),
      ),
    ).then((result) {
      // Refresh companies list if a new company was added
      if (result == true) {
        _loadCompanies();
      }
    });
  }

  Widget _buildCompanyPickerModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Text(
                  'เลือกบริษัท',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'เสร็จสิ้น',
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
                     // Search bar and Add button
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16),
             child: Row(
               children: [
                 Expanded(
                   child: TextField(
                     controller: _searchController,
                     decoration: InputDecoration(
                       hintText: 'ค้นหาบริษัท...',
                       prefixIcon: const Icon(Icons.search),
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                     ),
                   ),
                 ),
                 const SizedBox(width: 12),
                 ElevatedButton.icon(
                   onPressed: _showAddCompanyDialog,
                   icon: const Icon(Icons.add, size: 16),
                   label: const Text('เพิ่มบริษัท'),
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppTheme.primaryOrange,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(8),
                     ),
                   ),
                 ),
               ],
             ),
           ),
          
          const SizedBox(height: 16),
          
          // Selected companies
          if (_selectedCompanies.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'บริษัทที่เลือก',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCompanies.map((company) {
                      return _buildCompanyChip(company, true);
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
          ],
          
          // Available companies
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _filteredCompanies.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredCompanies.length,
                        itemBuilder: (context, index) {
                          final company = _filteredCompanies[index];
                          final isSelected = _selectedCompanies.any((c) => c.id == company.id);
                          
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                              child: Text(
                                company.name.isNotEmpty ? company.name[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              company.name,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'รหัส: ${company.customId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (company.taxId.isNotEmpty)
                                  Text(
                                    'เลขประจำตัวผู้เสียภาษี: ${company.taxId}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleCompany(company),
                              activeColor: AppTheme.primaryOrange,
                            ),
                            onTap: () => _toggleCompany(company),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppTheme.primaryOrange,
          ),
          SizedBox(height: 16),
          Text(
            'กำลังโหลดบริษัท...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _availableCompanies.isEmpty 
                ? 'ไม่มีบริษัทในระบบ'
                : 'ไม่พบบริษัทที่ตรงกับคำค้นหา',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _availableCompanies.isEmpty 
                ? 'กรุณาติดต่อผู้ดูแลระบบเพื่อเพิ่มบริษัท'
                : 'ลองค้นหาด้วยคำอื่น',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyChip(Company company, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryOrange : AppTheme.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryOrange,
          width: isSelected ? 0 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            company.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.primaryOrange,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _toggleCompany(company),
              child: Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (widget.isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          
          // Selected companies display
          if (_selectedCompanies.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedCompanies.map((company) {
                return _buildCompanyChip(company, true);
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          
          // Select button
          InkWell(
            onTap: _showCompanyPicker,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCompanies.isEmpty 
                        ? (widget.hintText ?? 'เลือกบริษัท') 
                        : 'แก้ไขบริษัท',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
