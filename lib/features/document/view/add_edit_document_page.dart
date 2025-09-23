import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/assignees_input_field.dart';
import '../../../core/widgets/customers_input_field.dart';
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
    // Initialize controller once in initState to prevent recreation on rebuilds
    Get.put(AddEditDocumentController(
      documentId: widget.documentId,
      documentType: widget.documentType,
    ));
  }

  @override
  void dispose() {
    // Properly dispose the controller when the widget is destroyed
    try {
      if (Get.isRegistered<AddEditDocumentController>()) {
        Get.delete<AddEditDocumentController>();
      }
    } catch (e) {
      print('Error disposing controller: $e');
    }
    super.dispose();
  }

    @override
  Widget build(BuildContext context) {
    return GetBuilder<AddEditDocumentController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundGrey,
          appBar: AppBar(
            title: Text(
              widget.documentId == null
                  ? (widget.documentType == 'QT'
                        ? 'create_quotation'.tr
                        : widget.documentType == 'INV'
                        ? 'create_invoice'.tr
                        : 'create_receipt'.tr)
                  : (widget.documentType == 'QT'
                        ? 'edit_quotation'.tr
                        : widget.documentType == 'INV'
                        ? 'edit_invoice'.tr
                        : 'edit_receipt'.tr),
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
                tooltip: 'expand_all_sections'.tr,
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
                tooltip: 'collapse_all_sections'.tr,
              ),
                             GetBuilder<AddEditDocumentController>(
                 builder: (controller) {
                   return TextButton(
                     onPressed:
                         (controller.isLoading || !_areRequiredFieldsComplete(controller))
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
                            'save'.tr,
                            style: TextStyle(
                              color: _areRequiredFieldsComplete(controller)
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
                                'document_status_template'.tr,
                                Icons.settings,
                                'status_template',
                                controller,
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
                                            'document_status'.tr,
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
                                            'document_template'.tr,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<String>(
                                            value: _getValidTemplateValue(controller),
                                            items: _buildTemplateDropdownItems(controller),
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
                                 'customer_data'.tr,
                                 Icons.person,
                                 'customer',
                                 controller,
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
                                 'seller_data'.tr,
                                 Icons.business,
                                 'seller',
                                 controller,
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
                                 '${'product_service_list'.tr}',
                                 Icons.inventory,
                                 'product',
                                 controller,
                               ),
                               const SizedBox(height: 12),
                               if (_sectionExpanded['product'] ?? false) ...[
                                 _buildProductSection(controller, widget.documentId),
                                 const SizedBox(height: 24),
                               ],
                             ],
                           );
                         },
                                               ),

                       // More Options Section
                       _buildSectionHeader(
                         'additional_data'.tr,
                         Icons.settings,
                         'more',
                         controller,
                       ),
                      const SizedBox(height: 12),
                      if (_sectionExpanded['more'] ?? false) ...[
                        _buildMoreOptionsSection(controller),
                        const SizedBox(height: 24),
                      ],

                      // Summary Section
                      _buildSectionHeader(
                        'total_summary'.tr,
                        Icons.calculate,
                        'summary',
                        controller,
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

  // Helper method to get valid template value for dropdown
  String? _getValidTemplateValue(AddEditDocumentController controller) {
    final selectedId = controller.selectedTemplateId;
    
    // If no template is selected, return null
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    
    // Check if the selected template ID exists in available templates
    final templateExists = controller.availableTemplates
        .any((template) => template['id'] == selectedId);
    
    // Return the ID only if it exists in available templates
    return templateExists ? selectedId : null;
  }

  // Helper method to build template dropdown items without duplicates
  List<DropdownMenuItem<String>> _buildTemplateDropdownItems(AddEditDocumentController controller) {
    final items = <DropdownMenuItem<String>>[];
    
    // Add "None" option
    items.add(DropdownMenuItem<String>(
      value: null,
      child: Text('${'none_option'.tr} (None)'),
    ));
    
    // Add unique template items
    final addedIds = <String>{};
    for (final template in controller.availableTemplates) {
      final id = template['id']?.toString();
      final name = template['name']?.toString() ?? 'Unknown Template';
      
      // Skip if ID is null or already added
      if (id == null || addedIds.contains(id)) {
        continue;
      }
      
      addedIds.add(id);
      items.add(DropdownMenuItem<String>(
        value: id,
        child: Text(name),
      ));
    }
    
    return items;
  }

  Widget _buildSectionHeader(String title, IconData icon, String sectionKey, AddEditDocumentController controller) {
    final isExpanded = _sectionExpanded[sectionKey] ?? false;
    
    // Check if section is required
    bool isRequired = sectionKey == 'customer' ||
        sectionKey == 'seller' ||
        sectionKey == 'product';
    
    // Summary section is required when there are validation errors (like invalid discount)
    if (sectionKey == 'summary') {
      isRequired = controller.isEndOfBillDiscountEnabled && 
                   !controller.validateEndOfBillDiscount(controller.endOfBillDiscountController.text);
    }
    
    final isComplete = _isSectionComplete(sectionKey, controller);

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
                      'please_fill_all_required_info'.tr,
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
  }

     // Check if section is complete based on required fields
   bool _isSectionComplete(String sectionKey, AddEditDocumentController controller) {
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
             (controller.selectedCustomerId?.isNotEmpty == true);
       case 'seller':
         return controller.selectedSellerIds.isNotEmpty;
       case 'product':
         return _areAllProductsComplete(
           controller,
         ); // Check if all products are complete
       case 'more':
         return true; // Optional section
       case 'summary':
         // Validate end-of-bill discount if enabled
         if (controller.isEndOfBillDiscountEnabled) {
           final discountValue = controller.endOfBillDiscountController.text;
           return controller.validateEndOfBillDiscount(discountValue);
         }
         return true; // If discount not enabled, summary is always valid
       default:
         return true;
     }
   }

  // Check if all required fields are complete
  bool _areRequiredFieldsComplete(AddEditDocumentController controller) {
      return _isSectionComplete('customer', controller) &&
          _isSectionComplete('seller', controller) &&
          _areAllProductsComplete(controller) &&
          _isSectionComplete('summary', controller);
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
                  'customer_data'.tr,
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
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryOrange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'loading_customers'.tr,
                      style: const TextStyle(
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
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_off,
                      color: AppTheme.textSecondary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'no_customers_found'.tr,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'add_customer_before_quotation'.tr,
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
            CustomersInputField(
              selectedCustomerIds: controller.selectedCustomerId != null 
                  ? [controller.selectedCustomerId!] 
                  : [],
              availableCustomers: controller.customers.map((customer) {
                return Customer(
                  id: customer.id,
                  name: customer.name,
                  customId: customer.customId,
                  emails: customer.emails,
                  phones: customer.phones,
                  companyNames: customer.companyNames,
                  customFields: [], // CustomersInputField Customer doesn't match entity Customer
                  workspaceId: customer.workspaceId,
                  createdAt: customer.createdAt,
                  updatedAt: customer.updatedAt,
                  createdBy: customer.createdBy,
                  updatedBy: customer.updatedBy,
                );
              }).toList(),
              onCustomersChanged: (selectedIds) {
                final selectedId = selectedIds.isNotEmpty ? selectedIds.first : null;
                controller.onCustomerChanged(selectedId);
              },
              label: 'select_customer_required'.tr,
              hintText: 'select_customer_hint'.tr,
              isLoading: controller.isLoadingCustomers,
              allowMultipleSelection: false,
              showBorder: false,
              workspaceId: controller.workspaceId,
              enableAlgoliaSearch: true,
            ),
          ],
          const SizedBox(height: 16),

          // Customer Company Selection - Always show when customer is selected
          if (controller.selectedCustomer != null) ...[
            _buildDropdownField(
              label: 'customer_company'.tr,
              hint: 'select_company'.tr,
              value: controller.selectedCompanyIdForUI,
              items: [
                // Add default "บุคคลธรรมดา" option first
                DropdownMenuItem<String>(
                  value: 'individual',
                  child: Text('select_individual'.tr),
                ),
                // Add all company names if available
                if (controller.selectedCustomer?.companyNames.isNotEmpty == true)
                  ...(controller.selectedCustomer?.companyNames ?? [])
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
                      .where((item) => item.value?.isNotEmpty == true)
                      .toList(),
              ],
              onChanged: controller.onCompanyChanged,
            ),
            const SizedBox(height: 16),
          ],

          // Customer Address
          _buildTextField(
            label: 'customer_address'.tr,
            hint: 'enter_customer_address'.tr,
            controller: controller.customerAddressController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Postal Code
          _buildTextField(
            label: 'postal_code'.tr,
            hint: 'enter_postal_code'.tr,
            controller: controller.customerPostalCodeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // National ID
          _buildTextField(
            label: 'id_number'.tr,
            hint: 'enter_id_number'.tr,
            controller: controller.customerNationalIdController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Website
          _buildTextField(
            label: 'เว็บไซต์',
            hint: 'กรอกเว็บไซต์',
            controller: controller.customerWebsiteController,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),

          // Multiple Phones
          _buildMultipleContactFields(
            controller: controller,
            label: 'phone_number'.tr,
            contactType: 'phone',
            contacts: controller.customerPhones,
            addContact: controller.addCustomerPhone,
            removeContact: controller.removeCustomerPhone,
            updateContact: controller.updateCustomerPhone,
            keyboardType: TextInputType.phone,
            hint: 'enter_phone_number'.tr,
          ),
          const SizedBox(height: 16),

          // Multiple Emails
          _buildMultipleContactFields(
            controller: controller,
            label: 'email'.tr,
            contactType: 'email',
            contacts: controller.customerEmails,
            addContact: controller.addCustomerEmail,
            removeContact: controller.removeCustomerEmail,
            updateContact: controller.updateCustomerEmail,
            keyboardType: TextInputType.emailAddress,
            hint: 'enter_email'.tr,
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
            label: 'seller_responsible_person'.tr,
            hintText: 'select_seller_from_responsible_list'.tr,
            isLoading: controller.isLoadingAssignees,
            allowMultipleSelection: false, // Single selection for seller
            showBorder: false,
          ),
          const SizedBox(height: 16),

          // Seller Phone
          _buildTextField(
            label: 'เบอร์ติดต่อ',
            hint: 'กรอกเบอร์ติดต่อผู้ขาย',
            controller: controller.sellerPhoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Job Name
          _buildTextField(
            label: 'job_name'.tr,
            hint: 'enter_job_name'.tr,
            controller: controller.jobNameController,
          ),
          const SizedBox(height: 16),

          // Ref ID
          _buildTextField(
            label: 'reference_code'.tr,
            hint: 'enter_reference_code'.tr,
            controller: controller.refIdController,
          ),
          const SizedBox(height: 16),

          // Document Date
          _buildDateField(
            label: 'issue_date'.tr,
            hint: 'select_issue_date'.tr,
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

  Widget _buildProductSection(AddEditDocumentController controller, String? documentId) {
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
          if (controller.selectedTemplateId == null && documentId == null) ...[
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

          // Warning for edit mode when template is missing
          if (controller.selectedTemplateId == null && documentId != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เทมเพลตของเอกสารนี้ไม่สามารถโหลดได้ แต่คุณยังสามารถแก้ไขสินค้าที่มีอยู่ได้',
                      style: TextStyle(color: AppTheme.primaryOrange, fontSize: 12),
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
                  onPressed: (controller.isLoadingProducts || 
                              (controller.selectedTemplateId == null && documentId == null))
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
                        : (controller.selectedTemplateId == null && documentId == null)
                            ? 'เลือกเทมเพลตก่อน'
                        : 'เลือกจากฐานข้อมูล',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (controller.selectedTemplateId == null && documentId == null)
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
                  onPressed: (controller.selectedTemplateId == null && documentId == null)
                      ? null
                      : controller.addProduct,
                  icon: Icon(
                    Icons.add,
                    color: (controller.selectedTemplateId == null && documentId == null)
                        ? AppTheme.textGrey
                        : AppTheme.primaryOrange,
                  ),
                  label: Text(
                    (controller.selectedTemplateId == null && documentId == null)
                        ? 'เลือกเทมเพลตก่อน'
                        : 'เพิ่มใหม่',
                    style: TextStyle(
                      color: (controller.selectedTemplateId == null && documentId == null)
                          ? AppTheme.textGrey
                          : AppTheme.primaryOrange,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: (controller.selectedTemplateId == null && documentId == null)
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
              return _buildProductItem(controller, index, product, documentId);
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
    String? documentId,
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
                'item_number'.tr.replaceFirst('{number}', '${index + 1}'),
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
          _buildDynamicProductFields(controller, index, documentId),
        ],
      ),
    );
  }
  
  Widget _buildDynamicProductFields(AddEditDocumentController controller, int index, String? documentId) {
    final fields = controller.templateProductFields;
    if (fields.isEmpty) {
      // In edit mode, show basic product fields even without template
      if (documentId != null) {
        return _buildBasicProductFields(controller, index);
      }
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
            String controllerKey = index.toString();
            
            // Handle different field mappings
            if (fieldType == 'product_field' && field['sourceField'] != null) {
              final sourceField = field['sourceField'].toString();
              if (sourceField.startsWith('customFields.')) {
                // Use field index prefix for custom fields to avoid duplication
                controllerKey = 'field_${i}_${sourceField.replaceFirst('customFields.', '')}';
              } else {
                // Use standard field names for basic product fields
                controllerKey = sourceField;
              }
            } else if (fieldType == 'predefined' && field['predefinedField'] != null) {
              // Use standard field names for predefined fields
              controllerKey = field['predefinedField'].toString();
            } else if (fieldType == 'user_input') {
              // Use field index prefix for user input fields to avoid duplication
              controllerKey = 'field_${i}_$fieldId';
            } else {
              // Use field index prefix for other cases to avoid duplication
              controllerKey = 'field_${i}_$fieldId';
            }
            
            // Determine keyboard type based on inputType and field rules
            TextInputType keyboardType = _getKeyboardTypeForField(field, controllerKey);
            // Extract actual field name for helper methods
            String actualFieldName = _extractFieldName(controllerKey);
            bool isRequired = _isFieldRequired(actualFieldName);
            String hint = _getFieldHint(actualFieldName, keyboardType);
            String? prefix = _getFieldPrefix(actualFieldName);
            int maxLines = _getFieldMaxLines(actualFieldName);
            
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
            // Generic field for unknown types - use field index prefix to avoid duplication
            fieldWidget = _buildTextField(
              label: fieldLabel,
              hint: 'กรอก $fieldLabel',
              controller: controller.getProductController(index, 'field_${i}_$fieldId'),
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

  // Build basic product fields when no template is available (edit mode fallback)
  Widget _buildBasicProductFields(AddEditDocumentController controller, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          label: 'ชื่อสินค้า *',
          hint: 'ระบุชื่อสินค้า',
          controller: controller.getProductController(index, 'name'),
          isRequired: true,
          onChanged: (value) => controller.update(),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'รายละเอียด',
          hint: 'ระบุรายละเอียดสินค้า',
          controller: controller.getProductController(index, 'description'),
          maxLines: 2,
          onChanged: (value) => controller.update(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GetBuilder<AddEditDocumentController>(
                builder: (controller) {
                  final quantityController = controller.getProductController(index, 'quantity');
                  final remainingLimit = controller.getRemainingQuantityLimit(index);
                  final currentValue = quantityController.text;
                  
                  // Use template-aware validation
                  final hasError = !controller.validateQuantityForTemplate(index, currentValue);
                  final errorMessage = controller.getQuantityErrorMessage(index, currentValue);
                  
                  String? helperText;
                  String? errorText;
                  
                  if (remainingLimit != null) {
                    final formattedLimit = remainingLimit.truncateToDouble() == remainingLimit 
                        ? remainingLimit.toInt().toString()
                        : remainingLimit.toStringAsFixed(2);
                    helperText = 'จำนวนคงเหลือ: $formattedLimit';
                    
                    if (hasError && errorMessage != null) {
                      errorText = errorMessage;
                    }
                  }
                  
                  return _buildTextField(
                    label: 'จำนวน *',
                    hint: '1',
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    isRequired: true,
                    helperText: helperText,
                    errorText: errorText,
                    hasError: hasError,
                    onChanged: (value) => controller.update(),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'หน่วย',
                hint: 'หน่วย',
                controller: controller.getProductController(index, 'unit'),
                onChanged: (value) => controller.update(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'ราคาต่อหน่วย *',
                hint: '0',
                controller: controller.getProductController(index, 'pricePerUnit'),
                keyboardType: TextInputType.number,
                prefix: '฿',
                isRequired: true,
                onChanged: (value) => controller.update(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                label: 'ส่วนลด',
                hint: '0',
                controller: controller.getProductController(index, 'discount'),
                keyboardType: TextInputType.number,
                prefix: '฿',
                onChanged: (value) => controller.update(),
              ),
            ),
          ],
        ),
      ],
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

  // Helper method to extract actual field name from prefixed controller key
  String _extractFieldName(String controllerKey) {
    // Remove field index prefix (e.g., 'field_0_name' -> 'name')
    if (controllerKey.startsWith('field_')) {
      final parts = controllerKey.split('_');
      if (parts.length >= 3) {
        return parts.sublist(2).join('_'); // Join remaining parts in case field name has underscores
      }
    }
    return controllerKey; // Return as-is if no prefix found
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
          // Payment Method
          _buildDropdownField(
            label: 'payment_method'.tr,
            hint: 'hint_payment_method'.tr,
            value: controller.selectedPaymentDetailId,
            items: controller.paymentMethodOptions.map((option) => 
              DropdownMenuItem<String>(
                value: option['id'],
                child: Text(option['displayName']!),
              )
            ).toList(),
            onChanged: controller.onPaymentMethodChanged,
          ),
          const SizedBox(height: 16),

          // Notes
          _buildTextField(
            label: 'note'.tr,
            hint: 'note_hint'.tr,
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
            GetBuilder<AddEditDocumentController>(
              builder: (controller) {
                final currentValue = controller.endOfBillDiscountController.text;
                final isValid = controller.validateEndOfBillDiscount(currentValue);
                final errorMessage = controller.getEndOfBillDiscountErrorMessage(currentValue);
                
                return _buildTextField(
                  label: 'discount_amount'.tr,
                  hint: '0',
                  controller: controller.endOfBillDiscountController,
                  keyboardType: TextInputType.number,
                  suffix: '฿',
                  hasError: !isValid,
                  errorText: errorMessage,
                  helperText: 'สูงสุด: ฿${controller.subtotal.toStringAsFixed(2)}',
                  onChanged: (value) {
                    // Validate and update
                    controller.update();
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            
            // After End-of-bill discount
            _buildSummaryRow(
              'total_after_discount'.tr,
              controller.afterDiscount.toStringAsFixed(2),
              '฿',
            ),
            const SizedBox(height: 16),
          ],

          // VAT Checkbox
          _buildCheckboxField(
            label: 'value_added_tax_7_percent'.tr,
            value: controller.isVatEnabled,
            onChanged: controller.onVatEnabledChanged,
          ),
          const SizedBox(height: 12),

          // VAT Amount
          if (controller.isVatEnabled) ...[
            _buildSummaryRow(
              'value_added_tax'.tr,
              controller.vatAmount.toStringAsFixed(2),
              '฿',
            ),
            const SizedBox(height: 12),
          ],

          // After VAT
          if (controller.isVatEnabled) ...[
            _buildSummaryRow(
              'total_after_tax'.tr,
              controller.afterVat.toStringAsFixed(2),
              '฿',
            ),
            const SizedBox(height: 16),
          ],

          // Withholding Tax
          _buildCheckboxField(
            label: 'withholding_tax'.tr,
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
                    label: 'percentage'.tr,
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
                    'withholding_tax'.tr,
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
                Text(
                  'net_total'.tr,
                  style: const TextStyle(
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
    String? helperText,
    String? errorText,
    bool hasError = false,
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
            helperText: helperText,
            errorText: hasError ? errorText : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppTheme.borderGrey,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppTheme.borderGrey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : AppTheme.primaryOrange,
              ),
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

  Widget _buildMultipleContactFields({
    required AddEditDocumentController controller,
    required String label,
    required String contactType,
    required List<Map<String, dynamic>> contacts,
    required VoidCallback addContact,
    required Function(int) removeContact,
    required Function(int, String) updateContact,
    required TextInputType keyboardType,
    required String hint,
  }) {
    return GetBuilder<AddEditDocumentController>(
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textDark,
                ),
              ),
              IconButton(
                onPressed: addContact,
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryOrange),
                tooltip: 'เพิ่ม$label',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (contacts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderGrey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ยังไม่มี$label กดปุ่ม + เพื่อเพิ่ม',
                style: const TextStyle(
                  color: AppTheme.textGrey,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ...contacts.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;
            final contactController = TextEditingController(text: contact['value'] ?? '');
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: contactController,
                      keyboardType: keyboardType,
                      onChanged: (value) => updateContact(index, value),
                      decoration: InputDecoration(
                        hintText: hint,
                        border: OutlineInputBorder(
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
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => removeContact(index),
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    tooltip: 'ลบ$label',
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
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

  void _showProductSelectionDialog(AddEditDocumentController controller) {
    // Use real product data from controller
    final availableProducts = controller.availableProducts;

    if (availableProducts.isEmpty) {
      Get.snackbar(
        'no_products_found'.tr,
        'no_products_found'.tr,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Move tempSelected outside StatefulBuilder to persist selections
    List<Map<String, dynamic>> tempSelected = [];
    String searchQuery = '';

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          // Filter products based on search query
          final filteredProducts = availableProducts.where((product) {
            if (searchQuery.isEmpty) return true;
            
            final query = searchQuery.toLowerCase();
            final name = product['name']?.toString().toLowerCase() ?? '';
            final sku = product['sku']?.toString().toLowerCase() ?? '';
            final description = product['description']?.toString().toLowerCase() ?? '';
            
            return name.contains(query) || 
                   sku.contains(query) || 
                   description.contains(query);
          }).toList();
          
          return AlertDialog(
            title: Text('select_products_from_database'.tr),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'search_products'.tr,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Product list
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
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
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  tempSelected.removeWhere(
                                    (p) => p['id'] == product['id'],
                                  );
                                } else {
                                  tempSelected.add(product);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Checkbox(
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
                                  ),
                                  const SizedBox(width: 12),
                                  // Product image
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: Colors.grey.shade100,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: product['imageUrl'] != null && 
                                             product['imageUrl'].toString().isNotEmpty
                                        ? Image.network(
                                            product['imageUrl'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey.shade400,
                                                size: 24,
                                              );
                                            },
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      AppTheme.primaryOrange,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.image,
                                            color: Colors.grey.shade400,
                                            size: 24,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Product details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name']?.toString() ?? '',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? AppTheme.primaryOrange
                                                : AppTheme.textPrimary,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${product['sku']?.toString() ?? ''}',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '฿${product['price']?.toString() ?? '0'}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.primaryOrange,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${product['unit']?.toString() ?? ''}',
                                              style: TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                child: Text('cancel'.tr),
              ),
              SizedBox(width: 100,
              child: ElevatedButton(
                onPressed: () {
                  if (tempSelected.isNotEmpty) {
                    controller.addProductsFromDatabase(tempSelected);
                    Navigator.of(
                      context,
                    ).pop(); // Use Navigator.pop instead of Get.back()
                  } else {
                    Get.snackbar(
                      'warning'.tr,
                      'please_select_at_least_one_product'.tr,
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                ),
                child: Text('add_products'.tr),
              ),
              ),
              
            ],
          );
        },
      ),
    );
  }