import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../controller/invoice_list_controller.dart';
import 'invoice_filter_page.dart';
import 'add_edit_document_page.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage> with WidgetsBindingObserver {
  late InvoiceListController controller;
  DateTime? _lastLoadMoreCall;

  @override
  void initState() {
    super.initState();
    controller = Get.put(InvoiceListController());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
      controller.refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(
          'invoices'.tr,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.fontSize18,
            fontFamily: AppFont.family,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.backgroundWhite,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                print('📱 Navigating to AddEditDocumentPage with documentType: INV');
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditDocumentPage(documentType: 'INV'),
                  ),
                );
                print('📱 Navigation completed, result: $result');
              } catch (e) {
                print('❌ Navigation error: $e');
                Get.snackbar(
                  'error'.tr,
                  'Navigation error: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            icon: const Icon(Icons.add),
            color: AppTheme.primaryOrange,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryOrange),
          );
        }

        return Column(
          children: [
            // Search and Filter Section
            _buildSearchAndFilterSection(controller),

            // Invoices List
            Expanded(child: _buildInvoicesList(controller)),
          ],
        );
      }),
    );
  }

  Widget _buildSearchAndFilterSection(InvoiceListController controller) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor.withValues(alpha: 0.05),
            blurRadius: AppTheme.spacing8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: controller.searchController,
            onChanged: controller.onSearchChanged,
            decoration: InputDecoration(
              hintText: 'search_invoices'.tr,
              hintStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
              ),
              suffixIcon: _buildSearchAndFilterSuffixIcons(controller),
              filled: true,
              fillColor: AppTheme.backgroundGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.spacing12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),

          // Active Filters Summary
          if (_hasActiveFilters(controller))
            _buildActiveFiltersSummary(controller),
        ],
      ),
    );
  }

  bool _hasActiveFilters(InvoiceListController controller) {
    return controller.selectedSeller.value != null ||
        controller.selectedDateRange.value != null ||
        controller.selectedStatuses.isNotEmpty;
  }

  Widget _buildActiveFiltersSummary(InvoiceListController controller) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.spacing8),
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: AppTheme.iconSize16,
            color: AppTheme.primaryOrange,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              _getActiveFiltersText(controller),
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: AppTheme.fontSize12,
                fontFamily: AppFont.family,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              controller.clearFilters();
            },
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing4),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.spacing4),
              ),
              child: Icon(
                Icons.close,
                size: AppTheme.iconSize12,
                color: AppTheme.primaryOrange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getActiveFiltersText(InvoiceListController controller) {
    final filters = <String>[];

    if (controller.selectedSeller.value != null) {
      filters.add('seller_filter'.tr.replaceFirst('{name}', controller.selectedSeller.value!.displayName));
    }

    if (controller.selectedDateRange.value != null) {
      filters.add('date_filter'.tr.replaceFirst('{range}', _getDateRangeDisplayText(controller)));
    }

    if (controller.selectedStatuses.isNotEmpty) {
      filters.add('status_filter'.tr.replaceFirst('{count}', controller.selectedStatuses.length.toString()));
    }

    return filters.join(' • ');
  }

  String _getDateRangeDisplayText(InvoiceListController controller) {
    if (controller.selectedDateRange.value == null) {
      return 'all'.tr;
    }

    switch (controller.selectedDateRange.value) {
      case 'today':
        return 'today'.tr;
      case 'this_week':
        return 'this_week'.tr;
      case 'this_month':
        return 'this_month'.tr;
      case 'custom':
        if (controller.selectedCustomDateRange.value != null) {
          final startDate = controller.selectedCustomDateRange.value!.start;
          final endDate = controller.selectedCustomDateRange.value!.end;
          return '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}';
        }
        return 'select_date_range'.tr;
      default:
        return 'all'.tr;
    }
  }

  Widget _buildSearchAndFilterSuffixIcons(InvoiceListController controller) {
    final hasActiveFilters = _hasActiveFilters(controller);
    final isSearching = controller.searchController.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spacing8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search button
          Obx(() => IconButton(
            onPressed: () => _triggerSearch(controller),
            icon: controller.isSearching.value
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : Icon(
                    Icons.search,
                    color: isSearching 
                        ? AppTheme.primaryOrange
                        : AppTheme.textSecondary,
                  ),
          )),
          // Filter button
          IconButton(
            onPressed: () => _showFilterCenterDialog(controller),
            icon: Icon(
              Icons.tune,
              color: hasActiveFilters
                  ? AppTheme.primaryOrange
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _triggerSearch(InvoiceListController controller) {
    final query = controller.searchController.text.trim();
    if (query.isNotEmpty) {
      controller.triggerAlgoliaSearch(query);
    }
  }

  void _showFilterCenterDialog(InvoiceListController controller) {
    Get.to(() => InvoiceFilterPage(controller: controller));
  }

  Widget _buildInvoicesList(InvoiceListController controller) {
    if (controller.invoices.isEmpty) {
      return _buildEmptyState(controller);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshData();
      },
      color: AppTheme.primaryOrange,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // Only handle ScrollUpdateNotification (actual scrolling) and ScrollEndNotification
          // This prevents triggering during drag start/drag end events
          if (scrollInfo is ScrollUpdateNotification || scrollInfo is ScrollEndNotification) {
            // Check if we're near the bottom and should load more
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              // Only load more if we're not already loading and there's more data to load
              if (!controller.isLoadingMore.value && controller.hasMore.value) {
                // Add debounce to prevent rapid calls (minimum 500ms between calls)
                final now = DateTime.now();
                if (_lastLoadMoreCall == null || now.difference(_lastLoadMoreCall!).inMilliseconds > 500) {
                  _lastLoadMoreCall = now;
                  controller.loadMoreInvoices();
                }
              }
            }
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing8,
          ),
          itemCount: controller.invoices.length + (controller.hasMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom when loading more
            if (index == controller.invoices.length) {
              return _buildLoadingMoreIndicator(controller);
            }
            
            final invoice = controller.invoices[index];
            return _buildInvoiceCard(invoice, controller);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(InvoiceListController controller) {
    return Obx(() {
      if (!controller.isLoadingMore.value) {
        return const SizedBox.shrink();
      }
      
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryOrange,
            strokeWidth: 2,
          ),
        ),
      );
    });
  }

  Widget _buildInvoiceCard(
    Map<String, dynamic> invoice,
    InvoiceListController controller,
  ) {
    final docNo = invoice['docNo'] ?? '';
    final customerName = invoice['customer']?['name'] ?? '';
    final grandTotal = invoice['grandTotal']?.toDouble() ?? 0.0;
    final status = invoice['status'] ?? 'DRAFT';
    final createdAt = invoice['createdAt'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.spacing8),
        border: Border.all(
          color: AppTheme.borderGrey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.spacing8),
          onTap: () => controller.viewInvoice(invoice),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            child: Row(
              children: [
                // Left side - Document info
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Document number
                      Row(
                        children: [
                          Text(
                            docNo,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontSize14,
                              fontFamily: AppFont.family,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          // Right side - Status
                          _buildCompactStatusChip(status),
                        ],
                      ),

                      const SizedBox(height: AppTheme.spacing4),

                      // Customer name
                      Text(
                        customerName,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSize12,
                          fontFamily: AppFont.family,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                    ],
                  ),
                ),

                const SizedBox(width: AppTheme.spacing12),

                // Center - Amount
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${'currency_symbol'.tr}${grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: AppTheme.fontSize14,
                          fontFamily: AppFont.family,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        controller.formatDate(createdAt),
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSize10,
                          fontFamily: AppFont.family,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'DRAFT':
        color = AppTheme.textSecondary;
        text = 'draft'.tr;
        break;
      case 'SENT':
        color = const Color(0xFF2196F3);
        text = 'sent'.tr;
        break;
      case 'PARTIAL_PAID':
        color = const Color(0xFFFF9800);
        text = 'partial_paid'.tr;
        break;
      case 'PAID':
        color = const Color(0xFF4CAF50);
        text = 'paid'.tr;
        break;
      case 'OVERDUE':
        color = const Color(0xFFF44336);
        text = 'overdue'.tr;
        break;
      case 'VOID':
        color = AppTheme.textSecondary;
        text = 'void'.tr;
        break;
      default:
        color = AppTheme.textSecondary;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.spacing8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: AppTheme.fontSize10,
          fontFamily: AppFont.family,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(InvoiceListController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.spacing16),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'no_invoices_found'.tr,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSize18,
              fontFamily: AppFont.family,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'start_creating_first_invoice'.tr,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSize14,
              fontFamily: AppFont.family,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                print('📱 Navigating to AddEditDocumentPage from empty state with documentType: INV');
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditDocumentPage(documentType: 'INV'),
                  ),
                );
                print('📱 Navigation completed from empty state, result: $result');
              } catch (e) {
                print('❌ Navigation error from empty state: $e');
                Get.snackbar(
                  'error'.tr,
                  'Navigation error: $e',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            icon: const Icon(Icons.add),
            label: Text('create_invoice'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing20,
                vertical: AppTheme.spacing12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.spacing12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
