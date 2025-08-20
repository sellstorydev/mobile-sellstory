import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';
import '../../../domain/entities/lane.dart';
import '../contract/board_view.dart';
import '../presenter/board_presenter.dart';
import '../state/board_state.dart';

class BoardController extends GetxController implements BoardView {
  final BoardPresenter _presenter;
  
  // Reactive state
  final RxList<Lane> lanes = <Lane>[].obs;
  final RxBool isLoading = false.obs;
  final RxString? error = RxString('');

  BoardController({
    required BoardPresenter presenter,
  }) : _presenter = presenter {
    _presenter.attachView(this);
  }

  @override
  void onInit() {
    super.onInit();
    LoggerService.to.lifecycle('BoardController', 'Initialized');
    load();
  }

  @override
  void onClose() {
    LoggerService.to.lifecycle('BoardController', 'Disposed');
    _presenter.detachView();
    super.onClose();
  }

  Future<void> load() async {
    LoggerService.to.methodEntry('BoardController.load');
    await _presenter.load();
    LoggerService.to.methodExit('BoardController.load');
  }

  Future<void> onMoveCard({
    required String cardId,
    required String fromLaneId,
    required String toLaneId,
    required int toIndex,
  }) async {
    LoggerService.to.userAction('Move Card', {
      'cardId': cardId,
      'fromLaneId': fromLaneId,
      'toLaneId': toLaneId,
      'toIndex': toIndex,
    });
    
    await _presenter.onMoveCard(
      cardId: cardId,
      fromLaneId: fromLaneId,
      toLaneId: toLaneId,
      toIndex: toIndex,
    );
  }

  Future<void> onReorderInLane({
    required String laneId,
    required int oldIndex,
    required int newIndex,
  }) async {
    LoggerService.to.userAction('Reorder Card in Lane', {
      'laneId': laneId,
      'oldIndex': oldIndex,
      'newIndex': newIndex,
    });
    
    await _presenter.onReorderInLane(
      laneId: laneId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
  }

  Future<void> onAddLane(String title, String boardId) async {
    LoggerService.to.userAction('Add Lane', {
      'title': title,
      'boardId': boardId,
    });
    
    await _presenter.onAddLane(title, boardId);
  }

  Future<void> onAddCard({
    required String laneId,
    required String title,
    required String assignee,
    required List<String> badges,
    required double amount,
    DateTime? dueDate,
  }) async {
    LoggerService.to.userAction('Add Card', {
      'laneId': laneId,
      'title': title,
      'assignee': assignee,
      'badges': badges,
      'amount': amount,
      'dueDate': dueDate?.toIso8601String(),
    });
    
    await _presenter.onAddCard(
      laneId: laneId,
      title: title,
      assignee: assignee,
      badges: badges,
      amount: amount,
      dueDate: dueDate,
    );
  }

  // BoardView implementation
  @override
  void showLoading(bool isLoading) {
    LoggerService.to.ui('Loading state changed: $isLoading');
    this.isLoading.value = isLoading;
  }

  @override
  void showError(String message) {
    LoggerService.to.error('Board error: $message');
    error?.value = message;
  }

  @override
  void render(BoardState state) {
    LoggerService.to.state('Board state updated', {
      'lanesCount': state.lanes.length,
      'isLoading': state.isLoading,
      'hasError': state.error?.isNotEmpty ?? false,
    });
    
    lanes.value = state.lanes;
    isLoading.value = state.isLoading;
    error?.value = state.error ?? '';
  }
}
