import 'package:get/get.dart';
import '../../../domain/entities/lane.dart';
import '../../../domain/entities/job_card.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/board.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../presenter/board_presenter.dart';
import '../contract/board_view.dart';
import '../state/board_state.dart';

class BoardController extends GetxController implements BoardView {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  late BoardPresenter _presenter;
  
  // Observable variables
  final RxString currentUserId = ''.obs;
  final RxString currentWorkspaceId = ''.obs;
  final RxString currentWorkspaceName = ''.obs;
  final RxList<Map<String, dynamic>> userWorkspaces = <Map<String, dynamic>>[].obs;
  final RxList<Lane> lanes = <Lane>[].obs;
  final RxList<JobCard> userAssignedCards = <JobCard>[].obs;
  final RxList<Board> boards = <Board>[].obs;
  final RxString currentBoardId = ''.obs;
  final RxString currentBoardName = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isInitialized = false.obs;
  
  @override
  void onInit() {
    super.onInit();
    _presenter = BoardPresenter(this, _repository);
    print('🔄 BoardController initialized');
  }
  
  @override
  void onClose() {
    print('🔄 BoardController disposed');
    super.onClose();
  }
  
  // Initialize with user data
  Future<void> initializeWithUser(String userId) async {
    try {
      print('🔄 Initializing user: $userId');
      
      currentUserId.value = userId;
      
      // Get user's workspaces
      print('📋 Fetching user workspaces...');
      final workspaces = await _repository.getUserWorkspaces(userId);
      userWorkspaces.value = workspaces;
      
      print('📋 User workspaces loaded: ${workspaces.length} workspaces');
      
      if (workspaces.isNotEmpty) {
        // Use the first workspace as default
        final firstWorkspace = workspaces.first;
        currentWorkspaceId.value = firstWorkspace['id'] as String;
        
        print('✅ User initialized with workspace: ${firstWorkspace['name']}');
        
        // Load boards for the selected workspace
        await getBoards();
        
        // Auto-select first board if available
        if (boards.isNotEmpty) {
          await switchBoard(boards.first.id);
        }
      } else {
        print('⚠️ No workspaces found for user: $userId');
        error.value = 'No workspaces found for this user';
      }
    } catch (e) {
      print('❌ Failed to initialize user: $e');
      error.value = 'Failed to initialize user data';
    }
  }
  
  // Switch workspace
  Future<void> switchWorkspace(String workspaceId) async {
    try {
      print('🔄 Switching to workspace: $workspaceId');
      currentWorkspaceId.value = workspaceId;
      
      // Clear current data
      lanes.clear();
      userAssignedCards.clear();
      boards.clear();
      currentBoardId.value = '';
      currentBoardName.value = '';
      
      // Load boards for the new workspace
      await getBoards();
      
      // Auto-select first board if available
      if (boards.isNotEmpty) {
        await switchBoard(boards.first.id);
      }
      
      print('✅ Workspace switched successfully');
    } catch (e) {
      print('❌ Failed to switch workspace: $e');
      error.value = 'Failed to switch workspace';
    }
  }

  // Switch board
  Future<void> switchBoard(String boardId) async {
    try {
      print('🔄 Switching to board: $boardId');
      currentBoardId.value = boardId;
      
      // Find board name
      final board = boards.firstWhere((b) => b.id == boardId);
      currentBoardName.value = board.name;
      
      // Clear current lanes and cards
      lanes.clear();
      userAssignedCards.clear();
      
      // Load lanes and cards for the selected board
      await load();
      
      print('✅ Board switched successfully');
    } catch (e) {
      print('❌ Failed to switch board: $e');
      error.value = 'Failed to switch board';
    }
  }
  
