import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // added for Timestamp support
import '../theme/app_theme.dart';
import '../services/company_service.dart';
import '../services/algolia_search_service.dart';
import '../../features/companies/view/add_edit_company_page.dart';
import '../../data/repositories/firestore_repository.dart';
import 'dart:async';

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
      companyNames = List<Map<String, dynamic>>.from(map['companyNames'] ?? []);
    } else if (map['name'] != null) {
      companyNames = [
        {
          'id': map['id'] ?? '',
          'label': 'Main',
            // Use name as value
          'value': map['name'] as String,
        }
      ];
    }

    DateTime _parseDate(dynamic raw) {
      if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (raw is DateTime) return raw;
      if (raw is Timestamp) return raw.toDate();
      if (raw is int) {
        // Heuristic: treat as ms if it's large, else seconds
        if (raw > 2000000000) { // already ms
          return DateTime.fromMillisecondsSinceEpoch(raw);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
        }
      }
      if (raw is String) {
        try { return DateTime.parse(raw); } catch (_) {}
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final createdAt = _parseDate(map['createdAt']);
    final updatedAt = _parseDate(map['updatedAt']);

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
      createdAt: createdAt,
      updatedAt: updatedAt,
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
  final List<String>? selectedCompanyIds; // new: IDs to fetch
  final Function(List<Company>) onCompaniesChanged;
  final String? label;
  final bool isRequired;
  final bool allowMultiple;
  final String? hintText;
  final String? workspaceId; // new override
  final bool lockWorkspaceId; // new: if true, ignore subsequent workspaceId changes
  final bool showAllWorkspaces; // new: load companies from all user workspaces


  const CompanyPicker({
    super.key,
    this.selectedCompanies,
    this.selectedCompanyIds,
    required this.onCompaniesChanged,
    this.label = 'บริษัท',
    this.isRequired = false,
    this.allowMultiple = true,
    this.hintText,
    this.workspaceId,
    this.lockWorkspaceId = false,
    this.showAllWorkspaces = false,
  });

  @override
  State<CompanyPicker> createState() => CompanyPickerState();
}

class CompanyPickerState extends State<CompanyPicker> { // renamed from _CompanyPickerState
  final TextEditingController _searchController = TextEditingController();
  final CompanyService _companyService = CompanyService();
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  
  List<Company> _availableCompanies = [];
  List<Company> _filteredCompanies = [];
  List<Company> _selectedCompanies = [];
  bool _isLoading = true;
  bool _isSearching = false;
  
  // Algolia search related
  Timer? _searchDebounceTimer;
  StreamSubscription? _algoliaSearchSubscription;

  // User and workspace related
  String _currentUserId = '';
  String _currentWorkspaceId = '';
  
  // Modal state management
  StateSetter? _currentModalStateSetter;

  // Pending selected company IDs (to be resolved after companies load)
  List<String> _pendingSelectedCompanyIds = [];
  bool _companiesLoaded = false;

  // Realtime subscription
  StreamSubscription<List<Company>>? _companiesSub;
  final Map<String, StreamSubscription<List<Company>>> _workspaceSubs = {}; // multi-workspace subs
  final Map<String, String> _workspaceNames = {}; // id -> name
  bool _usingAllWorkspaces = false;

  @override
  void initState() {
    super.initState();
    // Prefer full objects if provided; else store IDs for later resolution
    if (widget.selectedCompanies != null && widget.selectedCompanies!.isNotEmpty) {
      _selectedCompanies = List<Company>.from(widget.selectedCompanies!);
    } else if (widget.selectedCompanyIds != null && widget.selectedCompanyIds!.isNotEmpty) {
      _pendingSelectedCompanyIds = List<String>.from(widget.selectedCompanyIds!);
    }
    if (widget.showAllWorkspaces) {
      _usingAllWorkspaces = true;
      _initializeAllWorkspaces();
    } else if (widget.workspaceId != null && widget.workspaceId!.isNotEmpty) {
      _currentWorkspaceId = widget.workspaceId!;
      _loadCompanies();
    } else {
      _initializeUserAndWorkspace();
    }
  }

  void _scheduleSelectionUpdate(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      fn();
    });
  }


  @override
  void didUpdateWidget(CompanyPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showAllWorkspaces && !_usingAllWorkspaces) {
      _usingAllWorkspaces = true;
      _switchToAllWorkspaces();
    }
    if (!widget.showAllWorkspaces && _usingAllWorkspaces && widget.workspaceId != null && widget.workspaceId!.isNotEmpty) {
      // switch back to single workspace mode
      _usingAllWorkspaces = false;
      for (final sub in _workspaceSubs.values) { sub.cancel(); }
      _workspaceSubs.clear();
      _currentWorkspaceId = widget.workspaceId!;
      _availableCompanies.clear();
      _filteredCompanies.clear();
      _loadCompanies();
    }
    // Workspace override changed (only if not locked and not in all mode)
    if (!widget.showAllWorkspaces && !widget.lockWorkspaceId && oldWidget.workspaceId != widget.workspaceId && widget.workspaceId != null && widget.workspaceId!.isNotEmpty) {
      _currentWorkspaceId = widget.workspaceId!;
      _loadCompanies();
    }
    // If explicit Company objects change
    if (oldWidget.selectedCompanies != widget.selectedCompanies && widget.selectedCompanies != null) {
      final newList = List<Company>.from(widget.selectedCompanies!);
      _scheduleSelectionUpdate(() {
        _selectedCompanies = newList;
        widget.onCompaniesChanged(List<Company>.from(_selectedCompanies));
        setState(() {});
      });
    }
    // If list of IDs changed (and no direct Company list supplied)
    if (widget.selectedCompanies == null && oldWidget.selectedCompanyIds != widget.selectedCompanyIds) {
      _pendingSelectedCompanyIds = List<String>.from(widget.selectedCompanyIds ?? []);
      _scheduleSelectionUpdate(_resolvePendingSelectedIds);
    }
  }

  void _resolvePendingSelectedIds() {
    if (!_companiesLoaded) return; // wait until companies loaded
    if (_pendingSelectedCompanyIds.isEmpty) return;
    final idSet = _pendingSelectedCompanyIds.toSet();
    final resolved = _availableCompanies.where((c) => idSet.contains(c.id)).toList();
    // Only update if changed
    final currentIds = _selectedCompanies.map((c) => c.id).toSet();
    final resolvedIds = resolved.map((c) => c.id).toSet();
    if (currentIds.length != resolvedIds.length || !currentIds.containsAll(resolvedIds)) {
      _selectedCompanies = resolved;
      widget.onCompaniesChanged(List<Company>.from(_selectedCompanies));
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final sub in _workspaceSubs.values) {
      sub.cancel();
    }
    _companiesSub?.cancel();
    _searchDebounceTimer?.cancel();
    _algoliaSearchSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Apply current search filter to available companies
  List<Company> _applySearchFilter(String query) {
    final searchQuery = query.toLowerCase().trim();
    if (searchQuery.isEmpty) return List<Company>.from(_availableCompanies);
    return _availableCompanies.where((company) {
      return company.displayName.toLowerCase().contains(searchQuery) ||
          company.customId.toLowerCase().contains(searchQuery) ||
          company.taxId.toLowerCase().contains(searchQuery);
    }).toList();
  }

  Future<void> _loadCompanies() async { // now becomes realtime subscribe
    try {
      setState(() { _isLoading = true; });

      if (_currentWorkspaceId.isEmpty) {
        setState(() { _isLoading = false; });
        return;
      }

      // Cancel previous subscription if any
      await _companiesSub?.cancel();
      _companiesSub = _companyService.companiesStream(_currentWorkspaceId).listen((companies) {
        if (!mounted) return;
        setState(() {
          _availableCompanies = companies;
          // Only update filtered companies if there's no active search
          if (_searchController.text.trim().isEmpty) {
            _filteredCompanies = List<Company>.from(_availableCompanies);
          }
          _isLoading = false;
          _companiesLoaded = true;
        });
        _resolvePendingSelectedIds();
      }, onError: (e) {
        print('❌ Realtime companies stream error: $e');
        if (!mounted) return;
        setState(() { _isLoading = false; });
      });
    } catch (e) {
      print('❌ Error subscribing companies for workspace $_currentWorkspaceId: $e');
      setState(() { _isLoading = false; });
    }
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer if exists
    _searchDebounceTimer?.cancel();
    _algoliaSearchSubscription?.cancel();

    setState(() {
      _isSearching = value.trim().isNotEmpty;
    });

    // Force modal to update search state
    _currentModalStateSetter?.call(() {});

    // If query is empty, reset to show all companies (local list)
    if (value.trim().isEmpty) {
      setState(() {
        _filteredCompanies = List<Company>.from(_availableCompanies);
      });
      // Update modal with all companies
      _currentModalStateSetter?.call(() {});
      return;
    }

    // For non-empty queries, trigger Algolia search with debouncing
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        triggerAlgoliaSearch(value.trim());
      }
    });
  }

  /// Trigger Algolia search manually (called by search button)
  void triggerAlgoliaSearch(String query) {
    if (query.trim().isEmpty) {
      // If query is empty, reset to show all companies
      setState(() {
        _isSearching = false;
        _filteredCompanies = List<Company>.from(_availableCompanies);
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Force modal to show loading state
    _currentModalStateSetter?.call(() {});

    _searchWithAlgolia(query.trim());
  }

  /// Search companies using Algolia exclusively
  void _searchWithAlgolia(String query) async {
    if (_currentWorkspaceId.isEmpty) {
      // If no workspace, show empty results for search
      setState(() {
        _isSearching = false;
        _filteredCompanies = [];
      });

      // Force modal to update with empty state
      _currentModalStateSetter?.call(() {});
      return;
    }

    try {
      // Search with Algolia
      final searchStream = AlgoliaSearchService.searchCompanies(
        query: query,
        workspaceId: _currentWorkspaceId,
        hitsPerPage: 50,
      );

      _algoliaSearchSubscription = searchStream.listen(
        (response) {
          if (!mounted) return;

          try {
            final hits = response.hits;
            final algoliaResults = <Company>[];

            // Convert Algolia results to Company objects
            for (final hit in hits) {
              try {
                // Find the company in our local list by ID
                final companyId = hit['objectID'] as String?;
                if (companyId != null) {
                  final company = _availableCompanies.firstWhere(
                    (c) => c.id == companyId,
                    orElse: () {
                      // If not found in local list, create from Algolia data
                      final data = Map<String, dynamic>.from(hit);
                      data['id'] = companyId;
                      // Handle missing fields with defaults
                      data['companyNames'] = data['companyNames'] ?? [
                        {
                          'id': companyId,
                          'label': 'Main',
                          'value': data['name'] ?? 'Unknown Company',
                        }
                      ];
                      data['emails'] = data['emails'] ?? [];
                      data['phones'] = data['phones'] ?? [];
                      data['hashtags'] = data['hashtags'] ?? [];
                      data['associatedCustomerIds'] = data['customers'] ?? [];
                      data['createdAt'] = data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch;
                      data['updatedAt'] = data['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch;
                      data['createdBy'] = data['createdBy'] ?? '';
                      data['updatedBy'] = data['updatedBy'] ?? '';
                      return Company.fromMap(data);
                    },
                  );
                  algoliaResults.add(company);
                }
              } catch (e) {
                print('⚠️ Failed to convert Algolia hit to Company: $e');
              }
            }

            setState(() {
              _filteredCompanies = algoliaResults;
              _isSearching = false;
            });

            // Force modal to rebuild with new search results
            _currentModalStateSetter?.call(() {});

            print('🔍 Algolia company search results: ${algoliaResults.length} companies found');

          } catch (e) {
            print('⚠️ Error processing Algolia response: $e');
            // For Algolia-only search, show empty results on error
            setState(() {
              _filteredCompanies = [];
              _isSearching = false;
            });

            // Force modal to rebuild with empty state
            _currentModalStateSetter?.call(() {});
          }
        },
        onError: (error) {
          print('❌ Algolia company search error: $error');
          // For Algolia-only search, show empty results on error
          setState(() {
            _filteredCompanies = [];
            _isSearching = false;
          });

          // Force modal to rebuild with error state
          _currentModalStateSetter?.call(() {});
        },
      );

    } catch (e) {
      print('❌ Failed to search companies with Algolia: $e');
      // For Algolia-only search, show empty results on error
      setState(() {
        _filteredCompanies = [];
        _isSearching = false;
      });

      // Force modal to rebuild with error state
      _currentModalStateSetter?.call(() {});
    }
  }

  /// Clear search and reset to show all companies
  void clearSearch() {
    _searchController.clear();
    _algoliaSearchSubscription?.cancel();
    _searchDebounceTimer?.cancel();
    setState(() {
      _isSearching = false;
      _filteredCompanies = List<Company>.from(_availableCompanies);
    });

    // Force modal to update with all companies
    _currentModalStateSetter?.call(() {});
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
                       suffixIcon: _buildSearchAndClearSuffixIcons(setModalState),
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

                              onChanged: (_) {
                                _toggleCompany(company);
                                setState(() {});
                                setModalState?.call(() {});
                              },
                              activeColor: AppTheme.primaryOrange,
                            ),
                            onTap: () {
                              _toggleCompany(company);
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
            // Priority: Search query exists -> show search-specific message
            hasSearchQuery
                ? 'ไม่พบบริษัทที่ตรงกับคำค้นหา'
                : !hasLocalCompanies
                  ? 'ไม่มีบริษัทในระบบ'
                  : 'ไม่มีบริษัทในระบบ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            // Priority: Search query exists -> show search-specific advice
            hasSearchQuery
                ? 'ลองใช้คำค้นหาอื่น หรือตรวจสอบการสะกดคำ'
                : !hasLocalCompanies
                  ? 'กรุณาติดต่อผู้ดูแลระบบเพื่อเพิ่มบริษัท'
                  : 'พิมพ์เพื่อค้นหาบริษัทด้วย Algolia',
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

  Widget _buildSearchAndClearSuffixIcons([StateSetter? setModalState]) {
    final hasSearchText = _searchController.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search button
          IconButton(
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                triggerAlgoliaSearch(query);
                setModalState?.call(() {});
              }
            },
            icon: _isSearching
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : Icon(
                    Icons.search,
                    color: hasSearchText
                        ? AppTheme.primaryOrange
                        : Colors.grey,
                  ),
          ),
          // Clear button
          if (hasSearchText)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                clearSearch();
                setModalState?.call(() {});
              },
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


  // Public: refresh companies list
  Future<void> refresh() async {
    if (_currentWorkspaceId.isEmpty) {
      await _initializeUserAndWorkspace();
    } else {
      await _loadCompanies();
    }
  }

  // Public: open picker modal
  void open() {
    _showCompanyPicker();
  }

  // Public helper to set selected company IDs dynamically
  void setSelectedCompanyIds(List<String> ids) {
    _pendingSelectedCompanyIds = List<String>.from(ids);
    _resolvePendingSelectedIds();
  }

  // Public getters to allow parent widgets to inspect loaded companies
  List<Company> get availableCompanies => List<Company>.unmodifiable(_availableCompanies);
  Set<String> get availableCompanyIds => _availableCompanies.map((c) => c.id).where((id) => id.isNotEmpty).toSet();

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
            }).toList(),),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() { _isLoading = false; });
        return;
      }
      _currentUserId = currentUser.uid;

      final workspaces = await _repository.getUserWorkspaces(_currentUserId);
      if (workspaces.isEmpty) {
        setState(() { _isLoading = false; });
        return;
      }

      String? chosenId;
      try {
        final lastActive = await _repository.getUserLastActiveWorkspaceId(_currentUserId);
        if (lastActive != null && lastActive.isNotEmpty && workspaces.any((w) => w['id'] == lastActive)) {
          chosenId = lastActive;
        }
      } catch (e) {
        // Ignore error, will use first workspace
      }
      chosenId ??= workspaces.first['id'] as String? ?? '';
      _currentWorkspaceId = chosenId;
      await _loadCompanies();
    } catch (e) {
      print('❌ _initializeUserAndWorkspace error: $e');
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _mergeAllWorkspaceCompanies(Map<String, List<Company>> all) {
    final merged = <Company>[];
    for (final entry in all.entries) {
      merged.addAll(entry.value);
    }
    _availableCompanies = merged;
    _filteredCompanies = _applySearchFilter(_searchController.text);
  }

  Future<void> _initializeAllWorkspaces() async {
    try {
      setState(() { _isLoading = true; });
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() { _isLoading = false; });
        return;
      }
      _currentUserId = currentUser.uid;
      final workspaces = await _repository.getUserWorkspaces(_currentUserId);
      if (workspaces.isEmpty) {
        setState(() { _isLoading = false; });
        return;
      }
      for (final ws in workspaces) {
        final id = ws['id'] as String? ?? '';
        final name = ws['name'] as String? ?? id;
        if (id.isEmpty) continue;
        _workspaceNames[id] = name;
        _subscribeWorkspace(id);
      }
    } catch (e) {
      print('❌ _initializeAllWorkspaces error: $e');
      setState(() { _isLoading = false; });
    }
  }

  void _switchToAllWorkspaces() {
    for (final sub in _workspaceSubs.values) { sub.cancel(); }
    _workspaceSubs.clear();
    _availableCompanies.clear();
    _filteredCompanies.clear();
    _initializeAllWorkspaces();
  }

  void _subscribeWorkspace(String workspaceId) async {
    final sub = _companyService.companiesStream(workspaceId).listen((companies) {
      if (!mounted) return;
      // tag each company with its workspaceId (already present)
      final grouped = <String, List<Company>>{};
      // Rebuild grouped from existing subscriptions
      for (final entry in _workspaceSubs.entries) {
        if (entry.key == workspaceId) continue; // skip current; will add after
      }
      // We don't keep per-workspace cache yet; simple approach: refetch all via subs snapshots stored
      // Simpler: maintain a map id->list in state
      _workspaceCompanyCache[workspaceId] = companies;
      grouped.addAll(_workspaceCompanyCache);
      setState(() {
        _mergeAllWorkspaceCompanies(grouped);
        _isLoading = false;
        _companiesLoaded = true;
      });
      _resolvePendingSelectedIds();
    }, onError: (e) {
      print('❌ Stream error workspace $workspaceId: $e');
    });
    _workspaceSubs[workspaceId] = sub;
  }

  final Map<String,List<Company>> _workspaceCompanyCache = {}; // workspaceId -> companies
}
