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
      // Listen to both lanes and cards streams for real-time updates
      _repository.getLanesStream(workspaceId).listen((lanes) {
        LoggerService.to.business('Loaded ${lanes.length} lanes from repository');
        
        _currentState = _currentState.copyWith(
          lanes: lanes,
          isLoading: false,
          error: null,
        );
        _view?.render(_currentState);
      });

      // Also listen to all cards for immediate updates when cards are moved
      _repository.getAllCardsStream(workspaceId).listen((allCards) {
        LoggerService.to.business('All cards updated: ${allCards.length} cards');
        
        // Update current state with new card data
        if (_currentState.lanes.isNotEmpty) {
          final updatedLanes = _currentState.lanes.map((lane) {
            final laneCards = allCards.where((card) => card.laneId == lane.id).toList();
            laneCards.sort((a, b) => a.order.compareTo(b.order));
            return lane.copyWith(cards: laneCards);
          }).toList();
          
          _currentState = _currentState.copyWith(
            lanes: updatedLanes,
            isLoading: false,
            error: null,
          );
          _view?.render(_currentState);
        }
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

  // Add new card
  Future<void> onAddCard({
    required String workspaceId,
    required String laneId,
    required String title,
    String? assignee,
  }) async {
    LoggerService.to.methodEntry('BoardPresenter.onAddCard', {
      'workspaceId': workspaceId,
      'laneId': laneId,
      'title': title,
      'assignee': assignee,
    });
    
    try {
      final updatedLanes = _addCardUseCase.execute(
        lanes: _currentState.lanes,
        laneId: laneId,
        title: title,
        assignee: assignee ?? '',
        badges: [],
        amount: 0.0,
      );
      
      LoggerService.to.business('Card added successfully');
      
      // Optimistic update
      _currentState = _currentState.copyWith(lanes: updatedLanes);
      _view?.render(_currentState);
      
      // Persist to repository
      await _repository.addCard(workspaceId, laneId, title, assignee ?? '');
      LoggerService.to.database('Card added to repository');
    } catch (e) {
      LoggerService.to.error('Failed to add card', e);
      _view?.showError('Failed to add card: ${e.toString()}');
      // Reload to revert optimistic update
      await load(workspaceId);
    }
    
    LoggerService.to.methodExit('BoardPresenter.onAddCard');
  }

  // Update card
  Future<void> onUpdateCard({
    required String workspaceId,
    required JobCard card,
  }) async {
    LoggerService.to.methodEntry('BoardPresenter.onUpdateCard', {
      'workspaceId': workspaceId,
      'cardId': card.id,
      'title': card.title,
    });
    
    print('🔄 BoardPresenter.onUpdateCard - Card data:');
    print('  - ID: ${card.id}');
    print('  - Title: ${card.title}');
    print('  - Custom ID: ${card.customId}');
    print('  - Status: ${card.status}');
    print('  - Assignee: ${card.assignee}');
    print('  - Customer: ${card.customer}');
    
    try {
      // Optimistic update
      final updatedLanes = _currentState.lanes.map((lane) {
        final cardIndex = lane.cards.indexWhere((c) => c.id == card.id);
        if (cardIndex != -1) {
          final updatedCards = List<JobCard>.from(lane.cards);
          updatedCards[cardIndex] = card;
          print('✅ Updated card in lane: ${lane.title}');
          return lane.copyWith(cards: updatedCards);
        }
        return lane;
      }).toList();
      
      _currentState = _currentState.copyWith(lanes: updatedLanes);
      _view?.render(_currentState);
      
      LoggerService.to.business('Card updated successfully');
      
      // Persist to repository
      await _repository.updateCard(workspaceId, card);
      LoggerService.to.database('Card updated in repository');
      
      print('✅ Card update completed successfully');
    } catch (e) {
      LoggerService.to.error('Failed to update card', e);
      _view?.showError('Failed to update card: ${e.toString()}');
      // Reload to revert optimistic update
      await load(workspaceId);
      print('❌ Card update failed: $e');
    }
    
    LoggerService.to.methodExit('BoardPresenter.onUpdateCard');
  }

  // Update lane
  Future<void> onUpdateLane({
    required String workspaceId,
    required String laneId,
    required String title,
    required int order,
  }) async {
    LoggerService.to.methodEntry('BoardPresenter.onUpdateLane', {
      'workspaceId': workspaceId,
      'laneId': laneId,
      'title': title,
      'order': order,
    });
    
    try {
      // Optimistic update
      final updatedLanes = _currentState.lanes.map((lane) {
        if (lane.id == laneId) {
          return lane.copyWith(title: title, order: order);
        }
        return lane;
      }).toList();
      
      _currentState = _currentState.copyWith(lanes: updatedLanes);
      _view?.render(_currentState);
      
      LoggerService.to.business('Lane updated successfully');
      
      // Persist to repository
      await _repository.updateLane(workspaceId, laneId, {
        'title': title,
        'order': order,
      });
      LoggerService.to.database('Lane updated in repository');
    } catch (e) {
      LoggerService.to.error('Failed to update lane', e);
      _view?.showError('Failed to update lane: ${e.toString()}');
      // Reload to revert optimistic update
      await load(workspaceId);
    }
    
    LoggerService.to.methodExit('BoardPresenter.onUpdateLane');
  }

  // Delete lane
  Future<void> onDeleteLane({
    required String workspaceId,
    required String laneId,
  }) async {
    LoggerService.to.methodEntry('BoardPresenter.onDeleteLane', {
      'workspaceId': workspaceId,
      'laneId': laneId,
    });
    
    try {
      // Optimistic update
      final updatedLanes = _currentState.lanes.where((lane) => lane.id != laneId).toList();
      
      _currentState = _currentState.copyWith(lanes: updatedLanes);
      _view?.render(_currentState);
      
      LoggerService.to.business('Lane deleted successfully');
      
      // Persist to repository
      await _repository.deleteLane(workspaceId, laneId);
      LoggerService.to.database('Lane deleted from repository');
    } catch (e) {
      LoggerService.to.error('Failed to delete lane', e);
      _view?.showError('Failed to delete lane: ${e.toString()}');
      // Reload to revert optimistic update
      await load(workspaceId);
    }
    
    LoggerService.to.methodExit('BoardPresenter.onDeleteLane');
  }
}
