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
    _initializeUserAndWorkspace();
  }

  Future<void> _initializeUserAndWorkspace() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        
        // Get workspace from controller or repository
        final workspaceSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (workspaceSnapshot.exists) {
          _currentWorkspaceId = workspaceSnapshot.data()?['currentWorkspaceId'];
        }
      }
    } catch (e) {
      print('❌ Failed to initialize user and workspace: $e');
    }
  }

  // Initialize with job card and optional template ID
  Future<void> initializeWithJobCard(JobCard jobCard, {String? templateId}) async {
    await _initializeUserAndWorkspace();
    // Additional initialization logic can be added here if needed
  }

  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  /// สร้าง quotation จาก job card โดยอัตโนมัติ
  Future<String?> createQuotationFromJobCard(JobCard jobCard, {String? templateId}) async {
    print('🎯 CreateDocumentFromCardController - received templateId: $templateId');
    
    if (_currentUserId == null || _currentWorkspaceId == null) {
      Get.snackbar('Error', 'User or workspace not found');
      return null;
    }

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

      // Calculate totals from job card expenses
      final calculations = _calculateTotalsFromJobCard(jobCard);

      // Create document data structure similar to web version
      final documentData = {
        'docNo': docNo,
        'type': 'QT',
        'workspaceId': _currentWorkspaceId!,
        'status': 'DRAFT',
        
        // Customer information from job card
        'customer': {
          'id': jobCard.customerId,
          'name': jobCard.customer,
        },
        
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
        
        // Items from job card expenses
        'items': _convertExpensesToItems(jobCard.expenses),
        
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
        'Success',
        'Quotation $docNo created successfully',
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
        'Error',
        'Failed to create quotation: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// แปลง expenses จาก job card เป็น items สำหรับ quotation
  List<Map<String, dynamic>> _convertExpensesToItems(List<Map<String, dynamic>> expenses) {
    return expenses.map((expense) => {
      'id': expense['id'],
      'productId': expense['productId'],
      'name': expense['name'],
      'description': expense['description'] ?? '',
      'quantity': expense['quantity'] ?? 1,
      'unit': expense['unit'] ?? 'item',
      'pricePerUnit': expense['pricePerUnit'] ?? 0,
      'discount': expense['discount'] ?? 0,
      'discountType': expense['discountType'] ?? 'amount',
    }).toList();
  }

  /// คำนวณยอดรวมต่างๆ จาก job card
  Map<String, double> _calculateTotalsFromJobCard(JobCard jobCard) {
    final expenses = jobCard.expenses;
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
    
    // คำนวณ VAT (7%)
    final isVatEnabled = jobCard.isVatEnabled;
    final vatAmount = isVatEnabled ? (afterDiscount * 0.07) : 0.0;
    
    final grandTotal = afterDiscount + vatAmount;
    
    // คำนวณ WHT
    final whtPercentage = jobCard.withholdingTaxPercentage.toDouble() / 100;
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
