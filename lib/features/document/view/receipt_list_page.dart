import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../../../core/widgets/assignees_input_field.dart';
import '../controller/receipt_list_controller.dart';
import 'receipt_filter_page.dart';

class ReceiptListPage extends StatelessWidget {
  const ReceiptListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReceiptListController());

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'ใบเสร็จรับเงิน',
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
            onPressed: () => controller.createNewReceipt(),
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

            // Receipts List
            Expanded(child: _buildReceiptsList(controller)),
          ],
        );
      }),
    );
  }

  Widget _buildSearchAndFilterSection(ReceiptListController controller) {
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
              hintText: 'ค้นหาใบเสร็จรับเงิน...',
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

  bool _hasActiveFilters(ReceiptListController controller) {
    return controller.selectedSeller.value != null ||
        controller.selectedDateRange.value != null ||
        controller.selectedStatuses.isNotEmpty;
  }

  Widget _buildActiveFiltersSummary(ReceiptListController controller) {
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

  String _getActiveFiltersText(ReceiptListController controller) {
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

  String _getDateRangeDisplayText(ReceiptListController controller) {
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

  Widget _buildFilterSuffixIcon(ReceiptListController controller) {
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

  void _showFilterCenterDialog(ReceiptListController controller) {
    Get.to(() => ReceiptFilterPage(controller: controller));
  }

  Widget _buildReceiptsList(ReceiptListController controller) {
    if (controller.receipts.isEmpty) {
      return _buildEmptyState(controller);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing16,
        vertical: AppTheme.spacing8,
      ),
      itemCount: controller.receipts.length,
      itemBuilder: (context, index) {
        final receipt = controller.receipts[index];
        return _buildReceiptCard(receipt, controller);
      },
    );
  }

  Widget _buildReceiptCard(
    Map<String, dynamic> receipt,
    ReceiptListController controller,
  ) {
    final docNo = receipt['docNo'] ?? '';
    final customerName = receipt['customer']?['name'] ?? '';
    final grandTotal = receipt['grandTotal']?.toDouble() ?? 0.0;
    final status = receipt['status'] ?? 'COMPLETED';
    final createdAt = receipt['createdAt'] ?? 0;

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
          onTap: () => controller.viewReceipt(receipt),
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
    );
  }

  Widget _buildCompactStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'COMPLETED':
        color = const Color(0xFF4CAF50);
        text = 'เสร็จสิ้น';
        break;
      case 'VOID':
        color = AppTheme.textSecondary;
        text = 'ยกเลิก';
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

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'COMPLETED':
        color = const Color(0xFF4CAF50);
        text = 'เสร็จสิ้น';
        icon = Icons.check_circle;
        break;
      case 'VOID':
        color = AppTheme.textSecondary;
        text = 'ยกเลิก';
        icon = Icons.block;
        break;
      default:
        color = AppTheme.textSecondary;
        text = status;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing8,
        vertical: AppTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.spacing16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppTheme.iconSize12, color: color),
          const SizedBox(width: AppTheme.spacing4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontSize10,
              fontFamily: AppFont.family,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ReceiptListController controller) {
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
            'ไม่พบใบเสร็จรับเงิน',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSize18,
              fontFamily: AppFont.family,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'เริ่มต้นสร้างใบเสร็จรับเงินแรกของคุณ',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSize14,
              fontFamily: AppFont.family,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton.icon(
            onPressed: () => controller.createNewReceipt(),
            icon: const Icon(Icons.add),
            label: const Text('สร้างใบเสร็จรับเงิน'),
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
