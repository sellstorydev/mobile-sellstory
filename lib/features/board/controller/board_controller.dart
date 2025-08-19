import 'package:get/get.dart';
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
    load();
  }

  @override
  void onClose() {
    _presenter.detachView();
    super.onClose();
  }

  Future<void> load() async {
    await _presenter.load();
  }

  Future<void> onMoveCard({
    required String cardId,
    required String fromLaneId,
    required String toLaneId,
    required int toIndex,
  }) async {
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
    await _presenter.onReorderInLane(
      laneId: laneId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
  }

  Future<void> onAddLane(String title) async {
    await _presenter.onAddLane(title);
  }

  Future<void> onAddCard({
    required String laneId,
    required String title,
    required String assignee,
    required List<String> badges,
    required double amount,
    DateTime? dueDate,
  }) async {
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
    this.isLoading.value = isLoading;
  }

  @override
  void showError(String message) {
    error?.value = message;
  }

  @override
  void render(BoardState state) {
    lanes.value = state.lanes;
    isLoading.value = state.isLoading;
    error?.value = state.error ?? '';
  }
}
