import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_font.dart';
import '../controller/invoice_creation_controller.dart';

class InvoiceCreationOptionsPage extends StatelessWidget {
  final Map<String, dynamic> quotation;

  const InvoiceCreationOptionsPage({
    super.key,
    required this.quotation,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InvoiceCreationController(quotation: quotation));

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'สร้างใบแจ้งหนี้',
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
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryOrange),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quotation Info
              _buildQuotationInfo(controller),
              const SizedBox(height: AppTheme.spacing24),

              // Options
              Text(
                'เลือกประเภทใบแจ้งหนี้',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSize16,
                  fontFamily: AppFont.family,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Option 1: Full Invoice
              _buildOptionCard(
                controller: controller,
                optionNumber: 1,
                title: 'ยืนยันการสร้างใบแจ้งหนี้เต็มจำนวน',
                subtitle: 'สร้างใบแจ้งหนี้จำนวนเต็มตามใบเสนอราคา',
                onTap: () => _showFullInvoiceDialog(controller),
              ),

              const SizedBox(height: AppTheme.spacing12),

              // Option 2: Installment Invoice
              _buildOptionCard(
                controller: controller,
                optionNumber: 2,
                title: 'สร้างใบแจ้งหนี้ (แบ่งจ่ายตามงวด)',
                subtitle: 'สร้างใบแจ้งหนี้บางส่วนตามจำนวนหรือเปอร์เซ็นต์',
                onTap: () => _showInstallmentDialog(controller),
              ),

              const SizedBox(height: AppTheme.spacing12),

              // Option 3: Item-based Invoice
              _buildOptionCard(
                controller: controller,
                optionNumber: 3,
                title: 'สร้างใบแจ้งหนี้ (แบ่งจ่ายแบบรายการ)',
                subtitle: 'เลือกรายการสินค้าที่ต้องการออกใบแจ้งหนี้',
                onTap: () => _showItemSelectionDialog(controller),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildQuotationInfo(InvoiceCreationController controller) {
    final docNo = controller.quotation['docNo'] ?? '';
    final customerName = controller.quotation['customer']?['name'] ?? '';
    final grandTotal = controller.quotation['grandTotal']?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.spacing12),
        border: Border.all(
          color: AppTheme.primaryOrange.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ข้อมูลใบเสนอราคา',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: AppTheme.fontSize14,
              fontFamily: AppFont.family,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เลขที่: $docNo',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: AppTheme.fontSize14,
                  fontFamily: AppFont.family,
                ),
              ),
              Text(
                '฿${grandTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.primaryOrange,
                  fontSize: AppTheme.fontSize16,
                  fontFamily: AppFont.family,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'ลูกค้า: $customerName',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSize14,
              fontFamily: AppFont.family,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required InvoiceCreationController controller,
    required int optionNumber,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.spacing12),
        border: Border.all(
          color: AppTheme.borderGrey.withValues(alpha: 0.3),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.spacing12),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.spacing8),
                  ),
                  child: Center(
                    child: Text(
                      '$optionNumber',
                      style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontSize: AppTheme.fontSize16,
                        fontFamily: AppFont.family,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                          color: AppTheme.textPrimary,
                          fontSize: AppTheme.fontSize16,
                          fontFamily: AppFont.family,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSize14,
                          fontFamily: AppFont.family,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: AppTheme.iconSize16,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullInvoiceDialog(InvoiceCreationController controller) {
    final grandTotal = controller.quotation['grandTotal']?.toDouble() ?? 0.0;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.spacing16),
        ),
        title: Text(
          'ยืนยันการสร้างใบแจ้งหนี้เต็มจำนวน',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.fontSize18,
            fontFamily: AppFont.family,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'จำนวนเงินทั้งหมด',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
              ),
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              '฿${grandTotal.toStringAsFixed(2)}',
              style: TextStyle(
                color: AppTheme.primaryOrange,
                fontSize: AppTheme.fontSize24,
                fontFamily: AppFont.family,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'ต้องการสร้างใบแจ้งหนี้จำนวนเต็มจากใบเสนอราคานี้หรือไม่?',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.createFullInvoice();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.spacing8),
              ),
            ),
            child: Text(
              'confirm'.tr,
              style: TextStyle(
                fontSize: AppTheme.fontSize14,
                fontFamily: AppFont.family,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInstallmentDialog(InvoiceCreationController controller) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.spacing16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'สร้างใบแจ้งหนี้ (แบ่งจ่ายตามงวด)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSize18,
                  fontFamily: AppFont.family,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),

              // Radio buttons for calculation type
              Text(
                'ประเภทการคำนวณ',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSize14,
                  fontFamily: AppFont.family,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text(
                        'เปอร์เซ็นต์ (%)',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize14,
                          fontFamily: AppFont.family,
                        ),
                      ),
                      value: 'percent',
                      groupValue: controller.installmentType.value,
                      onChanged: (value) => controller.setInstallmentType(value!),
                      activeColor: AppTheme.primaryOrange,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: Text(
                        'จำนวน (บาท)',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize14,
                          fontFamily: AppFont.family,
                        ),
                      ),
                      value: 'amount',
                      groupValue: controller.installmentType.value,
                      onChanged: (value) => controller.setInstallmentType(value!),
                      activeColor: AppTheme.primaryOrange,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.spacing16),

              // Input field
              TextField(
                controller: controller.installmentInputController,
                keyboardType: TextInputType.number,
                onChanged: controller.onInstallmentInputChanged,
                decoration: InputDecoration(
                  labelText: controller.installmentType.value == 'percent' 
                      ? 'เปอร์เซ็นต์ที่ต้องการ' 
                      : 'จำนวนเงิน (บาท)',
                  labelStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSize14,
                    fontFamily: AppFont.family,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.spacing8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.spacing8),
                    borderSide: BorderSide(color: AppTheme.primaryOrange),
                  ),
                  suffixText: controller.installmentType.value == 'percent' ? '%' : '฿',
                ),
              ),

              const SizedBox(height: AppTheme.spacing24),

              // Calculation summary
              if (controller.calculatedAmount.value > 0) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppTheme.spacing8),
                    border: Border.all(
                      color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'สรุปการคำนวณ',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: AppTheme.fontSize14,
                          fontFamily: AppFont.family,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ยอดชำระสำหรับงวดนี้:',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontSize14,
                              fontFamily: AppFont.family,
                            ),
                          ),
                          Text(
                            '฿${controller.calculatedAmount.value.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppTheme.primaryOrange,
                              fontSize: AppTheme.fontSize16,
                              fontFamily: AppFont.family,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      // Show tax information based on quotation settings
                      if (controller.quotation['isVatEnabled'] == true || controller.quotation['isWhtEnabled'] == true) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.quotation['isVatEnabled'] == true 
                                  ? 'ภาษีมูลค่าเพิ่ม (${controller.quotation['vatPercentage'] ?? 7}%):' 
                                  : 'หัก ณ ที่จ่าย (${controller.quotation['withholdingTaxPercentage'] ?? 3}%):',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontSize14,
                                fontFamily: AppFont.family,
                              ),
                            ),
                            Text(
                              '฿${controller.withholdingAmount.value.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontSize14,
                                fontFamily: AppFont.family,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ยอดสุทธิ:',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: AppTheme.fontSize16,
                              fontFamily: AppFont.family,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '฿${controller.netAmount.value.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppTheme.primaryOrange,
                              fontSize: AppTheme.fontSize18,
                              fontFamily: AppFont.family,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'cancel'.tr,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSize14,
                          fontFamily: AppFont.family,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.calculatedAmount.value > 0
                          ? () {
                              Get.back();
                              controller.createInstallmentInvoice();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.spacing8),
                        ),
                      ),
                      child: Text(
                        'สร้างใบแจ้งหนี้',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize14,
                          fontFamily: AppFont.family,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
        ),
      ),
    );
  }

  void _showItemSelectionDialog(InvoiceCreationController controller) {
    controller.initializeItemSelection();
    
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.spacing16),
        ),
        child: Container(
          width: Get.width * 0.9,
          height: Get.height * 0.8,
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'เลือกรายการสินค้า',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSize18,
                  fontFamily: AppFont.family,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),

              // Check All section
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.spacing8),
                  border: Border.all(
                    color: AppTheme.primaryOrange.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: controller.isAllItemsSelected.value,
                      onChanged: (value) => controller.toggleAllItems(),
                      activeColor: AppTheme.primaryOrange,
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'เลือกทั้งหมด',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontSize14,
                        fontFamily: AppFont.family,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),

              // Items list
              Expanded(
                child: ListView.builder(
                  itemCount: controller.selectedItems.length,
                  itemBuilder: (context, index) {
                    final item = controller.selectedItems[index];
                    final isSelected = item['selected'] == true;
                    final maxQuantity = item['originalQuantity']?.toDouble() ?? 1.0;
                    final currentQuantity = item['quantity']?.toDouble() ?? 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryOrange.withValues(alpha: 0.05)
                            : Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppTheme.spacing8),
                        border: Border.all(
                          color: isSelected 
                              ? AppTheme.primaryOrange.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacing12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) => controller.toggleItemSelection(index),
                                  activeColor: AppTheme.primaryOrange,
                                ),
                                const SizedBox(width: AppTheme.spacing8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? '',
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: AppTheme.fontSize14,
                                          fontFamily: AppFont.family,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (item['description'] != null && item['description'].isNotEmpty)
                                        Text(
                                          item['description'],
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: AppTheme.fontSize12,
                                            fontFamily: AppFont.family,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '฿${((item['pricePerUnit'] ?? 0) * currentQuantity).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: AppTheme.primaryOrange,
                                        fontSize: AppTheme.fontSize14,
                                        fontFamily: AppFont.family,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'สูงสุด: ${maxQuantity.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: AppTheme.fontSize12,
                                        fontFamily: AppFont.family,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: AppTheme.spacing12),
                              Row(
                                children: [
                                  const SizedBox(width: 40), // Checkbox width
                                  Text(
                                    'จำนวน:',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: AppTheme.fontSize14,
                                      fontFamily: AppFont.family,
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacing12),
                                  Expanded(
                                    child: TextField(
                                      controller: controller.getQuantityController(index),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) => controller.updateItemQuantity(index, value),
                                      decoration: InputDecoration(
                                        hintText: '0',
                                        helperText: 'สูงสุด: ${(item['originalQuantity'] ?? 0).toStringAsFixed(0)}',
                                        helperStyle: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: AppTheme.fontSize12,
                                          fontFamily: AppFont.family,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.spacing8),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppTheme.spacing8),
                                          borderSide: BorderSide(color: AppTheme.primaryOrange),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacing12,
                                          vertical: AppTheme.spacing8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppTheme.spacing8),
                                  Text(
                                    item['unit'] ?? 'ชิ้น',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: AppTheme.fontSize14,
                                      fontFamily: AppFont.family,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Discount and calculation section
              const SizedBox(height: AppTheme.spacing16),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.spacing8),
                  border: Border.all(
                    color: AppTheme.borderGrey.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สรุปยอดเงิน',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontSize16,
                        fontFamily: AppFont.family,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    
                    // Subtotal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ยอดรวม:',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: AppTheme.fontSize14,
                            fontFamily: AppFont.family,
                          ),
                        ),
                        Text(
                          '฿${controller.itemBasedSubtotal.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.fontSize14,
                            fontFamily: AppFont.family,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppTheme.spacing12),
                    
                    // Discount input
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ส่วนลดท้ายบิลสำหรับงวดนี้:',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: AppTheme.fontSize14,
                                  fontFamily: AppFont.family,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacing4),
                              Text(
                                'สูงสุด ฿${controller.itemBasedSubtotal.value.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: AppTheme.textSecondary.withValues(alpha: 0.7),
                                  fontSize: AppTheme.fontSize12,
                                  fontFamily: AppFont.family,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacing8),
                        Expanded(
                          child: TextField(
                            controller: controller.itemBasedDiscountController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) => controller.calculateItemBasedDiscount(),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              prefixText: '฿',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.spacing8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.spacing8),
                                borderSide: BorderSide(color: AppTheme.primaryOrange),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacing12,
                                vertical: AppTheme.spacing8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (controller.itemBasedDiscountAmount.value > 0) ...[
                      const SizedBox(height: AppTheme.spacing12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ส่วนลด:',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: AppTheme.fontSize14,
                              fontFamily: AppFont.family,
                            ),
                          ),
                          Text(
                            '-฿${controller.itemBasedDiscountAmount.value.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: AppTheme.fontSize14,
                              fontFamily: AppFont.family,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    const SizedBox(height: AppTheme.spacing12),
                    const Divider(),
                    const SizedBox(height: AppTheme.spacing8),
                    
                    // Final total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ยอดรวมสุทธิ:',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: AppTheme.fontSize16,
                            fontFamily: AppFont.family,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '฿${controller.itemBasedAfterDiscount.value.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppTheme.primaryOrange,
                            fontSize: AppTheme.fontSize18,
                            fontFamily: AppFont.family,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons
              const SizedBox(height: AppTheme.spacing16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'cancel'.tr,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: AppTheme.fontSize14,
                          fontFamily: AppFont.family,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.hasSelectedItems.value
                          ? () {
                              Get.back();
                              controller.createItemBasedInvoice();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.spacing8),
                        ),
                      ),
                      child: Text(
                        'สร้างใบแจ้งหนี้',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize14,
                          fontFamily: AppFont.family,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
        ),
      ),
    );
  }
}
