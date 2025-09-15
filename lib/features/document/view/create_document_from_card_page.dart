import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../controller/create_document_from_card_controller.dart';

class CreateDocumentFromCardPage extends StatefulWidget {
  final JobCard jobCard;
  final String? templateId;

  const CreateDocumentFromCardPage({
    super.key,
    required this.jobCard,
    this.templateId,
  });

  @override
  State<CreateDocumentFromCardPage> createState() => _CreateDocumentFromCardPageState();
}

class _CreateDocumentFromCardPageState extends State<CreateDocumentFromCardPage> {
  late CreateDocumentFromCardController _controller;
  List<Map<String, dynamic>> _quotationTemplates = [];
  String? _selectedTemplateId;
  List<Map<String, dynamic>> _templateColumns = [];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(CreateDocumentFromCardController());

    // Set initial template ID from widget
    _selectedTemplateId = widget.templateId ?? 'none';
    
    // Initialize with job card and template ID
    _controller.initializeWithJobCard(widget.jobCard, templateId: widget.templateId);
    
    // Load templates
    _loadQuotationTemplates();
  }

  @override
  void dispose() {
    Get.delete<CreateDocumentFromCardController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Create Quotation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: Obx(() => _controller.isLoading 
        ? _buildLoadingView()
        : _buildContent()
      ),
      bottomNavigationBar: Obx(() => _controller.isLoading 
        ? const SizedBox.shrink()
        : _buildBottomButton()
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
          ),
          SizedBox(height: 24),
          Text(
            'Generating Quotation...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryOrange,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Please wait while we create your quotation\nfrom the job card data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Template Selection Section
          _buildTemplateSelectionSection(),
          const SizedBox(height: 24),
          
          // Job Card Preview Section
          _buildJobCardPreviewSection(),
          const SizedBox(height: 24),
          
          // Customer Information Preview
          _buildCustomerInfoSection(),
          const SizedBox(height: 24),
          
          // Products & Services Preview
          _buildProductsPreviewSection(),
          const SizedBox(height: 24),
          
          // Summary Preview
          _buildSummaryPreviewSection(),
          const SizedBox(height: 100), // Space for bottom button
        ],
      ),
    );
  }

  Widget _buildTemplateSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.design_services, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Document Template',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepOrange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _quotationTemplates.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading templates...', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _quotationTemplates.any((t) => t['id'] == _selectedTemplateId) 
                        ? _selectedTemplateId 
                        : null,
                    hint: const Text('Select Template'),
                    items: _quotationTemplates.map((template) {
                      return DropdownMenuItem<String>(
                        value: template['id'],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            template['name'],
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: _onTemplateChanged,
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.deepOrange),
                    iconSize: 20,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    isExpanded: true,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCardPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: AppTheme.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Job Card Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Job ID:', widget.jobCard.customId),
          _buildInfoRow('Title:', widget.jobCard.title),
          _buildInfoRow('Status:', widget.jobCard.status),
          if (widget.jobCard.assignedTo.isNotEmpty)
            _buildInfoRow('Assigned To:', widget.jobCard.assignedTo),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Customer:', widget.jobCard.customer.isNotEmpty 
            ? widget.jobCard.customer 
            : 'No customer selected'),
          if (widget.jobCard.company != null)
            _buildInfoRow('Company:', widget.jobCard.company!['value'] ?? ''),
          if (widget.jobCard.customerInterest != null)
            _buildInfoRow('Interest Level:', widget.jobCard.customerInterest!),
        ],
      ),
    );
  }

  Widget _buildProductsPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.deepOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Products & Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Template info
          if (_selectedTemplateId != null && _selectedTemplateId != 'none')
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Columns based on template: ${_getSelectedTemplateName()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Live expenses from subcollection: workspaces/{ws}/cards/{cardId}/expenses
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('workspaces')
                .doc(widget.jobCard.workspaceId)
                .collection('cards')
                .doc(widget.jobCard.id)
                .collection('expenses')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    'Failed to load items: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No products or services added',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }

              // Map and sort by 'order' if present
              final expenses = docs
                  .map((d) => {
                        ...d.data(),
                        'id': d.id,
                      })
                  .toList();

              expenses.sort((a, b) {
                final ao = (a['order'] ?? 0);
                final bo = (b['order'] ?? 0);
                final ai = ao is int ? ao : int.tryParse(ao.toString()) ?? 0;
                final bi = bo is int ? bo : int.tryParse(bo.toString()) ?? 0;
                return ai.compareTo(bi);
              });

              return Column(
                children: [
                  _buildProductTableHeader(),
                  const SizedBox(height: 8),
                  ...expenses.map((expense) => _buildProductRow(expense)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getSelectedTemplateName() {
    if (_selectedTemplateId == null || _selectedTemplateId == 'none') return 'Default';
    final match = _quotationTemplates.firstWhere(
      (t) => t['id'] == _selectedTemplateId,
      orElse: () => {},
    );
    if (match.isEmpty) return 'Default';
    return match['name']?.toString() ?? 'Template';
  }
  
  Widget _buildProductTableHeader() {
    final columns = _getDisplayColumns();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: columns.map<Widget>((column) {
          return Expanded(
            flex: _getColumnFlex(column),
            child: Text(
              column['label'] ?? column['id'] ?? '',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }
  
  List<Map<String, dynamic>> _getDisplayColumns() {
    // Use columns cached from selected template (or defaults if none)
    final columns = _templateColumns;
    if (columns.isEmpty) return _getDefaultColumns();

    final visibleColumns = columns
        .where((col) => col['isVisible'] == true)
        .cast<Map<String, dynamic>>()
        .toList();

    visibleColumns.sort((a, b) {
      final orderA = a['order'] ?? 999;
      final orderB = b['order'] ?? 999;
      return orderA.compareTo(orderB);
    });

    return visibleColumns;
  }
  
  int _getColumnFlex(Map<String, dynamic> column) {
    // Use width percentage if available, otherwise default flex
    final width = column['width'];
    if (width is String && width.contains('%')) {
      try {
        final percentage = double.parse(width.replaceAll('%', ''));
        return (percentage / 10).round().clamp(1, 10);
      } catch (e) {
        // If parsing fails, use default
      }
    }
    
    // Default flex based on column type or id
    final columnId = column['id'] ?? '';
    switch (columnId) {
      case 'product_name':
      case 'description':
        return 3;
      case 'quantity':
      case 'unit':
        return 1;
      case 'unit_price':
      case 'amount':
      case 'total':
        return 2;
      default:
        return 2;
    }
  }

  Widget _buildProductRow(Map<String, dynamic> expense) {
    final columns = _getDisplayColumns();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: columns.map<Widget>((column) {
          return Expanded(
            flex: _getColumnFlex(column),
            child: _buildColumnValue(column, expense),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildColumnValue(Map<String, dynamic> column, Map<String, dynamic> expense) {
    final columnId = column['id'] ?? '';
    final sourceField = column['sourceField'];
    String displayValue = '';
    
    // Resolve value by type rules
    final columnType = column['type'] ?? 'text';
    if (columnType == 'user_input') {
      final customInputs = expense['customInputs'] as Map<String, dynamic>?;
      final raw = customInputs?[columnId];
      if (raw != null && raw.toString().isNotEmpty) {
        displayValue = raw.toString();
      } else {
        // Fallback: use prefillSourceField if provided in template
        final prefill = column['prefillSourceField'];
        if (prefill != null && prefill is String && prefill.isNotEmpty) {
          displayValue = _getValueFromPath(expense, prefill) ?? '-';
        } else {
          displayValue = '-';
        }
      }
    } else if (columnType == 'predefined') {
      final predefined = column['predefinedField']?.toString() ?? '';
      switch (predefined) {
        case 'line_total':
          final quantity = double.tryParse(expense['quantity']?.toString() ?? '1') ?? 1;
          final pricePerUnit = double.tryParse(expense['pricePerUnit']?.toString() ?? '0') ?? 0;
          final discount = double.tryParse(expense['discount']?.toString() ?? '0') ?? 0;
          final discountType = expense['discountType'] ?? 'amount';
          final itemTotal = quantity * pricePerUnit;
          final discountAmount = discountType == 'percentage' ? (itemTotal * discount / 100) : discount;
          final finalAmount = (itemTotal - discountAmount).clamp(0, double.infinity);
          displayValue = '฿${NumberFormat('#,##0.00').format(finalAmount)}';
          break;
        default:
          // Unknown predefined field, try sourceField or fallback
          if (sourceField != null && sourceField.isNotEmpty) {
            displayValue = _getValueFromPath(expense, sourceField) ?? '';
          } else {
            displayValue = expense[columnId]?.toString() ?? '-';
          }
      }
    } else {
      // Determine the value to display based on column configuration
      if (sourceField != null && sourceField.isNotEmpty) {
        displayValue = _getValueFromPath(expense, sourceField) ?? '';
      } else {
        displayValue = _getFieldValue(expense, columnId);
      }
    }

    // Apply formatting only for numeric/currency/percentage columns if defined
    final formattedValue = _formatColumnValue(displayValue, columnType);

    return Text(
      formattedValue,
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black87,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
  
  String? _getValueFromPath(Map<String, dynamic> data, String path) {
    try {
      final keys = path.split('.');
      dynamic current = data;
      
      for (String key in keys) {
        if (current is Map && current.containsKey(key)) {
          current = current[key];
        } else {
          return null;
        }
      }
      
      return current?.toString();
    } catch (e) {
      return null;
    }
  }
  
  String _getFieldValue(Map<String, dynamic> expense, String fieldId) {
    switch (fieldId) {
      case 'product_name':
      case 'name':
        return expense['name']?.toString() ?? '';
      case 'description':
        return expense['description']?.toString() ?? '';
      case 'quantity':
        return expense['quantity']?.toString() ?? '1';
      case 'unit':
        return expense['unit']?.toString() ?? 'ชิ้น';
      case 'unit_price':
      case 'price':
        final price = expense['pricePerUnit'] ?? expense['price'] ?? 0;
        return '฿${NumberFormat('#,##0.00').format(price)}';
      case 'amount':
      case 'total':
        final quantity = double.tryParse(expense['quantity']?.toString() ?? '1') ?? 1;
        final pricePerUnit = double.tryParse(expense['pricePerUnit']?.toString() ?? '0') ?? 0;
        final discount = double.tryParse(expense['discount']?.toString() ?? '0') ?? 0;
        final discountType = expense['discountType'] ?? 'amount';
        
        final itemTotal = quantity * pricePerUnit;
        final discountAmount = discountType == 'percentage' 
          ? (itemTotal * discount / 100) 
          : discount;
        final finalAmount = itemTotal - discountAmount;
        return '฿${NumberFormat('#,##0.00').format(finalAmount)}';
      default:
        // Check if this is a custom input field from template
        final customInputs = expense['customInputs'] as Map<String, dynamic>?;
        if (customInputs != null && customInputs.containsKey(fieldId)) {
          return customInputs[fieldId]?.toString() ?? '-';
        }
        
        // Try to get value directly from expense data
        return expense[fieldId]?.toString() ?? '-';
    }
  }
  
  String _formatColumnValue(String value, String type) {
    if (value.isEmpty || value == '-') return value;
    
    switch (type) {
      case 'currency':
      case 'number':
        final numValue = double.tryParse(value);
        if (numValue != null) {
          return type == 'currency' 
              ? '฿${NumberFormat('#,##0.00').format(numValue)}'
              : NumberFormat('#,##0.##').format(numValue);
        }
        return value;
      case 'percentage':
        final numValue = double.tryParse(value);
        if (numValue != null) {
          return '${NumberFormat('#,##0.##').format(numValue)}%';
        }
        return value;
      default:
        return value;
    }
  }

  Widget _buildSummaryPreviewSection() {
    final calculations = _calculateTotals();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calculate,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSummaryRow('Subtotal', calculations['subtotal']!),
          if (calculations['discount']! > 0)
            _buildSummaryRow('Discount', calculations['discount']!, isNegative: true),
          if (widget.jobCard.isVatEnabled)
            _buildSummaryRow('VAT (7%)', calculations['vatAmount']!),
          _buildSummaryRow('Grand Total', calculations['grandTotal']!, isBold: true),
          if (widget.jobCard.withholdingTaxPercentage > 0)
            _buildSummaryRow('WHT (${widget.jobCard.withholdingTaxPercentage}%)', calculations['whtAmount']!, isNegative: true),
          _buildSummaryRow('Net Total', calculations['netTotal']!, isBold: true, isLarge: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {
    bool isNegative = false, 
    bool isBold = false, 
    bool isLarge = false
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}฿${_formatPrice(amount)}',
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isNegative ? Colors.red : (isBold ? AppTheme.primaryOrange : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateTotals() {
    final expenses = widget.jobCard.expenses;
    double subtotal = 0.0;
    double totalDiscount = 0.0;

    // คำนวณ subtotal และ discount จาก items
    for (final expense in expenses) {
      final quantity = (expense['quantity'] ?? 1).toDouble();
      final pricePerUnit = (expense['pricePerUnit'] ?? 0).toDouble();
      final discount = (expense['discount'] ?? 0).toDouble();
      final discountType = expense['discountType'] ?? 'amount';

      final itemTotal = quantity * pricePerUnit;
      subtotal += itemTotal;

      // คำนวณ discount
      if (discountType == 'percentage') {
        totalDiscount += (itemTotal * discount / 100);
      } else {
        totalDiscount += discount;
      }
    }

    // Additional discount จาก job card
    final additionalDiscount = widget.jobCard.additionalDiscount;
    if (additionalDiscount != null) {
      final discountValue = (additionalDiscount['value'] ?? 0).toDouble();
      final discountType = additionalDiscount['type'] ?? 'amount';
      
      if (discountType == 'percentage') {
        totalDiscount += (subtotal * discountValue / 100);
      } else {
        totalDiscount += discountValue;
      }
    }

    final afterDiscount = subtotal - totalDiscount;
    
    // คำนวณ VAT (7%)
    final isVatEnabled = widget.jobCard.isVatEnabled;
    final vatAmount = isVatEnabled ? (afterDiscount * 0.07) : 0.0;
    
    final grandTotal = afterDiscount + vatAmount;
    
    // คำนวณ WHT
    final whtPercentage = widget.jobCard.withholdingTaxPercentage.toDouble() / 100;
    final whtAmount = grandTotal * whtPercentage;
    
    final netTotal = grandTotal - whtAmount;

    return {
      'subtotal': subtotal,
      'discount': totalDiscount,
      'vatAmount': vatAmount,
      'grandTotal': grandTotal,
      'whtAmount': whtAmount,
      'netTotal': netTotal,
    };
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _controller.isLoading ? null : _createQuotation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _controller.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Create Quotation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Future<void> _createQuotation() async {
    final documentId = await _controller.createQuotationFromJobCard(
      widget.jobCard,
      templateId: _selectedTemplateId,
    );
    
    if (documentId != null) {
      // Navigate back to job card page with success signal
      Navigator.of(context).pop(true);
    }
  }

  // Load quotation templates
  Future<void> _loadQuotationTemplates() async {
    try {
      // Prefer the workspace from the job card to ensure template IDs line up
      String? workspaceId = widget.jobCard.workspaceId.isNotEmpty
          ? widget.jobCard.workspaceId
          : null;
      
      // Fallback: derive from user context if job card has no workspace
      if (workspaceId == null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;
        final repository = Get.find<FirestoreRepository>();
        final workspaces = await repository.getUserWorkspaces(user.uid);
        if (workspaces.isEmpty) return;
        
        try {
          final lastActiveWorkspaceId = await repository.getUserLastActiveWorkspaceId(user.uid);
          if (lastActiveWorkspaceId != null && lastActiveWorkspaceId.isNotEmpty) {
            final lastActiveWorkspace = workspaces.where((ws) => ws['id'] == lastActiveWorkspaceId).firstOrNull;
            if (lastActiveWorkspace != null) {
              workspaceId = lastActiveWorkspaceId;
            }
          }
        } catch (_) {}
        
        workspaceId ??= workspaces.first['id'] as String;
      }

      // Load templates
      final snapshot = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('quotationTemplates')
          .get();

      final List<Map<String, dynamic>> templates = [];
      
      // Add "None" option first
      templates.add({
        'id': 'none',
        'name': 'ไม่มี (None)',
      });

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final templateName = data['name'] ?? 'Unnamed Template';
        
        // Extract table component and columns
        final tableComponent = _findTableComponent(data);
        final columns = tableComponent?['columns'] as List<dynamic>? ?? [];
        
        templates.add({
          'id': doc.id,
          'name': templateName,
          'data': data,
          'columns': columns,
        });
      }

      setState(() {
        _quotationTemplates = templates;
        // Update template columns when templates are loaded
        _updateTemplateColumns();
        // Ensure selected template ID exists in the loaded templates
        if (_selectedTemplateId != null && 
            !templates.any((t) => t['id'] == _selectedTemplateId)) {
          _selectedTemplateId = 'none';
        }
      });
    } catch (e) {
    }
  }

  void _onTemplateChanged(String? templateId) {
    setState(() {
      _selectedTemplateId = templateId;
      _updateTemplateColumns();
    });
  }

  // Find table component in template data
  Map<String, dynamic>? _findTableComponent(Map<String, dynamic> templateData) {
    final body = templateData['body'];
    if (body != null && body['components'] != null && body['components'] is List) {
      final components = body['components'] as List;
      // Prefer components[1] when it's a table, per requirement
      if (components.length > 1 && components[1] is Map && components[1]['type'] == 'table') {
        return Map<String, dynamic>.from(components[1] as Map);
      }
      // Fallback: first table component
      for (final component in components) {
        if (component is Map && component['type'] == 'table') {
          return Map<String, dynamic>.from(component);
        }
      }
    }
    return null;
  }

  // Update template columns based on selected template
  void _updateTemplateColumns() {
    if (_selectedTemplateId == null || _selectedTemplateId == 'none') {
      _templateColumns = _getDefaultColumns();
      return;
    }

    final selectedTemplate = _quotationTemplates.firstWhere(
      (template) => template['id'] == _selectedTemplateId,
      orElse: () => {},
    );

    if (selectedTemplate.isNotEmpty && selectedTemplate['columns'] != null) {
      _templateColumns = List<Map<String, dynamic>>.from(selectedTemplate['columns']);
    } else {
      _templateColumns = _getDefaultColumns();
    }
  }

  // Get default columns if no template is selected
  List<Map<String, dynamic>> _getDefaultColumns() {
    return [
      {
        'id': 'name',
        'label': 'รายการ',
        'type': 'product_field',
        'sourceField': 'name',
        'isVisible': true,
        'isEditable': true,
        'order': 0,
        'width': '40%',
      },
      {
        'id': 'quantity',
        'label': 'จำนวน',
        'type': 'predefined',
        'predefinedField': 'quantity',
        'isVisible': true,
        'isEditable': true,
        'order': 1,
        'width': '15%',
        'align': 'center',
      },
      {
        'id': 'pricePerUnit',
        'label': 'ราคา/หน่วย',
        'type': 'product_field',
        'sourceField': 'pricePerUnit',
        'isVisible': true,
        'isEditable': true,
        'order': 2,
        'width': '20%',
        'align': 'right',
      },
      {
        'id': 'total',
        'label': 'รวม',
        'type': 'predefined',
        'predefinedField': 'line_total',
        'isVisible': true,
        'isEditable': false,
        'order': 3,
        'width': '25%',
        'align': 'right',
      },
    ];
  }
}
