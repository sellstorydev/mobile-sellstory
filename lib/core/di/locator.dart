import 'package:get/get.dart';
import 'package:flutter/foundation.dart'; // Add this import
import '../services/logger_service.dart';
import '../../data/repositories/jobcard_repository.dart';
import '../../data/repositories/firestore_repository.dart';
import '../../data/services/firestore_service.dart';
import '../../domain/usecases/add_card_usecase.dart';
import '../../domain/usecases/add_lane_usecase.dart';
import '../../domain/usecases/move_card_usecase.dart';
import '../../domain/usecases/reorder_card_in_lane_usecase.dart';
import '../../features/board/controller/board_controller.dart';
import '../../features/chat/controller/chat_controller.dart';

class Locator {
  static void setup() {
    final logger = Get.isRegistered<LoggerService>() ? Get.find<LoggerService>() : null;
    
    // Reduce logging in production
    if (kDebugMode) {
      logger?.devTools('Locator.setup() called', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    // Core Services (only if not already registered)
    if (!Get.isRegistered<LoggerService>()) {
      Get.put<LoggerService>(LoggerService(), permanent: true);
      if (kDebugMode) logger?.devTools('LoggerService registered');
    }
    
    // Services
    Get.lazyPut<FirestoreService>(() => FirestoreService(), fenix: true);

    // Repositories
    Get.lazyPut<JobCardRepository>(() => InMemoryJobCardRepository(), fenix: true);
    Get.lazyPut<FirestoreRepository>(() => FirestoreRepository(), fenix: true);

    // Use cases
    Get.lazyPut<MoveCardUseCase>(() => MoveCardUseCase(), fenix: true);
    Get.lazyPut<ReorderCardInLaneUseCase>(() => ReorderCardInLaneUseCase(), fenix: true);
    Get.lazyPut<AddCardUseCase>(() => AddCardUseCase(), fenix: true);
    Get.lazyPut<AddLaneUseCase>(() => AddLaneUseCase(), fenix: true);

    // Controllers
    Get.lazyPut<BoardController>(() => BoardController(), fenix: true);
    Get.lazyPut<ChatController>(() => ChatController(), fenix: true);

    if (kDebugMode) {
      logger?.devTools('Locator.setup() completed', {
        'timestamp': DateTime.now().toIso8601String(),
        'services_count': 9, // Updated count
      });
    }
  }
  
  // Method to re-setup dependencies after logout/login
  static void resetDependencies() {
    final logger = Get.isRegistered<LoggerService>() ? Get.find<LoggerService>() : null;
    
    logger?.devTools('Locator.resetDependencies() called', {
      'timestamp': DateTime.now().toIso8601String(),
      'reason': 'logout/login cycle',
    });
    
    // Clear non-permanent dependencies
    Get.delete<BoardController>(force: true);
    Get.delete<FirestoreRepository>(force: true);
    Get.delete<FirestoreService>(force: true);
    Get.delete<JobCardRepository>(force: true);
    Get.delete<MoveCardUseCase>(force: true);
    Get.delete<ReorderCardInLaneUseCase>(force: true);
    Get.delete<AddCardUseCase>(force: true);
    Get.delete<AddLaneUseCase>(force: true);
    Get.delete<ChatController>(force: true); // Ensure ChatController is also deleted

    logger?.devTools('Dependencies cleared', {
      'clearedDependencies': [
        'BoardController',
        'FirestoreRepository', 
        'FirestoreService',
        'JobCardRepository',
        'MoveCardUseCase',
        'ReorderCardInLaneUseCase',
        'AddCardUseCase',
        'AddLaneUseCase',
        'ChatController', // Added ChatController to the list
      ],
    });
    
    // Re-setup dependencies
    setup();
    
    logger?.devTools('Dependencies reset completed', {
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'success',
    });
  }
}
