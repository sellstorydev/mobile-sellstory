import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/id_generation_service.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../view/add_edit_document_page.dart';

class InvoiceCreationController extends GetxController {
  final Map<String, dynamic> quotation;
  
  InvoiceCreationController({required this.quotation});

  final FirestoreRepository _repository = FirestoreRepository();
  final IdGenerationService _idGenerationService = IdGenerationService();

  // Observable variables
  final isLoading = false.obs;
  final installmentType = 'percent'.obs; // 'percent' or 'amount'
  final installmentInputController = TextEditingController();
  final calculatedAmount = 0.0.obs;
  final withholdingAmount = 0.0.obs;
  final netAmount = 0.0.obs;
  final selectedItems = <Map<String, dynamic>>[].obs;
  final hasSelectedItems = false.obs;
  final isAllItemsSelected = false.obs;
  
  // Item-based invoice discount variables
  final itemBasedDiscountController = TextEditingController();
  final itemBasedSubtotal = 0.0.obs;
  final itemBasedDiscountAmount = 0.0.obs;
  final itemBasedAfterDiscount = 0.0.obs;

  // TextEditingControllers for item quantities
  final Map<int, TextEditingController> _quantityControllers = {};

  // Current user and workspace
  final currentUserId = ''.obs;
  final currentWorkspaceId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUserAndWorkspace();
  }

  @override
  void onClose() {
    installmentInputController.dispose();
    itemBasedDiscountController.dispose();
    
    // Dispose quantity controllers
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
    
    super.onClose();
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      isLoading.value = true;
      
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      currentUserId.value = currentUser.uid;
      
      // Get user workspaces
      final workspaces = await _repository.getUserWorkspaces(currentUserId.value);
      
      if (workspaces.isNotEmpty) {
        // Try to get the last active workspace
        final lastActiveWorkspaceId = await _repository.getUserLastActiveWorkspaceId(currentUserId.value);
        
        if (lastActiveWorkspaceId != null && workspaces.any((w) => w['id'] == lastActiveWorkspaceId)) {
          currentWorkspaceId.value = lastActiveWorkspaceId;
        } else {
          // Use the first available workspace
          currentWorkspaceId.value = workspaces.first['id'] as String;
        }
      }
      
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setInstallmentType(String type) {
    installmentType.value = type;
    installmentInputController.clear();
    calculatedAmount.value = 0.0;
    withholdingAmount.value = 0.0;
    netAmount.value = 0.0;
  }

  void onInstallmentInputChanged(String value) {
    if (value.isEmpty) {
      calculatedAmount.value = 0.0;
      withholdingAmount.value = 0.0;
      netAmount.value = 0.0;
      return;
    }

    final input = double.tryParse(value) ?? 0.0;
    final grandTotal = quotation['grandTotal']?.toDouble() ?? 0.0;

    double baseAmount = 0.0;
    if (installmentType.value == 'percent') {
      // Calculate based on percentage
      if (input > 0 && input <= 100) {
        baseAmount = (grandTotal * input) / 100;
      }
    } else {
      // Calculate based on amount
      if (input > 0 && input <= grandTotal) {
        baseAmount = input;
      }
    }

    calculatedAmount.value = baseAmount;

    // Get tax settings from quotation
    final isVatEnabled = quotation['isVatEnabled'] == true;
    final isWhtEnabled = quotation['isWhtEnabled'] == true;
    final vatPercentage = (quotation['vatPercentage'] ?? 7.0).toDouble();
    final whtPercentage = (quotation['withholdingTaxPercentage'] ?? 3.0).toDouble();

    // Calculate based on quotation's tax settings
    double vatAmount = 0.0;
    double whtAmount = 0.0;
    double finalAmount = baseAmount;

    if (isVatEnabled) {
      vatAmount = baseAmount * (vatPercentage / 100);
      finalAmount += vatAmount;
    }

    if (isWhtEnabled) {
      // WHT is calculated on base amount before VAT
      whtAmount = baseAmount * (whtPercentage / 100);
      finalAmount -= whtAmount;
    }

    // Store for UI display (reusing withholdingAmount for tax display)
    withholdingAmount.value = vatAmount + whtAmount;
    netAmount.value = finalAmount;
  }

  void initializeItemSelection() {
    final items = List<Map<String, dynamic>>.from(quotation['items'] ?? []);
    selectedItems.value = items.map((item) {
      return {
        ...item,
        'selected': false,
        'originalQuantity': item['quantity'],
        'quantity': 0,
      };
    }).toList();
    hasSelectedItems.value = false;
    isAllItemsSelected.value = false;
    
    // Initialize quantity controllers
    _quantityControllers.clear();
    for (int i = 0; i < selectedItems.length; i++) {
      _quantityControllers[i] = TextEditingController(text: '');
    }
  }

  TextEditingController getQuantityController(int index) {
    if (!_quantityControllers.containsKey(index)) {
      _quantityControllers[index] = TextEditingController(text: '');
    }
    return _quantityControllers[index]!;
  }

  void toggleAllItems() {
    final shouldSelectAll = !isAllItemsSelected.value;
    
    for (int i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];
      item['selected'] = shouldSelectAll;
      
      if (shouldSelectAll) {
        // Use original quantity but ensure it doesn't exceed the maximum
        final originalQuantity = item['originalQuantity']?.toDouble() ?? 0.0;
        item['quantity'] = originalQuantity;
        _quantityControllers[i]?.text = originalQuantity > 0 ? originalQuantity.toStringAsFixed(0) : '';
      } else {
        item['quantity'] = 0;
        _quantityControllers[i]?.text = '';
      }
      
      selectedItems[i] = item;
    }
    
    selectedItems.refresh();
    isAllItemsSelected.value = shouldSelectAll;
    _updateHasSelectedItems();
  }

  void toggleItemSelection(int index) {
    final item = selectedItems[index];
    item['selected'] = !(item['selected'] ?? false);
    
    if (item['selected'] == false) {
      item['quantity'] = 0;
      _quantityControllers[index]?.text = '';
    } else {
      // Set to original quantity but ensure it doesn't exceed maximum
      final originalQuantity = item['originalQuantity']?.toDouble() ?? 0.0;
      item['quantity'] = originalQuantity;
      _quantityControllers[index]?.text = originalQuantity > 0 ? originalQuantity.toStringAsFixed(0) : '';
    }
    
    selectedItems[index] = item;
    _updateHasSelectedItems();
    _updateAllSelectedState();
  }

  void updateItemQuantity(int index, String value) {
    final quantity = double.tryParse(value) ?? 0.0;
    final maxQuantity = selectedItems[index]['originalQuantity']?.toDouble() ?? 1.0;
    
    if (quantity < 0) {
      // Don't allow negative quantities
      _quantityControllers[index]?.text = '0';
      selectedItems[index]['quantity'] = 0;
      selectedItems.refresh();
      _updateHasSelectedItems();
      _updateAllSelectedState();
      return;
    }
    
    if (quantity > maxQuantity) {
      // If quantity exceeds maximum, set to maximum and show warning
      _quantityControllers[index]?.text = maxQuantity.toStringAsFixed(0);
      selectedItems[index]['quantity'] = maxQuantity;
      selectedItems.refresh();
      _updateHasSelectedItems();
      _updateAllSelectedState();
      
      // Show warning message
      Get.snackbar(
        'จำนวนเกินกำหนด',
        'จำนวนสูงสุดที่สามารถเลือกได้คือ ${maxQuantity.toStringAsFixed(0)} ${selectedItems[index]['unit'] ?? 'หน่วย'}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange.withOpacity(0.1),
        colorText: Colors.orange,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    
    // Valid quantity - update normally
    selectedItems[index]['quantity'] = quantity;
    selectedItems.refresh();
    _updateHasSelectedItems();
    _updateAllSelectedState();
  }

  void _updateHasSelectedItems() {
    hasSelectedItems.value = selectedItems.any((item) => 
        item['selected'] == true && (item['quantity'] ?? 0) > 0);
    
    // Recalculate subtotal when selection changes
    _calculateItemBasedTotals();
  }

  void _updateAllSelectedState() {
    // Check if all items are selected
    if (selectedItems.isNotEmpty) {
      final allSelected = selectedItems.every((item) => item['selected'] == true);
      isAllItemsSelected.value = allSelected;
    } else {
      isAllItemsSelected.value = false;
    }
  }

  void calculateItemBasedDiscount() {
    final discountInput = double.tryParse(itemBasedDiscountController.text) ?? 0.0;
    
    // Allow discount up to the current subtotal (no restriction from quotation)
    final maxDiscount = itemBasedSubtotal.value;
    
    if (discountInput >= 0 && discountInput <= maxDiscount) {
      itemBasedDiscountAmount.value = discountInput;
      itemBasedAfterDiscount.value = itemBasedSubtotal.value - discountInput;
    } else if (discountInput > maxDiscount) {
      // If exceeds subtotal, set to subtotal amount
      itemBasedDiscountAmount.value = maxDiscount;
      itemBasedAfterDiscount.value = 0.0;
      
      // Update the text field to show the corrected value
      itemBasedDiscountController.text = maxDiscount.toStringAsFixed(2);
    } else {
      // Negative discount not allowed
      itemBasedDiscountAmount.value = 0.0;
      itemBasedAfterDiscount.value = itemBasedSubtotal.value;
      itemBasedDiscountController.text = '0.00';
    }
  }

  void _calculateItemBasedTotals() {
    double subtotal = 0.0;
    
    for (final item in selectedItems) {
      if (item['selected'] == true && (item['quantity'] ?? 0) > 0) {
        final quantity = item['quantity']?.toDouble() ?? 0.0;
        final pricePerUnit = item['pricePerUnit']?.toDouble() ?? 0.0;
        final discount = item['discount']?.toDouble() ?? 0.0;
        
        double itemTotal = quantity * pricePerUnit;
        if (item['discountType'] == 'percent') {
          itemTotal -= (itemTotal * discount / 100);
        } else {
          itemTotal -= discount;
        }
        subtotal += itemTotal;
      }
    }
    
    itemBasedSubtotal.value = subtotal;
    
    // Recalculate discount
    calculateItemBasedDiscount();
  }

  Future<void> createFullInvoice() async {
    try {
      isLoading.value = true;

      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.orange)),
        barrierDismissible: false,
      );

      if (currentWorkspaceId.value.isEmpty) {
        throw Exception('No workspace available');
      }

      // Create invoice data by copying quotation data
      final invoiceData = await _createBaseInvoiceData();
      
      // Set invoice type
      invoiceData['invoiceType'] = 'full';
      
      // Set notes
      invoiceData['notes'] = 'Invoice for Quotation ${quotation['docNo']}';

      // Generate new document number
      invoiceData['docNo'] = await _idGenerationService.generateInvoiceDocNo(currentWorkspaceId.value);

      // Create invoice in Firestore
      final invoiceId = await _repository.createDocument(
        workspaceId: currentWorkspaceId.value,
        documentData: invoiceData,
      );

      // Update quotation status to INVOICED
      await _updateQuotationStatus('INVOICED');

      Get.back(); // Close loading dialog
      Get.back(); // Close options page
      
      // Show success message and navigate to invoice
      Get.snackbar(
        'สำเร็จ', 
        'สร้างใบแจ้งหนี้เต็มจำนวนเรียบร้อยแล้ว',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      // Navigate to the new invoice
      Get.to(() => AddEditDocumentPage(documentType: 'INV', documentId: invoiceId));

    } catch (e) {
      Get.back(); // Close loading dialog
      print('❌ Failed to create full invoice: $e');
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถสร้างใบแจ้งหนี้ได้: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createInstallmentInvoice() async {
    try {
      isLoading.value = true;

      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.orange)),
        barrierDismissible: false,
      );

      if (currentWorkspaceId.value.isEmpty) {
        throw Exception('No workspace available');
      }

      // Create invoice data by copying quotation data
      final invoiceData = await _createBaseInvoiceData();
      
      // Set invoice type
      invoiceData['invoiceType'] = 'installment';
      
      // Get tax settings from quotation
      final isVatEnabled = quotation['isVatEnabled'] == true;
      final isWhtEnabled = quotation['isWhtEnabled'] == true;
      final vatPercentage = (quotation['vatPercentage'] ?? 7.0).toDouble();
      final whtPercentage = (quotation['withholdingTaxPercentage'] ?? 3.0).toDouble();

      // Calculate amounts based on quotation's tax settings
      final subtotal = calculatedAmount.value;
      double vatAmount = 0.0;
      double whtAmount = 0.0;
      double grandTotal = subtotal;
      double netTotal = subtotal;

      if (isVatEnabled) {
        vatAmount = subtotal * (vatPercentage / 100);
        grandTotal += vatAmount;
        netTotal = grandTotal;
      }

      if (isWhtEnabled) {
        whtAmount = subtotal * (whtPercentage / 100);
        netTotal -= whtAmount;
      }
      
      // Update totals with calculated amounts
      invoiceData['subtotal'] = subtotal;
      invoiceData['vatAmount'] = vatAmount;
      invoiceData['grandTotal'] = grandTotal;
      invoiceData['netTotal'] = netTotal;
      invoiceData['whtAmount'] = whtAmount;
      
      // Use quotation's tax settings
      invoiceData['isVatEnabled'] = isVatEnabled;
      invoiceData['vatPercentage'] = vatPercentage;
      invoiceData['isWhtEnabled'] = isWhtEnabled;
      invoiceData['withholdingTaxPercentage'] = whtPercentage;
      
      // Disable discount for installment
      invoiceData['isEndOfBillDiscountEnabled'] = false;
      invoiceData['discount'] = 0.0;
      
      // Create simplified items for installment
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      invoiceData['items'] = [
        {
          "id": "summary-$timestamp",
          "name": "Partial Payment for Quotation ${quotation['docNo']}",
          "description": installmentType.value == 'percent' 
              ? "Invoice for ${installmentInputController.text}% of total amount"
              : "Invoice for ฿${calculatedAmount.value.toStringAsFixed(2)}",
          "quantity": 1,
          "unit": "installment",
          "pricePerUnit": subtotal,
          "discount": 0,
          "discountType": "amount"
        }
      ];
      
      // Set notes
      invoiceData['notes'] = 'Invoice for Quotation ${quotation['docNo']}';

      // Generate new document number
      invoiceData['docNo'] = await _idGenerationService.generateInvoiceDocNo(currentWorkspaceId.value);

      // Create invoice in Firestore
      final invoiceId = await _repository.createDocument(
        workspaceId: currentWorkspaceId.value,
        documentData: invoiceData,
      );

      // Update quotation status to INVOICED
      await _updateQuotationStatus('INVOICED');

      Get.back(); // Close loading dialog
      Get.back(); // Close options page
      
      // Show success message and navigate to invoice
      Get.snackbar(
        'สำเร็จ', 
        'สร้างใบแจ้งหนี้แบ่งจ่ายเรียบร้อยแล้ว',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      // Navigate to the new invoice
      Get.to(() => AddEditDocumentPage(documentType: 'INV', documentId: invoiceId));

    } catch (e) {
      Get.back(); // Close loading dialog
      print('❌ Failed to create installment invoice: $e');
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถสร้างใบแจ้งหนี้ได้: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createItemBasedInvoice() async {
    try {
      isLoading.value = true;

      // Show loading dialog
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.orange)),
        barrierDismissible: false,
      );

      if (currentWorkspaceId.value.isEmpty) {
        throw Exception('No workspace available');
      }

      // Create invoice data by copying quotation data
      final invoiceData = await _createBaseInvoiceData();
      
      // Set invoice type
      invoiceData['invoiceType'] = 'installment';
      
      // Filter and update selected items
      final filteredItems = selectedItems.where((item) => 
          item['selected'] == true && (item['quantity'] ?? 0) > 0).map((item) {
        final newItem = Map<String, dynamic>.from(item);
        newItem.remove('selected');
        newItem.remove('originalQuantity');
        return newItem;
      }).toList();

      invoiceData['items'] = filteredItems;

      // Recalculate totals based on selected items
      double newSubtotal = 0.0;
      for (final item in filteredItems) {
        final quantity = item['quantity']?.toDouble() ?? 0.0;
        final pricePerUnit = item['pricePerUnit']?.toDouble() ?? 0.0;
        final discount = item['discount']?.toDouble() ?? 0.0;
        
        double itemTotal = quantity * pricePerUnit;
        if (item['discountType'] == 'percent') {
          itemTotal -= (itemTotal * discount / 100);
        } else {
          itemTotal -= discount;
        }
        newSubtotal += itemTotal;
      }

      // Apply end-of-bill discount if any
      final endOfBillDiscount = itemBasedDiscountAmount.value;
      final subtotalAfterDiscount = newSubtotal - endOfBillDiscount;
      
      // Get tax settings from quotation
      final isVatEnabled = quotation['isVatEnabled'] == true;
      final isWhtEnabled = quotation['isWhtEnabled'] == true;
      final vatPercentage = (quotation['vatPercentage'] ?? 7.0).toDouble();
      final whtPercentage = (quotation['withholdingTaxPercentage'] ?? 3.0).toDouble();

      // Calculate taxes based on quotation's settings
      double vatAmount = 0.0;
      double whtAmount = 0.0;
      double grandTotal = subtotalAfterDiscount;
      double netTotal = subtotalAfterDiscount;

      if (isVatEnabled) {
        vatAmount = subtotalAfterDiscount * (vatPercentage / 100);
        grandTotal += vatAmount;
        netTotal = grandTotal;
      }

      if (isWhtEnabled) {
        whtAmount = subtotalAfterDiscount * (whtPercentage / 100);
        netTotal -= whtAmount;
      }

      // Update invoice data with calculated amounts
      invoiceData['subtotal'] = newSubtotal;
      invoiceData['discount'] = endOfBillDiscount;
      invoiceData['isEndOfBillDiscountEnabled'] = endOfBillDiscount > 0;
      invoiceData['vatAmount'] = vatAmount;
      invoiceData['grandTotal'] = grandTotal;
      invoiceData['netTotal'] = netTotal;
      invoiceData['whtAmount'] = whtAmount;
      
      // Use quotation's tax settings
      invoiceData['isVatEnabled'] = isVatEnabled;
      invoiceData['vatPercentage'] = vatPercentage;
      invoiceData['isWhtEnabled'] = isWhtEnabled;
      invoiceData['withholdingTaxPercentage'] = whtPercentage;
      
      // Set notes
      invoiceData['notes'] = 'Invoice for Quotation ${quotation['docNo']}';

      // Generate new document number
      invoiceData['docNo'] = await _idGenerationService.generateInvoiceDocNo(currentWorkspaceId.value);

      // Create invoice in Firestore
      final invoiceId = await _repository.createDocument(
        workspaceId: currentWorkspaceId.value,
        documentData: invoiceData,
      );

      // Update quotation status to INVOICED
      await _updateQuotationStatus('INVOICED');

      Get.back(); // Close loading dialog
      Get.back(); // Close options page
      
      // Show success message and navigate to invoice
      Get.snackbar(
        'สำเร็จ', 
        'สร้างใบแจ้งหนี้แบ่งจ่ายแบบรายการเรียบร้อยแล้ว',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
      );

      // Navigate to the new invoice
      Get.to(() => AddEditDocumentPage(documentType: 'INV', documentId: invoiceId));

    } catch (e) {
      Get.back(); // Close loading dialog
      print('❌ Failed to create item-based invoice: $e');
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถสร้างใบแจ้งหนี้ได้: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> _createBaseInvoiceData() async {
    // Create invoice data by copying quotation data
    final invoiceData = Map<String, dynamic>.from(quotation);
    
    // Remove quotation-specific fields
    invoiceData.remove('id');
    invoiceData.remove('validUntil');
    invoiceData.remove('approval');
    invoiceData.remove('approvers');
    
    // Update fields for invoice
    invoiceData['type'] = 'INV';
    invoiceData['status'] = 'DRAFT';
    invoiceData['paymentStatus'] = 'unpaid';
    
    // Keep quotation's tax and discount settings as defaults (will be overridden by specific invoice type methods if needed)
    // These settings will be used by the specific invoice creation methods
    
    // Calculate base totals without tax and discount (will be recalculated by specific methods)
    double subtotal = 0.0;
    final items = List<Map<String, dynamic>>.from(invoiceData['items'] ?? []);
    for (final item in items) {
      final quantity = (item['quantity'] ?? 0).toDouble();
      final pricePerUnit = (item['pricePerUnit'] ?? 0).toDouble();
      final discount = (item['discount'] ?? 0).toDouble();
      
      double lineTotal = quantity * pricePerUnit;
      if (item['discountType'] == 'percent') {
        lineTotal -= (lineTotal * discount / 100);
      } else {
        lineTotal -= discount;
      }
      subtotal += lineTotal;
    }
    
    invoiceData['subtotal'] = subtotal;
    invoiceData['grandTotal'] = subtotal; // Will be recalculated by specific methods
    invoiceData['netTotal'] = subtotal; // Will be recalculated by specific methods
    
    // Add related documents reference
    invoiceData['relatedDocuments'] = [
      {
        'id': quotation['id'],
        'docNo': quotation['docNo'],
        'type': 'QT',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      }
    ];
    
    // Set due date (30 days from now)
    final dueDate = DateTime.now().add(const Duration(days: 30));
    invoiceData['dueDate'] = dueDate.millisecondsSinceEpoch;
    
    // Update timestamps and user info
    final now = DateTime.now().millisecondsSinceEpoch;
    invoiceData['createdAt'] = now;
    invoiceData['updatedAt'] = now;
    invoiceData['createdBy'] = currentUserId.value;
    invoiceData['updatedBy'] = currentUserId.value;
    
    // Update activity log
    invoiceData['activityLog'] = [
      {
        'timestamp': now,
        'userId': currentUserId.value,
        'userDisplayName': invoiceData['seller']?['email'] ?? 'Unknown',
        'action': 'Created',
        'details': 'Created invoice from quotation ${quotation['docNo']}',
      }
    ];

    return invoiceData;
  }

  Future<void> _updateQuotationStatus(String newStatus) async {
    try {
      if (currentWorkspaceId.value.isEmpty || quotation['id'] == null) {
        print('❌ Cannot update quotation status: missing workspace or quotation ID');
        return;
      }

      // Prepare update data
      final updateData = {
        'status': newStatus,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedBy': currentUserId.value,
      };

      // Update quotation status in Firestore
      await _repository.updateDocument(
        workspaceId: currentWorkspaceId.value,
        documentId: quotation['id'],
        documentData: updateData,
      );

      print('✅ Quotation ${quotation['docNo']} status updated to $newStatus');
    } catch (e) {
      print('❌ Failed to update quotation status: $e');
      // Don't throw error here as the invoice was already created successfully
    }
  }
}
