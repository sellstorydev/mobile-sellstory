import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../domain/entities/job_card.dart';
import '../../board/controller/board_controller.dart';

class ArchiveController extends GetxController {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  final BoardController _boardController = Get.find<BoardController>();
  
  final isLoading = false.obs;
  final archiveItems = <JobCard>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadArchiveItems();
  }

  void loadArchiveItems() async {
    try {
      isLoading.value = true;
      
      // Get current workspace ID from BoardController
      final workspaceId = _boardController.currentWorkspaceId.value;
      
      if (workspaceId.isEmpty) {
        print('❌ No workspace selected for archive');
        archiveItems.clear();
        return;
      }      
      // Get all cards stream and filter for archived ones
      _repository.getAllCardsStream(workspaceId).listen((allCards) {
        final archivedCards = allCards.where((card) => card.status == 'Archived').toList();
        
        // Sort by updatedAt descending (most recent first)
        archivedCards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        
        archiveItems.value = archivedCards;
      }, onError: (error) {
        print('❌ Failed to load archived cards: $error');
        Get.snackbar(
          'Error',
          'Failed to load archive: $error',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      });
    } catch (e) {
      print('❌ Failed to load archive items: $e');
      Get.snackbar(
        'Error',
        'Failed to load archive: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> restoreItem(String itemId) async {
    try {
      isLoading.value = true;
      
      // Get current workspace ID
      final workspaceId = _boardController.currentWorkspaceId.value;
      
      if (workspaceId.isEmpty) {
        throw Exception('No workspace selected');
      }
      
      // Find the card in archive items
      final card = archiveItems.firstWhereOrNull((item) => item.id == itemId);
      if (card == null) {
        throw Exception('Card not found in archive');
      }
      
      // Update card status to "Pending" 
      final updatedCard = card.copyWith(
        status: 'Pending',
        updatedAt: DateTime.now(),
      );
      
      // Update in Firestore
      await _repository.updateCard(workspaceId, updatedCard);
      
      Get.snackbar(
        'สำเร็จ',
        'กู้คืนรายการ "${card.title}" เรียบร้อยแล้ว',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.primaryOrange.withValues(alpha: 0.1),
        colorText: AppTheme.primaryOrange,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Failed to restore item: $e');
      Get.snackbar(
        'Error',
        'ไม่สามารถกู้คืนรายการได้: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
        colorText: Get.theme.colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteItem(String itemId) async {
    // Show confirmation dialog first
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('คุณต้องการลบรายการนี้ถาวรหรือไม่? การดำเนินการนี้ไม่สามารถยกเลิกได้'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        isLoading.value = true;
        
        // Get current workspace ID
        final workspaceId = _boardController.currentWorkspaceId.value;
        
        if (workspaceId.isEmpty) {
          throw Exception('No workspace selected');
        }
        
        // Find the card to get its title for the success message
        final card = archiveItems.firstWhereOrNull((item) => item.id == itemId);
        final cardTitle = card?.title ?? 'Unknown';
        
        // Delete from Firestore
        await _repository.deleteCard(workspaceId, itemId);
        
        Get.snackbar(
          'สำเร็จ',
          'ลบรายการ "$cardTitle" เรียบร้อยแล้ว',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        print('❌ Failed to delete item: $e');
        Get.snackbar(
          'Error',
          'ไม่สามารถลบรายการได้: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error.withValues(alpha: 0.1),
          colorText: Get.theme.colorScheme.error,
        );
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> refreshArchive() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 500)); // Small delay for better UX
      loadArchiveItems(); // This will reload the data from Firestore
    } finally {
      // isLoading will be set to false in loadArchiveItems()
    }
  }
}
