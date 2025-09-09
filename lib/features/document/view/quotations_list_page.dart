import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../controller/quotations_list_controller.dart';
import 'quotations_filter_page.dart';

class QuotationsListPage extends StatefulWidget {
  const QuotationsListPage({super.key});

  @override
  State<QuotationsListPage> createState() => _QuotationsListPageState();
}

class _QuotationsListPageState extends State<QuotationsListPage> with WidgetsBindingObserver {
  late QuotationsListController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(QuotationsListController());
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
        title: const Text(
          'ใบเสนอราคา',
          style: TextStyle(
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
            onPressed: () => controller.createNewQuotation(),
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

            // Quotations List
            Expanded(child: _buildQuotationsList(controller)),
          ],
        );
      }),
    );
  }

  Widget _buildSearchAndFilterSection(QuotationsListController controller) {
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
              hintText: 'ค้นหาใบเสนอราคา...',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.textSecondary,
              ),
              suffixIcon: _buildFilterSuffixIcon(controller),
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

  bool _hasActiveFilters(QuotationsListController controller) {
    return controller.selectedSeller.value != null ||
        controller.selectedDateRange.value != null ||
        controller.selectedStatuses.isNotEmpty;
  }

  Widget _buildActiveFiltersSummary(QuotationsListController controller) {
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

  String _getActiveFiltersText(QuotationsListController controller) {
    final filters = <String>[];

    if (controller.selectedSeller.value != null) {
      filters.add('เซล: ${controller.selectedSeller.value!.displayName}');
    }

    if (controller.selectedDateRange.value != null) {
      filters.add('วันที่: ${_getDateRangeDisplayText(controller)}');
    }

    if (controller.selectedStatuses.isNotEmpty) {
      filters.add('สถานะ: ${controller.selectedStatuses.length} รายการ');
    }

    return filters.join(' • ');
  }

  String _getDateRangeDisplayText(QuotationsListController controller) {
    if (controller.selectedDateRange.value == null) {
      return 'ทั้งหมด';
    }

    switch (controller.selectedDateRange.value) {
      case 'today':
        return 'วันนี้';
      case 'this_week':
        return 'สัปดาห์นี้';
      case 'this_month':
        return 'เดือนนี้';
      case 'custom':
        if (controller.selectedCustomDateRange.value != null) {
          final startDate = controller.selectedCustomDateRange.value!.start;
          final endDate = controller.selectedCustomDateRange.value!.end;
          return '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}';
        }
        return 'เลือกช่วงวันที่';
      default:
        return 'ทั้งหมด';
    }
  }

  Widget _buildFilterSuffixIcon(QuotationsListController controller) {
    final hasActiveFilters = _hasActiveFilters(controller);

    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spacing8),
      child: IconButton(
        onPressed: () => _showFilterCenterDialog(controller),
        icon: Icon(
          Icons.tune,
          color: hasActiveFilters
              ? AppTheme.primaryOrange
              : AppTheme.textSecondary,
        ),
      ),
    );
  }

  void _showFilterCenterDialog(QuotationsListController controller) {
    Get.to(() => QuotationsFilterPage(controller: controller));
  }

  Widget _buildQuotationsList(QuotationsListController controller) {
    if (controller.quotations.isEmpty) {
      return _buildEmptyState(controller);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshData();
      },
      color: AppTheme.primaryOrange,
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // Check if we're near the bottom and should load more
          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            controller.loadMoreQuotations();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacing16,
            vertical: AppTheme.spacing8,
          ),
          itemCount: controller.quotations.length + (controller.hasMore.value ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom when loading more
            if (index == controller.quotations.length) {
              return _buildLoadingMoreIndicator(controller);
            }
            
            final quotation = controller.quotations[index];
            return _buildQuotationCard(quotation, controller);
          },
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator(QuotationsListController controller) {
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

  Widget _buildQuotationCard(
    Map<String, dynamic> quotation,
    QuotationsListController controller,
  ) {
    final docNo = quotation['docNo'] ?? '';
    final customerName = quotation['customer']?['name'] ?? '';
    final grandTotal = quotation['grandTotal']?.toDouble() ?? 0.0;
    final status = quotation['status'] ?? 'DRAFT';
    // final createdBy = quotation['createdBy']?['displayName'] ?? quotation['createdBy']?['name'] ?? 'ไม่ระบุ';
    final createdAt = quotation['createdAt'] ?? 0;

    return Builder(
      builder: (context) => Container(
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
          child: GestureDetector(
            onTap: () => controller.viewQuotation(quotation),
            onLongPress: () => _showContextMenu(context, quotation, controller),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.spacing8),
              ),
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

                      // // Created by
                      // Row(
                      //   children: [
                      //     Icon(
                      //       Icons.person_outline,
                      //       size: AppTheme.iconSize12,
                      //       color: AppTheme.textSecondary,
                      //     ),
                      //     const SizedBox(width: AppTheme.spacing4),
                      //     Expanded(
                      //       child: Text(
                      //         createdBy,
                      //         style: TextStyle(
                      //           color: AppTheme.textSecondary,
                      //           fontSize: AppTheme.fontSize10,
                      //           fontFamily: AppFont.family,
                      //         ),
                      //         maxLines: 1,
                      //         overflow: TextOverflow.ellipsis,
                      //       ),
                      //     ),
                      //   ],
                      // ),
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
                        '฿${grandTotal.toStringAsFixed(2)}',
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
        text = 'ร่าง';
        break;
      case 'SENT':
        color = const Color(0xFF2196F3);
        text = 'ส่งแล้ว';
        break;
      case 'PENDING_APPROVAL':
        color = const Color(0xFFFF9800);
        text = 'รออนุมัติ';
        break;
      case 'APPROVED':
        color = const Color(0xFF4CAF50);
        text = 'อนุมัติแล้ว';
        break;
      case 'REJECTED':
        color = const Color(0xFFF44336);
        text = 'ปฏิเสธ';
        break;
      case 'VOID':
        color = AppTheme.textSecondary;
        text = 'ยกเลิก';
        break;
      case 'INVOICED':
        color = const Color(0xFF9C27B0);
        text = 'ออกใบแจ้งหนี้แล้ว';
        break;
      case 'FULLY_PAID':
        color = const Color(0xFF4CAF50);
        text = 'ชำระแล้ว';
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

  Widget _buildEmptyState(QuotationsListController controller) {
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
            'ไม่พบใบเสนอราคา',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSize18,
              fontFamily: AppFont.family,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'เริ่มต้นสร้างใบเสนอราคาแรกของคุณ',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSize14,
              fontFamily: AppFont.family,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton.icon(
            onPressed: () => controller.createNewQuotation(),
            icon: const Icon(Icons.add),
            label: const Text('สร้างใบเสนอราคา'),
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

  void _showContextMenu(
    BuildContext context,
    Map<String, dynamic> quotation,
    QuotationsListController controller,
  ) {
    final status = quotation['status'] ?? '';
    
    // Only show context menu for SENT quotations
    if (status != 'APPROVED') {
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.spacing16),
            topRight: Radius.circular(AppTheme.spacing16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            
            // Title
            Text(
              'ตัวเลือก',
              style: TextStyle(
                fontSize: AppTheme.fontSize18,
                fontWeight: FontWeight.w600,
                fontFamily: AppFont.family,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            
            // Revise button
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppTheme.spacing8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.spacing8),
                ),
                child: const Icon(
                  Icons.edit_document,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              title: Text(
                'สร้างใบแจ้งหนี้',
                style: TextStyle(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: FontWeight.w500,
                  fontFamily: AppFont.family,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                'สร้างใบแจ้งหนี้จากใบเสนอราคานี้',
                style: TextStyle(
                  fontSize: AppTheme.fontSize14,
                  fontFamily: AppFont.family,
                  color: AppTheme.textSecondary,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                controller.reviseQuotationToInvoice(quotation);
              },
            ),
            
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }
}
