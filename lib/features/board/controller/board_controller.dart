import 'package:get/get.dart';
import '../../../domain/entities/lane.dart';
import '../../../domain/entities/job_card.dart';
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
        
        // Load data for the selected workspace
        await load();
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
      
      // Load data for the new workspace
      await load();
      
      print('✅ Workspace switched successfully');
    } catch (e) {
      print('❌ Failed to switch workspace: $e');
      error.value = 'Failed to switch workspace';
    }
  }
  
  // Load data for current workspace
  Future<void> load() async {
    if (currentWorkspaceId.value.isEmpty) {
      print('⚠️ No workspace selected for loading');
      return;
    }
    
    try {
      print('🔄 Loading board data for workspace: ${currentWorkspaceId.value}');
      await _presenter.load(currentWorkspaceId.value);
      print('✅ Board data loaded successfully - ${lanes.length} lanes');
    } catch (e) {
      print('❌ Failed to load board data: $e');
      error.value = 'Failed to load board data';
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

  // Getters for UI
  bool get hasWorkspaces => userWorkspaces.isNotEmpty;
  List<Map<String, dynamic>> get availableWorkspaces => userWorkspaces;

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
    this.lanes.value = state.lanes;
    isLoading.value = state.isLoading;
    error.value = state.error ?? '';
    isInitialized.value = true;
    
    print('📱 Board state updated - ${state.lanes.length} lanes');
  }
}
