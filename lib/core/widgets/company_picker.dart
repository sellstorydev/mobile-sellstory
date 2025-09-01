import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/company_service.dart';
import '../../features/companies/view/add_edit_company_page.dart';
import '../../data/repositories/firestore_repository.dart';

class Company {
  final String id;
  final List<Map<String, dynamic>> companyNames;
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
    required this.companyNames,
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
    // Handle both old 'name' field and new 'companyNames' array structure
    List<Map<String, dynamic>> companyNames = [];
    
    if (map['companyNames'] != null) {
      // New structure: companyNames array
      companyNames = List<Map<String, dynamic>>.from(map['companyNames'] ?? []);
    } else if (map['name'] != null) {
      // Old structure: single name field - convert to new structure
      companyNames = [
        {
          'id': map['id'] ?? '',
          'label': 'Main',
          'value': map['name'] as String,
        }
      ];
    }
    
    return Company(
      id: map['id'] ?? '',
      companyNames: companyNames,
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
      'companyNames': companyNames,
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

  // Helper method to get the main company name for display
  String get displayName {
    if (companyNames.isNotEmpty) {
      return companyNames.first['value'] as String? ?? 'Unknown Company';
    }
    return 'Unknown Company';
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
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  
  List<Company> _availableCompanies = [];
  List<Company> _filteredCompanies = [];
  List<Company> _selectedCompanies = [];
  bool _isLoading = true;
  bool _isSearching = false;
  
  // User and workspace related
  String _currentUserId = '';
  String _currentWorkspaceId = '';
  
  // Modal state management
  StateSetter? _currentModalStateSetter;

  @override
  void initState() {
    super.initState();
    _selectedCompanies = List<Company>.from(widget.selectedCompanies ?? []);
    _initializeUserAndWorkspace();
  }

  @override
  void didUpdateWidget(CompanyPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCompanies != widget.selectedCompanies) {
      setState(() {
        _selectedCompanies = List<Company>.from(widget.selectedCompanies ?? []);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No authenticated user found');
        return;
      }
      
      _currentUserId = currentUser.uid;
      print('👤 Initializing company picker with user: $_currentUserId');
      
      // Get user's workspaces
      print('📋 Fetching user workspaces...');
      final workspaces = await _repository.getUserWorkspaces(_currentUserId);
      
      print('📋 User workspaces loaded: ${workspaces.length} workspaces');
      
      if (workspaces.isNotEmpty) {
        // Try to get last active workspace ID
        String? selectedWorkspaceId;
        String? selectedWorkspaceName;
        
        try {
          final lastActiveWorkspaceId = await _repository.getUserLastActiveWorkspaceId(_currentUserId);
          print('📋 Last active workspace ID: $lastActiveWorkspaceId');
          
          if (lastActiveWorkspaceId != null && lastActiveWorkspaceId.isNotEmpty) {
            // Check if the last active workspace still exists in user's workspaces
            final lastActiveWorkspace = workspaces.firstWhereOrNull(
              (ws) => ws['id'] == lastActiveWorkspaceId
            );
            
            if (lastActiveWorkspace != null) {
              selectedWorkspaceId = lastActiveWorkspaceId;
              selectedWorkspaceName = lastActiveWorkspace['name'] as String;
              print('✅ Using last active workspace: $selectedWorkspaceName ($selectedWorkspaceId)');
            } else {
              print('⚠️ Last active workspace not found in user workspaces, using first workspace');
            }
          }
        } catch (e) {
          print('⚠️ Failed to get last active workspace: $e');
        }
        
        // Fallback to first workspace if no last active workspace
        if (selectedWorkspaceId == null) {
          final firstWorkspace = workspaces.first;
          selectedWorkspaceId = firstWorkspace['id'] as String;
          selectedWorkspaceName = firstWorkspace['name'] as String;
          print('✅ Using first workspace: $selectedWorkspaceName ($selectedWorkspaceId)');
        }
        
        _currentWorkspaceId = selectedWorkspaceId;
        
        print('✅ Company picker initialized with workspace: $selectedWorkspaceName');
        
        // Load companies for the selected workspace
        await _loadCompanies();
      } else {
        print('⚠️ No workspaces found for user: $_currentUserId');
      }
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
    }
  }

  Future<void> _loadCompanies() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (_currentWorkspaceId.isEmpty) {
        print('⚠️ CompanyPicker: No workspace ID available for companies');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final companies = await _companyService.getCompanies(_currentWorkspaceId);
      
      setState(() {
        _availableCompanies = companies;
        _filteredCompanies = companies;
        _isLoading = false;
      });
      
      print('📋 Companies loaded: ${companies.length} companies');
      
      // Force rebuild of any open modal
      if (mounted) {
        setState(() {});
        _currentModalStateSetter?.call(() {});
      }
    } catch (e) {
      print('Error loading companies: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    final searchQuery = value.toLowerCase().trim();
    setState(() {
      _isSearching = searchQuery.isNotEmpty;
      if (searchQuery.isEmpty) {
        _filteredCompanies = List<Company>.from(_availableCompanies);
      } else {
        _filteredCompanies = _availableCompanies.where((company) {
          return company.displayName.toLowerCase().contains(searchQuery) ||
                 company.customId.toLowerCase().contains(searchQuery) ||
                 company.taxId.toLowerCase().contains(searchQuery);
        }).toList();
      }
    });
    // Search query processed: "$searchQuery", Found: ${_filteredCompanies.length} companies
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
    // Notify parent immediately when selection changes
    widget.onCompaniesChanged(List<Company>.from(_selectedCompanies));
  }

  void _showCompanyPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          _currentModalStateSetter = setModalState;
          return _buildCompanyPickerModal(setModalState);
        },
      ),
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
    ).then((result) async {
      // Refresh companies list if a new company was added
      if (result == true) {
        await _loadCompanies();
        // Clear search when returning from add company
        _searchController.clear();
        _onSearchChanged(''); // Reset search filter
        // Force rebuild of the modal if it's open
        if (mounted) {
          setState(() {});
          _currentModalStateSetter?.call(() {});
        }
      }
    });
  }

  Widget _buildCompanyPickerModal([StateSetter? setModalState]) {
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
                  onPressed: () {
                    // Ensure the callback is called with the current selection
                    widget.onCompaniesChanged(List<Company>.from(_selectedCompanies));
                    _currentModalStateSetter = null; // Clean up
                    Navigator.pop(context);
                  },
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
                                        suffixIcon: _searchController.text.isNotEmpty
                     ? IconButton(
                         icon: const Icon(Icons.clear),
                         onPressed: () {
                           _searchController.clear();
                           _onSearchChanged('');
                           setModalState?.call(() {});
                         },
                       )
                     : null,
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(12),
                       ),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                     ),
                     onChanged: (value) {
                       // Trigger search on each character change
                       _onSearchChanged(value);
                       // Force modal to rebuild with search results
                       setModalState?.call(() {});
                     },
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedCompanies.map((company) {
                      return _buildCompanyChip(company, true, setModalState);
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
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Debug info (remove in production)
                          if (_isSearching)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                'Found ${_filteredCompanies.length} companies',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          Expanded(
                            child: ListView.builder(
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
                                company.displayName.isNotEmpty ? company.displayName[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              company.displayName,
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
                            onTap: () {
                              _toggleCompany(company);
                              // Force rebuild to show selection state immediately
                              setState(() {});
                              setModalState?.call(() {});
                            },
                          );
                        },
                      ),
                            ),
                          ],
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

  Widget _buildCompanyChip(Company company, bool isSelected, [StateSetter? setModalState]) {
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
            company.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppTheme.primaryOrange,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                _toggleCompany(company);
                // Force modal to rebuild after removing company
                setState(() {});
                setModalState?.call(() {});
              },
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
                    _selectedCompanies.isEmpty ? Icons.add : Icons.edit,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCompanies.isEmpty 
                        ? (widget.hintText ?? 'เลือกบริษัท') 
                        : 'แก้ไขบริษัท (${_selectedCompanies.length})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Selected companies display
          if (_selectedCompanies.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
                          children: _selectedCompanies.map((company) {
              return _buildCompanyChip(company, true, null);
            }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
