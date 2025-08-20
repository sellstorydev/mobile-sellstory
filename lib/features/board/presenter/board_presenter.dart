import '../../../core/services/logger_service.dart';
import '../../../data/repositories/jobcard_repository.dart';
import '../../../domain/usecases/add_card_usecase.dart';
import '../../../domain/usecases/add_lane_usecase.dart';
import '../../../domain/usecases/move_card_usecase.dart';
import '../../../domain/usecases/reorder_card_in_lane_usecase.dart';
import '../contract/board_view.dart';
import '../state/board_state.dart';

class BoardPresenter {
  final JobCardRepository _repository;
  final MoveCardUseCase _moveCardUseCase;
  final ReorderCardInLaneUseCase _reorderCardInLaneUseCase;
  final AddCardUseCase _addCardUseCase;
  final AddLaneUseCase _addLaneUseCase;
  
  BoardView? _view;
  BoardState _currentState = const BoardState(lanes: []);

  BoardPresenter({
    required JobCardRepository repository,
    required MoveCardUseCase moveCardUseCase,
    required ReorderCardInLaneUseCase reorderCardInLaneUseCase,
    required AddCardUseCase addCardUseCase,
    required AddLaneUseCase addLaneUseCase,
  }) : _repository = repository,
       _moveCardUseCase = moveCardUseCase,
       _reorderCardInLaneUseCase = reorderCardInLaneUseCase,
       _addCardUseCase = addCardUseCase,
       _addLaneUseCase = addLaneUseCase;

  void attachView(BoardView view) {
    LoggerService.to.lifecycle('BoardPresenter', 'View attached');
    _view = view;
  }

  void detachView() {
    LoggerService.to.lifecycle('BoardPresenter', 'View detached');
    _view = null;
  }

  Future<void> load() async {
    LoggerService.to.methodEntry('BoardPresenter.load');
    _view?.showLoading(true);
    
    try {
      final lanes = await _repository.getLanes();
      LoggerService.to.business('Loaded ${lanes.length} lanes from repository');
      
      _currentState = _currentState.copyWith(
        lanes: lanes,
        isLoading: false,
        error: null,
      );
      _view?.render(_currentState);
    } catch (e) {
      LoggerService.to.error('Failed to load lanes', e);
      _currentState = _currentState.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _view?.showError(e.toString());
    }
    
    LoggerService.to.methodExit('BoardPresenter.load');
  }

  Future<void> onMoveCard({
    required String cardId,
    required String fromLaneId,
    required String toLaneId,
    required int toIndex,
  }) async {
    LoggerService.to.methodEntry('BoardPresenter.onMoveCard', {
      'cardId': cardId,
      'fromLaneId': fromLaneId,
      'toLaneId': toLaneId,
      'toIndex': toIndex,
    });
    
    try {
      final updatedLanes = _moveCardUseCase.execute(
        lanes: _currentState.lanes,
        cardId: cardId,
        fromLaneId: fromLaneId,
        toLaneId: toLaneId,
        toIndex: toIndex,
      );
      
      LoggerService.to.business('Card moved successfully');
      
      // Optimistic update
      _currentState = _currentState.copyWith(lanes: updatedLanes);
      _view?.render(_currentState);
      
      // Persist to repository
      await _repository.updateLanes(updatedLanes);
      LoggerService.to.database('Lanes updated in repository');
    } catch (e) {
      LoggerService.to.error('Failed to move card', e);
      _view?.showError('Failed to move card: ${e.toString()}');
      // Reload to revert optimistic update
      await load();
    }
    
    LoggerService.to.methodExit('BoardPresenter.onMoveCard');
  }

  Future<void> onReorderInLane({
    required String laneId,
    required int oldIndex,
    required int newIndex,
  }) async {
    try {
      final updatedLanes = _reorderCardInLaneUseCase.execute(
        lanes: _currentState.lanes,
        laneId: laneId,
        oldIndex: oldIndex,
        newIndex: newIndex,
      );
      
      // Optimistic update
      _currentState = _currentState.copyWith(lanes: updatedLanes);
      _view?.render(_currentState);
      
      // Persist to repository
      await _repository.updateLanes(updatedLanes);
    } catch (e) {
      _view?.showError('Failed to reorder card: ${e.toString()}');
      // Reload to revert optimistic update
      await load();
    }
  }

  Future<void> onAddLane(String title, String boardId) async {
    try {
      final updatedLanes = _addLaneUseCase.execute(
        lanes: _currentState.lanes,
        title: title,
        boardId: boardId,
      );
      
      // Optimistic update
      _currentState = _currentState.copyWith(lanes: updatedLanes);
      _view?.render(_currentState);
      
      // Persist to repository
      await _repository.updateLanes(updatedLanes);
    } catch (e) {
      _view?.showError('Failed to add lane: ${e.toString()}');
      // Reload to revert optimistic update
      await load();
    }
  }

  Future<void> onAddCard({
    required String laneId,
    required String title,
    required String assignee,
    required List<String> badges,
    required double amount,
    DateTime? dueDate,
  }) async {
    try {
      final updatedLanes = _addCardUseCase.execute(
        lanes: _currentState.lanes,
        laneId: laneId,
        title: title,
        assignee: assignee,
        badges: badges,
        amount: amount,
        dueDate: dueDate,
      );
      
      // Optimistic update
      _currentState = _currentState.copyWith(lanes: updatedLanes);
      _view?.render(_currentState);
      
      // Persist to repository
      await _repository.updateLanes(updatedLanes);
    } catch (e) {
      _view?.showError('Failed to add card: ${e.toString()}');
      // Reload to revert optimistic update
      await load();
    }
  }
}
