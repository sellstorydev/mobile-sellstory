import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../domain/entities/job_card.dart';
import '../../../core/services/id_generation_service.dart';
import 'quotations_list_controller.dart';

class CreateDocumentFromCardController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  final IdGenerationService _idService = Get.find<IdGenerationService>();

  // Loading state
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  // User and workspace
  String? _currentUserId;
  String? _currentWorkspaceId;

  @override
  void onInit() {
    super.onInit();
    // Don't initialize here, wait for initializeWithJobCard to be called
    // This ensures we have job card data to use for workspace ID
  }

  Future<void> _initializeUserAndWorkspace({JobCard? jobCard}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        
        // ลำดับความสำคัญในการหา workspace ID:
        // 1. จาก job card ถ้ามี
        // 2. จาก user's currentWorkspaceId
        // 3. จาก user's first workspace
        
        if (jobCard != null && jobCard.workspaceId.isNotEmpty) {
          _currentWorkspaceId = jobCard.workspaceId;
          print('🎯 Using workspace ID from job card: $_currentWorkspaceId');
        } else {
          // Get workspace from user document
          final workspaceSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
              
          if (workspaceSnapshot.exists) {
            final userData = workspaceSnapshot.data()!;
            _currentWorkspaceId = userData['currentWorkspaceId'];
            print('🎯 Using workspace ID from user currentWorkspaceId: $_currentWorkspaceId');
            
            // ถ้ายังไม่มี workspace ID ให้หา workspace แรกของ user
            if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) {
              final userWorkspaces = await _repository.getUserWorkspaces(user.uid);
              if (userWorkspaces.isNotEmpty) {
                _currentWorkspaceId = userWorkspaces.first['id'] as String;
                print('🎯 Using first workspace from user workspaces: $_currentWorkspaceId');
              }
            }
          }
        }
      }
      
      print('🎯 Final workspace ID: $_currentWorkspaceId, User ID: $_currentUserId');
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
    }
  }

  // Initialize with job card and optional template ID
  Future<void> initializeWithJobCard(JobCard jobCard, {String? templateId}) async {
    await _initializeUserAndWorkspace(jobCard: jobCard);
    // Additional initialization logic can be added here if needed
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  /// สร้าง quotation จาก job card โดยอัตโนมัติ
  Future<String?> createQuotationFromJobCard(JobCard jobCard, {String? templateId}) async {
    print('🎯 CreateDocumentFromCardController - received templateId: $templateId');
    
    // Re-initialize to ensure we have correct workspace and user data
    await _initializeUserAndWorkspace(jobCard: jobCard);
    
    if (_currentUserId == null) {
      print('❌ Current user ID is null');
      Get.snackbar('error'.tr, 'please_login_again'.tr);
      return null;
    }
    
    if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) {
      print('❌ Current workspace ID is null or empty. Job card workspace: ${jobCard.workspaceId}');
      Get.snackbar('error'.tr, 'workspace_not_found_check_access'.tr);
      return null;
    }

    print('🎯 Using User ID: $_currentUserId, Workspace ID: $_currentWorkspaceId');

    _setLoading(true);

    try {
      // Generate document number
      final docNo = await _idService.generateDocumentDocNo(
        _currentWorkspaceId!,
        'quotation'
      );

      // Get current user info
      final currentUserInfo = await _repository.getCurrentUserInfo(_currentUserId!);
      
      // Get template ID (use provided templateId or get default)
      final finalTemplateId = templateId ?? await _getDefaultQuotationTemplateId();
      print('🎯 Final templateId to use: $finalTemplateId');

      // Get items from Firestore subcollection (includes customInputs)
      final items = await _getItemsFromFirestoreSubcollection(jobCard);
      
      // Calculate totals from the fetched items
      final calculations = _calculateTotalsFromItems(items, jobCard);

      // Create document data structure similar to web version
      final documentData = {
        'docNo': docNo,
        'type': 'QT',
        'workspaceId': _currentWorkspaceId!,
        'status': 'DRAFT',
        
        // Customer information from job card (get full customer data)
        'customer': await _getFullCustomerData(jobCard.customerId ?? ''),
        
        // Seller information from current user
        'seller': {
          'uid': _currentUserId!,
          'displayName': currentUserInfo?['displayName'] ?? '',
          'photoURL': currentUserInfo?['photoURL'],
        },
        'sellerName': currentUserInfo?['displayName'] ?? '',
        
        // Job card information
        'jobName': jobCard.title,
        'jobCardId': jobCard.id,
        'jobcardCustomId': jobCard.customId,
        'jobCardBoardId': jobCard.boardId,
        
        // Project information (empty as default)
        'project': {
          'name': '',
          'refId': '',
        },
        
        // Items from job card expenses (fetch from Firestore subcollection)
        'items': items,
        
        // Calculated amounts
        'subtotal': calculations['subtotal'],
        'discount': calculations['discount'],
        'vatAmount': calculations['vatAmount'],
        'grandTotal': calculations['grandTotal'],
        'whtAmount': calculations['whtAmount'],
        'withholdingTaxPercentage': jobCard.withholdingTaxPercentage.toDouble(),
        'netTotal': calculations['netTotal'],
        'isVatEnabled': jobCard.isVatEnabled,
        
        // Valid until (30 days from now as default)
        'validUntil': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch,
        
        // Timestamps
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'createdBy': _currentUserId!,
        'updatedBy': _currentUserId!,
        
        // Activity log
        'activityLog': [
          {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'userId': _currentUserId!,
            'userDisplayName': currentUserInfo?['displayName'] ?? '',
            'action': 'Created',
            'details': 'Created quotation $docNo from job card ${jobCard.customId}',
          }
        ],
        
        // Template ID
        'templateId': finalTemplateId,
      };

      // Save document to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(_currentWorkspaceId!)
          .collection('documents')
          .add(documentData);

      // Update job card with related document
      await _updateJobCardWithRelatedDocument(jobCard.id, docRef.id, docNo);

      // Show success message
      Get.snackbar(
        'success'.tr,
        'quotation_created_success_with_no'.trParams({'docNo': docNo}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh quotations list if available
      try {
        final quotationsController = Get.find<QuotationsListController>();
        quotationsController.refreshData();
      } catch (e) {
        // Controller not found, ignore
      }

      return docRef.id;

    } catch (e) {
      print('❌ Failed to create quotation from job card: $e');
      Get.snackbar(
        'error'.tr,
        'error_occurred_details'.trParams({'error': e.toString()}),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// ดึงข้อมูล customer แบบเต็มจาก Firestore
  Future<Map<String, dynamic>> _getFullCustomerData(String customerId) async {
    try {
      final customerDoc = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(_currentWorkspaceId!)
          .collection('customers')
          .doc(customerId)
          .get();

      if (customerDoc.exists) {
        return customerDoc.data()!;
      } else {
        // Fallback to basic data
        return {
          'id': customerId,
          'name': 'Unknown Customer',
        };
      }
    } catch (e) {
      print('❌ Error getting customer data: $e');
      return {
        'id': customerId,
        'name': 'Unknown Customer',
      };
    }
  }

  /// ดึงข้อมูล items จาก Firestore subcollection เพื่อให้ได้ customInputs
  Future<List<Map<String, dynamic>>> _getItemsFromFirestoreSubcollection(JobCard jobCard) async {
    try {
      print('🔍 Getting items from Firestore subcollection for card: ${jobCard.id}');
      
      final expensesSnapshot = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(_currentWorkspaceId!)
          .collection('cards')
          .doc(jobCard.id)
          .collection('expenses')
          .get();

      final items = <Map<String, dynamic>>[];
      
      for (final doc in expensesSnapshot.docs) {
        final expenseData = doc.data();
        
        print('🔍 Processing expense: ${expenseData['name']} - customInputs: ${expenseData['customInputs']}');
        
        final item = {
          'id': doc.id,
          'productId': expenseData['productId'],
          'name': expenseData['name'],
          'description': expenseData['description'] ?? '',
          'quantity': expenseData['quantity'] ?? 1,
          'unit': expenseData['unit'] ?? 'item',
          'pricePerUnit': expenseData['pricePerUnit'] ?? 0,
          'discount': expenseData['discount'] ?? 0,
          'discountType': expenseData['discountType'] ?? 'amount',
          // ดึง customInputs จาก Firestore subcollection
          'customInputs': expenseData['customInputs'] ?? {},
        };
        
        items.add(item);
      }
      
      // Sort by order if available
      items.sort((a, b) {
        final orderA = a['order'] ?? 0;
        final orderB = b['order'] ?? 0;
        return orderA.compareTo(orderB);
      });
      
      print('✅ Successfully retrieved ${items.length} items with customInputs from Firestore');
      return items;
      
    } catch (e) {
      print('❌ Error getting items from Firestore subcollection: $e');
      // Fallback to job card expenses if Firestore fails
      print('🔄 Falling back to job card expenses');
      return _convertExpensesToItems(jobCard.expenses);
    }
  }

  /// แปลง expenses จาก job card เป็น items สำหรับ quotation
  List<Map<String, dynamic>> _convertExpensesToItems(List<Map<String, dynamic>> expenses) {
    print('🔍 _convertExpensesToItems - Processing ${expenses.length} expenses');
    
    final convertedItems = expenses.map((expense) {
      final customInputs = expense['customInputs'] ?? {};
      print('🔍 Expense: ${expense['name']} - customInputs: $customInputs');
      
      return {
        'id': expense['id'],
        'productId': expense['productId'],
        'name': expense['name'],
        'description': expense['description'] ?? '',
        'quantity': expense['quantity'] ?? 1,
        'unit': expense['unit'] ?? 'item',
        'pricePerUnit': expense['pricePerUnit'] ?? 0,
        'discount': expense['discount'] ?? 0,
        'discountType': expense['discountType'] ?? 'amount',
        // เพิ่ม customInputs เพื่อให้ PDF แสดง custom columns ถูกต้อง
        'customInputs': customInputs,
      };
    }).toList();
    
    print('🔍 Converted ${convertedItems.length} items with customInputs');
    return convertedItems;
  }

  /// คำนวณยอดรวมต่างๆ จาก items ที่ดึงมาจาก Firestore
  Map<String, double> _calculateTotalsFromItems(List<Map<String, dynamic>> items, JobCard jobCard) {
    double subtotal = 0.0;
    double totalDiscount = 0.0;

    // คำนวณ subtotal และ discount จาก items
    for (final item in items) {
      final quantity = (item['quantity'] ?? 1).toDouble();
      final pricePerUnit = (item['pricePerUnit'] ?? 0).toDouble();
      final discount = (item['discount'] ?? 0).toDouble();
      final discountType = item['discountType'] ?? 'amount';

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
    final additionalDiscount = jobCard.additionalDiscount;
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
    
    // คำนวณ VAT
    final vatRate = jobCard.isVatEnabled ? 0.07 : 0.0;
    final vatAmount = afterDiscount * vatRate;
    
    final grandTotal = afterDiscount + vatAmount;
    
    // คำนวณ Withholding Tax
    final whtRate = jobCard.withholdingTaxPercentage / 100.0;
    final whtAmount = grandTotal * whtRate;
    
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

  /// ดึง default template ID สำหรับ quotation
  Future<String> _getDefaultQuotationTemplateId() async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(_currentWorkspaceId!)
          .get();

      if (profileDoc.exists) {
        final data = profileDoc.data()!;
        final companyProfile = data['companyProfile'] as Map<String, dynamic>?;
        final docSettings = companyProfile?['docSettings'] as Map<String, dynamic>?;
        final defaultTemplateIds = docSettings?['defaultTemplateIds'] as Map<String, dynamic>?;
        
        return defaultTemplateIds?['quotation'] ?? '';
      }
    } catch (e) {
      print('❌ Failed to get default template ID: $e');
    }
    
    return '';
  }

  /// อัปเดต job card ด้วยข้อมูล related document
  Future<void> _updateJobCardWithRelatedDocument(String cardId, String documentId, String docNo) async {
    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(_currentWorkspaceId!)
          .collection('cards')
          .doc(cardId)
          .update({
        'relatedDocuments': FieldValue.arrayUnion([
          {
            'id': documentId,
            'docNo': docNo,
            'type': 'QT',
          }
        ]),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('❌ Failed to update job card with related document: $e');
    }
  }
}
