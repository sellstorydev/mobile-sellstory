import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../../features/customers/view/add_edit_customer_page.dart';
import '../../features/customers/controller/customers_controller.dart';
import '../../domain/entities/customer.dart';




class CustomersInputField extends StatefulWidget {
  final List<String> selectedCustomerIds;
  final Function(List<String>) onCustomersChanged;
  final String label;
  final String hintText;
  final bool allowMultipleSelection;
  final bool showBorder;
  final VoidCallback? onCustomerAdded;

  const CustomersInputField({
    super.key,
    required this.selectedCustomerIds,
    required this.onCustomersChanged,
    this.label = 'select_customer',
    this.hintText = 'select_customer_hint',
    this.allowMultipleSelection = true,
    this.showBorder = true,
    this.onCustomerAdded,
  });

  @override
  State<CustomersInputField> createState() => _CustomersInputFieldState();
}

class _CustomersInputFieldState extends State<CustomersInputField> {
  late CustomersController _controller;

  @override
  void initState() {
    super.initState();
    // Get or create CustomersController
    if (!Get.isRegistered<CustomersController>()) {
      Get.put<CustomersController>(CustomersController(Get.find()));
    }
    _controller = Get.find<CustomersController>();
  }

  Future<void> _openAddCustomerPage() async {
    final result = await Get.to(
      () => AddEditCustomerPage(customerSources: _controller.customerSources),
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

          Obx(() {
            final isLoading = _controller.isLoading.value;
            final customers = _controller.filteredCustomers;

            if (isLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (customers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ไม่พบลูกค้าในระบบ',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            return Column(
              children: [
                // Button to open full page selection
                InkWell(
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
                            color: AppTheme.primaryOrange.withValues(alpha: 0.1),
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
                                  children: [
                                    ...widget.selectedCustomerIds.take(2).map((customerId) {
                                      final customer = customers.firstWhere(
                                        (c) => c.id == customerId,
                                        orElse: () => Customer(
                                          id: customerId,
                                          name: 'Unknown Customer',
                                          customId: customerId,
                                          prefix: '',
                                          gender: '',
                                          age: 0,
                                          customerType: '',
                                          emails: const [],
                                          phones: const [],
                                          companyNames: const [],
                                          nationalId: '',
                                          address: '',
                                          source: '',
                                          hashtags: const [],
                                          assignees: const [],
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
                                          color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          customer.name.isNotEmpty ? customer.name : customer.customId,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.primaryOrange,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    }),
                                    if (widget.selectedCustomerIds.length > 2)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '+${widget.selectedCustomerIds.length - 2}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
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
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showCustomersFullPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomersSelectionPage(
          selectedCustomerIds: List.from(widget.selectedCustomerIds),
          onCustomersChanged: widget.onCustomersChanged,
          label: widget.label.tr,
          allowMultipleSelection: widget.allowMultipleSelection,
          onCustomerAdded: widget.onCustomerAdded,
        ),
      ),
    );
  }
}


class CustomersSelectionPage extends StatefulWidget {
  final List<String> selectedCustomerIds;
  final Function(List<String>) onCustomersChanged;
  final String label;
  final bool allowMultipleSelection;
  final VoidCallback? onCustomerAdded;

  const CustomersSelectionPage({
    super.key,
    required this.selectedCustomerIds,
    required this.onCustomersChanged,
    required this.label,
    required this.allowMultipleSelection,
    this.onCustomerAdded,
  });

  @override
  State<CustomersSelectionPage> createState() => _CustomersSelectionPageState();
}

class _CustomersSelectionPageState extends State<CustomersSelectionPage> {
  late CustomersController _controller;
  List<String> _tempSelectedCustomerIds = [];

  @override
  void initState() {
    super.initState();
    _tempSelectedCustomerIds = List.from(widget.selectedCustomerIds);
    
    // Get CustomersController
    if (!Get.isRegistered<CustomersController>()) {
      Get.put<CustomersController>(CustomersController(Get.find()));
    }
    _controller = Get.find<CustomersController>();
  }

  void _triggerSearch() {
    final query = _controller.searchController.text.trim();
    _controller.triggerAlgoliaSearch(query);
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
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGrey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _controller.searchController,
                      onChanged: _controller.onSearchChanged,
                      onSubmitted: (_) => _triggerSearch(),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'ค้นหาลูกค้า...',
                        hintStyle: const TextStyle(color: AppTheme.textSecondary),
                        border: InputBorder.none,
                        prefixIcon: Obx(
                          () => _controller.isSearching.value
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
                              : const Icon(
                                  Icons.search,
                                  color: AppTheme.textSecondary,
                                ),
                        ),
                        suffixIcon: _controller.searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _controller.clearSearch();
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Search button
                Material(
                  color: AppTheme.primaryOrange,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _triggerSearch,
                    child: Container(
                      height: 44,
                      width: 44,
                      child: const Icon(Icons.search, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    final result = await Get.to(
                      () => AddEditCustomerPage(customerSources: _controller.customerSources),
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
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
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
          Obx(() {
            final isSearching = _controller.isSearching.value;
            final hasQuery = _controller.searchController.text.trim().isNotEmpty;
            final customers = _controller.filteredCustomers;
            
            if (isSearching || hasQuery) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade50,
                child: Text(
                  'ผลการค้นหา: ${customers.length} คน',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),

          // Customers list
          Expanded(
            child: Obx(() {
              final customers = _controller.filteredCustomers;
              final isLoading = _controller.isLoading.value;

              if (isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryOrange,
                  ),
                );
              }

              if (customers.isEmpty) {
                return Center(
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
                        _controller.searchController.text.trim().isNotEmpty
                            ? 'ไม่พบลูกค้าที่ตรงกับคำค้นหา'
                            : 'ไม่มีลูกค้าในระบบ',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_controller.searchController.text.trim().isNotEmpty) ...[
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
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  final isSelected = _tempSelectedCustomerIds.contains(customer.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: AppTheme.primaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        customer.name.isNotEmpty ? customer.name : customer.customId,
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
                          if (customer.companyNames.isNotEmpty)
                            Text(
                              'บริษัท: ${customer.companyNames.first['value'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          if (customer.emails.isNotEmpty)
                            Text(
                              'อีเมล: ${customer.emails.first['value'] ?? ''}',
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
              );
            }),
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

// Update older withOpacity usages in CustomersInputField UI portion as well
// (small icon background and selected chips)
// ...existing code above...
// We'll patch specific color calls below:

// Note: This is a patch hint; the actual replacements are inline edits above where applicable.
