import 'package:get/get.dart';
import '../services/logger_service.dart';
import '../../data/repositories/jobcard_repository.dart';
import '../../data/repositories/firestore_repository.dart';
import '../../data/services/firestore_service.dart';
import '../../domain/usecases/add_card_usecase.dart';
import '../../domain/usecases/add_lane_usecase.dart';
import '../../domain/usecases/move_card_usecase.dart';
import '../../domain/usecases/reorder_card_in_lane_usecase.dart';
import '../../features/board/presenter/board_presenter.dart';

class Locator {
  static void setup() {
    // Core Services
    Get.put<LoggerService>(LoggerService(), permanent: true);
    
    // Services
    Get.lazyPut<FirestoreService>(() => FirestoreService(), fenix: true);
    
    // Repositories
    Get.lazyPut<JobCardRepository>(() => InMemoryJobCardRepository());
    Get.lazyPut<FirestoreRepository>(() => FirestoreRepository());
    
    // Use cases
    Get.lazyPut<MoveCardUseCase>(() => MoveCardUseCase());
    Get.lazyPut<ReorderCardInLaneUseCase>(() => ReorderCardInLaneUseCase());
    Get.lazyPut<AddCardUseCase>(() => AddCardUseCase());
    Get.lazyPut<AddLaneUseCase>(() => AddLaneUseCase());
    
    // Presenter
    Get.lazyPut<BoardPresenter>(() => BoardPresenter(
      repository: Get.find<JobCardRepository>(),
      moveCardUseCase: Get.find<MoveCardUseCase>(),
      reorderCardInLaneUseCase: Get.find<ReorderCardInLaneUseCase>(),
      addCardUseCase: Get.find<AddCardUseCase>(),
      addLaneUseCase: Get.find<AddLaneUseCase>(),
    ));
  }
}
