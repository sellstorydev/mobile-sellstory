import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Subscription for realtime updates
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatroomsSub;

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

  Future<void> _getCurrentWorkspaceId() async {
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

  // Start realtime listener for chatrooms in current workspace
  Future<void> startRealtime() async {
    if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) {
      await _getCurrentWorkspaceId();
      if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) {
        error.value = 'No workspace selected';
        return;
      }
    }

    // If already listening, restart
    await stopRealtime();

    isLoading.value = true;
    error.value = '';

    try {
      final col = _firestoreService.getChatroomsCollection(_currentWorkspaceId!);
      _chatroomsSub = _firestoreService.getDocumentsStream(
        col,
        queryBuilder: (q) => q
            .where('is_deleted', isEqualTo: 'N')
            .orderBy('last_message_info.last_upd', descending: true),
      ).listen((qs) {
        final items = qs.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;

          final lastMessageInfo = data['last_message_info'] as Map<String, dynamic>? ?? {};

          data['name'] = data['name'] ?? data['customerName'] ?? lastMessageInfo['who_name'] ?? 'Unknown';
          data['type'] = (data['dialog_type']?.toString().toUpperCase() == 'GROUP') ? 'group' : 'direct';
          data['lastMessage'] = lastMessageInfo['message'] ?? data['message'] ?? '';
          data['avatarUrl'] = data['avatar'];
          data['status'] = data['chatroom_status'] ?? 'active';
          data['unreadCount'] = int.tryParse(data['count']?.toString() ?? '0') ?? 0;
          data['isOnline'] = (data['bot_status'] == 'Y');
          data['sourceType'] = data['source_type'] ?? 'unknown';
          data['isPinned'] = data['chat_pin'] == 'Y';
          data['isNew'] = data['is_new'] == 'Y';

          DateTime? parseDate(dynamic v) {
            if (v == null) return null;
            if (v is Timestamp) return v.toDate();
            if (v is String) {
              try { return DateTime.parse(v); } catch (_) {}
            }
            return null;
          }

          data['lastMessageAt'] = parseDate(lastMessageInfo['last_upd']);
          data['createdAt'] = parseDate(data['created']);

          return data;
        }).toList();

        conversations.value = items;
        isLoading.value = false;
        error.value = '';
      }, onError: (e) {
        isLoading.value = false;
        error.value = 'Failed to get realtime chatrooms: $e';
      });
    } catch (e) {
      isLoading.value = false;
      error.value = 'Failed to start realtime: $e';
    }
  }

  Future<void> stopRealtime() async {
    await _chatroomsSub?.cancel();
    _chatroomsSub = null;
  }

  Future<void> loadConversations() async {
    // Preserve for compatibility: switch to realtime
    await startRealtime();
  }


  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setFilter(String filter) {
    activeFilter.value = filter;
    // No server reload; filter is applied client-side on conversations stream
  }

  void refresh() {
    // Restart stream to force refresh if needed
    startRealtime();
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
    filtered.sort((a, b) {
      final aTime = a['lastMessageAt'] as DateTime?;
      final bTime = b['lastMessageAt'] as DateTime?;
      final aVal = aTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bVal = bTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bVal.compareTo(aVal);
    });

    // Sort strictly by latest message time (descending)
    // filtered.sort((a, b) {
    //   // Prioritize pinned chats
    //   final aPinned = a['chat_pin'] == 'Y';
    //   final bPinned = b['chat_pin'] == 'Y';
    //
    //   if (aPinned && !bPinned) return -1;
    //   if (!aPinned && bPinned) return 1;
    //
    //   // Then sort by last message time
    //   final aTime = a['lastMessageAt'] as DateTime?;
    //   final bTime = b['lastMessageAt'] as DateTime?;
    //
    //   if (aTime == null && bTime == null) return 0;
    //   if (aTime == null) return 1;
    //   if (bTime == null) return -1;
    //
    //   return bTime.compareTo(aTime);
    // });

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

  // Add method to get current workspace ID for ChatScreen
  String? getCurrentWorkspaceId() {
    return _currentWorkspaceId;
  }

  @override
  void onClose() {
    _logger.info('ChatController disposed');
    stopRealtime();
    super.onClose();
  }
}