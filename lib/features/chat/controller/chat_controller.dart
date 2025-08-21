import 'package:get/get.dart';
import '../../../data/services/firestore_service.dart';
import '../../../core/services/logger_service.dart';
import '../../board/controller/board_controller.dart'; // Add this import

class ChatController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final LoggerService _logger = Get.find<LoggerService>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString activeFilter = 'all'.obs;

  // Current user and workspace
  String? _currentUserId;
  String? _currentWorkspaceId;

  @override
  void onInit() {
    super.onInit();
    _logger.info('ChatController initialized');
  }

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    _getCurrentWorkspaceId();
    _logger.info('Current user set: $userId');
  }

  void _getCurrentWorkspaceId() async {
    if (_currentUserId == null) return;

    try {
      // First try to get workspace ID from user's lastActiveWorkspaceId
      final userData = await _firestoreService.getDocument(
        _firestoreService.usersCollection.doc(_currentUserId!)
      );

      if (userData != null && userData['lastActiveWorkspaceId'] != null && userData['lastActiveWorkspaceId'].toString().isNotEmpty) {
        _currentWorkspaceId = userData['lastActiveWorkspaceId'] as String;
        _logger.info('Got workspace ID from user document: $_currentWorkspaceId');
        return;
      }

      // Fallback: Get first workspace from user's workspaces array (index 0)
      if (userData != null && userData['workspaces'] != null) {
        final workspaces = userData['workspaces'] as List<dynamic>?;
        if (workspaces != null && workspaces.isNotEmpty) {
          final firstWorkspace = workspaces[0] as Map<String, dynamic>;
          _currentWorkspaceId = firstWorkspace['id'] as String? ?? firstWorkspace['workspaceId'] as String?;
          if (_currentWorkspaceId != null) {
            _logger.info('Got workspace ID from first workspace (index 0): $_currentWorkspaceId');
            return;
          }
        }
      }

      // Last fallback: Get workspace ID from BoardController if available
      if (Get.isRegistered<BoardController>()) {
        final boardController = Get.find<BoardController>();
        _currentWorkspaceId = boardController.currentWorkspaceId.value;
        _logger.info('Got workspace ID from BoardController: $_currentWorkspaceId');
      } else {
        _logger.warning('BoardController not registered and no workspace found');
      }
    } catch (e) {
      _logger.failure('Failed to get workspace ID', e);

      // Last resort: try BoardController
      try {
        if (Get.isRegistered<BoardController>()) {
          final boardController = Get.find<BoardController>();
          _currentWorkspaceId = boardController.currentWorkspaceId.value;
          _logger.info('Fallback: Got workspace ID from BoardController: $_currentWorkspaceId');
        }
      } catch (e2) {
        _logger.failure('All methods to get workspace ID failed', e2);
      }
    }
  }

  Future<void> loadConversations() async {


    if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) {
      _getCurrentWorkspaceId(); // Try to get it again

      if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) {
        error.value = 'No workspace selected';
        _logger.warning('Cannot load conversations: no workspace ID available');
        return;
      }
    }

    try {
      isLoading.value = true;
      error.value = '';

      _logger.info('Loading chatrooms for workspace: $_currentWorkspaceId');

      final result = await _firestoreService.getChatroomsForWorkspace(_currentWorkspaceId!);
      conversations.value = result;

      _logger.success('Loaded ${result.length} chatrooms');
    } catch (e) {
      error.value = 'Failed to load chatrooms: $e';
      _logger.failure('Failed to load chatrooms', e);
    } finally {
      isLoading.value = false;
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setFilter(String filter) {
    activeFilter.value = filter;
    loadConversations(); // Reload with new filter
  }

  List<Map<String, dynamic>> get filteredConversations {
    var filtered = conversations.where((conv) {
      // Search filter
      if (searchQuery.value.isNotEmpty) {
        final query = searchQuery.value.toLowerCase();
        final name = (conv['name'] ?? '').toString().toLowerCase();
        final lastMessage = (conv['lastMessage'] ?? '').toString().toLowerCase();
        final customerName = (conv['customerName'] ?? '').toString().toLowerCase();

        if (!name.contains(query) &&
            !lastMessage.contains(query) &&
            !customerName.contains(query)) {
          return false;
        }
      }

      // Status filter based on your JSON structure
      switch (activeFilter.value) {
        case 'unread':
          final unreadCount = int.tryParse(conv['count']?.toString() ?? '0') ?? 0;
          return unreadCount > 0;
        case 'assigned':
          // You might need to add assignedUsers field or use a different logic
          return conv['chatroom_status'] == 'assigned';
        case 'inProgress':
          return conv['chatroom_status'] == 'in_progress' || conv['chatroom_status'] == 'active';
        case 'groupOnly':
          return conv['is_group'] == 'Y';
        case 'new':
          return conv['is_new'] == 'Y';
        case 'pinned':
          return conv['chat_pin'] == 'Y';
        case 'line':
          return conv['source_type'] == 'line';
        default:
          return true;
      }
    }).toList();

    // Sort by last message time or pinned status
    filtered.sort((a, b) {
      // Prioritize pinned chats
      final aPinned = a['chat_pin'] == 'Y';
      final bPinned = b['chat_pin'] == 'Y';

      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;

      // Then sort by last message time
      final aTime = a['lastMessageAt'] as DateTime?;
      final bTime = b['lastMessageAt'] as DateTime?;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      return bTime.compareTo(aTime);
    });

    return filtered;
  }

  Future<void> markAsRead(String conversationId) async {
    if (_currentUserId == null) return;

    try {
      await _firestoreService.markConversationAsRead(conversationId, _currentUserId!);

      // Update local state
      final index = conversations.indexWhere((conv) => conv['id'] == conversationId);
      if (index >= 0) {
        conversations[index]['unreadCount'] = 0;
        conversations.refresh();
      }

      _logger.info('Marked conversation as read: $conversationId');
    } catch (e) {
      _logger.failure('Failed to mark conversation as read', e);
    }
  }

  void refresh() {
    loadConversations();
  }

  // Add method to get current workspace ID for ChatScreen
  String? getCurrentWorkspaceId() {
    return _currentWorkspaceId;
  }

  @override
  void onClose() {
    _logger.info('ChatController disposed');
    super.onClose();
  }
}
