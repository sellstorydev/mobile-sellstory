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
import 'lane_display_controller.dart';
import '../../../core/services/quota_usage_service.dart';
import '../../customers/controller/customers_controller.dart';

class BoardController extends GetxController implements BoardView {
  final FirestoreRepository _repository = Get.find<FirestoreRepository>();
  late BoardPresenter _presenter;

  // Observable variables
  final RxString currentUserId = ''.obs;
  final RxString currentWorkspaceId = ''.obs;
  final RxString currentWorkspaceName = ''.obs;
  final RxList<Map<String, dynamic>> userWorkspaces =
      <Map<String, dynamic>>[].obs;
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
  bool _isControllerInitialized = false;

  // Helper to safely access the search controller
  TextEditingController? get safeSearchTextController {
    if (!_isControllerInitialized) {
      print('❌ SearchTextController not yet initialized');
      return null;
    }

    try {
      // Check if controller is disposed by trying to access a property
      searchTextController.text;
      return searchTextController;
    } catch (e) {
      print('❌ SearchTextController is disposed, returning null');
      return null;
    }
  }

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

  // Computed property to get current hashtags
  List<String> get currentAvailableHashtags {
    final Set<String> hashtags = {};

    for (final lane in _originalLanes) {
      for (final card in lane.cards) {
        if (card.hashtags.isNotEmpty) {
          for (final hashtagObj in card.hashtags) {
            if (hashtagObj['text'] != null) {
              final hashtagText = hashtagObj['text'] as String;
              if (hashtagText.isNotEmpty) {
                hashtags.add(hashtagText.trim());
              }
            }
          }
        }
      }
    }

    final result = hashtags.toList();
    // Update the reactive list too
    if (availableHashtags.length != result.length ||
        !availableHashtags.every((item) => result.contains(item))) {
      availableHashtags.value = result;
    }

    return result;
  }

  // Computed property to get current interests
  List<String> get currentAvailableInterests {
    final Set<String> interests = {};
    for (final lane in _originalLanes) {
      for (final card in lane.cards) {
        if (card.customerInterest != null &&
            card.customerInterest!.isNotEmpty) {
          interests.add(card.customerInterest!.trim());
        }
      }
    }

    final result = interests.toList();

    // Update the reactive list too
    if (availableInterests.length != result.length ||
        !availableInterests.every((item) => result.contains(item))) {
      availableInterests.value = result;
    }

    return result;
  }

  final RxList<String> availableInterests = <String>[].obs;
  // UI behavior: whether to hide lanes with zero cards when filters are active
  final RxBool hideEmptyLanesWhenFiltering = false.obs;

  // Date filter functionality
  final RxList<String> selectedDateFilterTypes =
      <String>[].obs; // startDate, endDate, createdDate, etc.
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
    _isControllerInitialized = true;

    // Initialize display controller if not already available
    if (!Get.isRegistered<LaneDisplayController>()) {
      Get.put(LaneDisplayController());
    }
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    _isControllerInitialized = false;

    // Safe disposal of text controller
    try {
      searchTextController.dispose();
    } catch (e) {
      print('❌ SearchTextController already disposed: $e');
    }

