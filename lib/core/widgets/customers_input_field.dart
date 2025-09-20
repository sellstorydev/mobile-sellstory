import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/algolia_search_service.dart';
import '../../features/customers/view/add_edit_customer_page.dart';
import 'dart:async';

/// Customer data model matching Firestore structure
class Customer {
  final String id;
  final String name;
  final String customId;
  final List<Map<String, dynamic>> emails;
  final List<Map<String, dynamic>> phones;
  final List<Map<String, dynamic>> companyNames;
  final List<Map<String, dynamic>> customFields;
  final String workspaceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Customer({
    required this.id,
    required this.name,
    required this.customId,
    required this.emails,
    required this.phones,
    required this.companyNames,
    required this.customFields,
    required this.workspaceId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic raw) {
      if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (raw is DateTime) return raw;
      if (raw is Timestamp) return raw.toDate();
      if (raw is int) {
        // Heuristic: treat as ms if it's large, else seconds
        if (raw > 2000000000) {
          // already ms
          return DateTime.fromMillisecondsSinceEpoch(raw);
        } else {
          return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
        }
      }
      if (raw is String) {
        try {
          return DateTime.parse(raw);
        } catch (_) {}
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return Customer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      customId: map['customId'] ?? '',
      emails: List<Map<String, dynamic>>.from(map['emails'] ?? []),
      phones: List<Map<String, dynamic>>.from(map['phones'] ?? []),
      companyNames: List<Map<String, dynamic>>.from(map['companyNames'] ?? []),
      customFields: List<Map<String, dynamic>>.from(map['customFields'] ?? []),
      workspaceId: map['workspaceId'] ?? '',
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
      createdBy: map['createdBy'] ?? '',
      updatedBy: map['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'customId': customId,
      'emails': emails,
      'phones': phones,
      'companyNames': companyNames,
      'customFields': customFields,
      'workspaceId': workspaceId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }

  /// Get display name for the customer
  String get displayName {
    if (name.isNotEmpty) return name;
    if (companyNames.isNotEmpty) {
      final firstCompany = companyNames.first['value'] as String?;
      if (firstCompany != null && firstCompany.isNotEmpty) {
        return firstCompany;
      }
    }
    return customId.isNotEmpty ? customId : 'Unknown Customer';
  }

  /// Get primary email
  String get primaryEmail {
    if (emails.isNotEmpty) {
      final email = emails.first['value'] as String?;
      return email ?? '';
    }
    return '';
  }

  /// Get primary phone
  String get primaryPhone {
    if (phones.isNotEmpty) {
      final phone = phones.first['value'] as String?;
      return phone ?? '';
    }
    return '';
  }

  /// Get primary company name
  String get primaryCompanyName {
    if (companyNames.isNotEmpty) {
      final company = companyNames.first['value'] as String?;
      return company ?? '';
    }
    return '';
  }
}

class CustomersInputField extends StatefulWidget {
  final List<String> selectedCustomerIds;
  final List<Customer> availableCustomers;
  final Function(List<String>) onCustomersChanged;
  final String label;
  final String hintText;
  final bool isLoading;
  final bool allowMultipleSelection;
  final bool showBorder;
  final String? workspaceId;
  final bool enableAlgoliaSearch;
  final VoidCallback? onCustomerAdded;

  const CustomersInputField({
    super.key,
    required this.selectedCustomerIds,
    required this.availableCustomers,
    required this.onCustomersChanged,
    this.label = 'select_customer',
    this.hintText = 'select_customer_hint',
    this.isLoading = false,
    this.allowMultipleSelection = true,
    this.showBorder = true,
    this.workspaceId,
    this.enableAlgoliaSearch = true,
    this.onCustomerAdded,
  });

  @override
  State<CustomersInputField> createState() => _CustomersInputFieldState();
}

class _CustomersInputFieldState extends State<CustomersInputField> {
  final TextEditingController _searchController = TextEditingController();
  // Algolia search related
  Timer? _searchDebounceTimer;
  StreamSubscription? _algoliaSearchSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _algoliaSearchSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // This component just opens a full page, so we don't need local filtering
    // The search functionality is handled in the full page
  }

  Future<void> _openAddCustomerPage() async {
    final result = await Get.to(
      () => const AddEditCustomerPage(customerSources: []),
    );
    
    if (result == true && widget.onCustomerAdded != null) {
      // Notify parent to refresh customer list
      widget.onCustomerAdded!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.showBorder ? const EdgeInsets.all(16) : null,
      decoration: widget.showBorder
          ? BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showBorder)
            Row(
              children: [
                Text(
                  widget.label.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _openAddCustomerPage,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          if (widget.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Column(
              children: [
                // Search field with add customer button
                Row(
                  children: [
                    // Button to open full page selection
                    Expanded(
                      child: InkWell(
                        onTap: _showCustomersFullPage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Small customer icon
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryOrange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Display selected customers or hint
                              Expanded(
                                child: widget.selectedCustomerIds.isEmpty
                                    ? Text(
                                        widget.hintText.tr,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      )
                                    : Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                  children:
                                      widget.selectedCustomerIds.take(2).map((
                                        customerId,
                                      ) {
                                        final customer = widget
                                            .availableCustomers
                                            .firstWhere(
                                              (c) => c.id == customerId,
                                              orElse: () => Customer(
                                                id: customerId,
                                                name: 'Unknown Customer',
                                                customId: customerId,
                                                emails: [],
                                                phones: [],
                                                companyNames: [],
                                                customFields: [],
                                                workspaceId: '',
                                                createdAt: DateTime.now(),
                                                updatedAt: DateTime.now(),
                                                createdBy: '',
                                                updatedBy: '',
                                              ),
                                            );
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryOrange
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            customer.displayName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primaryOrange,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList()..addAll(
                                        widget.selectedCustomerIds.length > 2
                                            ? [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '+${widget.selectedCustomerIds.length - 2}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme
                                                          .textSecondary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ]
                                            : [],
                                      ),
                                ),
                              ),

                              // Arrow icon
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // const SizedBox(width: 8),

                    // // Add Customer Button
                    // IconButton(
                    //   onPressed: _openAddCustomerPage,
                    //   icon: const Icon(
                    //     Icons.person_add,
                    //     color: AppTheme.primaryOrange,
                    //     size: 24,
                    //   ),
                    //   tooltip: 'Add New Customer',
                    //   style: IconButton.styleFrom(
                    //     backgroundColor: Colors.white,
                    //     side: BorderSide(color: Colors.grey.shade400),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(8),
                    //     ),
                    //     padding: const EdgeInsets.all(12),
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showCustomersFullPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomersSelectionPage(
          selectedCustomerIds: List.from(widget.selectedCustomerIds),
          availableCustomers: widget.availableCustomers,
          onCustomersChanged: widget.onCustomersChanged,
          label: widget.label.tr,
          allowMultipleSelection: widget.allowMultipleSelection,
          workspaceId: widget.workspaceId,
          enableAlgoliaSearch: widget.enableAlgoliaSearch,
          onCustomerAdded: widget.onCustomerAdded,
        ),
      ),
    );
  }
}

class CustomersSelectionPage extends StatefulWidget {
  final List<String> selectedCustomerIds;
  final List<Customer> availableCustomers;
  final Function(List<String>) onCustomersChanged;
  final String label;
  final bool allowMultipleSelection;
  final String? workspaceId;
  final bool enableAlgoliaSearch;
  final VoidCallback? onCustomerAdded;

  const CustomersSelectionPage({
    super.key,
    required this.selectedCustomerIds,
    required this.availableCustomers,
    required this.onCustomersChanged,
    required this.label,
    required this.allowMultipleSelection,
    this.workspaceId,
    this.enableAlgoliaSearch = true,
    this.onCustomerAdded,
  });

  @override
  State<CustomersSelectionPage> createState() => _CustomersSelectionPageState();
}

class _CustomersSelectionPageState extends State<CustomersSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];
  List<String> _tempSelectedCustomerIds = [];
  bool _isSearching = false;
  // Algolia search related
  Timer? _searchDebounceTimer;
  StreamSubscription? _algoliaSearchSubscription;

  @override
  void initState() {
    super.initState();
    _tempSelectedCustomerIds = List.from(widget.selectedCustomerIds);
    _filteredCustomers = List.from(widget.availableCustomers);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _algoliaSearchSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer and search
    _searchDebounceTimer?.cancel();
    _algoliaSearchSubscription?.cancel();

    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
    });

    // If query is empty, reset to show all customers
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _filteredCustomers = List.from(widget.availableCustomers);
      });
      return;
    }

    // Use Algolia search if enabled and workspace ID is available
    if (widget.enableAlgoliaSearch &&
        widget.workspaceId != null &&
        widget.workspaceId!.isNotEmpty) {
      // Debounce Algolia search
      _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _searchWithAlgolia(_searchController.text.trim());
        }
      });
    } else {
      // Fallback to local search
      _searchLocally(_searchController.text.trim());
    }
  }

  void _searchWithAlgolia(String query) async {
    if (widget.workspaceId == null || widget.workspaceId!.isEmpty) {
      _searchLocally(query);
      return;
    }
    try {
      final searchStream = AlgoliaSearchService.searchCustomers(
        query: query,
        workspaceId: widget.workspaceId!,
        hitsPerPage: 50,
      );

      _algoliaSearchSubscription = searchStream.listen(
        (response) {
          if (!mounted) return;

          try {
            final hits = response.hits;
            final algoliaResults = <Customer>[];

            // Convert Algolia results to Customer objects
            for (final hit in hits) {
              try {
                // Find the customer in our local list by ID
                final customerId = hit['objectID'] as String?;
                if (customerId != null) {
                  final customer = widget.availableCustomers.firstWhere(
                    (c) => c.id == customerId,
                    orElse: () {
                      // If not found in local list, create from Algolia data
                      final data = Map<String, dynamic>.from(hit);
                      data['id'] = customerId;
                      // Handle missing fields with defaults
                      data['emails'] = data['emails'] ?? [];
                      data['phones'] = data['phones'] ?? [];
                      data['companyNames'] = data['companyNames'] ?? [];
                      data['customFields'] = data['customFields'] ?? [];
                      data['createdAt'] =
                          data['createdAt'] ??
                          DateTime.now().millisecondsSinceEpoch;
                      data['updatedAt'] =
                          data['updatedAt'] ??
                          DateTime.now().millisecondsSinceEpoch;
                      data['createdBy'] = data['createdBy'] ?? '';
                      data['updatedBy'] = data['updatedBy'] ?? '';
                      return Customer.fromMap(data);
                    },
                  );
                  algoliaResults.add(customer);
                }
              } catch (e) {
                print('❌ Failed to convert Algolia hit to Customer: $e');
              }
            }

            setState(() {
              _filteredCustomers = algoliaResults;
              _isSearching = false;
            });
          } catch (e) {
            print('❌ Error processing Algolia response: $e');
            // Fallback to local search on error
            _searchLocally(query);
          }
        },
        onError: (error) {
          print('❌ Algolia customer search error: $error');
          // Fallback to local search on error
          _searchLocally(query);
        },
      );
    } catch (e) {
      print('❌ Failed to search customers with Algolia: $e');
      // Fallback to local search on error
      _searchLocally(query);
    }
  }

  void _searchLocally(String query) {
    setState(() {
      _isSearching = _searchController.text.isNotEmpty;
      if (_isSearching) {
        _filteredCustomers = widget.availableCustomers
            .where(
              (customer) =>
                  customer.displayName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  customer.customId.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  customer.primaryEmail.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  customer.primaryCompanyName.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      } else {
        _filteredCustomers = List.from(widget.availableCustomers);
      }
    });
  }

  void _toggleSelection(String customerId) {
    setState(() {
      if (_tempSelectedCustomerIds.contains(customerId)) {
        _tempSelectedCustomerIds.remove(customerId);
      } else {
        if (widget.allowMultipleSelection) {
          _tempSelectedCustomerIds.add(customerId);
        } else {
          // Single selection mode - replace current selection
          _tempSelectedCustomerIds = [customerId];
        }
      }
    });
  }

  void _applySelection() {
    widget.onCustomersChanged(_tempSelectedCustomerIds);
    Navigator.of(context).pop();
  }

  void _clearSelection() {
    setState(() {
      _tempSelectedCustomerIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(
          widget.label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearSelection,
            child: const Text(
              'ล้าง',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: widget.enableAlgoliaSearch
                          ? 'ค้นหาลูกค้าด้วย...'
                          : 'ค้นหาลูกค้า...',
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primaryOrange,
                                ),
                              ),
                            )
                          : const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final result = await Get.to(
                      () => const AddEditCustomerPage(customerSources: []),
                    );
                    
                    if (result == true && widget.onCustomerAdded != null) {
                      Navigator.of(context).pop();
                      widget.onCustomerAdded!();
                    }
                  },
                  icon: const Icon(
                    Icons.person_add,
                    color: AppTheme.primaryOrange,
                    size: 24,
                  ),
                  tooltip: 'Add New Customer',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),

          // Selection mode indicator
          if (widget.allowMultipleSelection)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppTheme.primaryOrange.withOpacity(0.1),
              child: Text(
                _tempSelectedCustomerIds.isEmpty
                    ? 'เลือกลูกค้า (สามารถเลือกหลายคนได้)'
                    : 'เลือกแล้ว ${_tempSelectedCustomerIds.length} คน',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // Search results info
          if (_isSearching || _searchController.text.trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey.shade50,
              child: Text(
                widget.enableAlgoliaSearch
                    ? 'ผลการค้นหาจาก: ${_filteredCustomers.length} คน'
                    : 'ผลการค้นหา: ${_filteredCustomers.length} คน',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Customers list
          Expanded(
            child: _filteredCustomers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.trim().isNotEmpty
                              ? 'ไม่พบลูกค้าที่ตรงกับคำค้นหา'
                              : 'ไม่มีลูกค้าในระบบ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_searchController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'ลองใช้คำค้นหาอื่น หรือตรวจสอบการสะกดคำ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _filteredCustomers[index];
                      final isSelected = _tempSelectedCustomerIds.contains(
                        customer.id,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryOrange.withOpacity(
                              0.1,
                            ),
                            child: Text(
                              customer.displayName.isNotEmpty
                                  ? customer.displayName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                color: AppTheme.primaryOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            customer.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (customer.customId.isNotEmpty)
                                Text(
                                  'รหัส: ${customer.customId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              if (customer.primaryCompanyName.isNotEmpty)
                                Text(
                                  'บริษัท: ${customer.primaryCompanyName}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              if (customer.primaryEmail.isNotEmpty)
                                Text(
                                  'อีเมล: ${customer.primaryEmail}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(customer.id),
                            activeColor: AppTheme.primaryOrange,
                          ),
                          onTap: () => _toggleSelection(customer.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppTheme.primaryOrange),
                ),
                child: const Text(
                  'ยกเลิก',
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _applySelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'เลือก (${_tempSelectedCustomerIds.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
