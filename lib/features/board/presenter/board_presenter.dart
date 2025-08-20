import '../../../core/services/logger_service.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../../../domain/entities/lane.dart';
import '../../../domain/entities/job_card.dart';
import '../../../domain/usecases/add_card_usecase.dart';
import '../../../domain/usecases/add_lane_usecase.dart';
import '../../../domain/usecases/move_card_usecase.dart';
import '../../../domain/usecases/reorder_card_in_lane_usecase.dart';
import '../contract/board_view.dart';
import '../state/board_state.dart';

class BoardPresenter {
  final FirestoreRepository _repository;
  final MoveCardUseCase _moveCardUseCase;
  final ReorderCardInLaneUseCase _reorderCardInLaneUseCase;
  final AddCardUseCase _addCardUseCase;
  final AddLaneUseCase _addLaneUseCase;
  
  BoardView? _view;
  BoardState _currentState = const BoardState(lanes: []);

  BoardPresenter(this._view, this._repository)
      : _moveCardUseCase = MoveCardUseCase(),
        _reorderCardInLaneUseCase = ReorderCardInLaneUseCase(),
        _addCardUseCase = AddCardUseCase(),
        _addLaneUseCase = AddLaneUseCase();

  void attachView(BoardView view) {
    LoggerService.to.lifecycle('BoardPresenter', 'View attached');
    _view = view;
  }

  void detachView() {
    LoggerService.to.lifecycle('BoardPresenter', 'View detached');
    _view = null;
  }

  Future<void> load(String workspaceId) async {
    LoggerService.to.methodEntry('BoardPresenter.load', {'workspaceId': workspaceId});
    _view?.showLoading(true);
    
    try {
      // Listen to lanes stream
      _repository.getLanesStream(workspaceId).listen((lanes) {
        LoggerService.to.business('Loaded ${lanes.length} lanes from repository');
        
        _currentState = _currentState.copyWith(
          lanes: lanes,
          isLoading: false,
          error: null,
        );
        _view?.render(_currentState);
      });
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
    required String workspaceId,
    required String cardId,
    required String fromLaneId,
    required String toLaneId,
    required int toIndex,
  }) async {
    LoggerService.to.methodEntry('BoardPresenter.onMoveCard', {
      'workspaceId': workspaceId,
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
      await _repository.moveCard(workspaceId, cardId, fromLaneId, toLaneId, toIndex);
      LoggerService.to.database('Card moved in repository');
    } catch (e) {
      LoggerService.to.error('Failed to move card', e);
      _view?.showError('Failed to move card: ${e.toString()}');
      // Reload to revert optimistic update
      await load(workspaceId);
    }
    
    LoggerService.to.methodExit('BoardPresenter.onMoveCard');
  }

  Future<void> onReorderInLane({
    required String workspaceId,
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
      await _repository.reorderCardsInLane(workspaceId, laneId, updatedLanes.firstWhere((l) => l.id == laneId).cards.map((c) => c.id).toList());
    } catch (e) {
      _view?.showError('Failed to reorder card: ${e.toString()}');
      // Reload to revert optimistic update
      await load(workspaceId);
    }
  }

  Future<void> onAddLane(String workspaceId, String title) async {
    try {
      final newLane = Lane(
        id: '',
        title: title,
        boardId: workspaceId,
        order: _currentState.lanes.length,
        cards: [],
      );
      
      // Create lane in repository
      final laneId = await _repository.createLane(workspaceId, newLane);
      
      LoggerService.to.business('Lane created successfully');
    } catch (e) {
      _view?.showError('Failed to add lane: ${e.toString()}');
    }
  }

  Future<void> onAddCard({
    required String workspaceId,
    required String laneId,
    required String title,
    required String assignee,
  }) async {
    try {
      final newCard = JobCard(
        id: '',
        title: title,
        assignee: assignee,
        badges: [],
        amount: 0.0,
        laneId: laneId,
        boardId: workspaceId,
        workspaceId: workspaceId,
        order: _currentState.lanes.firstWhere((l) => l.id == laneId).cards.length,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Create card in repository
      final cardId = await _repository.createCard(workspaceId, newCard);
      
      LoggerService.to.business('Card created successfully');
    } catch (e) {
      _view?.showError('Failed to add card: ${e.toString()}');
    }
  }
}
