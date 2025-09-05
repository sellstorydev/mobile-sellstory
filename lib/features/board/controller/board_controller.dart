import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/entities/lane.dart';
import '../../../domain/entities/job_card.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/company.dart';
import '../../../domain/entities/board.dart';
import '../../../data/repositories/firestore_repository.dart';
import '../presenter/board_presenter.dart';
import '../contract/board_view.dart';
import '../state/board_state.dart';
import '../../../data/services/mobile_permissions_service.dart';

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
  final Rx<Board?> currentBoard = Rx<Board?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isInitialized = false.obs;
  
  // Search functionality
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final RxList<Lane> filteredLanes = <Lane>[].obs;
  final RxList<Lane> _originalLanes = <Lane>[].obs;
  late TextEditingController searchTextController;
  
  // Filter functionality
  final RxList<String> selectedAssignees = <String>[].obs;
  final RxList<String> selectedCustomers = <String>[].obs;
  final RxList<String> selectedHashtags = <String>[].obs;
  final RxList<String> selectedInterests = <String>[].obs;
  final RxList<String> selectedStatuses = <String>[].obs;
  final RxBool isFiltering = false.obs;
  final RxList<String> availableAssignees = <String>[].obs;
  final RxList<String> availableCustomers = <String>[].obs;
  final RxList<String> availableHashtags = <String>[].obs;
  final RxList<String> availableInterests = <String>[].obs;
  
  // Date filter functionality
  final RxList<String> selectedDateFilterTypes = <String>[].obs; // startDate, endDate, createdDate, etc.
  final Rx<DateTime?> selectedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedEndDate = Rx<DateTime?>(null);
  final RxBool showCardsWithoutDate = false.obs;
  
  // Search debounce timer
  Timer? _searchDebounceTimer;
  
  @override
  void onInit() {
    super.onInit();
    _presenter = BoardPresenter(this, _repository);
    searchTextController = TextEditingController();
    print('🔄 BoardController initialized');
  }
  
  @override
  void onClose() {
    print('🔄 BoardController disposed');
    _searchDebounceTimer?.cancel();
    searchTextController.dispose();
    super.onClose();
  }

  // Save card view settings to user preferences
  Future<void> saveCardViewSettings(List<dynamic> cardFields) async {
    try {
      print('💾 Saving card view settings...');
      
      // Convert card fields to the format expected by Firestore
      final Map<String, dynamic> viewSettings = {};
      
      for (final field in cardFields) {
        viewSettings[field.id] = {
          'isVisible': field.isVisible,
          'order': field.order,
          'style': {
            'fontSize': 14,
            'fontWeight': 'normal',
            'color': field.isVisible ? '#000000' : '#666666',
          },
        };
      }
      
      // Save to user's viewSettings in Firestore
      await _repository.updateUserViewSettings(
        currentUserId.value,
        viewSettings,
      );
      
      print('✅ Card view settings saved successfully');
    } catch (e) {
      print('❌ Failed to save card view settings: $e');
      rethrow;
    }
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
        // Try to get last active workspace ID
        String? selectedWorkspaceId;
        String? selectedWorkspaceName;
        
        try {
          final lastActiveWorkspaceId = await _repository.getUserLastActiveWorkspaceId(userId);
          print('📋 Last active workspace ID: $lastActiveWorkspaceId');
          
          if (lastActiveWorkspaceId != null && lastActiveWorkspaceId.isNotEmpty) {
            // Check if the last active workspace still exists in user's workspaces
            final lastActiveWorkspace = workspaces.firstWhereOrNull(
              (ws) => ws['id'] == lastActiveWorkspaceId
            );
            
            if (lastActiveWorkspace != null) {
              selectedWorkspaceId = lastActiveWorkspaceId;
              selectedWorkspaceName = lastActiveWorkspace['name'] as String;
              print('✅ Using last active workspace: $selectedWorkspaceName ($selectedWorkspaceId)');
            } else {
              print('⚠️ Last active workspace not found in user workspaces, using first workspace');
            }
          }
        } catch (e) {
          print('⚠️ Failed to get last active workspace: $e');
        }
        
        // Fallback to first workspace if no last active workspace
        if (selectedWorkspaceId == null) {
          final firstWorkspace = workspaces.first;
          selectedWorkspaceId = firstWorkspace['id'] as String;
          selectedWorkspaceName = firstWorkspace['name'] as String;
          print('✅ Using first workspace: $selectedWorkspaceName ($selectedWorkspaceId)');
        }
        
        currentWorkspaceId.value = selectedWorkspaceId!;
        currentWorkspaceName.value = selectedWorkspaceName!;
        
        // Prefetch permissions for selected workspace
        try {
          await MobilePermissionsService.to.getMyPermissions(workspaceId: currentWorkspaceId.value);
        } catch (_) {}

        print('✅ User initialized with workspace: $selectedWorkspaceName');

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

       // Update current workspace name
       final workspace = userWorkspaces.firstWhere((ws) => ws['id'] == workspaceId);
       currentWorkspaceName.value = workspace['name'] as String;

       // Update last active workspace ID in user document
       try {
         await _repository.updateUserLastActiveWorkspaceId(currentUserId.value, workspaceId);
         print('✅ Last active workspace ID updated');
       } catch (e) {
         print('⚠️ Failed to update last active workspace ID: $e');
         // Don't throw error, continue with workspace switch
       }

       // Refresh permissions for the new workspace (company change)
       try {
         await MobilePermissionsService.to.getMyPermissions(workspaceId: workspaceId);
       } catch (_) {}

       // Clear current data
       lanes.clear();
       userAssignedCards.clear();
       boards.clear();
       currentBoardId.value = '';
       currentBoardName.value = '';

       // Load boards for the new workspace
       await getBoards();

       print('✅ Workspace switched successfully');
     } catch (e) {
       print('❌ Failed to switch workspace: $e');
       error.value = 'Failed to switch workspace';
       rethrow;
     }
   }

  // Switch board
  Future<void> switchBoard(String boardId) async {
    try {
      print('🔄 Switching to board: $boardId');
      
      // Check if board exists in current boards list
      final board = boards.firstWhereOrNull((b) => b.id == boardId);
      if (board == null) {
        print('⚠️ Board $boardId not found in current boards list');
        throw Exception('Board not found');
      }
      
      currentBoardId.value = boardId;
      currentBoardName.value = board.name;
      currentBoard.value = board; // Set current board for member lookup
      
      print('📋 Board members: ${board.members.length} members');
      for (final member in board.members) {
        print('  - ${member['displayName']} (${member['uid']})');
      }
      
      // Clear current lanes and cards
      lanes.clear();
      userAssignedCards.clear();
      
      // Load lanes and cards for the selected board
      await load();
      
      print('✅ Board switched successfully');
    } catch (e) {
      print('❌ Failed to switch board: $e');
      error.value = 'Failed to switch board';
      rethrow;
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
            print('  - Assignee: ${updatedCard.assignedTo}');
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

  // Get users for a specific workspace
  Future<List<Map<String, dynamic>>> getWorkspaceUsers(String workspaceId) async {
    try {
      print('🔄 Getting users for workspace: $workspaceId');
      final users = await _repository.getWorkspaceUsers(workspaceId);
      print('✅ Users loaded: ${users.length} users');
      return users;
    } catch (e) {
      print('❌ Failed to get workspace users: $e');
      error.value = 'Failed to load workspace users';
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
      
      // Refresh board data to show the new card
      await refresh();
      
      return cardId;
    } catch (e) {
      print('❌ Failed to create card: $e');
      error.value = 'Failed to create card';
      rethrow;
    }
  }

  // Delete card
  Future<void> deleteCard(String cardId) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for deleting card');
      throw Exception('No workspace selected');
    }
    
    try {
      print('🔄 Deleting card: $cardId');
      await _repository.deleteCard(currentWorkspaceId.value, cardId);
      print('✅ Card deleted successfully');
      
      // Refresh board data to update the view
      await refresh();
    } catch (e) {
      print('❌ Failed to delete card: $e');
      error.value = 'Failed to delete card';
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

  // Get boards for specific workspace
  Future<List<Board>> getBoardsForWorkspace(String workspaceId) async {
    try {
      print('🔄 Getting boards for workspace: $workspaceId');
      final boardsList = await _repository.getBoards(workspaceId);
      print('✅ Boards loaded successfully for workspace $workspaceId - ${boardsList.length} boards');
      return boardsList;
    } catch (e) {
      print('❌ Failed to get boards for workspace $workspaceId: $e');
      return [];
    }
  }

  // Get lanes for a specific board
  Future<List<Lane>> getLanesByBoardId(String boardId) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for getting lanes');
      return [];
    }
    
    try {
      print('🔄 Getting lanes for board: $boardId in workspace: ${currentWorkspaceId.value}');
      
      // Get lanes stream for the specific board
      final lanesStream = _repository.getLanesStream(currentWorkspaceId.value, boardId: boardId);
      final lanesList = await lanesStream.first;
      
      print('✅ Lanes loaded successfully for board $boardId - ${lanesList.length} lanes');
      return lanesList;
    } catch (e) {
      print('❌ Failed to get lanes for board $boardId: $e');
      error.value = 'Failed to get lanes';
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
        print('      * Description: "${card.description}"');
        print('      * Customer: "${card.customer}"');
        print('      * Assignee: "${card.assignedTo}"');
        print('      * Status: "${card.status}"');
      }
    }
    
    this.lanes.value = state.lanes;
    _originalLanes.value = state.lanes; // Store original lanes for search
    
    // Update available assignees, customers, and hashtags
    _updateAvailableAssignees();
    _updateAvailableCustomers();
    _updateAvailableHashtags();
    
    // Apply current search and filter if exists
    final hasAssigneeFilter = selectedAssignees.isNotEmpty;
    final hasCustomerFilter = selectedCustomers.isNotEmpty;
    final hasHashtagFilter = selectedHashtags.isNotEmpty;
    final hasDateFilter = selectedDateFilterTypes.isNotEmpty;
    final hasStatusFilter = selectedStatuses.isNotEmpty;
    final hasSearchQuery = searchQuery.value.isNotEmpty;
    
    if (hasSearchQuery && (hasAssigneeFilter || hasCustomerFilter || hasHashtagFilter || hasStatusFilter || hasDateFilter)) {
      print('🔍 Reapplying search and filter');
      _performSearch(searchQuery.value);
      _performFilter();
    } else if (hasSearchQuery) {
      print('🔍 Reapplying search filter: "${searchQuery.value}"');
      _performSearch(searchQuery.value);
    } else if (hasAssigneeFilter || hasCustomerFilter || hasHashtagFilter || hasStatusFilter || hasDateFilter) {
      print('🔍 Reapplying filters - Assignees: ${selectedAssignees.length}, Customers: ${selectedCustomers.length}, Hashtags: ${selectedHashtags.length}, Statuses: ${selectedStatuses.length}, Date: ${hasDateFilter}');
      _performFilter();
    } else {
      filteredLanes.value = state.lanes;
    }
    
    isLoading.value = state.isLoading;
    error.value = state.error ?? '';
    isInitialized.value = true;
    
    print('📱 Board state updated - ${state.lanes.length} lanes');
  }
  
  // Search Methods
  void updateSearchQuery(String query) {
    final trimmedQuery = query.trim();
    searchQuery.value = trimmedQuery;
    
    // Sync with TextEditingController
    if (searchTextController.text != query) {
      searchTextController.text = query;
      searchTextController.selection = TextSelection.fromPosition(
        TextPosition(offset: query.length),
      );
    }
    
    // Cancel previous timer if exists
    _searchDebounceTimer?.cancel();
    
    if (trimmedQuery.isEmpty) {
      clearSearch();
    } else {
                   // Set a new timer for debounce (1000ms delay)
             _searchDebounceTimer = Timer(const Duration(seconds: 1), () {
        _performSearch(trimmedQuery);
      });
    }
  }
  
  void clearSearch() {
    searchQuery.value = '';
    searchTextController.clear();
    isSearching.value = false;
    filteredLanes.value = _originalLanes;
    print('🔍 Search cleared');
  }
  
  void _performSearch(String query) {
    if (query.isEmpty) {
      clearSearch();
      return;
    }
    
    isSearching.value = true;
    final searchLower = query.toLowerCase();
    
    print('🔍 Performing search for: "$query"');
    print('🔍 Available lanes to search: ${_originalLanes.length}');
    
    // Count total cards available
    int totalCards = 0;
    for (final lane in _originalLanes) {
      totalCards += lane.cards.length;
      print('🔍 Lane "${lane.title}" has ${lane.cards.length} cards');
    }
    print('🔍 Total cards to search: $totalCards');
    
    final List<Lane> searchResults = [];
    int matchingCards = 0;
    
    for (final lane in _originalLanes) {
      // Filter cards that match the search query
      final filteredCards = lane.cards.where((card) {
        final matches = _cardMatchesSearch(card, searchLower);
        if (matches) matchingCards++;
        return matches;
      }).toList();
      
      // Check if lane title matches
      final laneTitleMatches = lane.title.toLowerCase().contains(searchLower);
      
      // Include lane if it has matching cards or the lane title matches
      if (filteredCards.isNotEmpty || laneTitleMatches) {
        // If lane title matches, include all cards; otherwise include only filtered cards
        final cardsToInclude = laneTitleMatches ? lane.cards : filteredCards;
            
        searchResults.add(Lane(
          id: lane.id,
          title: lane.title,
          order: lane.order,
          cards: cardsToInclude,
          boardId: lane.boardId,
        ));
        
        print('🔍 Including lane "${lane.title}" with ${cardsToInclude.length} cards');
      }
    }
    
    filteredLanes.value = searchResults;
    print('🔍 Search completed - Found ${searchResults.length} lanes with matching content');
    print('🔍 Total matching cards: $matchingCards');
  }
  
  bool _cardMatchesSearch(JobCard card, String searchLower) {
    // Helper function to safely check string contains
    bool safeContains(String? text, String search) {
      if (text == null || text.isEmpty) return false;
      return text.toLowerCase().contains(search);
    }
    
    // Debug logging for search
    if (searchLower == 'test' || searchLower == 'card' || searchLower == 'new') {
      print('🔍 Checking card "${card.title}" against "$searchLower"');
      print('  - title: "${card.title}"');
      print('  - description: "${card.description}"');
      print('  - customId: "${card.customId}"');
      print('  - customer: "${card.customer}"');
              print('  - assignee: "${card.assignedTo}"');
      print('  - status: "${card.status}"');
    }
    
    return safeContains(card.title, searchLower) ||
           safeContains(card.description, searchLower) ||
           safeContains(card.customId, searchLower) ||
           safeContains(card.customer, searchLower) ||
           safeContains(card.assignedTo, searchLower) ||
           safeContains(card.status, searchLower) ||
           safeContains(card.updatedByDisplayName, searchLower) ||
           safeContains(card.company?['value'], searchLower) ||
           safeContains(card.hashtag ?? '', searchLower);
  }
  
  // Filter Methods
  void toggleAssigneeFilter(String assigneeId) {
    if (selectedAssignees.contains(assigneeId)) {
      selectedAssignees.remove(assigneeId);
    } else {
      selectedAssignees.add(assigneeId);
    }
    _performFilter();
  }
  
  void toggleCustomerFilter(String customerName) {
    if (selectedCustomers.contains(customerName)) {
      selectedCustomers.remove(customerName);
    } else {
      selectedCustomers.add(customerName);
    }
    _performFilter();
  }
  
  void toggleHashtagFilter(String hashtag) {
    if (selectedHashtags.contains(hashtag)) {
      selectedHashtags.remove(hashtag);
    } else {
      selectedHashtags.add(hashtag);
    }
    _performFilter();
  }
  
  void toggleInterestFilter(String interest) {
    if (selectedInterests.contains(interest)) {
      selectedInterests.remove(interest);
    } else {
      selectedInterests.add(interest);
    }
    _performFilter();
  }
  
  void toggleStatusFilter(String status) {
    print('🎯 Status pressed: $status');
    print('🎯 Current selected statuses before: $selectedStatuses');
    
    // Single select logic - clear all others first
    if (selectedStatuses.contains(status)) {
      // If already selected, clear all (deselect)
      selectedStatuses.clear();
      print('🎯 Cleared all statuses (deselected $status)');
    } else {
      // If not selected, clear all and select only this one
      selectedStatuses.clear();
      selectedStatuses.add(status);
      print('🎯 Selected only $status, cleared others');
    }
    
    print('🎯 Final selected statuses: $selectedStatuses');
    _performFilter();
  }
  
  void toggleDateFilterType(String dateType) {
    if (selectedDateFilterTypes.contains(dateType)) {
      selectedDateFilterTypes.remove(dateType);
    } else {
      selectedDateFilterTypes.add(dateType);
    }
    
    // Don't auto-apply filter - let user control when to apply
    // Filter will be applied when user clicks Apply button
  }
  
  void toggleShowCardsWithoutDate() {
    showCardsWithoutDate.value = !showCardsWithoutDate.value;
    _performFilter();
  }
  
  void clearAllFilters() {
    selectedAssignees.clear();
    selectedCustomers.clear();
    selectedHashtags.clear();
    selectedInterests.clear();
    selectedStatuses.clear();
    selectedDateFilterTypes.clear();
    showCardsWithoutDate.value = false;
    _performFilter();
  }
  
  // Date Filter Methods
  void updateDateFilter(String dateType, DateTime? startDate, DateTime? endDate) {
    // Add dateType if not already selected
    if (!selectedDateFilterTypes.contains(dateType)) {
      selectedDateFilterTypes.add(dateType);
    }
    selectedStartDate.value = startDate;
    selectedEndDate.value = endDate;
    _performFilter();
  }
  
  void clearDateFilter() {
    selectedDateFilterTypes.clear();
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    _performFilter();
  }
  
  void setQuickDateFilter(String type) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (type) {
      case 'today':
        // วันนี้ 00:00:00 ถึง วันนี้ 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today.add(const Duration(milliseconds: 86399999));
        break;
      case 'thisWeek':
        // วันนี้ 00:00:00 ถึง +7 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today.add(const Duration(days: 7)).add(const Duration(milliseconds: 86399999));
        break;
      case 'thisMonth':
        // วันนี้ 00:00:00 ถึง +30 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today.add(const Duration(days: 30)).add(const Duration(milliseconds: 86399999));
        break;
      case 'lastMonth':
        // เดือนก่อน 00:00:00 ถึง วันนี้ 23:59:59
        final lastMonth = DateTime(today.year, today.month - 1, today.day);
        selectedStartDate.value = lastMonth;
        selectedEndDate.value = today.add(const Duration(milliseconds: 86399999));
        break;
      case '+1day':
        // วันนี้ 00:00:00 ถึง วันนี้ +1 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today.add(const Duration(days: 1)).add(const Duration(milliseconds: 86399999));
        break;
      case '+3days':
        // วันนี้ 00:00:00 ถึง วันนี้ +3 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today.add(const Duration(days: 3)).add(const Duration(milliseconds: 86399999));
        break;
      case '+7days':
        // วันนี้ 00:00:00 ถึง วันนี้ +7 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today.add(const Duration(days: 7)).add(const Duration(milliseconds: 86399999));
        break;
      case '+14days':
        // วันนี้ 00:00:00 ถึง วันนี้ +14 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today.add(const Duration(days: 14)).add(const Duration(milliseconds: 86399999));
        break;
      case '+30days':
        // วันนี้ 00:00:00 ถึง วันนี้ +30 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today.add(const Duration(days: 30)).add(const Duration(milliseconds: 86399999));
        break;
      case 'lastWeek':
        // วันนี้ 00:00:00 ถึง วันนี้ -7 วัน 23:59:59
        selectedStartDate.value = today.subtract(const Duration(days: 7));
        selectedEndDate.value = today.add(const Duration(milliseconds: 86399999));
        break;
    }
  }
  
  void clearFilter() {
    selectedAssignees.clear();
    selectedCustomers.clear();
    selectedHashtags.clear();
    selectedInterests.clear();
    selectedStatuses.clear();
    selectedDateFilterTypes.clear();
    selectedStartDate.value = null;
    selectedEndDate.value = null;
    showCardsWithoutDate.value = false;
    isFiltering.value = false;
    // Re-apply search if active, otherwise show original lanes
    if (searchQuery.value.isNotEmpty) {
      _performSearch(searchQuery.value);
    } else {
      filteredLanes.value = _originalLanes;
    }
    print('🔍 Filter cleared');
  }
  
  void _performFilter() {
    final hasAssigneeFilter = selectedAssignees.isNotEmpty;
    final hasCustomerFilter = selectedCustomers.isNotEmpty;
    final hasHashtagFilter = selectedHashtags.isNotEmpty;
    final hasInterestFilter = selectedInterests.isNotEmpty;
    final hasStatusFilter = selectedStatuses.isNotEmpty;
    final hasDateFilter = selectedDateFilterTypes.isNotEmpty && 
                         (selectedStartDate.value != null || selectedEndDate.value != null);
    final hasShowWithoutDate = showCardsWithoutDate.value;
    
    if (!hasAssigneeFilter && !hasCustomerFilter && !hasHashtagFilter && !hasInterestFilter && !hasStatusFilter && !hasDateFilter && !hasShowWithoutDate) {
      isFiltering.value = false;
      if (searchQuery.value.isNotEmpty) {
        _performSearch(searchQuery.value);
      } else {
        filteredLanes.value = _originalLanes;
      }
      return;
    }
    
    isFiltering.value = true;
    
    print('🔍 Filtering - Assignees: ${selectedAssignees.length} selected: $selectedAssignees');
    print('🔍 Filtering - Customers: ${selectedCustomers.length} selected: $selectedCustomers');
    print('🔍 Filtering - Hashtags: ${selectedHashtags.length} selected: $selectedHashtags');
    print('🔍 Filtering - Interests: ${selectedInterests.length} selected: $selectedInterests');
    print('🔍 Filtering - Statuses: ${selectedStatuses.length} selected: $selectedStatuses');
    print('🔍 Filtering - Date Types: ${selectedDateFilterTypes.length} selected: $selectedDateFilterTypes from ${selectedStartDate.value} to ${selectedEndDate.value}');
    print('🔍 Filtering - Show Without Date: $hasShowWithoutDate');
    
    // Start with original lanes or search results
    final sourceLanes = searchQuery.value.isNotEmpty ? 
        _getSearchResults(searchQuery.value) : _originalLanes;
    
    // Debug: Print sample card data for troubleshooting
    if (sourceLanes.isNotEmpty && sourceLanes.first.cards.isNotEmpty) {
      final sampleCard = sourceLanes.first.cards.first;
      print('🔍 Sample Card Debug:');
      print('  - Title: ${sampleCard.title}');
      print('  - Assignee: ${sampleCard.assignedTo}');
      print('  - Customer: ${sampleCard.customer}');
      print('  - CustomerId: ${sampleCard.customerId}');
      print('  - CustomerInterest: ${sampleCard.customerInterest}');
      print('  - Hashtags: ${sampleCard.hashtags}');
      print('  - CreatedAt: ${sampleCard.createdAt}');
      print('  - DueDate: ${sampleCard.dueDate}');
      
      // Debug: Print filter values for comparison
      print('🔍 Filter Values Debug:');
      print('  - Selected Assignees: $selectedAssignees');
      print('  - Selected Customers: $selectedCustomers');
      print('  - Selected Hashtags: $selectedHashtags');
      print('  - Selected Interests: $selectedInterests');
      print('  - Selected Date Types: $selectedDateFilterTypes');
      print('  - Start Date: ${selectedStartDate.value}');
      print('  - End Date: ${selectedEndDate.value}');
    }
    
    print('🔍 Source lanes for filtering: ${sourceLanes.length} lanes');
    
    final List<Lane> filterResults = [];
    int matchingCards = 0;
    
    for (final lane in sourceLanes) {
      print('🔍 Checking lane "${lane.title}" with ${lane.cards.length} cards');
      
      // Filter cards by assignee, customer, hashtag, interest, status, and/or date
      final filteredCards = lane.cards.where((card) {
        bool assigneeMatches = true;
        bool customerMatches = true;
        bool hashtagMatches = true;
        bool interestMatches = true;
        bool statusMatches = true;
        bool dateMatches = true;
        
        // Check assignee filter (OR logic - match any selected assignee)
        if (hasAssigneeFilter) {
          assigneeMatches = selectedAssignees.contains(card.assignedTo);
        }
        
        // Check customer filter (OR logic - match any selected customer)  
        if (hasCustomerFilter) {
          customerMatches = selectedCustomers.any((selectedCustomer) => 
            (card.customerId ?? '').toLowerCase().contains(selectedCustomer.toLowerCase()));
        }
        
        // Check hashtag filter (OR logic - match any selected hashtag)
        if (hasHashtagFilter) {
          hashtagMatches = selectedHashtags.any((selectedHashtag) => 
            card.hashtags.any((hashtag) => 
              (hashtag['text'] ?? '').toString().toLowerCase().contains(selectedHashtag.toLowerCase())));
        }
        
        // Check interest filter (OR logic - match any selected interest)
        if (hasInterestFilter) {
          interestMatches = selectedInterests.any((selectedInterest) => 
            (card.customerInterest ?? '').toLowerCase().contains(selectedInterest.toLowerCase()));
        }
        
        // Check status filter (OR logic - match any selected status)
        if (hasStatusFilter) {
          statusMatches = selectedStatuses.contains(card.status);
        }
        
        // Check date filter
        if (hasDateFilter) {
          dateMatches = _checkDateFilter(card);
        }
        
        // Check show cards without date filter
        bool withoutDateMatches = true;
        if (hasShowWithoutDate) {
          // Show cards that don't have any of the selected date types
          withoutDateMatches = selectedDateFilterTypes.every((filterType) {
            DateTime? cardDate;
            switch (filterType) {
              case 'startDate':
              case 'createdDate':
                cardDate = card.createdAt;
                break;
              case 'endDate':
              case 'dueDate':
              case 'toDoDate':
              case 'expectedClosingDate':
                cardDate = card.dueDate;
                break;
              case 'updatedAt':
                cardDate = card.updatedAt;
                break;
              default:
                cardDate = card.createdAt;
            }
            return cardDate == null; // Return true if date is null (no date)
          });
        }
        
        final matches = assigneeMatches && customerMatches && hashtagMatches && interestMatches && statusMatches && dateMatches && withoutDateMatches;
        print('🔍 Card "${card.title}" - Assignee: "${card.assignedTo}" (${assigneeMatches}), Customer: "${card.customer}" (${customerMatches}), CustomerId: "${card.customerId ?? ''}" (${customerMatches}), Hashtag: "${card.hashtags}" (${hashtagMatches}), Interest: "${card.customerInterest ?? ''}" (${interestMatches}), Status: "${card.status}" (${statusMatches}), Date: (${dateMatches}) - Match: $matches');
        
        // Debug: Show why card didn't match
        if (!matches) {
          print('🔍 ❌ Card "${card.title}" did not match because:');
          if (!assigneeMatches) print('    - Assignee filter failed: "${card.assignedTo}" not in $selectedAssignees');
          if (!customerMatches) print('    - Customer filter failed: "${card.customerId ?? ''}" not matching $selectedCustomers');
          if (!hashtagMatches) print('    - Hashtag filter failed: "${card.hashtags}" not matching $selectedHashtags');
          if (!interestMatches) print('    - Interest filter failed: "${card.customerInterest ?? ''}" not matching $selectedInterests');
          if (!dateMatches) print('    - Date filter failed');
        }
        
        if (matches) matchingCards++;
        return matches;
      }).toList();
      
      // Include lane if it has matching cards
      if (filteredCards.isNotEmpty) {
        filterResults.add(Lane(
          id: lane.id,
          title: lane.title,
          order: lane.order,
          cards: filteredCards,
          boardId: lane.boardId,
        ));
        
        print('🔍 Including lane "${lane.title}" with ${filteredCards.length} cards');
      } else {
        print('🔍 Skipping lane "${lane.title}" - no matching cards');
      }
    }
    
    filteredLanes.value = filterResults;
    print('🔍 Filter completed - Found ${filterResults.length} lanes with matching criteria');
    print('🔍 Total matching cards: $matchingCards');
  }
  
  bool _checkDateFilter(JobCard card) {
    final startDate = selectedStartDate.value;
    final endDate = selectedEndDate.value;
    final filterTypes = selectedDateFilterTypes;
    
    // Return true if any of the selected date types match the date range
    return filterTypes.any((filterType) {
      DateTime? cardDate;
      
      // Get the appropriate date from card based on filter type
      switch (filterType) {
        case 'startDate':
          // For now, using createdAt as startDate - can be extended
          cardDate = card.createdAt;
          break;
        case 'endDate':
          // Using dueDate as endDate
          cardDate = card.dueDate;
          break;
        case 'createdDate':
          cardDate = card.createdAt;
          break;
        case 'dueDate':
        case 'toDoDate':
          cardDate = card.dueDate;
          break;
        case 'updatedAt':
          cardDate = card.updatedAt;
          break;
        case 'expectedClosingDate':
          // Using dueDate as expected closing date
          cardDate = card.dueDate;
          break;
        default:
          cardDate = card.createdAt;
      }
      
      if (cardDate == null) return false;
      
      // Check if card date is within the selected range
      bool matches = true;
      
      if (startDate != null) {
        matches = matches && cardDate.isAfter(startDate.subtract(const Duration(days: 1)));
      }
      
      if (endDate != null) {
        matches = matches && cardDate.isBefore(endDate.add(const Duration(days: 1)));
      }
      
      return matches;
    });
  }
  
  List<Lane> _getSearchResults(String query) {
    final searchLower = query.toLowerCase();
    final List<Lane> searchResults = [];
    
    for (final lane in _originalLanes) {
      final filteredCards = lane.cards.where((card) {
        return _cardMatchesSearch(card, searchLower);
      }).toList();
      
      final laneTitleMatches = lane.title.toLowerCase().contains(searchLower);
      
      if (filteredCards.isNotEmpty || laneTitleMatches) {
        final cardsToInclude = laneTitleMatches ? lane.cards : filteredCards;
        searchResults.add(Lane(
          id: lane.id,
          title: lane.title,
          order: lane.order,
          cards: cardsToInclude,
          boardId: lane.boardId,
        ));
      }
    }
    
    return searchResults;
  }
  
  void _updateAvailableAssignees() {
    final Set<String> assigneeUids = {};
    
    for (final lane in _originalLanes) {
      for (final card in lane.cards) {
        if (card.assignedTo.isNotEmpty) {
          assigneeUids.add(card.assignedTo);
        }
      }
    }
    
    // Convert UIDs to display names for UI, but keep UIDs for internal filtering
    final List<String> assigneeDisplays = assigneeUids.map((uid) => getDisplayNameFromUid(uid)).toList();
    availableAssignees.value = assigneeUids.toList(); // Keep UIDs for filtering logic
    print('🔍 Available assignees updated: ${assigneeUids.length} assignees');
    print('🔍 UIDs: $assigneeUids');
    print('🔍 Display names: $assigneeDisplays');
  }
  
  void _updateAvailableCustomers() {
    final Set<String> customerNames = {};
    
    for (final lane in _originalLanes) {
      for (final card in lane.cards) {
        if (card.customer.isNotEmpty) {
          customerNames.add(card.customer);
        }
      }
    }
    
    availableCustomers.value = customerNames.toList();
    print('🔍 Available customers updated: ${customerNames.length} customers');
    print('🔍 Customers: $customerNames');
  }
  
  void _updateAvailableHashtags() {
    final Set<String> hashtags = {};
    
    for (final lane in _originalLanes) {
      for (final card in lane.cards) {
        final cardHashtag = card.hashtag ?? '';
        if (cardHashtag.isNotEmpty) {
          // Split hashtags by common delimiters and clean them
          final cardHashtags = cardHashtag
              .split(RegExp(r'[,\s]+'))
              .where((tag) => tag.isNotEmpty)
              .map((tag) => tag.trim().replaceFirst('#', ''))
              .where((tag) => tag.isNotEmpty);
          hashtags.addAll(cardHashtags);
        }
      }
    }
    
    availableHashtags.value = hashtags.toList();
    print('🔍 Available hashtags updated: ${hashtags.length} hashtags');
    print('🔍 Hashtags: $hashtags');
  }
  
  // Helper method to get display name from UID
  String getDisplayNameFromUid(String uid) {
    if (currentBoard.value?.members != null) {
      for (final member in currentBoard.value!.members) {
        if (member['uid'] == uid) {
          return member['displayName'] ?? uid;
        }
      }
    }
    return uid; // Return UID if display name not found
  }
  
  // Getter for lanes to use in UI (returns filtered/searched lanes)
  List<Lane> get displayLanes {
    if (isSearching.value || selectedAssignees.isNotEmpty || selectedCustomers.isNotEmpty || selectedHashtags.isNotEmpty || selectedStatuses.isNotEmpty || selectedDateFilterTypes.isNotEmpty) {
      return filteredLanes;
    }
    return lanes;
  }

  // Get hashtags from workspace hashtagSettings
  Future<List<Map<String, dynamic>>> getWorkspaceHashtags() async {
    try {
      final workspaceId = currentWorkspaceId.value;
      if (workspaceId.isEmpty) {
        print('⚠️ No workspace selected for loading hashtags');
        return [];
      }

      print('🔄 Loading hashtags for workspace: $workspaceId');
      
      // Get workspace data
      final workspaceData = await _repository.getWorkspace(workspaceId);
      
      if (workspaceData != null) {
        final hashtagSettings = workspaceData['companyProfile']?['hashtagSettings'] as Map<String, dynamic>?;
        
        if (hashtagSettings != null && hashtagSettings['isEnabled'] == true) {
          final masterList = hashtagSettings['masterList'] as List<dynamic>?;
          
          if (masterList != null) {
            final hashtags = masterList
                .where((hashtag) => hashtag['enabled'] == true && hashtag['scopes']?['jobBoard'] == true)
                .map((hashtag) => {
                  'id': hashtag['id'] ?? '',
                  'text': hashtag['name'] ?? '',
                  'color': hashtag['color'] ?? '#f97316',
                })
                .toList();
            
            print('✅ Loaded ${hashtags.length} hashtags from workspace settings');
            return List<Map<String, dynamic>>.from(hashtags);
          }
        }
      }
      
      print('⚠️ No hashtag settings found for workspace');
      return [];
    } catch (e) {
      print('❌ Failed to load workspace hashtags: $e');
      return [];
    }
  }
}