  // Load data for current workspace and board
  Future<void> load() async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for loading');
      return;
    }

    if (currentBoardId.value.isEmpty) {
      print('⚠️ No board selected for loading');
      return;
    }
    
    try {
      print('🔄 Loading board data for workspace: ${currentWorkspaceId.value}, board: ${currentBoardId.value}');
      await _presenter.load(currentWorkspaceId.value, currentBoardId.value);
      print('✅ Board data loaded successfully - ${lanes.length} lanes');
    } catch (e) {
      print('❌ Failed to load board data: $e');
      error.value = 'Failed to load board data';
    }
  }

  // Manual refresh method
  Future<void> refresh() async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for refresh');
      return;
    }

    if (currentBoardId.value.isEmpty) {
      print('⚠️ No board selected for refresh');
      return;
    }
    
    try {
      print('🔄 Manual refresh triggered for workspace: ${currentWorkspaceId.value}, board: ${currentBoardId.value}');
      isLoading.value = true;
      
      // Force reload data
      await _presenter.load(currentWorkspaceId.value, currentBoardId.value);
      
      print('✅ Manual refresh completed - ${lanes.length} lanes');
    } catch (e) {
      print('❌ Failed to refresh board data: $e');
      error.value = 'Failed to refresh board data';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Load user's assigned cards
  Future<void> loadUserAssignedCards() async {
    if (currentWorkspaceId.value.isEmpty || currentUserId.value.isEmpty) {
      print('⚠️ Missing workspace or user ID for loading assigned cards');
      return;
    }
    
    try {
      print('🔄 Loading user assigned cards...');
      
      // Listen to user's assigned cards
      _repository.getUserAssignedCardsStream(currentWorkspaceId.value, currentUserId.value)
          .listen((cards) {
        userAssignedCards.value = cards;
        print('✅ User assigned cards updated - ${cards.length} cards');
      });
    } catch (e) {
      print('❌ Failed to load user assigned cards: $e');
      error.value = 'Failed to load assigned cards';
    }
  }
  
  // Move card between lanes
  Future<void> onMoveCard({
    required String cardId,
    required String fromLaneId,
    required String toLaneId,
    required int toIndex,
  }) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for moving card');
      return;
    }
    
    print('🔄 Moving card $cardId from $fromLaneId to $toLaneId at index $toIndex');
    
    await _presenter.onMoveCard(
      workspaceId: currentWorkspaceId.value,
      cardId: cardId,
      fromLaneId: fromLaneId,
      toLaneId: toLaneId,
      toIndex: toIndex,
    );
  }

  // Reorder cards within the same lane
  Future<void> onReorderInLane({
    required String laneId,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for reordering cards');
      return;
    }
    
    print('🔄 Reordering cards in lane $laneId from index $oldIndex to $newIndex');
    
    await _presenter.onReorderInLane(
      workspaceId: currentWorkspaceId.value,
      laneId: laneId,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
  }

  // Add new lane
  Future<void> onAddLane(String title) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for adding lane');
      return;
    }
    
    print('🔄 Adding new lane: $title');
    
    await _presenter.onAddLane(currentWorkspaceId.value, title);
  }

  // Add new card
  Future<void> onAddCard({
    required String laneId,
    required String title,
    String? assignee,
  }) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for adding card');
      return;
    }
    
    print('🔄 Adding new card: $title to lane: $laneId');
    
    await _presenter.onAddCard(
      workspaceId: currentWorkspaceId.value,
      laneId: laneId,
      title: title,
      assignee: assignee ?? '',
    );
  }

  // Update card
  Future<void> updateCard(JobCard updatedCard) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for updating card');
      return;
    }
    
    print('🔄 BoardController.updateCard - Card data:');
    print('  - ID: ${updatedCard.id}');
    print('  - Title: ${updatedCard.title}');
    print('  - Custom ID: ${updatedCard.customId}');
    print('  - Status: ${updatedCard.status}');
    print('  - Assignee: ${updatedCard.assignee}');
    print('  - Customer: ${updatedCard.customer}');
    
    await _presenter.onUpdateCard(
      workspaceId: currentWorkspaceId.value,
      card: updatedCard,
    );
    
    print('✅ BoardController.updateCard completed');
  }

  // Update lane
  Future<void> updateLane({
    required String laneId,
    required String title,
    required int order,
  }) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for updating lane');
      return;
    }
    
    print('🔄 BoardController.updateLane - Lane data:');
    print('  - ID: $laneId');
    print('  - Title: $title');
    print('  - Order: $order');
    
    await _presenter.onUpdateLane(
      workspaceId: currentWorkspaceId.value,
      laneId: laneId,
      title: title,
      order: order,
    );
    
    print('✅ BoardController.updateLane completed');
  }

  // Delete lane
  Future<void> deleteLane({required String laneId}) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for deleting lane');
      return;
    }
    
    print('🔄 BoardController.deleteLane - Lane ID: $laneId');
    
    await _presenter.onDeleteLane(
      workspaceId: currentWorkspaceId.value,
      laneId: laneId,
    );
    
    print('✅ BoardController.deleteLane completed');
  }

  // Getters for UI
  bool get hasWorkspaces => userWorkspaces.isNotEmpty;
  List<Map<String, dynamic>> get availableWorkspaces => userWorkspaces;

  // Get customers for current workspace
  Future<List<Customer>> getCustomers() async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for getting customers');
      return [];
    }
    
    try {
      print('🔄 Getting customers for workspace: ${currentWorkspaceId.value}');
      final customers = await _repository.getCustomers(currentWorkspaceId.value);
      print('✅ Customers loaded successfully - ${customers.length} customers');
      return customers;
    } catch (e) {
      print('❌ Failed to get customers: $e');
      error.value = 'Failed to get customers';
      return [];
    }
  }

  // Get companies for current workspace
  Future<List<Company>> getCompanies() async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for getting companies');
      return [];
    }
    
    try {
      print('🔄 Getting companies for workspace: ${currentWorkspaceId.value}');
      final companies = await _repository.getCompanies(currentWorkspaceId.value);
      print('✅ Companies loaded successfully - ${companies.length} companies');
      return companies;
    } catch (e) {
      print('❌ Failed to get companies: $e');
      error.value = 'Failed to get companies';
      return [];
    }
  }

  // Create card with full data
  Future<String> createCard(JobCard card) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for creating card');
      throw Exception('No workspace selected');
    }
    
    try {
      print('🔄 Creating card in workspace: ${currentWorkspaceId.value}');
      final cardId = await _repository.createCard(currentWorkspaceId.value, card);
      print('✅ Card created successfully with ID: $cardId');
      return cardId;
    } catch (e) {
      print('❌ Failed to create card: $e');
      error.value = 'Failed to create card';
      rethrow;
    }
  }

  // Get boards for current workspace
  Future<List<Board>> getBoards() async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for getting boards');
      return [];
    }
    
    try {
      print('🔄 Getting boards for workspace: ${currentWorkspaceId.value}');
      final boardsList = await _repository.getBoards(currentWorkspaceId.value);
      boards.value = boardsList;
      print('✅ Boards loaded successfully - ${boardsList.length} boards');
      return boardsList;
    } catch (e) {
      print('❌ Failed to get boards: $e');
      error.value = 'Failed to get boards';
      return [];
    }
  }

  // Create board
  Future<String> createBoard(String name) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for creating board');
      throw Exception('No workspace selected');
    }
    
    try {
      print('🔄 Creating board in workspace: ${currentWorkspaceId.value}');
      final boardId = await _repository.createBoard(
        currentWorkspaceId.value, 
        name, 
        currentUserId.value,
      );
      print('✅ Board created successfully with ID: $boardId');
      
      // Refresh boards list
      await getBoards();
      
      return boardId;
    } catch (e) {
      print('❌ Failed to create board: $e');
      error.value = 'Failed to create board';
      rethrow;
    }
  }

  // Update board
  Future<void> updateBoard(String boardId, String newName) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for updating board');
      throw Exception('No workspace selected');
    }
    
    try {
      print('🔄 Updating board: $boardId');
      await _repository.updateBoard(currentWorkspaceId.value, boardId, newName);
      print('✅ Board updated successfully');
      
      // Refresh boards list
      await getBoards();
    } catch (e) {
      print('❌ Failed to update board: $e');
      error.value = 'Failed to update board';
      rethrow;
    }
  }

  // Delete board
  Future<void> deleteBoard(String boardId) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for deleting board');
      throw Exception('No workspace selected');
    }
    
    try {
      print('🔄 Deleting board: $boardId');
      await _repository.deleteBoard(currentWorkspaceId.value, boardId);
      print('✅ Board deleted successfully');
      
      // Refresh boards list
      await getBoards();
    } catch (e) {
      print('❌ Failed to delete board: $e');
      error.value = 'Failed to delete board';
      rethrow;
    }
  }

  // BoardView implementation
  @override
  void showLoading(bool isLoading) {
    this.isLoading.value = isLoading;
    print('📱 Loading state changed: $isLoading');
  }

  @override
  void showError(String message) {
    error.value = message;
    print('❌ Board error: $message');
  }

  @override
  void render(BoardState state) {
    print('🔄 BoardController.render - Updating UI with new state:');
    print('  - Lanes count: ${state.lanes.length}');
    for (final lane in state.lanes) {
      print('  - Lane: ${lane.title} (${lane.cards.length} cards)');
      for (final card in lane.cards) {
        print('    - Card: ${card.title} (ID: ${card.id}, Custom ID: ${card.customId})');
      }
    }
    
    this.lanes.value = state.lanes;
    isLoading.value = state.isLoading;
    error.value = state.error ?? '';
    isInitialized.value = true;
    
    print('📱 Board state updated - ${state.lanes.length} lanes');
  }
}
