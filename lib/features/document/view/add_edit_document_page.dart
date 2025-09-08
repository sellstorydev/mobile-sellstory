import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/assignees_input_field.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../domain/entities/customer.dart';
import '../controller/add_edit_document_controller.dart';

class AddEditDocumentPage extends StatefulWidget {
  final String? documentId; // null for new, non-null for edit
  final String documentType; // 'QT' for quotation, 'INV' for invoice

  const AddEditDocumentPage({
    super.key,
    this.documentId,
    required this.documentType,
  });

  @override
  State<AddEditDocumentPage> createState() => _AddEditDocumentPageState();
}

class _AddEditDocumentPageState extends State<AddEditDocumentPage> {
  // Section expansion states
  final Map<String, bool> _sectionExpanded = {
    'status': true, // Document status section collapsed by default
    'customer': false, // Customer section expanded by default
    'seller': false, // Other sections collapsed by default
    'product': false,
    'more': false,
    'summary': false,
  };

  @override
  void initState() {
    super.initState();
  }

    @override
  Widget build(BuildContext context) {
    return GetBuilder<AddEditDocumentController>(
      init: AddEditDocumentController(documentId: widget.documentId),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          appBar: AppBar(
            title: Text(
              widget.documentId == null
                  ? (widget.documentType == 'QT'
                        ? 'สร้างใบเสนอราคา'
                        : 'สร้างใบแจ้งหนี้')
                  : (widget.documentType == 'QT'
                        ? 'แก้ไขใบเสนอราคา'
                        : 'แก้ไขใบแจ้งหนี้'),
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppTheme.backgroundWhite,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
              onPressed: () => Get.back(),
            ),
            actions: [
              // Expand All Sections Button
              IconButton(
                onPressed: () {
                  setState(() {
                    _sectionExpanded.updateAll((key, value) => true);
                  });
                },
                icon: const Icon(
                  Icons.unfold_more,
                  color: AppTheme.primaryOrange,
                ),
                tooltip: 'ขยายทุกส่วน',
              ),
              // Collapse All Sections Button
              IconButton(
                onPressed: () {
                  setState(() {
                    _sectionExpanded.updateAll((key, value) => false);
                  });
                },
                icon: const Icon(
                  Icons.unfold_less,
                  color: AppTheme.primaryOrange,
                ),
                tooltip: 'ย่อทุกส่วน',
              ),
                             GetBuilder<AddEditDocumentController>(
                 builder: (controller) {
                   return TextButton(
                     onPressed:
                         (controller.isLoading || !_areRequiredFieldsComplete())
                         ? null
                         : controller.saveDocument,
                    child: controller.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryOrange,
                              ),
                            ),
                          )
                        : Text(
                            'บันทึก',
                            style: TextStyle(
                              color: _areRequiredFieldsComplete()
                                  ? AppTheme.primaryOrange
                                  : AppTheme.textGrey,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
          body: controller.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryOrange,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                                     child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                      // Document Status and Template Section
                        GetBuilder<AddEditDocumentController>(
                          builder: (controller) {
                            return Column(
                              children: [
                                _buildSectionHeader(
                                'สถานะเอกสาร & เทมเพลต',
                                Icons.settings,
                                'status_template',
                                ),
                                const SizedBox(height: 12),
                              if (_sectionExpanded['status_template'] ??
                                  true) 
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.borderGrey,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'สถานะเอกสาร',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<String>(
                                            value: controller.documentStatus,
                                            items: controller.availableStatuses
                                                .map((status) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: status,
                                                    child: Text(status),
                                                  );
                                                })
                                                .toList(),
                                            onChanged: controller
                                                .onDocumentStatusChanged,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'เทมเพลตเอกสาร',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<String>(
                                            value:
                                                controller.selectedTemplateId,
                                            items: [
                                              const DropdownMenuItem<String>(
                                                value: null,
                                                child: Text('ไม่มี (None)'),
                                              ),
                                              ...controller.availableTemplates
                                                  .map((template) {
                                                    return DropdownMenuItem<
                                                      String
                                                    >(
                                                      value: template['id'],
                                                      child: Text(
                                                        template['name'],
                                                      ),
                                                    );
                                                  }),
                                            ],
                                            onChanged:
                                                controller.onTemplateChanged,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),



                                               // Customer Section
                        GetBuilder<AddEditDocumentController>(
                         builder: (controller) {
                           return Column(
                             children: [
                               _buildSectionHeader(
                                 'ข้อมูลลูกค้า',
                                 Icons.person,
                                 'customer',
                               ),
                               const SizedBox(height: 12),
                               if (_sectionExpanded['customer'] ?? false) ...[
                                 _buildCustomerSection(controller),
                                 const SizedBox(height: 24),
                               ],
                             ],
                           );
                         },
                       ),

                                             // Seller Section
                       GetBuilder<AddEditDocumentController>(
                         builder: (controller) {
                           return Column(
                             children: [
                               _buildSectionHeader(
                                 'ข้อมูลผู้ขาย',
                                 Icons.business,
                                 'seller',
                               ),
                               const SizedBox(height: 12),
                               if (_sectionExpanded['seller'] ?? false) ...[
                                 _buildSellerSection(controller),
                                 const SizedBox(height: 24),
                               ],
                             ],
                           );
                         },
                       ),

                                             // Product Section
                       GetBuilder<AddEditDocumentController>(
                         builder: (controller) {
                           return Column(
                             children: [
                               _buildSectionHeader(
                                 'รายการสินค้า/บริการ (${controller.products.length} รายการ)',
                                 Icons.inventory,
                                 'product',
                               ),
                               const SizedBox(height: 12),
                               if (_sectionExpanded['product'] ?? false) ...[
                                 _buildProductSection(controller),
                                 const SizedBox(height: 24),
                               ],
                             ],
                           );
                         },
                                               ),

                       // More Options Section
                       _buildSectionHeader(
                         'ข้อมูลเพิ่มเติม',
                         Icons.settings,
                         'more',
                       ),
                      const SizedBox(height: 12),
                      if (_sectionExpanded['more'] ?? false) ...[
                        _buildMoreOptionsSection(controller),
                        const SizedBox(height: 24),
                      ],

                      // Summary Section
                      _buildSectionHeader(
                        'สรุปยอด',
                        Icons.calculate,
                        'summary',
                      ),
                      const SizedBox(height: 12),
                      if (_sectionExpanded['summary'] ?? false) ...[
                        _buildSummarySection(controller),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String sectionKey) {
    final isExpanded = _sectionExpanded[sectionKey] ?? false;
    final isRequired =
        sectionKey == 'customer' ||
        sectionKey == 'seller' ||
        sectionKey == 'product';
    final isComplete = _isSectionComplete(sectionKey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isComplete
            ? AppTheme.primaryOrange.withOpacity(0.1)
            : AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? AppTheme.primaryOrange.withOpacity(0.3)
              : AppTheme.errorRed.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _sectionExpanded[sectionKey] = !isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isComplete ? AppTheme.primaryOrange : AppTheme.errorRed,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isComplete
                          ? AppTheme.primaryOrange
                          : AppTheme.errorRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isRequired && !isComplete)
                    Text(
                      'กรุณากรอกข้อมูลให้ครบถ้วน',
                      style: TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            // Required field indicator
            if (isRequired)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppTheme.primaryOrange
                      : AppTheme.errorRed,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isComplete ? '✓' : '!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: isComplete ? AppTheme.primaryOrange : AppTheme.errorRed,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

     // Check if section is complete based on required fields
   bool _isSectionComplete(String sectionKey) {
     final controller = Get.find<AddEditDocumentController>();

     switch (sectionKey) {
       case 'status':
        return controller
            .documentStatus
            .isNotEmpty; // Status is always complete if set
      case 'status_template':
        return controller
            .documentStatus
            .isNotEmpty; // Status is always complete if set
       case 'customer':
         return controller.selectedCustomerId != null &&
             controller.selectedCustomerId!.isNotEmpty;
       case 'seller':
         return controller.selectedSellerIds.isNotEmpty;
       case 'product':
         final controller = Get.find<AddEditDocumentController>();
         return _areAllProductsComplete(
           controller,
         ); // Check if all products are complete
       case 'more':
         return true; // Optional section
       case 'summary':
         return true; // Calculated section
       default:
         return true;
     }
   }

  // Check if all required fields are complete
  bool _areRequiredFieldsComplete() {
          final controller = Get.find<AddEditDocumentController>();
      return _isSectionComplete('customer') &&
          _isSectionComplete('seller') &&
          _areAllProductsComplete(controller);
  }

  // Check if the last product has all required fields filled
  bool _isLastProductComplete(AddEditDocumentController controller) {
    if (controller.products.isEmpty) return true;

    final lastIndex = controller.products.length - 1;
    return _isProductCompleteWithTemplate(controller, lastIndex);
  }

  // Check if all products have required fields filled
  bool _areAllProductsComplete(AddEditDocumentController controller) {
    if (controller.products.isEmpty) return true;

    for (int i = 0; i < controller.products.length; i++) {
      if (!_isProductCompleteWithTemplate(controller, i)) {
      return false;
      }
    }

    return true;
  }

  // Check if a product is complete based on template fields
  bool _isProductCompleteWithTemplate(AddEditDocumentController controller, int index) {
    final fields = controller.templateProductFields;
    if (fields.isEmpty) return true; // No template fields means complete
    
    for (final field in fields) {
      final fieldId = field['id']?.toString() ?? '';
      final fieldType = field['type']?.toString() ?? '';
      final isVisible = field['isVisible'] ?? true;
      
      if (!isVisible) continue;
      
      // Check required fields based on field type
      bool isRequired = false;
      String fieldValue = '';
      
      if (fieldType == 'product_field') {
        if (field['sourceField'] == 'name' || fieldId == 'name') {
          isRequired = true;
          fieldValue = controller.getProductController(index, 'name').text.trim();
        } else if (field['sourceField'] == 'pricePerUnit' || fieldId == 'pricePerUnit') {
          isRequired = true;
          fieldValue = controller.getProductController(index, 'pricePerUnit').text.trim();
        }
      } else if (fieldType == 'predefined') {
        if (field['predefinedField'] == 'quantity' || fieldId == 'quantity') {
          isRequired = true;
          fieldValue = controller.getProductController(index, 'quantity').text.trim();
        } else if (field['predefinedField'] == 'unit' || fieldId == 'unit') {
          isRequired = true;
          fieldValue = controller.getProductController(index, 'unit').text.trim();
        }
      }
      
      if (isRequired && fieldValue.isEmpty) {
        return false;
      }

      // Validate numeric fields
      if (isRequired && (fieldId == 'quantity' || field['predefinedField'] == 'quantity')) {
        final quantityValue = double.tryParse(fieldValue);
        if (quantityValue == null || quantityValue <= 0) {
          return false;
        }
      }
      
      if (isRequired && (fieldId == 'pricePerUnit' || field['sourceField'] == 'pricePerUnit')) {
        final priceValue = double.tryParse(fieldValue);
        if (priceValue == null || priceValue < 0) {
        return false;
        }
      }
    }

    return true;
  }

  Widget _buildCustomerSection(AddEditDocumentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Section Header with Refresh Button
          Row(
            children: [
              Expanded(
                child: Text(
                  'ข้อมูลลูกค้า',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Customer Selection
          if (controller.isLoadingCustomers &&
              controller.customers.isEmpty) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryOrange,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'กำลังโหลดรายชื่อลูกค้า...',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (controller.customers.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLightGrey),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_off,
                      color: AppTheme.textSecondary,
                      size: 32,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'ไม่พบลูกค้าในระบบ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'กรุณาเพิ่มลูกค้าในระบบก่อนสร้างใบเสนอราคา',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            _buildDropdownField(
              label: 'เลือกลูกค้า *',
              hint: 'เลือกลูกค้าจากฐานข้อมูล',
              value: controller.selectedCustomerId,
              items: controller.customers.map((customer) {
                return DropdownMenuItem<String>(
                  value: customer.id,
                  child: Text(controller.getCustomerDisplayName(customer)),
                );
              }).toList(),
              onChanged: (value) => controller.onCustomerChanged(value),
              isRequired: true,
            ),
          ],
          const SizedBox(height: 16),

          // Customer Company Selection
          if (controller.selectedCustomer != null &&
              controller.selectedCustomer!.companyNames.isNotEmpty) ...[
            _buildDropdownField(
              label: 'บริษัทลูกค้า',
              hint: 'เลือกบริษัท',
              value: controller.selectedCompanyId,
              items: controller.selectedCustomer!.companyNames
                  .map((company) {
                    final companyId = company['id'] as String?;
                    if (companyId != null) {
                      return DropdownMenuItem<String>(
                        value: companyId,
                        child: Text(controller.getCompanyDisplayName(company)),
                      );
                    }
                    return DropdownMenuItem<String>(
                      value: '',
                      child: Text('Unknown Company'),
                    );
                  })
                  .where((item) => item.value!.isNotEmpty)
                  .toList(),
              onChanged: controller.onCompanyChanged,
            ),
            const SizedBox(height: 16),
          ],

          // Customer Address
          _buildTextField(
            label: 'ที่อยู่ลูกค้า',
            hint: 'กรอกที่อยู่ลูกค้า',
            controller: controller.customerAddressController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Postal Code
          _buildTextField(
            label: 'รหัสไปรษณีย์',
            hint: 'กรอกรหัสไปรษณีย์',
            controller: controller.customerPostalCodeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // National ID
          _buildTextField(
            label: 'เลขประจำตัวประชาชน',
            hint: 'กรอกเลขประจำตัวประชาชน',
            controller: controller.customerNationalIdController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Phone
          _buildTextField(
            label: 'เบอร์โทรศัพท์',
            hint: 'กรอกเบอร์โทรศัพท์',
            controller: controller.customerPhoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Email
          _buildTextField(
            label: 'อีเมล',
            hint: 'กรอกอีเมล',
            controller: controller.customerEmailController,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildSellerSection(AddEditDocumentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller/Assignee Selection
          AssigneesInputField(
            selectedAssignees: controller.selectedSellerIds,
            availableMembers: controller.availableAssignees,
            onAssigneesChanged: controller.onSellerAssigneesChanged,
            label: 'ผู้ขาย/ผู้รับผิดชอบ *',
            hintText: 'เลือกผู้ขายจากรายชื่อผู้รับผิดชอบ',
            isLoading: controller.isLoadingAssignees,
            allowMultipleSelection: false, // Single selection for seller
            showBorder: false,
          ),
          const SizedBox(height: 16),

          // Job Name
          _buildTextField(
            label: 'ชื่องาน',
            hint: 'กรอกชื่องาน',
            controller: controller.jobNameController,
          ),
          const SizedBox(height: 16),

          // Ref ID
          _buildTextField(
            label: 'รหัสอ้างอิง',
            hint: 'กรอกรหัสอ้างอิง',
            controller: controller.refIdController,
          ),
          const SizedBox(height: 16),

          // Document Date
          _buildDateField(
            label: 'วันที่ออกเอกสาร',
            hint: 'เลือกวันที่ออกเอกสาร',
            value: controller.documentDate,
            onChanged: controller.onDocumentDateChanged,
          ),
          const SizedBox(height: 16),

          // Valid Until Date
          _buildDateField(
            label: 'ยืนราคาถึงวันที่',
            hint: 'เลือกวันที่ยืนราคาถึง',
            value: controller.validUntilDate,
            onChanged: controller.onValidUntilDateChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection(AddEditDocumentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template requirement warning
          if (controller.selectedTemplateId == null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: AppTheme.errorRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'กรุณาเลือกเทมเพลตเอกสารก่อนเพิ่มสินค้า เพื่อกำหนดฟิลด์ที่ต้องการ',
                      style: TextStyle(color: AppTheme.errorRed, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Product Selection Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (controller.isLoadingProducts || controller.selectedTemplateId == null)
                      ? null
                      : () => _showProductSelectionDialog(controller),
                  icon: controller.isLoadingProducts
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.storage, color: Colors.white),
                  label: Text(
                    controller.isLoadingProducts
                        ? 'กำลังโหลด...'
                        : controller.selectedTemplateId == null
                            ? 'เลือกเทมเพลตก่อน'
                        : 'เลือกจากฐานข้อมูล',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.selectedTemplateId == null 
                        ? AppTheme.textGrey 
                        : AppTheme.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.selectedTemplateId == null
                      ? null
                      : controller.addProduct,
                  icon: Icon(
                    Icons.add,
                    color: controller.selectedTemplateId == null
                        ? AppTheme.textGrey
                        : AppTheme.primaryOrange,
                  ),
                  label: Text(
                    controller.selectedTemplateId == null
                        ? 'เลือกเทมเพลตก่อน'
                        : 'เพิ่มใหม่',
                    style: TextStyle(
                      color: controller.selectedTemplateId == null
                          ? AppTheme.textGrey
                          : AppTheme.primaryOrange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: controller.selectedTemplateId == null
                          ? AppTheme.textGrey
                          : AppTheme.primaryOrange,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Product List
          if (controller.products.isNotEmpty) ...[
            ...controller.products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return _buildProductItem(controller, index, product);
            }).toList(),
            const SizedBox(height: 16),
          ],

          // Help message for product requirements
          if (controller.products.isNotEmpty &&
              !_isLastProductComplete(controller))
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.errorRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'กรุณากรอกข้อมูลสินค้าปัจจุบันให้ครบถ้วน (ชื่อ, จำนวน, หน่วย, ราคา) ก่อนเพิ่มสินค้าใหม่',
                      style: TextStyle(color: AppTheme.errorRed, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
    AddEditDocumentController controller,
    int index,
    Map<String, dynamic> product,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'รายการที่ ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => controller.removeProduct(index),
                icon: const Icon(
                  Icons.delete,
                  color: AppTheme.errorRed,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dynamic product fields based on template
          _buildDynamicProductFields(controller, index),
        ],
      ),
    );
  }
  
  Widget _buildDynamicProductFields(AddEditDocumentController controller, int index) {
    final fields = controller.templateProductFields;
    if (fields.isEmpty) {
      return const Text('ไม่พบฟิลด์สินค้าในเทมเพลต');
    }
    
    List<Widget> fieldWidgets = [];
    
    for (int i = 0; i < fields.length; i++) {
      final field = fields[i];
      final fieldId = field['id']?.toString() ?? '';
      final fieldLabel = field['label']?.toString() ?? '';
      final fieldType = field['type']?.toString() ?? '';
      final isVisible = field['isVisible'] ?? true;
      final isEditable = field['isEditable'] ?? true;
      final formula = field['formula']?.toString() ?? '';
      
      if (!isVisible) continue;
      
      Widget fieldWidget;
      
      // Check if this is a calculated field with formula
      if (fieldType == 'predefined' && 
          field['predefinedField'] == 'line_total' && 
          formula.isNotEmpty) {
        // This is a calculated total field - display as read-only with calculated value
        fieldWidget = _buildCalculatedTotalField(
          controller: controller,
          productIndex: index,
          label: fieldLabel,
          formula: formula,
        );
      } else {
        // Regular input fields
        switch (fieldType) {
          case 'product_field':
          case 'predefined':
          case 'user_input':
            // Determine the controller key for this field
            String controllerKey = fieldId;
            
            // Handle different field mappings
            if (fieldType == 'product_field' && field['sourceField'] != null) {
              final sourceField = field['sourceField'].toString();
              if (sourceField.startsWith('customFields.')) {
                controllerKey = sourceField.replaceFirst('customFields.', '');
              } else {
                controllerKey = sourceField;
              }
            } else if (fieldType == 'predefined' && field['predefinedField'] != null) {
              controllerKey = field['predefinedField'].toString();
            } else if (fieldType == 'user_input') {
              controllerKey = fieldId;
            }
            
            // Determine keyboard type based on inputType and field rules
            TextInputType keyboardType = _getKeyboardTypeForField(field, controllerKey);
            bool isRequired = _isFieldRequired(controllerKey);
            String hint = _getFieldHint(controllerKey, keyboardType);
            String? prefix = _getFieldPrefix(controllerKey);
            int maxLines = _getFieldMaxLines(controllerKey);
            
            fieldWidget = _buildTextField(
              label: isRequired ? '$fieldLabel *' : fieldLabel,
              hint: hint,
              controller: controller.getProductController(index, controllerKey),
              keyboardType: keyboardType,
              prefix: prefix,
              maxLines: maxLines,
              isRequired: isRequired,
              isEnabled: isEditable, // Respect isEditable from template
              onChanged: (value) => controller.update(),
            );
            break;
            
          default:
            // Generic field for unknown types
            fieldWidget = _buildTextField(
              label: fieldLabel,
              hint: 'กรอก $fieldLabel',
              controller: controller.getProductController(index, fieldId),
              onChanged: (value) => controller.update(),
            );
        }
      }
      
      fieldWidgets.add(fieldWidget);
      
      // Add spacing between fields (except for the last one)
      if (i < fields.length - 1) {
        fieldWidgets.add(const SizedBox(height: 12));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fieldWidgets,
    );
  }

  // Helper method to determine keyboard type based on field configuration
  TextInputType _getKeyboardTypeForField(Map<String, dynamic> field, String controllerKey) {
    // Check if field has explicit inputType - this takes priority
    final inputType = field['inputType']?.toString();
    if (inputType != null) {
      return inputType == 'number' ? TextInputType.number : TextInputType.text;
    }
    
    // Apply default rules based on field type and sourceField
    final fieldType = field['type']?.toString() ?? '';
    
    if (fieldType == 'predefined') {
      // All predefined fields are numeric
      return TextInputType.number;
    } else if (fieldType == 'product_field') {
      // For product_field, only pricePerUnit is numeric, others are text
      final sourceField = field['sourceField']?.toString() ?? '';
      return sourceField == 'pricePerUnit' ? TextInputType.number : TextInputType.text;
    } else if (fieldType == 'user_input') {
      // Default to text for user_input unless specified otherwise
      return TextInputType.text;
    }
    
    // Default fallback
    return TextInputType.text;
  }

  // Helper method to determine if field is required
  bool _isFieldRequired(String controllerKey) {
    return ['name', 'quantity', 'unit', 'pricePerUnit'].contains(controllerKey);
  }

  // Helper method to get appropriate hint text
  String _getFieldHint(String controllerKey, TextInputType keyboardType) {
    switch (controllerKey) {
      case 'quantity':
      case 'pricePerUnit':
      case 'discount':
        return '0.00';
      case 'unit':
        return 'ชิ้น';
      default:
        return keyboardType == TextInputType.number ? '0' : 'กรอกข้อมูล';
    }
  }

  // Helper method to get field prefix
  String? _getFieldPrefix(String controllerKey) {
    return ['pricePerUnit', 'discount'].contains(controllerKey) ? '฿' : null;
  }

  // Helper method to get max lines
  int _getFieldMaxLines(String controllerKey) {
    return controllerKey == 'description' ? 2 : 1;
  }

  // Build calculated total field that displays formula result
  Widget _buildCalculatedTotalField({
    required AddEditDocumentController controller,
    required int productIndex,
    required String label,
    required String formula,
  }) {
    final calculatedTotal = controller.calculateProductTotal(productIndex);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGrey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderLightGrey),
          ),
          child: Row(
            children: [
              Text(
                '฿',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  calculatedTotal.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.calculate,
                size: 16,
                color: AppTheme.textSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'คำนวณจาก: $formula',
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildMoreOptionsSection(AddEditDocumentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Methods
          _buildMultiSelectField(
            label: 'ช่องทางการชำระเงิน',
            hint: 'เลือกช่องทางการชำระเงิน',
            selectedItems: controller.selectedPaymentMethods,
            availableItems: controller.availablePaymentMethods,
            onChanged: controller.onPaymentMethodsChanged,
          ),
          const SizedBox(height: 16),

          // Notes
          _buildTextField(
            label: 'หมายเหตุ',
            hint: 'กรอกหมายเหตุเพิ่มเติม',
            controller: controller.notesController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Signature Selection (only show if template has signature fields)
          if (controller.templateSignatureFields.isNotEmpty) ...[
            Text(
              'ลายเซ็น',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...controller.templateSignatureFields.where((signatureField) => 
              signatureField != null && 
              signatureField['signatureRoleName'] != null
            ).map((signatureField) {
              final roleName = signatureField['signatureRoleName']?.toString() ?? '';
              final selectedSignatureId = controller.selectedSignatures[roleName];
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roleName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      value: selectedSignatureId,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('เลือกลายเซ็น'),
                        ),
                        ...controller.availableSignatures.where((signature) => 
                          signature != null && 
                          signature['id'] != null
                        ).map((signature) {
                          return DropdownMenuItem<String>(
                            value: signature['id'],
                            child: Text(
                              signature['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) => controller.onSignatureChanged(roleName, value),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  // Show selected signature image below dropdown
                  if (selectedSignatureId != null) ...[
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final selectedSignature = controller.availableSignatures.firstWhere(
                          (signature) => signature['id'] == selectedSignatureId,
                          orElse: () => <String, dynamic>{},
                        );
                        
                        if (selectedSignature['url']?.isNotEmpty == true) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderGrey),
                              borderRadius: BorderRadius.circular(8),
                              color: AppTheme.backgroundGrey.withOpacity(0.1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.borderGrey),
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.white,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      selectedSignature['url'],
                                      fit: BoxFit.contain,
                                      width: 60,
                                      height: 30,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 60,
                                          height: 30,
                                          color: AppTheme.backgroundGrey,
                                          child: Icon(Icons.image_not_supported, size: 20),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 60,
                                          height: 30,
                                          color: AppTheme.backgroundGrey,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedSignature['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        '${selectedSignature['ownerName'] ?? ''} - ${selectedSignature['position'] ?? ''}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              );
            }).toList(),
          ],
          const SizedBox(height: 16),

          // Company Stamp (Coming Soon)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderLightGrey),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ตรายางบริษัท',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          value: controller.selectedCompanySealId,
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('เลือกตรายางบริษัท'),
                            ),
                            ...controller.availableCompanySeals.where((seal) => 
                              seal != null && 
                              seal['id'] != null
                            ).map((seal) {
                              return DropdownMenuItem<String>(
                                value: seal['id'],
                                child: Text(
                                  seal['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) => controller.onCompanySealChanged(value),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      // Show selected company seal image below dropdown
                      if (controller.selectedCompanySealId != null) ...[
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final selectedSeal = controller.availableCompanySeals.firstWhere(
                              (seal) => seal['id'] == controller.selectedCompanySealId,
                              orElse: () => <String, dynamic>{},
                            );
                            
                            if (selectedSeal['url']?.isNotEmpty == true) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppTheme.borderGrey),
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppTheme.backgroundGrey.withOpacity(0.1),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppTheme.borderGrey),
                                        borderRadius: BorderRadius.circular(4),
                                        color: Colors.white,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          selectedSeal['url'],
                                          fit: BoxFit.contain,
                                          width: 60,
                                          height: 30,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 30,
                                              color: AppTheme.backgroundGrey,
                                              child: Icon(Icons.image_not_supported, size: 20),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              width: 60,
                                              height: 30,
                                              color: AppTheme.backgroundGrey,
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        selectedSeal['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(AddEditDocumentController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryOrange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtotal
          _buildSummaryRow(
            'ยอดรวม',
            controller.subtotal.toStringAsFixed(2),
            '฿',
          ),
          const SizedBox(height: 16),

          // End-of-bill discount checkbox
          _buildCheckboxField(
            label: 'ส่วนลดท้ายบิล',
            value: controller.isEndOfBillDiscountEnabled,
            onChanged: controller.onEndOfBillDiscountEnabledChanged,
          ),
          const SizedBox(height: 12),

          // End-of-bill discount input
          if (controller.isEndOfBillDiscountEnabled) ...[
            _buildTextField(
              label: 'จำนวนส่วนลด',
              hint: '0',
              controller: controller.endOfBillDiscountController,
              keyboardType: TextInputType.number,
              suffix: '฿',
              onChanged: (value) => controller.update(),
            ),
            const SizedBox(height: 12),
            
            // After End-of-bill discount
            _buildSummaryRow(
              'ยอดรวมหลังหักส่วนลด',
              controller.afterDiscount.toStringAsFixed(2),
              '฿',
            ),
            const SizedBox(height: 16),
          ],

          // VAT Checkbox
          _buildCheckboxField(
            label: 'ภาษีมูลค่าเพิ่ม (7%)',
            value: controller.isVatEnabled,
            onChanged: controller.onVatEnabledChanged,
          ),
          const SizedBox(height: 12),

          // VAT Amount
          if (controller.isVatEnabled) ...[
            _buildSummaryRow(
              'ภาษีมูลค่าเพิ่ม',
              controller.vatAmount.toStringAsFixed(2),
              '฿',
            ),
            const SizedBox(height: 12),
          ],

          // After VAT
          if (controller.isVatEnabled) ...[
            _buildSummaryRow(
              'ยอดรวมหลังหักภาษี',
              controller.afterVat.toStringAsFixed(2),
              '฿',
            ),
            const SizedBox(height: 16),
          ],

          // Withholding Tax
          _buildCheckboxField(
            label: 'หักภาษี ณ ที่จ่าย',
            value: controller.isWhtEnabled,
            onChanged: controller.onWhtEnabledChanged,
          ),
          const SizedBox(height: 12),

          // WHT Percentage and Amount
          if (controller.isWhtEnabled) ...[
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    label: 'เปอร์เซ็นต์',
                    hint: '3',
                    controller: controller.whtPercentageController,
                    keyboardType: TextInputType.number,
                    suffix: '%',
                    onChanged: (value) => controller.update(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildSummaryRow(
                    'หักภาษี ณ ที่จ่าย',
                    controller.whtAmount.toStringAsFixed(2),
                    '฿',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Net Total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryOrange),
            ),
            child: Row(
              children: [
                const Text(
                  'ยอดรวมสุทธิ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '฿${controller.netTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefix,
    String? suffix,
    bool isRequired = false,
    bool isEnabled = true,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          enabled: isEnabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefix,
            suffixText: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryOrange),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?)? onChanged,
    bool isRequired = false,
    bool isEnabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: isEnabled ? onChanged : null,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryOrange),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String hint,
    required DateTime? value,
    required Function(DateTime?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: Get.context!,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              onChanged(date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderGrey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  value != null
                      ? '${value.day}/${value.month}/${value.year}'
                      : hint,
                  style: TextStyle(
                    color: value != null
                        ? AppTheme.textPrimary
                        : AppTheme.textGrey,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxField({
    required String label,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryOrange,
        ),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton({
    required String label,
    required String value,
    required String? groupValue,
    required Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: AppTheme.primaryOrange,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildMultiSelectField({
    required String label,
    required String hint,
    required List<String> selectedItems,
    required List<String> availableItems,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () =>
              _showMultiSelectDialog(availableItems, selectedItems, onChanged),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderGrey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, color: AppTheme.textSecondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selectedItems.isNotEmpty ? selectedItems.join(', ') : hint,
                    style: TextStyle(
                      color: selectedItems.isNotEmpty
                          ? AppTheme.textPrimary
                          : AppTheme.textGrey,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
              ],
            ),
          ),
        ),
        if (selectedItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: selectedItems.map((item) {
              return Chip(
                label: Text(item),
                backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: AppTheme.primaryOrange,
                  fontSize: 12,
                ),
                deleteIcon: const Icon(
                  Icons.close,
                  color: AppTheme.primaryOrange,
                  size: 16,
                ),
                onDeleted: () {
                  final newItems = List<String>.from(selectedItems)
                    ..remove(item);
                  onChanged(newItems);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, String currency) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const Spacer(),
        Text(
          '$currency$value',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  void _showMultiSelectDialog(
    List<String> availableItems,
    List<String> selectedItems,
    Function(List<String>) onChanged,
  ) {
    List<String> tempSelected = List.from(selectedItems);

    Get.dialog(
      AlertDialog(
        title: const Text('เลือกช่องทางการชำระเงิน'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: availableItems.map((item) {
                  return CheckboxListTile(
                    title: Text(item),
                    value: tempSelected.contains(item),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          tempSelected.add(item);
                        } else {
                          tempSelected.remove(item);
                        }
                      });
                    },
                    activeColor: AppTheme.primaryOrange,
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () {
              onChanged(tempSelected);
              Get.back();
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

     // Helper method to get status display name
   String _getStatusDisplayName(String status) {
     switch (status) {
       // Quotation statuses
       case 'DRAFT':
         return 'ร่าง (Draft)';
       case 'SENT':
         return 'ส่งแล้ว (Sent)';
       case 'PENDING_APPROVAL':
         return 'รอการอนุมัติ (Pending Approval)';
       case 'APPROVED':
         return 'อนุมัติแล้ว (Approved)';
       case 'REJECTED':
         return 'ปฏิเสธ (Rejected)';
       case 'VOID':
         return 'ยกเลิก (Void)';
       case 'INVOICED':
         return 'ออกใบแจ้งหนี้แล้ว (Invoiced)';
       case 'FULLY_PAID':
         return 'ชำระเงินครบแล้ว (Fully Paid)';
       // Invoice statuses
       case 'PARTIAL_PAID':
         return 'ชำระบางส่วน (Partial Paid)';
       case 'PAID':
         return 'ชำระแล้ว (Paid)';
       case 'OVERDUE':
         return 'เกินกำหนด (Overdue)';
       default:
         return 'ร่าง (Draft)';
     }
   }

   // Build document status section
   Widget _buildDocumentStatusSection(AddEditDocumentController controller) {
     return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: AppTheme.backgroundWhite,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: AppTheme.primaryOrange),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Text(
             'สถานะเอกสาร',
             style: const TextStyle(
               fontSize: 16,
               fontWeight: FontWeight.w600,
               color: AppTheme.textPrimary,
             ),
           ),
           const SizedBox(height: 12),
           DropdownButtonFormField<String>(
             value: controller.documentStatus,
             items: controller.availableStatuses.map((status) {
               return DropdownMenuItem(
                 value: status,
                 child: Text(_getStatusDisplayName(status)),
               );
             }).toList(),
             onChanged: controller.onDocumentStatusChanged,
             decoration: InputDecoration(
               hintText: 'เลือกสถานะเอกสาร',
               border: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(8),
                 borderSide: const BorderSide(color: AppTheme.borderGrey),
               ),
               enabledBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(8),
                 borderSide: const BorderSide(color: AppTheme.borderGrey),
               ),
               focusedBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(8),
                 borderSide: const BorderSide(color: AppTheme.primaryOrange),
               ),
               contentPadding: const EdgeInsets.symmetric(
                 horizontal: 12,
                 vertical: 12,
               ),
             ),
           ),
         ],
       ),
     );
   }

       void _showProductSelectionDialog(AddEditDocumentController controller) {
     // Use real product data from controller
     final availableProducts = controller.availableProducts;

    if (availableProducts.isEmpty) {
      Get.snackbar(
        'ข้อมูล',
        'ไม่พบสินค้าในระบบ กรุณาเพิ่มสินค้าก่อน',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Move tempSelected outside StatefulBuilder to persist selections
    List<Map<String, dynamic>> tempSelected = [];

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('เลือกสินค้าจากฐานข้อมูล'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'ค้นหาสินค้า...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      // TODO: Implement search functionality
                    },
                  ),
                  const SizedBox(height: 16),
                  // Product list
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableProducts.length,
                      itemBuilder: (context, index) {
                        final product = availableProducts[index];
                        final isSelected = tempSelected.any(
                          (p) => p['id'] == product['id'],
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryOrange.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryOrange
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              product['name']?.toString() ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.primaryOrange
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product['description']?.toString() ?? ''),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '฿${product['price']?.toString() ?? '0'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryOrange,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${product['unit']?.toString() ?? ''}',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'SKU: ${product['sku']?.toString() ?? ''}',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  tempSelected.add(product);
                                } else {
                                  tempSelected.removeWhere(
                                    (p) => p['id'] == product['id'],
                                  );
                                }
                              });
                            },
                            activeColor: AppTheme.primaryOrange,
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (tempSelected.isNotEmpty) {
                    controller.addProductsFromDatabase(tempSelected);
                    Navigator.of(
                      context,
                    ).pop(); // Use Navigator.pop instead of Get.back()
                  } else {
                    Get.snackbar(
                      'คำเตือน',
                      'กรุณาเลือกสินค้าอย่างน้อย 1 รายการ',
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                ),
                child: const Text('เพิ่มสินค้า'),
              ),
            ],
          );
        },
      ),
    );
  }
  //
  // Widget _buildSectionHeader(String title, IconData icon, String sectionKey) {
  //   final isExpanded = _sectionExpanded[sectionKey] ?? false;
  //   final isRequired = sectionKey == 'customer' || sectionKey == 'seller' || sectionKey == 'product';
  //   final isComplete = _isSectionComplete(sectionKey);
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: isComplete
  //           ? AppTheme.primaryOrange.withOpacity(0.1)
  //           : AppTheme.errorRed.withOpacity(0.1),
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: isComplete
  //             ? AppTheme.primaryOrange.withOpacity(0.3)
  //             : AppTheme.errorRed.withOpacity(0.3),
  //         width: 1,
  //       ),
  //     ),
  //     child: InkWell(
  //       onTap: () {
  //         setState(() {
  //           _sectionExpanded[sectionKey] = !isExpanded;
  //         });
  //       },
  //       borderRadius: BorderRadius.circular(12),
  //       child: Row(
  //         children: [
  //           Icon(
  //             icon,
  //             color: isComplete ? AppTheme.primaryOrange : AppTheme.errorRed,
  //             size: 20,
  //           ),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   title,
  //                   style: TextStyle(
  //                     color: isComplete
  //                         ? AppTheme.primaryOrange
  //                         : AppTheme.errorRed,
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w600,
  //                   ),
  //                 ),
  //                 if (isRequired && !isComplete)
  //                   Text(
  //                     'กรุณากรอกข้อมูลให้ครบถ้วน',
  //                     style: TextStyle(
  //                       color: AppTheme.errorRed,
  //                       fontSize: 12,
  //                       fontStyle: FontStyle.italic,
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),
  //           // Required field indicator
  //           if (isRequired)
  //             Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //               decoration: BoxDecoration(
  //                 color: isComplete
  //                     ? AppTheme.primaryOrange
  //                     : AppTheme.errorRed,
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Text(
  //                 isComplete ? '✓' : '!',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           const SizedBox(width: 8),
  //           Icon(
  //             isExpanded ? Icons.expand_less : Icons.expand_more,
  //             color: isComplete ? AppTheme.primaryOrange : AppTheme.errorRed,
  //             size: 24,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  //    // Check if section is complete based on required fields
  //  bool _isSectionComplete(String sectionKey) {
  //    final controller = Get.find<AddEditDocumentController>();

  //    switch (sectionKey) {
  //      case 'status':
  //        return controller.documentStatus.isNotEmpty; // Status is always complete if set
  //      case 'customer':
  //        return controller.selectedCustomerId != null &&
  //            controller.selectedCustomerId!.isNotEmpty;
  //      case 'seller':
  //        return controller.selectedSellerIds.isNotEmpty;
  //      case 'product':
  //        final controller = Get.find<AddEditDocumentController>();
  //        return _areAllProductsComplete(
  //          controller,
  //        ); // Check if all products are complete
  //      case 'more':
  //        return true; // Optional section
  //      case 'summary':
  //        return true; // Calculated section
  //      default:
  //        return true;
  //    }
  //  }
  // // Check if all required fields are complete
  // bool _areRequiredFieldsComplete() {
  //         final controller = Get.find<AddEditDocumentController>();
  //     return _isSectionComplete('customer') &&
  //         _isSectionComplete('seller') &&
  //         _areAllProductsComplete(controller);
  // }

  // // Check if the last product has all required fields filled
  // bool _isLastProductComplete(AddEditDocumentController controller) {
  //   if (controller.products.isEmpty) return true;

  //   final lastIndex = controller.products.length - 1;
  //   final product = controller.products[lastIndex];
  //   final productId = product['id'];

  //   // Get controllers for the last product
  //   final nameController = controller.getProductController(lastIndex, 'name');
  //   final quantityController = controller.getProductController(
  //     lastIndex,
  //     'quantity',
  //   );
  //   final unitController = controller.getProductController(lastIndex, 'unit');
  //   final priceController = controller.getProductController(
  //     lastIndex,
  //     'pricePerUnit',
  //   );
  //   // Check if all required fields are filled
  //   final name = nameController.text.trim();
  //   final quantity = quantityController.text.trim();
  //   final unit = unitController.text.trim();
  //   final price = priceController.text.trim();

  //   if (name.isEmpty || quantity.isEmpty || unit.isEmpty || price.isEmpty) {
  //     return false;
  //   }

  //   // Check if quantity and price are valid numbers
  //   final quantityValue = double.tryParse(quantity);
  //   final priceValue = double.tryParse(price);

  //   if (quantityValue == null ||
  //       priceValue == null ||
  //       quantityValue <= 0 ||
  //       priceValue < 0) {
  //     return false;
  //   }

  //   return true;
  // }

  // // Check if all products have required fields filled
  // bool _areAllProductsComplete(AddEditDocumentController controller) {
  //   if (controller.products.isEmpty) return true;

  //   for (int i = 0; i < controller.products.length; i++) {
  //     final product = controller.products[i];
  //     final productId = product['id'];

  //     // Get controllers for this product
  //     final nameController = controller.getProductController(i, 'name');
  //     final quantityController = controller.getProductController(i, 'quantity');
  //     final unitController = controller.getProductController(i, 'unit');
  //     final priceController = controller.getProductController(
  //       i,
  //       'pricePerUnit',
  //     );
  //     // Check if all required fields are filled
  //     final name = nameController.text.trim();
  //     final quantity = quantityController.text.trim();
  //     final unit = unitController.text.trim();
  //     final price = priceController.text.trim();

  //     if (name.isEmpty || quantity.isEmpty || unit.isEmpty || price.isEmpty) {
  //       return false;
  //     }

  //     // Check if quantity and price are valid numbers
  //     final quantityValue = double.tryParse(quantity);
  //     final priceValue = double.tryParse(price);

  //     if (quantityValue == null ||
  //         priceValue == null ||
  //         quantityValue <= 0 ||
  //         priceValue < 0) {
  //       return false;
  //     }
  //   }

  //   return true;
  // }

  // Widget _buildCustomerSection(AddEditDocumentController controller) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppTheme.backgroundWhite,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppTheme.borderGrey),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Customer Section Header with Refresh Button
  //         Row(
  //           children: [
  //             Expanded(
  //               child: Text(
  //                 'ข้อมูลลูกค้า',
  //                 style: const TextStyle(
  //                   fontSize: 16,
  //                   fontWeight: FontWeight.w600,
  //                   color: AppTheme.textPrimary,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         // Customer Selection
  //         if (controller.isLoadingCustomers &&
  //             controller.customers.isEmpty) ...[
  //           const Center(
  //             child: Padding(
  //               padding: EdgeInsets.all(16.0),
  //               child: Column(
  //                 children: [
  //                   CircularProgressIndicator(
  //                     valueColor: AlwaysStoppedAnimation<Color>(
  //                       AppTheme.primaryOrange,
  //                     ),
  //                   ),
  //                   SizedBox(height: 8),
  //                   Text(
  //                     'กำลังโหลดรายชื่อลูกค้า...',
  //                     style: TextStyle(
  //                       color: AppTheme.textSecondary,
  //                       fontSize: 14,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ] else if (controller.customers.isEmpty) ...[
  //           Container(
  //             padding: const EdgeInsets.all(16),
  //             decoration: BoxDecoration(
  //               color: AppTheme.backgroundGrey,
  //               borderRadius: BorderRadius.circular(8),
  //               border: Border.all(color: AppTheme.borderLightGrey),
  //             ),
  //             child: const Center(
  //               child: Column(
  //                 children: [
  //                   Icon(
  //                     Icons.person_off,
  //                     color: AppTheme.textSecondary,
  //                     size: 32,
  //                   ),
  //                   SizedBox(height: 8),
  //                   Text(
  //                     'ไม่พบลูกค้าในระบบ',
  //                     style: TextStyle(
  //                       color: AppTheme.textSecondary,
  //                       fontSize: 14,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                   ),
  //                   SizedBox(height: 4),
  //                   Text(
  //                     'กรุณาเพิ่มลูกค้าในระบบก่อนสร้างใบเสนอราคา',
  //                     style: TextStyle(
  //                       color: AppTheme.textSecondary,
  //                       fontSize: 12,
  //                     ),
  //                     textAlign: TextAlign.center,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ] else ...[
  //           _buildDropdownField(
  //             label: 'เลือกลูกค้า *',
  //             hint: 'เลือกลูกค้าจากฐานข้อมูล',
  //             value: controller.selectedCustomerId,
  //             items: controller.customers.map((customer) {
  //               return DropdownMenuItem<String>(
  //                 value: customer.id,
  //                 child: Text(controller.getCustomerDisplayName(customer)),
  //               );
  //             }).toList(),
  //             onChanged: (value) => controller.onCustomerChanged(value),
  //             isRequired: true,
  //           ),
  //         ],
  //         const SizedBox(height: 16),
  //         // Customer Company Selection
  //         if (controller.selectedCustomer != null &&
  //             controller.selectedCustomer!.companyNames.isNotEmpty) ...[
  //           _buildDropdownField(
  //             label: 'บริษัทลูกค้า',
  //             hint: 'เลือกบริษัท',
  //             value: controller.selectedCompanyId,
  //             items: controller.selectedCustomer!.companyNames
  //                 .map((company) {
  //                   final companyId = company['id'] as String?;
  //                   if (companyId != null) {
  //                     return DropdownMenuItem<String>(
  //                       value: companyId,
  //                       child: Text(controller.getCompanyDisplayName(company)),
  //                     );
  //                   }
  //                   return DropdownMenuItem<String>(
  //                     value: '',
  //                     child: Text('Unknown Company'),
  //                   );
  //                 })
  //                 .where((item) => item.value!.isNotEmpty)
  //                 .toList(),
  //             onChanged: controller.onCompanyChanged,
  //           ),
  //           const SizedBox(height: 16),
  //         ],
  //         // Customer Address
  //         _buildTextField(
  //           label: 'ที่อยู่ลูกค้า',
  //           hint: 'กรอกที่อยู่ลูกค้า',
  //           controller: controller.customerAddressController,
  //           maxLines: 3,
  //         ),
  //         const SizedBox(height: 16),
  //         // Postal Code
  //         _buildTextField(
  //           label: 'รหัสไปรษณีย์',
  //           hint: 'กรอกรหัสไปรษณีย์',
  //           controller: controller.customerPostalCodeController,
  //           keyboardType: TextInputType.number,
  //         ),
  //         const SizedBox(height: 16),
  //         // National ID
  //         _buildTextField(
  //           label: 'เลขประจำตัวประชาชน',
  //           hint: 'กรอกเลขประจำตัวประชาชน',
  //           controller: controller.customerNationalIdController,
  //           keyboardType: TextInputType.number,
  //         ),
  //         const SizedBox(height: 16),
  //         // Phone
  //         _buildTextField(
  //           label: 'เบอร์โทรศัพท์',
  //           hint: 'กรอกเบอร์โทรศัพท์',
  //           controller: controller.customerPhoneController,
  //           keyboardType: TextInputType.phone,
  //         ),
  //         const SizedBox(height: 16),
  //         // Email
  //         _buildTextField(
  //           label: 'อีเมล',
  //           hint: 'กรอกอีเมล',
  //           controller: controller.customerEmailController,
  //           keyboardType: TextInputType.emailAddress,
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // Widget _buildSellerSection(AddEditDocumentController controller) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppTheme.backgroundWhite,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppTheme.borderGrey),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Seller/Assignee Selection
  //         AssigneesInputField(
  //           selectedAssignees: controller.selectedSellerIds,
  //           availableMembers: controller.availableAssignees,
  //           onAssigneesChanged: controller.onSellerAssigneesChanged,
  //           label: 'ผู้ขาย/ผู้รับผิดชอบ *',
  //           hintText: 'เลือกผู้ขายจากรายชื่อผู้รับผิดชอบ',
  //           isLoading: controller.isLoadingAssignees,
  //           allowMultipleSelection: false, // Single selection for seller
  //           showBorder: false,
  //         ),
  //         const SizedBox(height: 16),
  //         // Job Name
  //         _buildTextField(
  //           label: 'ชื่องาน',
  //           hint: 'กรอกชื่องาน',
  //           controller: controller.jobNameController,
  //         ),
  //         const SizedBox(height: 16),
  //         // Ref ID
  //         _buildTextField(
  //           label: 'รหัสอ้างอิง',
  //           hint: 'กรอกรหัสอ้างอิง',
  //           controller: controller.refIdController,
  //         ),
  //         const SizedBox(height: 16),
  //         // Document Date
  //         _buildDateField(
  //           label: 'วันที่ออกเอกสาร',
  //           hint: 'เลือกวันที่ออกเอกสาร',
  //           value: controller.documentDate,
  //           onChanged: controller.onDocumentDateChanged,
  //         ),
  //         const SizedBox(height: 16),
  //         // Valid Until Date
  //         _buildDateField(
  //           label: 'ยืนราคาถึงวันที่',
  //           hint: 'เลือกวันที่ยืนราคาถึง',
  //           value: controller.validUntilDate,
  //           onChanged: controller.onValidUntilDateChanged,
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // Widget _buildProductSection(AddEditDocumentController controller) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppTheme.backgroundWhite,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppTheme.borderGrey),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Product Selection Buttons
  //         Row(
  //           children: [
  //             Expanded(
  //               child: ElevatedButton.icon(
  //                 onPressed: controller.isLoadingProducts
  //                     ? null
  //                     : () => _showProductSelectionDialog(controller),
  //                 icon: controller.isLoadingProducts
  //                     ? const SizedBox(
  //                         width: 16,
  //                         height: 16,
  //                         child: CircularProgressIndicator(
  //                           strokeWidth: 2,
  //                           valueColor: AlwaysStoppedAnimation<Color>(
  //                             Colors.white,
  //                           ),
  //                         ),
  //                       )
  //                     : const Icon(Icons.storage, color: Colors.white),
  //                 label: Text(
  //                   controller.isLoadingProducts
  //                       ? 'กำลังโหลด...'
  //                       : 'เลือกจากฐานข้อมูล',
  //                   style: const TextStyle(color: Colors.white),
  //                 ),
  //                 style: ElevatedButton.styleFrom(
  //                   backgroundColor: AppTheme.primaryOrange,
  //                   padding: const EdgeInsets.symmetric(vertical: 12),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: OutlinedButton.icon(
  //                 onPressed:
  //                     controller.products.isEmpty ||
  //                         _isLastProductComplete(controller)
  //                     ? controller.addProduct
  //                     : null,
  //                 icon: Icon(
  //                   Icons.add,
  //                   color:
  //                       controller.products.isEmpty ||
  //                           _isLastProductComplete(controller)
  //                       ? AppTheme.primaryOrange
  //                       : AppTheme.textGrey,
  //                 ),
  //                 label: Text(
  //                   'เพิ่มใหม่',
  //                   style: TextStyle(
  //                     color:
  //                         controller.products.isEmpty ||
  //                             _isLastProductComplete(controller)
  //                         ? AppTheme.primaryOrange
  //                         : AppTheme.textGrey,
  //                   ),
  //                 ),
  //                 style: OutlinedButton.styleFrom(
  //                   side: BorderSide(
  //                     color:
  //                         controller.products.isEmpty ||
  //                             _isLastProductComplete(controller)
  //                         ? AppTheme.primaryOrange
  //                         : AppTheme.textGrey,
  //                   ),
  //                   padding: const EdgeInsets.symmetric(vertical: 12),
  //                   shape: RoundedRectangleBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         // Product List
  //         if (controller.products.isNotEmpty) ...[
  //           ...controller.products.asMap().entries.map((entry) {
  //             final index = entry.key;
  //             final product = entry.value;
  //             return _buildProductItem(controller, index, product);
  //           }).toList(),
  //           const SizedBox(height: 16),
  //         ],
  //         // Help message for product requirements
  //         if (controller.products.isNotEmpty &&
  //             !_isLastProductComplete(controller))
  //           Container(
  //             margin: const EdgeInsets.only(bottom: 12),
  //             padding: const EdgeInsets.all(8),
  //             decoration: BoxDecoration(
  //               color: AppTheme.errorRed.withOpacity(0.1),
  //               borderRadius: BorderRadius.circular(8),
  //               border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
  //             ),
  //             child: Row(
  //               children: [
  //                 Icon(Icons.info_outline, color: AppTheme.errorRed, size: 16),
  //                 const SizedBox(width: 8),
  //                 Expanded(
  //                   child: Text(
  //                     'กรุณากรอกข้อมูลสินค้าปัจจุบันให้ครบถ้วน (ชื่อ, จำนวน, หน่วย, ราคา) ก่อนเพิ่มสินค้าใหม่',
  //                     style: TextStyle(color: AppTheme.errorRed, fontSize: 12),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // }
  // Widget _buildProductItem(
  //   AddEditDocumentController controller,
  //   int index,
  //   Map<String, dynamic> product,
  // ) {
  //   return Container(
  //     margin: const EdgeInsets.only(bottom: 16),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppTheme.backgroundGrey,
  //       borderRadius: BorderRadius.circular(8),
  //       border: Border.all(color: AppTheme.borderLightGrey),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             Text(
  //               'รายการที่ ${index + 1}',
  //               style: const TextStyle(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w600,
  //                 color: AppTheme.textPrimary,
  //               ),
  //             ),
  //             const Spacer(),
  //             IconButton(
  //               onPressed: () => controller.removeProduct(index),
  //               icon: const Icon(
  //                 Icons.delete,
  //                 color: AppTheme.errorRed,
  //                 size: 20,
  //               ),
  //               padding: EdgeInsets.zero,
  //               constraints: const BoxConstraints(),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         // Product Name
  //         _buildTextField(
  //           label: 'ชื่อสินค้า/บริการ *',
  //           hint: 'กรอกชื่อสินค้า/บริการ',
  //           controller: controller.getProductController(index, 'name'),
  //           isRequired: true,
  //         ),
  //         const SizedBox(height: 12),
  //         // Description
  //         _buildTextField(
  //           label: 'รายละเอียด',
  //           hint: 'กรอกรายละเอียดสินค้า/บริการ',
  //           controller: controller.getProductController(index, 'description'),
  //           maxLines: 2,
  //         ),
  //         const SizedBox(height: 12),
  //         // Quantity and Unit
  //         Row(
  //           children: [
  //             Expanded(
  //               flex: 2,
  //               child: _buildTextField(
  //                 label: 'จำนวน *',
  //                 hint: '0',
  //                 controller: controller.getProductController(
  //                   index,
  //                   'quantity',
  //                 ),
  //                 keyboardType: TextInputType.number,
  //                 isRequired: true,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               flex: 1,
  //               child: _buildTextField(
  //                 label: 'หน่วย *',
  //                 hint: 'ชิ้น',
  //                 controller: controller.getProductController(index, 'unit'),
  //                 isRequired: true,
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 12),
  //         // Price and Discount
  //         Row(
  //           children: [
  //             Expanded(
  //               flex: 2,
  //               child: _buildTextField(
  //                 label: 'ราคาต่อหน่วย *',
  //                 hint: '0.00',
  //                 controller: controller.getProductController(
  //                   index,
  //                   'pricePerUnit',
  //                 ),
  //                 keyboardType: TextInputType.number,
  //                 prefix: '฿',
  //                 isRequired: true,
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               flex: 1,
  //               child: _buildTextField(
  //                 label: 'ส่วนลด',
  //                 hint: '0.00',
  //                 controller: controller.getProductController(
  //                   index,
  //                   'discount',
  //                 ),
  //                 keyboardType: TextInputType.number,
  //                 prefix: '฿',
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // Widget _buildMoreOptionsSection(AddEditDocumentController controller) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppTheme.backgroundWhite,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppTheme.borderGrey),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Payment Methods
  //         _buildMultiSelectField(
  //           label: 'ช่องทางการชำระเงิน',
  //           hint: 'เลือกช่องทางการชำระเงิน',
  //           selectedItems: controller.selectedPaymentMethods,
  //           availableItems: controller.availablePaymentMethods,
  //           onChanged: controller.onPaymentMethodsChanged,
  //         ),
  //         const SizedBox(height: 16),
  //         // Notes
  //         _buildTextField(
  //           label: 'หมายเหตุ',
  //           hint: 'กรอกหมายเหตุเพิ่มเติม',
  //           controller: controller.notesController,
  //           maxLines: 3,
  //         ),
  //         const SizedBox(height: 16),
  //         // Signature and Stamp
  //         _buildCheckboxField(
  //           label: 'ลายเซ็นและตรายาง',
  //           value: controller.includeSignature,
  //           onChanged: controller.onIncludeSignatureChanged,
  //         ),
  //         const SizedBox(height: 16),
  //         // Company Stamp (Coming Soon)
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: AppTheme.backgroundGrey,
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: AppTheme.borderLightGrey),
  //           ),
  //           child: Row(
  //             children: [
  //               Icon(
  //                 Icons.info_outline,
  //                 color: AppTheme.textSecondary,
  //                 size: 20,
  //               ),
  //               const SizedBox(width: 8),
  //               Expanded(
  //                 child: Text(
  //                   'ตรายางบริษัท (Coming Soon)',
  //                   style: TextStyle(
  //                     color: AppTheme.textSecondary,
  //                     fontSize: 14,
  //                     fontStyle: FontStyle.italic,
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }



  // Widget _buildSummarySection(AddEditDocumentController controller) {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: AppTheme.backgroundWhite,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: AppTheme.primaryOrange),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         // Subtotal
  //         _buildSummaryRow(
  //           'ยอดรวม',
  //           controller.subtotal.toStringAsFixed(2),
  //           '฿',
  //         ),
  //         const SizedBox(height: 12),
  //         // Discount
  //         _buildSummaryRow(
  //           'ส่วนลด',
  //           controller.totalDiscount.toStringAsFixed(2),
  //           '฿',
  //         ),
  //         const SizedBox(height: 12),
  //         // After Discount
  //         _buildSummaryRow(
  //           'ยอดรวมหลังหักส่วนลด',
  //           controller.afterDiscount.toStringAsFixed(2),
  //           '฿',
  //         ),
  //         const SizedBox(height: 16),
  //         // VAT Checkbox
  //         _buildCheckboxField(
  //           label: 'ภาษีมูลค่าเพิ่ม (7%)',
  //           value: controller.isVatEnabled,
  //           onChanged: controller.onVatEnabledChanged,
  //         ),
  //         const SizedBox(height: 12),
  //         // VAT Amount
  //         if (controller.isVatEnabled) ...[
  //           _buildSummaryRow(
  //             'ภาษีมูลค่าเพิ่ม',
  //             controller.vatAmount.toStringAsFixed(2),
  //             '฿',
  //           ),
  //           const SizedBox(height: 12),
  //         ],
  //         // After VAT
  //         if (controller.isVatEnabled) ...[
  //           _buildSummaryRow(
  //             'ยอดรวมหลังหักภาษี',
  //             controller.afterVat.toStringAsFixed(2),
  //             '฿',
  //           ),
  //           const SizedBox(height: 16),
  //         ],
  //         // Withholding Tax
  //         _buildCheckboxField(
  //           label: 'หักภาษี ณ ที่จ่าย',
  //           value: controller.isWhtEnabled,
  //           onChanged: controller.onWhtEnabledChanged,
  //         ),
  //         const SizedBox(height: 12),
  //         // WHT Percentage and Amount
  //         if (controller.isWhtEnabled) ...[
  //           Row(
  //             children: [
  //               Expanded(
  //                 flex: 2,
  //                 child: _buildTextField(
  //                   label: 'เปอร์เซ็นต์',
  //                   hint: '3',
  //                   controller: controller.whtPercentageController,
  //                   keyboardType: TextInputType.number,
  //                   suffix: '%',
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               Expanded(
  //                 flex: 3,
  //                 child: _buildSummaryRow(
  //                   'หักภาษี ณ ที่จ่าย',
  //                   controller.whtAmount.toStringAsFixed(2),
  //                   '฿',
  //                 ),
  //               ),
  //             ],
  //           ),
  //           const SizedBox(height: 12),
  //         ],
  //         // Net Total
  //         Container(
  //           padding: const EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: AppTheme.primaryOrange.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: AppTheme.primaryOrange),
  //           ),
  //           child: Row(
  //             children: [
  //               const Text(
  //                 'ยอดรวมสุทธิ',
  //                 style: TextStyle(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.w600,
  //                   color: AppTheme.textPrimary,
  //                 ),
  //               ),
  //               const Spacer(),
  //               Text(
  //                 '฿${controller.netTotal.toStringAsFixed(2)}',
  //                 style: const TextStyle(
  //                   fontSize: 24,
  //                   fontWeight: FontWeight.bold,
  //                   color: AppTheme.primaryOrange,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  // Widget _buildTextField({
  //   required String label,
  //   required String hint,
  //   required TextEditingController controller,
  //   int maxLines = 1,
  //   TextInputType? keyboardType,
  //   String? prefix,
  //   String? suffix,
  //   bool isRequired = false,
  //   Function(String)? onChanged,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.w500,
  //           color: AppTheme.textPrimary,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       TextField(
  //         controller: controller,
  //         maxLines: maxLines,
  //         keyboardType: keyboardType,
  //         onChanged: onChanged,
  //         decoration: InputDecoration(
  //           hintText: hint,
  //           prefixText: prefix,
  //           suffixText: suffix,
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: const BorderSide(color: AppTheme.borderGrey),
  //           ),
  //           enabledBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: const BorderSide(color: AppTheme.borderGrey),
  //           ),
  //           focusedBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: const BorderSide(color: AppTheme.primaryOrange),
  //           ),
  //           contentPadding: const EdgeInsets.symmetric(
  //             horizontal: 12,
  //             vertical: 12,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  // Widget _buildDropdownField({
  //   required String label,
  //   required String hint,
  //   required String? value,
  //   required List<DropdownMenuItem<String>> items,
  //   required Function(String?)? onChanged,
  //   bool isRequired = false,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.w500,
  //           color: AppTheme.textPrimary,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       DropdownButtonFormField<String>(
  //         value: value,
  //         items: items,
  //         onChanged: onChanged,
  //         decoration: InputDecoration(
  //           hintText: hint,
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: const BorderSide(color: AppTheme.borderGrey),
  //           ),
  //           enabledBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: const BorderSide(color: AppTheme.borderGrey),
  //           ),
  //           focusedBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(8),
  //             borderSide: const BorderSide(color: AppTheme.primaryOrange),
  //           ),
  //           contentPadding: const EdgeInsets.symmetric(
  //             horizontal: 12,
  //             vertical: 12,
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  // Widget _buildDateField({
  //   required String label,
  //   required String hint,
  //   required DateTime? value,
  //   required Function(DateTime?) onChanged,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.w500,
  //           color: AppTheme.textPrimary,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       InkWell(
  //         onTap: () async {
  //           final date = await showDatePicker(
  //             context: Get.context!,
  //             initialDate: value ?? DateTime.now(),
  //             firstDate: DateTime(2020),
  //             lastDate: DateTime(2030),
  //           );
  //           if (date != null) {
  //             onChanged(date);
  //           }
  //         },
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //           decoration: BoxDecoration(
  //             border: Border.all(color: AppTheme.borderGrey),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Row(
  //             children: [
  //               Icon(
  //                 Icons.calendar_today,
  //                 color: AppTheme.textSecondary,
  //                 size: 20,
  //               ),
  //               const SizedBox(width: 8),
  //               Text(
  //                 value != null
  //                     ? '${value.day}/${value.month}/${value.year}'
  //                     : hint,
  //                 style: TextStyle(
  //                   color: value != null
  //                       ? AppTheme.textPrimary
  //                       : AppTheme.textGrey,
  //                   fontSize: 14,
  //                 ),
  //               ),
  //               const Spacer(),
  //               Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  // Widget _buildCheckboxField({
  //   required String label,
  //   required bool value,
  //   required Function(bool?) onChanged,
  // }) {
  //   return Row(
  //     children: [
  //       Checkbox(
  //         value: value,
  //         onChanged: onChanged,
  //         activeColor: AppTheme.primaryOrange,
  //       ),
  //       Expanded(
  //         child: Text(
  //           label,
  //           style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
  //         ),
  //       ),
  //     ],
  //   );
  // }
  // Widget _buildRadioButton({
  //   required String label,
  //   required String value,
  //   required String? groupValue,
  //   required Function(String?) onChanged,
  // }) {
  //   return Row(
  //     children: [
  //       Radio<String>(
  //         value: value,
  //         groupValue: groupValue,
  //         onChanged: onChanged,
  //         activeColor: AppTheme.primaryOrange,
  //       ),
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
  //       ),
  //     ],
  //   );
  // }
  // Widget _buildMultiSelectField({
  //   required String label,
  //   required String hint,
  //   required List<String> selectedItems,
  //   required List<String> availableItems,
  //   required Function(List<String>) onChanged,
  // }) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.w500,
  //           color: AppTheme.textPrimary,
  //         ),
  //       ),
  //       const SizedBox(height: 8),
  //       InkWell(
  //         onTap: () =>
  //             _showMultiSelectDialog(availableItems, selectedItems, onChanged),
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  //           decoration: BoxDecoration(
  //             border: Border.all(color: AppTheme.borderGrey),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Row(
  //             children: [
  //               Icon(Icons.payment, color: AppTheme.textSecondary, size: 20),
  //               const SizedBox(width: 8),
  //               Expanded(
  //                 child: Text(
  //                   selectedItems.isNotEmpty ? selectedItems.join(', ') : hint,
  //                   style: TextStyle(
  //                     color: selectedItems.isNotEmpty
  //                         ? AppTheme.textPrimary
  //                         : AppTheme.textGrey,
  //                     fontSize: 14,
  //                   ),
  //                 ),
  //               ),
  //               Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
  //             ],
  //           ),
  //         ),
  //       ),
  //       if (selectedItems.isNotEmpty) ...[
  //         const SizedBox(height: 8),
  //         Wrap(
  //           spacing: 8,
  //           children: selectedItems.map((item) {
  //             return Chip(
  //               label: Text(item),
  //               backgroundColor: AppTheme.primaryOrange.withOpacity(0.1),
  //               labelStyle: const TextStyle(
  //                 color: AppTheme.primaryOrange,
  //                 fontSize: 12,
  //               ),
  //               deleteIcon: const Icon(
  //                 Icons.close,
  //                 color: AppTheme.primaryOrange,
  //                 size: 16,
  //               ),
  //               onDeleted: () {
  //                 final newItems = List<String>.from(selectedItems)
  //                   ..remove(item);
  //                 onChanged(newItems);
  //               },
  //             );
  //           }).toList(),
  //         ),
  //       ],
  //     ],
  //   );
  // }
  // Widget _buildSummaryRow(String label, String value, String currency) {
  //   return Row(
  //     children: [
  //       Text(
  //         label,
  //         style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
  //       ),
  //       const Spacer(),
  //       Text(
  //         '$currency$value',
  //         style: const TextStyle(
  //           fontSize: 16,
  //           fontWeight: FontWeight.w600,
  //           color: AppTheme.textPrimary,
  //         ),
  //       ),
  //     ],
  //   );
  // }
  // void _showMultiSelectDialog(
  //   List<String> availableItems,
  //   List<String> selectedItems,
  //   Function(List<String>) onChanged,
  // ) {
  //   List<String> tempSelected = List.from(selectedItems);
  //   Get.dialog(
  //     AlertDialog(
  //       title: const Text('เลือกช่องทางการชำระเงิน'),
  //       content: StatefulBuilder(
  //         builder: (BuildContext context, StateSetter setState) {
  //           return SizedBox(
  //             width: double.maxFinite,
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: availableItems.map((item) {
  //                 return CheckboxListTile(
  //                   title: Text(item),
  //                   value: tempSelected.contains(item),
  //                   onChanged: (bool? value) {
  //                     setState(() {
  //                       if (value == true) {
  //                         tempSelected.add(item);
  //                       } else {
  //                         tempSelected.remove(item);
  //                       }
  //                     });
  //                   },
  //                   activeColor: AppTheme.primaryOrange,
  //                 );
  //               }).toList(),
  //             ),
  //           );
  //         },
  //       ),
  //       actions: [
  //         TextButton(onPressed: () => Get.back(), child: const Text('ยกเลิก')),
  //         ElevatedButton(
  //           onPressed: () {
  //             onChanged(tempSelected);
  //             Get.back();
  //           },
  //           child: const Text('ยืนยัน'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  //    // Helper method to get status display name
  //  String _getStatusDisplayName(String status) {
  //    switch (status) {
  //      // Quotation statuses
  //      case 'DRAFT':
  //        return 'ร่าง (Draft)';
  //      case 'SENT':
  //        return 'ส่งแล้ว (Sent)';
  //      case 'PENDING_APPROVAL':
  //        return 'รอการอนุมัติ (Pending Approval)';
  //      case 'APPROVED':
  //        return 'อนุมัติแล้ว (Approved)';
  //      case 'REJECTED':
  //        return 'ปฏิเสธ (Rejected)';
  //      case 'VOID':
  //        return 'ยกเลิก (Void)';
  //      case 'INVOICED':
  //        return 'ออกใบแจ้งหนี้แล้ว (Invoiced)';
  //      case 'FULLY_PAID':
  //        return 'ชำระเงินครบแล้ว (Fully Paid)';
  //      // Invoice statuses
  //      case 'PARTIAL_PAID':
  //        return 'ชำระบางส่วน (Partial Paid)';
  //      case 'PAID':
  //        return 'ชำระแล้ว (Paid)';
  //      case 'OVERDUE':
  //        return 'เกินกำหนด (Overdue)';
  //      default:
  //        return 'ร่าง (Draft)';
  //    }
  //  }
  //  // Build document status section
  //  Widget _buildDocumentStatusSection(AddEditDocumentController controller) {
  //    return Container(
  //      padding: const EdgeInsets.all(16),
  //      decoration: BoxDecoration(
  //        color: AppTheme.backgroundWhite,
  //        borderRadius: BorderRadius.circular(12),
  //        border: Border.all(color: AppTheme.primaryOrange),
  //      ),
  //      child: Column(
  //        crossAxisAlignment: CrossAxisAlignment.start,
  //        children: [
  //          Text(
  //            'สถานะเอกสาร',
  //            style: const TextStyle(
  //              fontSize: 16,
  //              fontWeight: FontWeight.w600,
  //              color: AppTheme.textPrimary,
  //            ),
  //          ),
  //          const SizedBox(height: 12),
  //          DropdownButtonFormField<String>(
  //            value: controller.documentStatus,
  //            items: controller.availableStatuses.map((status) {
  //              return DropdownMenuItem(
  //                value: status,
  //                child: Text(_getStatusDisplayName(status)),
  //              );
  //            }).toList(),
  //            onChanged: controller.onDocumentStatusChanged,
  //            decoration: InputDecoration(
  //              hintText: 'เลือกสถานะเอกสาร',
  //              border: OutlineInputBorder(
  //                borderRadius: BorderRadius.circular(8),
  //                borderSide: const BorderSide(color: AppTheme.borderGrey),
  //              ),
  //              enabledBorder: OutlineInputBorder(
  //                borderRadius: BorderRadius.circular(8),
  //                borderSide: const BorderSide(color: AppTheme.borderGrey),
  //              ),
  //              focusedBorder: OutlineInputBorder(
  //                borderRadius: BorderRadius.circular(8),
  //                borderSide: const BorderSide(color: AppTheme.primaryOrange),
  //              ),
  //              contentPadding: const EdgeInsets.symmetric(
  //                horizontal: 12,
  //                vertical: 12,
  //              ),
  //            ),
  //          ),
  //        ],
  //      ),
  //    );
  //  }

  //      void _showProductSelectionDialog(AddEditDocumentController controller) {
  //    // Use real product data from controller
  //    final availableProducts = controller.availableProducts;

  //   if (availableProducts.isEmpty) {
  //     Get.snackbar(
  //       'ข้อมูล',
  //       'ไม่พบสินค้าในระบบ กรุณาเพิ่มสินค้าก่อน',
  //       backgroundColor: Colors.orange,
  //       colorText: Colors.white,
  //     );
  //     return;
  //   }

  //   // Move tempSelected outside StatefulBuilder to persist selections
  //   List<Map<String, dynamic>> tempSelected = [];

  //   Get.dialog(
  //     StatefulBuilder(
  //       builder: (context, setState) {
  //         return AlertDialog(
  //           title: const Text('เลือกสินค้าจากฐานข้อมูล'),
  //           content: SizedBox(
  //             width: double.maxFinite,
  //             height: 400,
  //             child: Column(
  //               children: [
  //                 // Search bar
  //                 TextField(
  //                   decoration: InputDecoration(
  //                     hintText: 'ค้นหาสินค้า...',
  //                     prefixIcon: const Icon(Icons.search),
  //                     border: OutlineInputBorder(
  //                       borderRadius: BorderRadius.circular(8),
  //                     ),
  //                   ),
  //                   onChanged: (value) {
  //                     // TODO: Implement search functionality
  //                   },
  //                 ),
  //                 const SizedBox(height: 16),
  //                 // Product list
  //                 Expanded(
  //                   child: ListView.builder(
  //                     itemCount: availableProducts.length,
  //                     itemBuilder: (context, index) {
  //                       final product = availableProducts[index];
  //                       final isSelected = tempSelected.any(
  //                         (p) => p['id'] == product['id'],
  //                       );
  //                       return Container(
  //                         margin: const EdgeInsets.only(bottom: 8),
  //                         decoration: BoxDecoration(
  //                           color: isSelected
  //                               ? AppTheme.primaryOrange.withOpacity(0.1)
  //                               : Colors.white,
  //                           borderRadius: BorderRadius.circular(8),
  //                           border: Border.all(
  //                             color: isSelected
  //                                 ? AppTheme.primaryOrange
  //                                 : Colors.grey.shade300,
  //                           ),
  //                         ),
  //                         child: CheckboxListTile(
  //                           title: Text(
  //                             product['name']?.toString() ?? '',
  //                             style: TextStyle(
  //                               fontWeight: FontWeight.w600,
  //                               color: isSelected
  //                                   ? AppTheme.primaryOrange
  //                                   : AppTheme.textPrimary,
  //                             ),
  //                           ),
  //                           subtitle: Column(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               Text(product['description']?.toString() ?? ''),
  //                               const SizedBox(height: 4),
  //                               Row(
  //                                 children: [
  //                                   Text(
  //                                     '฿${product['price']?.toString() ?? '0'}',
  //                                     style: const TextStyle(
  //                                       fontWeight: FontWeight.w600,
  //                                       color: AppTheme.primaryOrange,
  //                                     ),
  //                                   ),
  //                                   const SizedBox(width: 8),
  //                                   Text(
  //                                     '${product['unit']?.toString() ?? ''}',
  //                                     style: TextStyle(
  //                                       color: AppTheme.textSecondary,
  //                                     ),
  //                                   ),
  //                                   const SizedBox(width: 8),
  //                                   Text(
  //                                     'SKU: ${product['sku']?.toString() ?? ''}',
  //                                     style: TextStyle(
  //                                       color: AppTheme.textSecondary,
  //                                       fontSize: 12,
  //                                     ),
  //                                   ),
  //                                 ],
  //                               ),
  //                             ],
  //                           ),
  //                           value: isSelected,
  //                           onChanged: (bool? value) {
  //                             setState(() {
  //                               if (value == true) {
  //                                 tempSelected.add(product);
  //                               } else {
  //                                 tempSelected.removeWhere(
  //                                   (p) => p['id'] == product['id'],
  //                                 );
  //                               }
  //                             });
  //                           },
  //                           activeColor: AppTheme.primaryOrange,
  //                           controlAffinity: ListTileControlAffinity.leading,
  //                         ),
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child: const Text('ยกเลิก'),
  //             ),
  //             ElevatedButton(
  //               onPressed: () {
  //                 if (tempSelected.isNotEmpty) {
  //                   controller.addProductsFromDatabase(tempSelected);
  //                   Navigator.of(
  //                     context,
  //                   ).pop(); // Use Navigator.pop instead of Get.back()
  //                 } else {
  //                   Get.snackbar(
  //                     'คำเตือน',
  //                     'กรุณาเลือกสินค้าอย่างน้อย 1 รายการ',
  //                     backgroundColor: Colors.orange,
  //                     colorText: Colors.white,
  //                   );
  //                 }
  //               },
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: AppTheme.primaryOrange,
  //               ),
  //               child: const Text('เพิ่มสินค้า'),
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );
  // }
}
