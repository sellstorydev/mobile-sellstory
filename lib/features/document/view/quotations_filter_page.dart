import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../controller/quotations_list_controller.dart';

class QuotationsFilterPage extends StatelessWidget {
  final QuotationsListController controller;

  const QuotationsFilterPage({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'ตัวกรอง',
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
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.clearFilters();
              Get.back();
            },
            child: const Text(
              'ล้างตัวกรอง',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Sections
            _buildFilterSection(
              'เซล',
              controller.selectedSeller.value?.displayName ?? 'ทั้งหมด',
              Icons.person_outline,
              () => _showSellerFilterDialog(),
            ),
            const SizedBox(height: AppTheme.spacing16),
            
            _buildFilterSection(
              'วันที่',
              _getDateRangeDisplayText(),
              Icons.calendar_today,
              () => _showDateFilterDialog(),
            ),
            const SizedBox(height: AppTheme.spacing16),
            
            _buildFilterSection(
              'สถานะ',
              '${controller.selectedStatuses.length} รายการ',
              Icons.filter_list,
              () => _showStatusFilterDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.spacing12),
          border: Border.all(
            color: AppTheme.borderGrey,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor.withValues(alpha: 0.05),
              blurRadius: AppTheme.spacing8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: AppTheme.iconSize28,
              height: AppTheme.iconSize28,
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.spacing8),
              ),
              child: Icon(
                icon,
                size: AppTheme.iconSize20,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSize12,
                      fontFamily: AppFont.family,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontSize16,
                      fontFamily: AppFont.family,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  String _getDateRangeDisplayText() {
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

  void _showSellerFilterDialog() {
    Get.to(() => SellerFilterPage(controller: controller));
  }

  void _showDateFilterDialog() {
    Get.to(() => DateFilterPage(controller: controller));
  }

  void _showStatusFilterDialog() {
    Get.to(() => StatusFilterPage(controller: controller));
  }
}

// Seller Filter Page
class SellerFilterPage extends StatelessWidget {
  final QuotationsListController controller;

  const SellerFilterPage({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'เลือกเซล',
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
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.selectedSeller.value = null;
              controller.applyFilters();
              Get.back();
            },
            child: const Text(
              'ล้าง',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
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
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderGrey.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ค้นหาเซล...',
                hintStyle: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSize14,
                  fontFamily: AppFont.family,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.textSecondary,
                ),
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
          ),
          
          // All option
          ListTile(
            leading: Radio<dynamic>(
              value: null,
              groupValue: controller.selectedSeller.value,
              onChanged: (value) {
                controller.selectedSeller.value = value;
                controller.applyFilters();
                Get.back();
              },
              activeColor: AppTheme.primaryOrange,
            ),
            title: const Text(
              'ทั้งหมด',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontSize16,
                fontFamily: AppFont.family,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              controller.selectedSeller.value = null;
              controller.applyFilters();
              Get.back();
            },
          ),
          
          const Divider(height: 1),
          
          // TODO: Add actual seller list here
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 48,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  Text(
                    'รายชื่อเซลจะแสดงที่นี่',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontSize16,
                      fontFamily: AppFont.family,
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

// Date Filter Page
class DateFilterPage extends StatelessWidget {
  final QuotationsListController controller;

  const DateFilterPage({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'เลือกช่วงวันที่',
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
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.selectedDateRange.value = null;
              controller.selectedCustomDateRange.value = null;
              controller.applyFilters();
              Get.back();
            },
            child: const Text(
              'ล้าง',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
             body: Column(
         children: [
           // Date options directly visible
           Expanded(
             child: ListView(
               padding: const EdgeInsets.all(AppTheme.spacing16),
               children: [
                 // All option
                 _buildDateOption(
                   'ทั้งหมด',
                   null,
                   Icons.all_inclusive,
                   () {
                     controller.selectedDateRange.value = null;
                     controller.selectedCustomDateRange.value = null;
                     controller.applyFilters();
                     Get.back();
                   },
                 ),
                 
                 const SizedBox(height: AppTheme.spacing12),
                 
                 // Today
                 _buildDateOption(
                   'วันนี้',
                   'today',
                   Icons.today,
                   () {
                     controller.selectedDateRange.value = 'today';
                     controller.applyFilters();
                     Get.back();
                   },
                 ),
                 
                 const SizedBox(height: AppTheme.spacing12),
                 
                 // This week
                 _buildDateOption(
                   'สัปดาห์นี้',
                   'this_week',
                   Icons.view_week,
                   () {
                     controller.selectedDateRange.value = 'this_week';
                     controller.applyFilters();
                     Get.back();
                   },
                 ),
                 
                 const SizedBox(height: AppTheme.spacing12),
                 
                 // This month
                 _buildDateOption(
                   'เดือนนี้',
                   'this_month',
                   Icons.calendar_view_month,
                   () {
                     controller.selectedDateRange.value = 'this_month';
                     controller.applyFilters();
                     Get.back();
                   },
                 ),
                 
                 const SizedBox(height: AppTheme.spacing12),
                 
                 // Custom date range
                 _buildDateOption(
                   'เลือกช่วงวันที่เอง',
                   'custom',
                   Icons.date_range,
                   () async {
                     final picked = await showDateRangePicker(
                       context: context,
                       firstDate: DateTime(2020),
                       lastDate: DateTime.now().add(const Duration(days: 365)),
                       initialDateRange: controller.selectedCustomDateRange.value,
                       builder: (context, child) {
                         return Theme(
                           data: Theme.of(context).copyWith(
                             colorScheme: Theme.of(context).colorScheme.copyWith(
                               primary: AppTheme.primaryOrange,
                             ),
                           ),
                           child: child!,
                         );
                       },
                     );
                     
                     if (picked != null) {
                       controller.selectedDateRange.value = 'custom';
                       controller.selectedCustomDateRange.value = picked;
                       controller.applyFilters();
                       Get.back();
                     }
                   },
                 ),
               ],
             ),
           ),
         ],
       ),
    );
  }

  Widget _buildDateOption(String title, String? value, IconData icon, VoidCallback onTap) {
    final isSelected = controller.selectedDateRange.value == value;
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryOrange.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.spacing12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryOrange : AppTheme.borderGrey.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
                 leading: Container(
           width: 32,
           height: 32,
           decoration: BoxDecoration(
             color: isSelected ? AppTheme.primaryOrange : AppTheme.backgroundGrey,
             borderRadius: BorderRadius.circular(AppTheme.spacing8),
           ),
           child: Icon(
             icon,
             size: AppTheme.iconSize20,
             color: isSelected ? Colors.white : AppTheme.textSecondary,
           ),
         ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryOrange : AppTheme.textPrimary,
            fontSize: AppTheme.fontSize16,
            fontFamily: AppFont.family,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        trailing: isSelected ? const Icon(
          Icons.check_circle,
          color: AppTheme.primaryOrange,
        ) : null,
        onTap: onTap,
      ),
    );
  }
}

// Status Filter Page
class StatusFilterPage extends StatefulWidget {
  final QuotationsListController controller;

  const StatusFilterPage({
    super.key,
    required this.controller,
  });

  @override
  State<StatusFilterPage> createState() => _StatusFilterPageState();
}

class _StatusFilterPageState extends State<StatusFilterPage> {
  final Set<String> tempSelectedStatuses = {};

  @override
  void initState() {
    super.initState();
    tempSelectedStatuses.addAll(widget.controller.selectedStatuses);
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = [
      {'value': 'DRAFT', 'label': 'ร่าง', 'icon': Icons.edit_outlined},
      {'value': 'SENT', 'label': 'ส่งแล้ว', 'icon': Icons.send},
      {'value': 'PENDING_APPROVAL', 'label': 'รออนุมัติ', 'icon': Icons.pending},
      {'value': 'APPROVED', 'label': 'อนุมัติแล้ว', 'icon': Icons.check_circle},
      {'value': 'REJECTED', 'label': 'ปฏิเสธ', 'icon': Icons.cancel},
      {'value': 'VOID', 'label': 'ยกเลิก', 'icon': Icons.block},
      {'value': 'INVOICED', 'label': 'ออกใบแจ้งหนี้แล้ว', 'icon': Icons.receipt},
      {'value': 'FULLY_PAID', 'label': 'ชำระแล้ว', 'icon': Icons.payment},
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'เลือกสถานะ',
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
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                tempSelectedStatuses.clear();
              });
            },
            child: const Text(
              'ล้าง',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
             body: Column(
         children: [
           // Selected count indicator
           if (tempSelectedStatuses.isNotEmpty)
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(AppTheme.spacing16),
               decoration: BoxDecoration(
                 color: AppTheme.primaryOrange.withValues(alpha: 0.05),
                 border: Border(
                   bottom: BorderSide(
                     color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                     width: 1,
                   ),
                 ),
               ),
               child: Row(
                 children: [
                   Icon(
                     Icons.check_circle,
                     size: AppTheme.iconSize16,
                     color: AppTheme.primaryOrange,
                   ),
                   const SizedBox(width: AppTheme.spacing8),
                   Text(
                     'เลือกแล้ว ${tempSelectedStatuses.length} รายการ',
                     style: TextStyle(
                       color: AppTheme.primaryOrange,
                       fontSize: AppTheme.fontSize14,
                       fontFamily: AppFont.family,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 ],
               ),
             ),
           
           // Status options directly visible
           Expanded(
             child: ListView.builder(
               padding: const EdgeInsets.all(AppTheme.spacing16),
               itemCount: statusOptions.length,
               itemBuilder: (context, index) {
                 final status = statusOptions[index];
                 final isSelected = tempSelectedStatuses.contains(status['value']);
                 
                 return Container(
                   margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
                   decoration: BoxDecoration(
                     color: isSelected ? AppTheme.primaryOrange.withValues(alpha: 0.1) : Colors.white,
                     borderRadius: BorderRadius.circular(AppTheme.spacing12),
                     border: Border.all(
                       color: isSelected ? AppTheme.primaryOrange : AppTheme.borderGrey.withValues(alpha: 0.3),
                       width: 1,
                     ),
                   ),
                   child: ListTile(
                     leading: Container(
                       width: 32,
                       height: 32,
                       decoration: BoxDecoration(
                         color: isSelected ? AppTheme.primaryOrange : AppTheme.backgroundGrey,
                         borderRadius: BorderRadius.circular(AppTheme.spacing8),
                       ),
                       child: Icon(
                         status['icon'] as IconData,
                         size: AppTheme.iconSize20,
                         color: isSelected ? Colors.white : AppTheme.textSecondary,
                       ),
                     ),
                     title: Text(
                       status['label'] as String,
                       style: TextStyle(
                         color: isSelected ? AppTheme.primaryOrange : AppTheme.textPrimary,
                         fontSize: AppTheme.fontSize16,
                         fontFamily: AppFont.family,
                         fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                       ),
                     ),
                     trailing: isSelected ? const Icon(
                       Icons.check_circle,
                       color: AppTheme.primaryOrange,
                     ) : null,
                     onTap: () {
                       setState(() {
                         if (isSelected) {
                           tempSelectedStatuses.remove(status['value'] as String);
                         } else {
                           tempSelectedStatuses.add(status['value'] as String);
                         }
                         // Apply filters immediately
                         widget.controller.selectedStatuses.clear();
                         widget.controller.selectedStatuses.addAll(tempSelectedStatuses);
                         widget.controller.applyFilters();
                       });
                     },
                   ),
                 );
               },
             ),
           ),
         ],
       ),
     );
   }
 }
