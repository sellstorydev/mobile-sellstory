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

  // Cached workspace info
  Map<String, dynamic>? _workspaceData;
  List<Map<String, dynamic>> _wsFacebook = const [];
  List<Map<String, dynamic>> _wsInstagram = const [];
  List<Map<String, dynamic>> _wsLine = const [];
  // Hashtag master cache: id->item and name(lower)->item
  final Map<String, Map<String, dynamic>> _hashtagById = {};
  final Map<String, Map<String, dynamic>> _hashtagByNameLower = {};

  // Cache assignees for customerId -> [displayNames]
  final Map<String, List<String>> _assigneesCache = {};

  bool get _isListening => _chatroomsSub != null;


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

  // Load workspace connections (facebook/instagram/line) and attach matching provider info to each chatroom item so ConversationTile can show provider name and correct platform icon. If multiple connections exist and no direct ID to match, fall back to single-connection per platform when available.
  Future<void> _loadWorkspaceConnectionsIfNeeded() async {
    if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) return;
    if (_workspaceData != null) return; // already loaded

    try {
      _workspaceData = await _firestoreService.getWorkspace(_currentWorkspaceId!);
      final ws = _workspaceData ?? {};
      final connections = (ws['connections'] ?? ws['companyProfile']?['connections']) as Map<String, dynamic>?;

      List<Map<String, dynamic>> asList(dynamic v) {
        if (v is List) return v.cast<Map<String, dynamic>>();
        return const [];
      }

      _wsFacebook = asList(connections?['facebook']);
      _wsInstagram = asList(connections?['instagram']);
      _wsLine = asList(connections?['line']);

      // Load hashtag settings (master list)
      final hs = (ws['hashtagSettings'] ?? ws['companyProfile']?['hashtagSettings']) as Map<String, dynamic>?;
      final master = asList(hs?['masterList']);
      _hashtagById.clear();
      _hashtagByNameLower.clear();
      for (final item in master) {
        final id = (item['id'] ?? '').toString();
        final name = (item['name'] ?? '').toString();
        if (id.isNotEmpty) _hashtagById[id] = item;
        if (name.isNotEmpty) _hashtagByNameLower[name.toLowerCase()] = item;
      }

      _logger.info('Loaded workspace connections: fb=${_wsFacebook.length}, ig=${_wsInstagram.length}, line=${_wsLine.length}; hashtags=${master.length}');
    } catch (e) {
      _logger.warning('Failed to load workspace connections: $e');
    }
  }

  List<Map<String, String>> _buildHashtagMeta(Map<String, dynamic> chatData) {
    // Prefer hashtagIds for exact match; fallback to names
    final List ids = (chatData['hashtagIds'] is List) ? (chatData['hashtagIds'] as List) : const [];
    final List namesRaw = (chatData['hashtags'] is List) ? (chatData['hashtags'] as List) : const [];

    final List<Map<String, String>> out = [];

    if (ids.isNotEmpty) {
      for (final v in ids) {
        final id = v.toString();
        final item = _hashtagById[id];
        if (item != null) {
          final name = (item['name'] ?? id).toString();
          final color = (item['color'] ?? '').toString();
          if (name.isNotEmpty) {
            out.add({'name': name.startsWith('#') ? name : '#$name', 'color': color});
          }
        }
      }
    }

    // Also include names that might not have ids
    for (final n in namesRaw) {
      final raw = n.toString().trim();
      if (raw.isEmpty) continue;
      // Avoid duplicates by normalized name (strip leading #)
      final norm = raw.startsWith('#') ? raw.substring(1) : raw;
      final already = out.any((m) => (m['name'] ?? '').replaceFirst('#', '') == norm);
      if (already) continue;
      final item = _hashtagByNameLower[norm.toLowerCase()];
      if (item != null) {
        final color = (item['color'] ?? '').toString();
        out.add({'name': raw.startsWith('#') ? raw : '#$raw', 'color': color});
      } else {
        // No master match; keep name without color
        out.add({'name': raw.startsWith('#') ? raw : '#$raw'});
      }
    }

    return out;
  }

  Map<String, dynamic> _attachProviderInfo(Map<String, dynamic> data) {
    String platform = (data['source_type'] ?? data['sourceType'] ?? '').toString().toLowerCase();

    Map<String, dynamic>? firstWhereOrNull(List<Map<String, dynamic>> list, bool Function(Map<String, dynamic>) test) {
      for (final e in list) {
        if (test(e)) return e;
      }
      return null;
    }

    Map<String, dynamic>? matched;

    final docConnections = (data['connections'] ?? data['companyProfile']?['connections']) as Map<String, dynamic>?;
    List<Map<String, dynamic>> asList(dynamic v) => (v is List) ? v.cast<Map<String, dynamic>>() : const [];

    final docFacebook = asList(docConnections?['facebook']);
    final docInstagram = asList(docConnections?['instagram']);
    final docLine = asList(docConnections?['line']);

    final fbCandidates = docFacebook.isNotEmpty ? docFacebook : _wsFacebook;
    final igCandidates = docInstagram.isNotEmpty ? docInstagram : _wsInstagram;
    final lineCandidates = docLine.isNotEmpty ? docLine : _wsLine;

    bool isUnknown = platform.isEmpty || platform == 'unknown';
    if (isUnknown) {
      final hasPageId = (data['pageId']?.toString().isNotEmpty ?? false);
      final hasIgUserId = (data['igUserId']?.toString().isNotEmpty ?? false);
      final hasLineIds = (data['channelId']?.toString().isNotEmpty ?? false) || (data['botId']?.toString().isNotEmpty ?? false) || (data['lineUserId']?.toString().isNotEmpty ?? false);

      if (hasPageId) {
        platform = 'facebook';
      } else if (hasIgUserId) {
        platform = 'instagram';
      } else if (hasLineIds) {
        platform = 'line';
      } else {
        final available = <String, int>{
          'facebook': fbCandidates.length,
          'instagram': igCandidates.length,
          'line': lineCandidates.length,
        }..removeWhere((k, v) => v == 0);
        if (available.length == 1) {
          platform = available.keys.first;
        }
      }

      if (platform.isNotEmpty) {
        data['source_type'] = data['source_type'] ?? platform;
        data['sourceType'] = data['sourceType'] ?? platform;
      }
    }

    if (platform.contains('facebook')) {
      final pageId = (data['pageId'] ?? data['connection']?['pageId'])?.toString();
      if (pageId != null && pageId.isNotEmpty) {
        matched = firstWhereOrNull(fbCandidates, (e) => (e['pageId']?.toString() ?? '') == pageId);
      }
      matched ??= fbCandidates.length == 1 ? (fbCandidates.isNotEmpty ? fbCandidates.first : null) : null;
      matched ??= fbCandidates.isNotEmpty ? fbCandidates.first : null;
    } else if (platform.contains('instagram') || platform == 'ig') {
      final igUserId = (data['igUserId'] ?? data['connection']?['igUserId'])?.toString();
      final pageId = (data['pageId'] ?? data['connection']?['pageId'])?.toString();
      if (igUserId != null && igUserId.isNotEmpty) {
        matched = firstWhereOrNull(igCandidates, (e) => (e['igUserId']?.toString() ?? '') == igUserId);
      }
      if (matched == null && pageId != null && pageId.isNotEmpty) {
        matched = firstWhereOrNull(igCandidates, (e) => (e['pageId']?.toString() ?? '') == pageId);
      }
      matched ??= igCandidates.length == 1 ? (igCandidates.isNotEmpty ? igCandidates.first : null) : null;
      matched ??= igCandidates.isNotEmpty ? igCandidates.first : null;
    } else if (platform.contains('line')) {
      final channelId = (data['channelId'] ?? data['connection']?['channelId'])?.toString();
      final botId = (data['botId'] ?? data['connection']?['botId'])?.toString();
      final userId = (data['lineUserId'] ?? data['connection']?['userId'])?.toString();

      if (channelId != null && channelId.isNotEmpty) {
        matched = firstWhereOrNull(lineCandidates, (e) => (e['channelId']?.toString() ?? '') == channelId);
      }
      matched ??= (botId != null && botId.isNotEmpty)
          ? firstWhereOrNull(lineCandidates, (e) => (e['botId']?.toString() ?? '') == botId)
          : null;
      matched ??= (userId != null && userId.isNotEmpty)
          ? firstWhereOrNull(lineCandidates, (e) => (e['userId']?.toString() ?? '') == userId)
          : null;

      if (matched == null && lineCandidates.isNotEmpty) {
        final title = (data['name'] ?? data['customerName'] ?? data['who_name'] ?? '').toString();
        if (title.isNotEmpty) {
          matched = firstWhereOrNull(lineCandidates, (e) {
            final dn = (e['displayName'] ?? e['statusMessage'] ?? '').toString();
            return dn.isNotEmpty && title.contains(dn);
          });
        }
      }

      matched ??= lineCandidates.length == 1 ? (lineCandidates.isNotEmpty ? lineCandidates.first : null) : null;
      matched ??= lineCandidates.isNotEmpty ? lineCandidates.first : null;
    } else {
      final all = <Map<String, dynamic>>[]
        ..addAll(fbCandidates)
        ..addAll(igCandidates)
        ..addAll(lineCandidates);
      if (all.length == 1) {
        matched = all.first;
        final p = (docFacebook.isNotEmpty ? 'facebook' : docInstagram.isNotEmpty ? 'instagram' : docLine.isNotEmpty ? 'line' : (_wsFacebook.isNotEmpty ? 'facebook' : _wsInstagram.isNotEmpty ? 'instagram' : _wsLine.isNotEmpty ? 'line' : 'unknown'));
        if (p != 'unknown') {
          data['source_type'] = data['source_type'] ?? p;
          data['sourceType'] = data['sourceType'] ?? p;
          platform = p;
        }
      } else if (all.isNotEmpty) {
        if (lineCandidates.isNotEmpty) {
          matched = lineCandidates.first;
          platform = 'line';
        } else if (fbCandidates.isNotEmpty) {
          matched = fbCandidates.first;
          platform = 'facebook';
        } else if (igCandidates.isNotEmpty) {
          matched = igCandidates.first;
          platform = 'instagram';
        }
        if (matched != null) {
          data['source_type'] = data['source_type'] ?? platform;
          data['sourceType'] = data['sourceType'] ?? platform;
        }
      }
    }

    if (matched != null) {
      final effectivePlatform = (data['source_type'] ?? platform).toString().toLowerCase();
      final platformLabel = effectivePlatform.contains('facebook')
          ? 'facebook'
          : effectivePlatform.contains('instagram') || effectivePlatform == 'ig' ? 'instagram' : effectivePlatform.contains('line') ? 'line' : 'unknown';

      data['connection'] = {
        ...matched,
        'platform': platformLabel,
      };

      final existingPageName = (data['pageName'] ?? '').toString().trim();
      final matchedPageName = (matched['pageName'] ?? matched['displayName'] ?? matched['igUsername'] ?? '').toString().trim();
      if (existingPageName.isEmpty && matchedPageName.isNotEmpty) {
        data['pageName'] = matchedPageName;
      }

      data['pageId'] = data['pageId'] ?? matched['pageId'];
      data['igUserId'] = data['igUserId'] ?? matched['igUserId'];
      data['channelId'] = data['channelId'] ?? matched['channelId'];
      data['botId'] = data['botId'] ?? matched['botId'];

      data['avatarUrl'] = data['avatarUrl'] ?? data['avatar'] ??
          matched['pageImageUrl'] ?? matched['profilePictureUrl'] ?? matched['pictureUrl'];

      _logger.info('Provider matched for chatroom ${data['id']}: ${data['pageName']} ($platformLabel)');
    } else {
      String candidateName = '';
      Map<String, dynamic>? candidate;
      if (platform.contains('facebook') && fbCandidates.isNotEmpty) {
        candidate = fbCandidates.first;
        candidateName = (candidate['pageName'] ?? '').toString();
      } else if ((platform.contains('instagram') || platform == 'ig') && igCandidates.isNotEmpty) {
        candidate = igCandidates.first;
        candidateName = (candidate['pageName'] ?? candidate['igUsername'] ?? '').toString();
      } else if (platform.contains('line') && lineCandidates.isNotEmpty) {
        candidate = lineCandidates.first;
        candidateName = (candidate['displayName'] ?? '').toString();
      }

      if ((data['pageName'] ?? '').toString().isEmpty && candidateName.isNotEmpty) {
        data['pageName'] = candidateName;
        data['connection'] = {
          ...?candidate,
          'platform': platform.isEmpty ? 'unknown' : platform,
        };
        data['avatarUrl'] = data['avatarUrl'] ?? data['avatar'] ??
            candidate?['pageImageUrl'] ?? candidate?['profilePictureUrl'] ?? candidate?['pictureUrl'];
        _logger.info('Provider fallback set for chatroom ${data['id']}: ${data['pageName']} ($platform)');
      } else {
        _logger.warning('No provider matched for chatroom ${data['id']} (platform: ${platform.isEmpty ? 'unknown' : platform})');
      }
    }

    return data;
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

    // Already listening: do nothing to prevent flicker
    if (_isListening) {
      _logger.info('startRealtime: already listening, skip restart');
      return;
    }

    // Preload connections so tiles can show provider/page names
    await _loadWorkspaceConnectionsIfNeeded();

    // First start only: show loading if no data yet
    if (conversations.isEmpty) {
      isLoading.value = true;
    }
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

          // Attach provider info if possible
          final enriched = _attachProviderInfo(data);
          // Attach hashtag meta (name + color from master list)
          try {
            enriched['hashtagMeta'] = _buildHashtagMeta(enriched);
          } catch (_) {}
          return enriched;
        }).toList();

        // Preserve list identity to reduce widget rebuild/flicker
        conversations.assignAll(items);
        isLoading.value = false;
        error.value = '';

        // Asynchronously enrich with assignee display names
        _augmentAssignees(items);
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
    // Avoid restarting stream to prevent UI flicker
    _logger.info('ChatController.refresh: soft refresh (no restart)');
    conversations.refresh();
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

  Future<void> _augmentAssignees(List<Map<String, dynamic>> items) async {
    final wsId = _currentWorkspaceId;
    if (wsId == null || wsId.isEmpty) return;

    for (final item in items) {
      // Resolve customerId from various fields
      final cid = (item['customerId'] ?? item['customer_id'] ?? item['customer']?['id'])?.toString();
      if (cid == null || cid.isEmpty) continue;

      List<String>? names = _assigneesCache[cid];
      if (names == null) {
        try {
          final cSnap = await FirestoreService.to
              .getWorkspaceCustomersCollection(wsId)
              .doc(cid)
              .get();
          final cData = cSnap.data() ?? {};
          final uids = ((cData['assignees'] as List?) ?? []).map((e) => e.toString()).toList();
          if (uids.isEmpty) {
            names = const [];
          } else {
            final futures = uids.map((uid) async {
              final u = await FirestoreService.to.usersCollection.doc(uid).get();
              final m = u.data() ?? {};
              final dn = (m['displayName'] ?? m['name'] ?? '').toString();
              return dn.isNotEmpty ? dn : uid;
            });
            names = await Future.wait(futures);
          }
          _assigneesCache[cid] = names;
        } catch (_) {
          names = const [];
        }
      }

      // Update the item in conversations list
      final idx = conversations.indexWhere((c) => (c['id']?.toString() ?? '') == (item['id']?.toString() ?? ''));
      if (idx >= 0) {
        conversations[idx]['assigneeNames'] = names;
        conversations.refresh();
      }
    }
  }
}