    super.onClose();
  }

  // Save card view settings to user preferences
  Future<void> saveCardViewSettings(List<dynamic> cardFields) async {
    try {
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
    } catch (e) {
      print('❌ Failed to save card view settings: $e');
      rethrow;
    }
  }

  // Initialize with user data
  Future<void> initializeWithUser(String userId) async {
    try {
      currentUserId.value = userId;

      // Get user's workspaces
      final workspaces = await _repository.getUserWorkspaces(userId);
      userWorkspaces.value = workspaces;

      if (workspaces.isNotEmpty) {
        // Try to get last active workspace ID
        String? selectedWorkspaceId;
        String? selectedWorkspaceName;

        try {
          final lastActiveWorkspaceId = await _repository
              .getUserLastActiveWorkspaceId(userId);

          if (lastActiveWorkspaceId != null &&
              lastActiveWorkspaceId.isNotEmpty) {
            // Check if the last active workspace still exists in user's workspaces
            final lastActiveWorkspace = workspaces.firstWhereOrNull(
              (ws) => ws['id'] == lastActiveWorkspaceId,
            );

            if (lastActiveWorkspace != null) {
              selectedWorkspaceId = lastActiveWorkspaceId;
              selectedWorkspaceName = lastActiveWorkspace['name'] as String;
            }
          }
        } catch (e) {
          print('❌ Failed to get last active workspace: $e');
        }

        // Fallback to first workspace if no last active workspace
        if (selectedWorkspaceId == null) {
          final firstWorkspace = workspaces.first;
          selectedWorkspaceId = firstWorkspace['id'] as String;
          selectedWorkspaceName = firstWorkspace['name'] as String;
        }

        currentWorkspaceId.value = selectedWorkspaceId ?? '';
        currentWorkspaceName.value = selectedWorkspaceName ?? '';

        // Prefetch permissions for selected workspace
        try {
          await MobilePermissionsService.to.getMyPermissions(
            workspaceId: currentWorkspaceId.value,
          );
        } catch (_) {
          print(
            '❌ Failed to prefetch permissions for workspace: $currentWorkspaceId',
          );
        }
        // Load boards for the selected workspace
        await getBoards();

        // Auto-select first board if available
        if (boards.isNotEmpty) {
          await switchBoard(boards.first.id);
        }
      } else {
        print('❌ No workspaces found for user: $userId');
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
      currentWorkspaceId.value = workspaceId;

      // Update current workspace name
      final workspace = userWorkspaces.firstWhere(
        (ws) => ws['id'] == workspaceId,
      );
      currentWorkspaceName.value = workspace['name'] as String;

      // Update last active workspace ID in user document
      try {
        await _repository.updateUserLastActiveWorkspaceId(
          currentUserId.value,
          workspaceId,
        );
      } catch (e) {
        print('❌ Failed to update last active workspace ID: $e');
        // Don't throw error, continue with workspace switch
      }

      // Refresh permissions for the new workspace (company change)
      try {
        await MobilePermissionsService.to.getMyPermissions(
          workspaceId: workspaceId,
        );
      } catch (_) {}

      // Notify CustomersController of workspace change if it's registered
      if (Get.isRegistered<CustomersController>()) {
        try {
          final customersController = Get.find<CustomersController>();
          await customersController.switchWorkspace(workspaceId);
        } catch (e) {
          print('❌ Failed to notify CustomersController: $e');
        }
      }

      // Clear current data
      lanes.clear();
      userAssignedCards.clear();
      boards.clear();
      currentBoardId.value = '';
      currentBoardName.value = '';

      // Load boards for the new workspace
      await getBoards();
    } catch (e) {
      print('❌ Failed to switch workspace: $e');
      error.value = 'Failed to switch workspace';
      rethrow;
    }
  }

  // Switch board
  Future<void> switchBoard(String boardId) async {
    try {
      // Check if board exists in current boards list
      final board = boards.firstWhereOrNull((b) => b.id == boardId);
      if (board == null) {
        print('❌ Board $boardId not found in current boards list');
        throw Exception('Board not found');
      }

      currentBoardId.value = boardId;
      currentBoardName.value = board.name;
      currentBoard.value = board; // Set current board for member lookup

      // Clear current lanes and cards
      lanes.clear();
      userAssignedCards.clear();
      // Load lanes and cards for the selected board
      await load();
    } catch (e) {
      print('❌ Failed to switch board: $e');
      error.value = 'Failed to switch board';
      rethrow;
    }
  }

  // Load data for current workspace and board
  Future<void> load() async {
    if (currentWorkspaceId.value.isEmpty) {
      print('❌ No workspace selected for loading');
      return;
    }

    if (currentBoardId.value.isEmpty) {
      print('❌ No board selected for loading');
      return;
    }

    try {
      await _presenter.load(currentWorkspaceId.value, currentBoardId.value);
    } catch (e) {
      print('❌ Failed to load board data: $e');
      error.value = 'Failed to load board data';
    }
  }

  // Manual refresh method
  Future<void> refresh() async {
    if (currentWorkspaceId.value.isEmpty) {
      print('❌ No workspace selected for refresh');
      return;
    }

    if (currentBoardId.value.isEmpty) {
      print('❌ No board selected for refresh');
      return;
    }

    try {
      isLoading.value = true;
      // Force reload data
      await _presenter.load(currentWorkspaceId.value, currentBoardId.value);
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
      print('❌ Missing workspace or user ID for loading assigned cards');
      return;
    }

    try {
      // Listen to user's assigned cards
      _repository
          .getUserAssignedCardsStream(
            currentWorkspaceId.value,
            currentUserId.value,
          )
          .listen((cards) {
            userAssignedCards.value = cards;
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
      print('❌ No workspace selected for moving card');
      return;
    }
    await _presenter.onMoveCard(
      workspaceId: currentWorkspaceId.value,
      cardId: cardId,
      fromLaneId: fromLaneId,
      toLaneId: toLaneId,
      toIndex: toIndex,
    );

    // Refresh board data after moving card
    await refresh();

    // Update UI immediately
    update();
  }

  // Reorder cards within the same lane
  Future<void> onReorderInLane({
    required String laneId,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('❌ No workspace selected for reordering cards');
      return;
    }

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
      print('❌ No workspace selected for adding lane');
      return;
    }
    await _presenter.onAddLane(currentWorkspaceId.value, title);
  }

  // Clone lane with all its cards
  Future<void> onCloneLane(Lane sourceLane) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('❌ CONTROLLER: No workspace selected for cloning lane');
      return;
    }

    try {
      // Create cloned lane with new title
      final clonedLaneTitle = '${sourceLane.title} (Copy)';

      // Create the lane directly using the presenter
      await _presenter.onAddLane(currentWorkspaceId.value, clonedLaneTitle);

      // Reload lanes to get the newly created lane
      await _presenter.load(currentWorkspaceId.value, currentBoardId.value);

      final clonedLanes = lanes
          .where((lane) => lane.title == clonedLaneTitle)
          .toList();

      if (clonedLanes.isEmpty) {
        print('❌ CONTROLLER: Failed to find cloned lane - throwing exception');
        throw Exception('Failed to find cloned lane');
      }

      final clonedLane = clonedLanes.last; // Get the most recently created one

      // Clone all cards from source lane to the new lane
      for (int i = 0; i < sourceLane.cards.length; i++) {
        final sourceCard = sourceLane.cards[i];

        // Create a cloned card with all the necessary properties
        final clonedCard = JobCard(
          id: '', // Will be auto-generated
          title: '${sourceCard.title} (Copy)',
          description: sourceCard.description,
          assignedTo: sourceCard.assignedTo,
          status: sourceCard.status,
          customId: '', // Will be auto-generated
          dueDate: sourceCard.dueDate,
          startDate: sourceCard.startDate,
          endDate: sourceCard.endDate,
          badges: List<String>.from(sourceCard.badges),
          amount: sourceCard.amount,
          laneId: clonedLane.id,
          boardId: sourceCard.boardId.isNotEmpty
              ? sourceCard.boardId
              : currentBoardId.value,
          workspaceId: sourceCard.workspaceId.isNotEmpty
              ? sourceCard.workspaceId
              : currentWorkspaceId.value,
          order: i, // Maintain order
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          customer: sourceCard.customer,
          updatedByDisplayName: sourceCard.updatedByDisplayName,
          customerId: sourceCard.customerId,
          company: sourceCard.company != null
              ? Map<String, dynamic>.from(sourceCard.company!)
              : null,
          hashtag: sourceCard.hashtag,
          hashtags: sourceCard.hashtags
              .map((h) => Map<String, dynamic>.from(h))
              .toList(),
          customerInterest: sourceCard.customerInterest,
          expenses: sourceCard.expenses
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          todos: sourceCard.todos
              .map((t) => Map<String, dynamic>.from(t))
              .toList(),
          notes: sourceCard.notes
              .map((n) => Map<String, dynamic>.from(n))
              .toList(),
          watchers: List<String>.from(sourceCard.watchers),
          customFields: sourceCard.customFields
              .map((cf) => Map<String, dynamic>.from(cf))
              .toList(),
          createdBy: currentUserId.value.isNotEmpty
              ? currentUserId.value
              : sourceCard.createdBy,
          updatedBy: currentUserId.value.isNotEmpty
              ? currentUserId.value
              : sourceCard.updatedBy,
          collaborators: List<String>.from(sourceCard.collaborators),
          priority: sourceCard.priority,
          isVatEnabled: sourceCard.isVatEnabled,
          additionalDiscount: sourceCard.additionalDiscount != null
              ? Map<String, dynamic>.from(sourceCard.additionalDiscount!)
              : null,
          withholdingTaxPercentage: sourceCard.withholdingTaxPercentage,
        );

        try {
          await _presenter.onCreateFullCard(
            workspaceId: currentWorkspaceId.value,
            card: clonedCard,
          );
        } catch (cardError) {
          print('❌ CONTROLLER: Failed to clone card ${i + 1}: $cardError');
          if (cardError is Exception) {
            print('❌ CONTROLLER: Exception stack trace: ${StackTrace.current}');
          }
          continue;
        }
      }

      // Reload lanes to show the updated data
      await _presenter.load(currentWorkspaceId.value, currentBoardId.value);
    } catch (e) {
      print('❌ CONTROLLER: Failed to clone lane: $e');
      if (e is Exception) {
        print('❌ CONTROLLER: Exception stack trace: ${StackTrace.current}');
      }
      error.value = 'Failed to clone lane: ${e.toString()}';
      rethrow;
    }
  }

  // Add new card
  Future<void> onAddCard({
    required String laneId,
    required String title,
    String? assignee,
  }) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('❌ No workspace selected for adding card');
      return;
    }

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
      print('❌ No workspace selected for updating card');
      return;
    }
    await _presenter.onUpdateCard(
      workspaceId: currentWorkspaceId.value,
      card: updatedCard,
    );
  }

  // Update lane
  Future<void> updateLane({
    required String laneId,
    required String title,
    required int order,
  }) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('❌ No workspace selected for updating lane');
      return;
    }

    await _presenter.onUpdateLane(
      workspaceId: currentWorkspaceId.value,
      laneId: laneId,
      title: title,
      order: order,
    );
  }

  // Delete lane
  Future<void> deleteLane({required String laneId}) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('❌ No workspace selected for deleting lane');
      return;
    }
    await _presenter.onDeleteLane(
      workspaceId: currentWorkspaceId.value,
      laneId: laneId,
    );
  }

  // Getters for UI
  bool get hasWorkspaces => userWorkspaces.isNotEmpty;
  List<Map<String, dynamic>> get availableWorkspaces => userWorkspaces;

  // Get customers for current workspace
  Future<List<Customer>> getCustomers() async {
    if (currentWorkspaceId.value.isEmpty) {
      print('❌ No workspace selected for getting customers');
      return [];
    }

    try {
      final customers = await _repository.getCustomers(
        currentWorkspaceId.value,
      );
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
      print('❌ No workspace selected for getting companies');
      return [];
    }

    try {
      final companies = await _repository.getCompanies(
        currentWorkspaceId.value,
      );
      return companies;
    } catch (e) {
      print('❌ Failed to get companies: $e');
      error.value = 'Failed to get companies';
      return [];
    }
  }

  // Get users for a specific workspace
  Future<List<Map<String, dynamic>>> getWorkspaceUsers(
    String workspaceId,
  ) async {
    try {
      final users = await _repository.getWorkspaceUsers(workspaceId);
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
      print('❌ No workspace selected for creating card');
      throw Exception('No workspace selected');
    }

    try {
      final cardId = await _repository.createCard(
        currentWorkspaceId.value,
        card,
      );
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
      print('❌ No workspace selected for deleting card');
      throw Exception('No workspace selected');
    }

    try {
      await _repository.deleteCard(currentWorkspaceId.value, cardId);
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
      print('❌ No workspace selected for getting boards');
      return [];
    }

    try {
      final boardsList = await _repository.getBoards(currentWorkspaceId.value);
      boards.value = boardsList;
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
      final boardsList = await _repository.getBoards(workspaceId);
      return boardsList;
    } catch (e) {
      print('❌ Failed to get boards for workspace $workspaceId: $e');
      return [];
    }
  }

  // Get lanes for a specific board
  Future<List<Lane>> getLanesByBoardId(String boardId) async {
    if (currentWorkspaceId.value.isEmpty) {
      print('❌ No workspace selected for getting lanes');
      return [];
    }

    try {
      // Get lanes stream for the specific board
      final lanesStream = _repository.getLanesStream(
        currentWorkspaceId.value,
        boardId: boardId,
      );
      final lanesList = await lanesStream.first;
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
      print('❌ No workspace selected for creating board');
      throw Exception('No workspace selected');
    }

    try {
      final boardId = await _repository.createBoard(
        currentWorkspaceId.value,
        name,
        currentUserId.value,
      );

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
      print('❌ No workspace selected for updating board');
      throw Exception('No workspace selected');
    }

    try {
      await _repository.updateBoard(currentWorkspaceId.value, boardId, newName);

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
      print('❌ No workspace selected for deleting board');
      throw Exception('No workspace selected');
    }

    try {
      await _repository.deleteBoard(currentWorkspaceId.value, boardId);

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
  }

  @override
  void showError(String message) {
    error.value = message;
    print('❌ Board error: $message');
  }

  @override
  void render(BoardState state) {
    this.lanes.value = state.lanes;

    // Filter out archived cards from all lanes before storing
    final lanesWithoutArchived = state.lanes.map((lane) {
      final originalCardCount = lane.cards.length;
      final nonArchivedCards = lane.cards
          .where((card) => card.status != 'Archived')
          .toList();

      final archivedCount = originalCardCount - nonArchivedCards.length;

      // Debug: Check hashtags in this lane
      int cardsWithHashtags = 0;
      for (final card in nonArchivedCards) {
        if (card.hashtags.isNotEmpty) {
          cardsWithHashtags++;
        }
      }
      return Lane(
        id: lane.id,
        title: lane.title,
        order: lane.order,
        cards: nonArchivedCards,
        boardId: lane.boardId,
      );
    }).toList();

    _originalLanes.value =
        lanesWithoutArchived; // Store filtered lanes for search

    // Update display with filtered lanes
    this.lanes.value = lanesWithoutArchived;

    // Update available assignees, customers, and hashtags
    _updateAvailableAssignees();
    _updateAvailableCustomers();
    _updateAvailableHashtags();
    _updateAvailableInterests();

    // Apply current search and filter if exists
    final hasAssigneeFilter = selectedAssignees.isNotEmpty;
    final hasCustomerFilter = selectedCustomers.isNotEmpty;
    final hasHashtagFilter = selectedHashtags.isNotEmpty;
    final hasInterestFilter = selectedInterests.isNotEmpty;
    final hasDateFilter = selectedDateFilterTypes.isNotEmpty;
    final hasStatusFilter = selectedStatuses.isNotEmpty;
    final hasSearchQuery = searchQuery.value.isNotEmpty;

    if (hasSearchQuery &&
        (hasAssigneeFilter ||
            hasCustomerFilter ||
            hasHashtagFilter ||
            hasInterestFilter ||
            hasStatusFilter ||
            hasDateFilter)) {
      _performSearch(searchQuery.value);
      _performFilter();
    } else if (hasSearchQuery) {
      _performSearch(searchQuery.value);
    } else if (hasAssigneeFilter ||
        hasCustomerFilter ||
        hasHashtagFilter ||
        hasInterestFilter ||
        hasStatusFilter ||
        hasDateFilter) {
      _performFilter();
    } else {
      filteredLanes.value = state.lanes;
    }

    isLoading.value = state.isLoading;
    error.value = state.error ?? '';
    isInitialized.value = true;
  }

  // Search Methods
  void updateSearchQuery(String query) {
    final trimmedQuery = query.trim();
    searchQuery.value = trimmedQuery;

    // Sync with TextEditingController (with safety check)
    final controller = safeSearchTextController;
    if (controller != null) {
      try {
        if (controller.text != query) {
          controller.text = query;
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: query.length),
          );
        }
      } catch (e) {
        print('❌ SearchTextController disposed during updateSearchQuery: $e');
      }
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

    // Clear TextEditingController (with safety check)
    final controller = safeSearchTextController;
    if (controller != null) {
      try {
        controller.clear();
      } catch (e) {
        print('❌ SearchTextController disposed during clearSearch: $e');
      }
    }

    isSearching.value = false;
    filteredLanes.value = _originalLanes;
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    isSearching.value = true;
    final searchLower = query.toLowerCase();

    // Count total cards available
    int totalCards = 0;
    for (final lane in _originalLanes) {
      totalCards += lane.cards.length;
    }

    final List<Lane> searchResults = [];
    int matchingCards = 0;

    for (final lane in _originalLanes) {
      // Filter cards that match the search query AND are not archived
      final filteredCards = lane.cards.where((card) {
        final matches = _cardMatchesSearch(card, searchLower);
        final notArchived = card.status != 'Archived';
        if (matches && notArchived) matchingCards++;
        return matches && notArchived;
      }).toList();

      // Check if lane title matches
      final laneTitleMatches = lane.title.toLowerCase().contains(searchLower);

      // Include lane if it has matching cards or the lane title matches
      if (filteredCards.isNotEmpty || laneTitleMatches) {
        // If lane title matches, include all non-archived cards; otherwise include only filtered cards
        final cardsToInclude = laneTitleMatches
            ? lane.cards.where((card) => card.status != 'Archived').toList()
            : filteredCards;

        searchResults.add(
          Lane(
            id: lane.id,
            title: lane.title,
            order: lane.order,
            cards: cardsToInclude,
            boardId: lane.boardId,
          ),
        );
      }
    }

    filteredLanes.value = searchResults;
  }

  bool _cardMatchesSearch(JobCard card, String searchLower) {
    // Helper function to safely check string contains
    bool safeContains(String? text, String search) {
      if (text == null || text.isEmpty) return false;
      return text.toLowerCase().contains(search);
    }

    return safeContains(card.title, searchLower) ||
        safeContains(card.description, searchLower) ||
        safeContains(card.customId, searchLower) ||
        safeContains(card.customer, searchLower) ||
        safeContains(card.assignedTo, searchLower) ||
        safeContains(card.status, searchLower) ||
        safeContains(card.updatedByDisplayName, searchLower) ||
        safeContains(card.company?['value'], searchLower) ||
        _cardHashtagsContain(card, searchLower);
  }

  // Helper method to check if card hashtags contain search term
  bool _cardHashtagsContain(JobCard card, String searchLower) {
    for (final hashtagObj in card.hashtags) {
      if (hashtagObj['text'] != null) {
        final hashtagText = hashtagObj['text'] as String;
        if (hashtagText.toLowerCase().contains(searchLower)) {
          return true;
        }
      }
    }
    return false;
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
    // Single select logic - clear all others first
    if (selectedStatuses.contains(status)) {
      // If already selected, clear all (deselect)
      selectedStatuses.clear();
    } else {
      // If not selected, clear all and select only this one
      selectedStatuses.clear();
      selectedStatuses.add(status);
    }

    _performFilter();
  }

  void toggleDateFilterType(String dateType) {
    if (selectedDateFilterTypes.contains(dateType)) {
      selectedDateFilterTypes.remove(dateType);
    } else {
      selectedDateFilterTypes.add(dateType);
    }

    // Apply filter immediately when date type is toggled
    _performFilter();
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
  void updateDateFilter(
    String dateType,
    DateTime? startDate,
    DateTime? endDate,
  ) {
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
        selectedEndDate.value = today.add(
          const Duration(milliseconds: 86399999),
        );
        break;
      case 'thisWeek':
        // วันนี้ 00:00:00 ถึง +7 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today
            .add(const Duration(days: 7))
            .add(const Duration(milliseconds: 86399999));
        break;
      case 'thisMonth':
        // วันนี้ 00:00:00 ถึง +30 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today
            .add(const Duration(days: 30))
            .add(const Duration(milliseconds: 86399999));
        break;
      case 'lastMonth':
        // เดือนก่อน 00:00:00 ถึง วันนี้ 23:59:59
        final lastMonth = DateTime(today.year, today.month - 1, today.day);
        selectedStartDate.value = lastMonth;
        selectedEndDate.value = today.add(
          const Duration(milliseconds: 86399999),
        );
        break;
      case '+1day':
        // วันนี้ 00:00:00 ถึง วันนี้ +1 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today
            .add(const Duration(days: 1))
            .add(const Duration(milliseconds: 86399999));
        break;
      case '+3days':
        // วันนี้ 00:00:00 ถึง วันนี้ +3 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today
            .add(const Duration(days: 3))
            .add(const Duration(milliseconds: 86399999));
        break;
      case '+7days':
        // วันนี้ 00:00:00 ถึง วันนี้ +7 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today
            .add(const Duration(days: 7))
            .add(const Duration(milliseconds: 86399999));
        break;
      case '+14days':
        // วันนี้ 00:00:00 ถึง วันนี้ +14 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today
            .add(const Duration(days: 14))
            .add(const Duration(milliseconds: 86399999));
        break;
      case '+30days':
        // วันนี้ 00:00:00 ถึง วันนี้ +30 วัน 23:59:59
        selectedStartDate.value = today;
        selectedEndDate.value = today
            .add(const Duration(days: 30))
            .add(const Duration(milliseconds: 86399999));
        break;
      case 'lastWeek':
        // วันนี้ 00:00:00 ถึง วันนี้ -7 วัน 23:59:59
        selectedStartDate.value = today.subtract(const Duration(days: 7));
        selectedEndDate.value = today.add(
          const Duration(milliseconds: 86399999),
        );
        break;
    }
    
    // Apply filter immediately after setting dates
    _performFilter();
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
  }

  void _performFilter() {
    final hasAssigneeFilter = selectedAssignees.isNotEmpty;
    final hasCustomerFilter = selectedCustomers.isNotEmpty;
    final hasHashtagFilter = selectedHashtags.isNotEmpty;
    final hasInterestFilter = selectedInterests.isNotEmpty;
    final hasStatusFilter = selectedStatuses.isNotEmpty;
    final hasDateFilter =
        selectedDateFilterTypes.isNotEmpty &&
        (selectedStartDate.value != null || selectedEndDate.value != null);
    final hasShowWithoutDate = showCardsWithoutDate.value;

    if (!hasAssigneeFilter &&
        !hasCustomerFilter &&
        !hasHashtagFilter &&
        !hasInterestFilter &&
        !hasStatusFilter &&
        !hasDateFilter &&
        !hasShowWithoutDate) {
      isFiltering.value = false;
      if (searchQuery.value.isNotEmpty) {
        _performSearch(searchQuery.value);
      } else {
        filteredLanes.value = _originalLanes;
      }
      return;
    }

    isFiltering.value = true;
    // Start with original lanes or search results
    final sourceLanes = searchQuery.value.isNotEmpty
        ? _getSearchResults(searchQuery.value)
        : _originalLanes;

    // Debug: Print sample card data for troubleshooting
    if (sourceLanes.isNotEmpty && sourceLanes.first.cards.isNotEmpty) {
      final sampleCard = sourceLanes.first.cards.first;
    }

    final List<Lane> filterResults = [];
    int matchingCards = 0;

    for (final lane in sourceLanes) {
      // Filter cards by assignee, customer, hashtag, interest, status, and/or date
      final filteredCards = lane.cards.where((card) {
        // Skip archived cards
        if (card.status == 'Archived') return false;

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
          customerMatches = selectedCustomers.any(
            (selectedCustomer) => card.customer.toLowerCase().contains(
              selectedCustomer.toLowerCase(),
            ),
          );
        }

        // Check hashtag filter (OR logic - match any selected hashtag)
        if (hasHashtagFilter) {
          hashtagMatches = selectedHashtags.any(
            (selectedHashtag) => card.hashtags.any(
              (hashtag) => (hashtag['text'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(selectedHashtag.toLowerCase()),
            ),
          );
        }

        // Check interest filter (OR logic - match any selected interest)
        if (hasInterestFilter) {
          interestMatches = selectedInterests.any((selectedInterest) {
            final cardInterest = card.customerInterest?.toLowerCase() ?? '';
            final filterInterest = selectedInterest.toLowerCase();
            final matches = cardInterest == filterInterest;
            return matches;
          });
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
                cardDate = card.startDate;
                break;
              case 'endDate':
                cardDate = card.endDate;
                break;
              case 'createdAt':
                cardDate = card.createdAt;
                break;
              case 'dueDate':
              case 'toDoDate':
                // Check if any todo has a dueDate
                bool hasTodoDueDate = false;
                if (card.todos.isNotEmpty) {
                  for (final todo in card.todos) {
                    if (todo['dueDate'] != null) {
                      hasTodoDueDate = true;
                      break;
                    }
                  }
                }
                cardDate = hasTodoDueDate ? DateTime.now() : null; // If has todo dueDate, consider it has date
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

        final matches =
            assigneeMatches &&
            customerMatches &&
            hashtagMatches &&
            interestMatches &&
            statusMatches &&
            dateMatches &&
            withoutDateMatches;

        if (matches) matchingCards++;
        return matches;
      }).toList();

      // Always include all lanes, but filter their cards
      filterResults.add(
        Lane(
          id: lane.id,
          title: lane.title,
          order: lane.order,
          cards: filteredCards, // may be empty if no matching cards
          boardId: lane.boardId,
        ),
      );
    }

    filteredLanes.value = filterResults;
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
          // Use actual startDate field from card
          cardDate = card.startDate;
          break;
        case 'endDate':
          // Use actual endDate field from card
          cardDate = card.endDate;
          break;
        case 'createdAt':
          cardDate = card.createdAt;
          break;
        case 'dueDate':
        case 'toDoDate':
          // Check todos for dueDate
          if (card.todos.isNotEmpty) {
            for (final todo in card.todos) {
              if (todo['dueDate'] != null) {
                cardDate = DateTime.fromMillisecondsSinceEpoch(todo['dueDate'] as int);
                break;
              }
            }
          }
          if (cardDate == null) {
            cardDate = card.dueDate;
          }
          break;
        case 'updatedAt':
          cardDate = card.updatedAt;
          break;
        default:
          cardDate = card.createdAt;
      }

      if (cardDate == null) return false;

      // Check if card date is within the selected range
      bool matches = true;

      if (startDate != null) {
        matches =
            matches &&
            cardDate.isAfter(startDate.subtract(const Duration(days: 1)));
      }

      if (endDate != null) {
        matches =
            matches && cardDate.isBefore(endDate.add(const Duration(days: 1)));
      }

      return matches;
    });
  }

  List<Lane> _getSearchResults(String query) {
    final searchLower = query.toLowerCase();
    final List<Lane> searchResults = [];

    for (final lane in _originalLanes) {
      final filteredCards = lane.cards.where((card) {
        final matchesSearch = _cardMatchesSearch(card, searchLower);
        final notArchived = card.status != 'Archived';
        return matchesSearch && notArchived;
      }).toList();

      final laneTitleMatches = lane.title.toLowerCase().contains(searchLower);

      if (filteredCards.isNotEmpty || laneTitleMatches) {
        final cardsToInclude = laneTitleMatches
            ? lane.cards.where((card) => card.status != 'Archived').toList()
            : filteredCards;
        searchResults.add(
          Lane(
            id: lane.id,
            title: lane.title,
            order: lane.order,
            cards: cardsToInclude,
            boardId: lane.boardId,
          ),
        );
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
    final List<String> assigneeDisplays = assigneeUids
        .map((uid) => getDisplayNameFromUid(uid))
        .toList();
    availableAssignees.value = assigneeUids
        .toList(); // Keep UIDs for filtering logic
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
  }

  void _updateAvailableHashtags() {
    final Set<String> hashtags = {};
    int totalCards = 0;
    int cardsWithHashtags = 0;
    for (final lane in _originalLanes) {
      for (final card in lane.cards) {
        totalCards++;
        // Use hashtags array instead of hashtag string
        if (card.hashtags.isNotEmpty) {
          cardsWithHashtags++;
          for (final hashtagObj in card.hashtags) {
            if (hashtagObj['text'] != null) {
              final hashtagText = hashtagObj['text'] as String;
              if (hashtagText.isNotEmpty) {
                final trimmedText = hashtagText.trim();
                hashtags.add(trimmedText);
              }
            }
          }
        }
      }
    }

    availableHashtags.value = hashtags.toList();
    // Trigger UI update manually
    availableHashtags.refresh();
  }

  void _updateAvailableInterests() {
    final Set<String> interests = {};
    int totalCards = 0;
    int cardsWithInterests = 0;

    for (final lane in _originalLanes) {
      for (final card in lane.cards) {
        totalCards++;
        if (card.customerInterest != null &&
            card.customerInterest!.isNotEmpty) {
          cardsWithInterests++;
          interests.add(card.customerInterest!.trim());
        }
      }
    }

    availableInterests.value = interests.toList();
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
    final hasAnyFilter =
        isSearching.value ||
        selectedAssignees.isNotEmpty ||
        selectedCustomers.isNotEmpty ||
        selectedHashtags.isNotEmpty ||
        selectedInterests.isNotEmpty ||
        selectedStatuses.isNotEmpty ||
        selectedDateFilterTypes.isNotEmpty;

    if (hasAnyFilter) {
      final result = List<Lane>.from(filteredLanes);
      return result;
    }

    return lanes;
  }

  // Get hashtags from workspace hashtagSettings
  Future<List<Map<String, dynamic>>> getWorkspaceHashtags() async {
    try {
      final workspaceId = currentWorkspaceId.value;
      if (workspaceId.isEmpty) {
        print('❌ No workspace selected for loading hashtags');
        return [];
      }
      // Get workspace data
      final workspaceData = await _repository.getWorkspace(workspaceId);

      if (workspaceData != null) {
        final hashtagSettings =
            workspaceData['companyProfile']?['hashtagSettings']
                as Map<String, dynamic>?;

        if (hashtagSettings != null && hashtagSettings['isEnabled'] == true) {
          final masterList = hashtagSettings['masterList'] as List<dynamic>?;

          if (masterList != null) {
            final hashtags = masterList
                .where(
                  (hashtag) =>
                      hashtag['enabled'] == true &&
                      hashtag['scopes']?['jobBoard'] == true,
                )
                .map(
                  (hashtag) => {
                    'id': hashtag['id'] ?? '',
                    'text': hashtag['name'] ?? '',
                    'color': hashtag['color'] ?? '#f97316',
                  },
                )
                .toList();
            return List<Map<String, dynamic>>.from(hashtags);
          }
        }
      }
      return [];
    } catch (e) {
      print('❌ Failed to load workspace hashtags: $e');
      return [];
    }
  }

  // Get user display name from Firestore users collection with caching
  Future<String> getUserDisplayName(String userId) async {
    try {
      final userData = await _repository.getUserById(userId);
      if (userData != null && userData['displayName'] != null) {
        final displayName = userData['displayName'] as String;
        return displayName;
      }

      return userId; // Fallback to user ID if display name not found
    } catch (e) {
      print('❌ Failed to get user display name for $userId: $e');
      return userId; // Fallback to user ID on error
    }
  }
}
