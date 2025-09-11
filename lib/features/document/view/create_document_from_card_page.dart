import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/job_card.dart';
import '../controller/create_document_from_card_controller.dart';

class CreateDocumentFromCardPage extends StatefulWidget {
  final JobCard jobCard;

  const CreateDocumentFromCardPage({
    super.key,
    required this.jobCard,
  });

  @override
  State<CreateDocumentFromCardPage> createState() => _CreateDocumentFromCardPageState();
}

class _CreateDocumentFromCardPageState extends State<CreateDocumentFromCardPage> {
  late CreateDocumentFromCardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(CreateDocumentFromCardController());
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
          
          if (widget.jobCard.expenses.isEmpty)
            const Center(
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
            )
          else
            ...widget.jobCard.expenses.map((expense) => _buildProductRow(expense)),
        ],
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> expense) {
    final quantity = expense['quantity'] ?? 1;
    final pricePerUnit = expense['pricePerUnit'] ?? 0;
    final discount = expense['discount'] ?? 0;
    final discountType = expense['discountType'] ?? 'amount';
    
    final itemTotal = quantity * pricePerUnit;
    final discountAmount = discountType == 'percentage' 
      ? (itemTotal * discount / 100) 
      : discount.toDouble();
    final finalAmount = itemTotal - discountAmount;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            expense['name'] ?? 'Unnamed Product',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (expense['description'] != null && expense['description'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                expense['description'],
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Qty: $quantity ${expense['unit'] ?? 'item'}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'Price: ฿${_formatPrice(pricePerUnit.toDouble())}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'Total: ฿${_formatPrice(finalAmount)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryOrange,
                  ),
                ),
              ),
            ],
          ),
          if (discount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Discount: ${discountType == 'percentage' ? '$discount%' : '฿${_formatPrice(discount.toDouble())}'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                ),
              ),
            ),
        ],
      ),
    );
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
    final documentId = await _controller.createQuotationFromJobCard(widget.jobCard);
    
    if (documentId != null) {
      // Navigate back to job card page with success signal
      Navigator.of(context).pop(true);
    }
  }
}
