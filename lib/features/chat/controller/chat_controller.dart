import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../data/services/firestore_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/user_cache_service.dart';
import '../../board/controller/board_controller.dart'; // Add this import
import '../../../data/services/mobile_permissions_service.dart';
import 'package:dio/dio.dart';
import '../../../core/network/mobile_api.dart';
import '../../../data/services/firebase_auth_service.dart';

class ChatController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final LoggerService _logger = Get.find<LoggerService>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> conversations =
      <Map<String, dynamic>>[].obs;
  final RxString searchQuery = ''.obs;
  // Room IDs matched by message full-text search (mirror collection)
  final RxSet<String> _messageSearchRoomIds = <String>{}.obs;
  Worker? _searchDebounce;
  final RxString activeFilter = 'all'.obs;

  // ===== Visible Chatrooms API pagination state =====
  final RxBool useVisibleApi =
      true.obs; // toggle to use server visibility endpoint
  final RxBool isApiLoading = false.obs; // loading (initial or refreshing)
  final RxBool isApiLoadingMore = false.obs; // loading next page
  String? _nextCursor; // pagination cursor
  bool _apiHasMore = true; // whether more pages available
  DateTime _lastLoadMoreAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Keep last applied workspace for API mode to detect switching
  String? _apiWorkspaceBound;

  // NEW: Loading flag while resolving assignees for permission-based filtering on first entry
  final RxBool isAssigneeLoading = false.obs;
  bool _assigneeInitialSettled = false;

  // Current user and workspace
  String? _currentUserId;
  String? _currentWorkspaceId;

  // Subscription for realtime updates
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatroomsSub;

  // Workspace change listener (GetX Worker)
  Worker? _wsListener;

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
  // NEW: Cache assignee UIDs for customerId -> [uids] to keep IDs when names are cached
  final Map<String, List<String>> _assigneeUidsCache = {};

  // Cache customer hashtags to avoid repeated reads: customerId -> ids/meta
  final Map<String, List<String>> _customerHashtagIdsCache = {};
  final Map<String, List<Map<String, String>>> _customerHashtagMetaCache = {};

  // Filters (reactive)
  final RxSet<String> platformFilters =
      <String>{}.obs; // 'facebook','instagram','line'
  final RxString statusFilter = ''.obs; // '', 'NEW','IN_PROGRESS','DONE'
  final RxList<String> hashtagIdFilters =
      <String>[].obs; // selected hashtag IDs
  final RxString salesIdFilter = ''.obs; // single sales/user id
  final RxString customerIdFilter = ''.obs; // single customer id

  // Helpers to set/clear filters
  void setPlatformFilters(Set<String> values) {
    platformFilters
      ..clear()
      ..addAll(values.map((e) => e.toLowerCase()));
    conversations.refresh();
  }

  // Public helpers for UI integration
  bool isMessageSearchHit(String roomId) {
    try {
      return _messageSearchRoomIds.contains(roomId);
    } catch (_) {
      return false;
    }
  }

  String currentSearchTerm() => searchQuery.value;
  


  void getUsersFromChatroom(_currentWorkspaceId) async {
    try {
      final wsDoc = await _firestoreService.workspacesCollection
          .doc(_currentWorkspaceId)
          .get();
      if (!wsDoc.exists) {
        _logger.warning(
          'getUsersFromChatroom: workspace $_currentWorkspaceId does not exist',
        );
        _logger.methodExit(
          'ChatController.getUsersFromChatroom',
          'early:return:workspace-not-found',
        );
        return;
      }

      // workspace data not needed here currently
    } catch (e, st) {
      _logger.failure(
        'getUsersFromChatroom: failed to fetch workspace/users',
        e,
        st,
      );
      _logger.methodExit('ChatController.getUsersFromChatroom', 'error');
    }
  }

  void setStatusFilter(String value) {
    statusFilter.value = value.toUpperCase();
  }

  void setHashtagFilters(List<String> ids) {
    hashtagIdFilters
      ..clear()
      ..addAll(ids);
    conversations.refresh();
  }

  void setSalesFilter(String? uid) {
    salesIdFilter.value = (uid ?? '').trim();
  }

  void setCustomerFilter(String? cid) {
    customerIdFilter.value = (cid ?? '').trim();
  }


  void clearAllFilters() {
    platformFilters.clear();
    statusFilter.value = '';
    hashtagIdFilters.clear();
    salesIdFilter.value = '';
    customerIdFilter.value = '';
    activeFilter.value = 'all'; // keep legacy no-op
    conversations.refresh();
  }

  bool get _isListening => _chatroomsSub != null;

  @override
  void onInit() {
    super.onInit();

   
    _logger.info('ChatController initialized');
    // React to workspace changes from BoardController
    if (Get.isRegistered<BoardController>()) {
      final bc = Get.find<BoardController>();
      _wsListener = ever<String>(bc.currentWorkspaceId, (wsId) async {
        final newId = (wsId).toString();
        if (newId.isEmpty) return;
        if (newId == (_currentWorkspaceId ?? '')) return;
        _logger.info('Workspace changed to $newId -> restart chat realtime');
        _currentWorkspaceId = newId;
        // Clear message search matches on workspace change
        _messageSearchRoomIds.clear();

        _workspaceData = null; // reset caches bound to workspace
        // Reset assignee initial settle flags for new workspace
        _assigneeInitialSettled = false;
        isAssigneeLoading.value = false;
        if (useVisibleApi.value) {
          // Reset API pagination state on workspace change
          _resetApiPagination();
          // Soft debounce
          await Future.delayed(const Duration(milliseconds: 50));
          await fetchVisibleChatrooms(initial: true, force: true);
        } else {
          await stopRealtime();
          await Future.delayed(const Duration(milliseconds: 50));
          await startRealtime();
        }
      });
    }

    // Debounce search to query mirror collection for message contents
    _searchDebounce = debounce<String>(searchQuery, (q) async {
      await _runMessageSearch(q);
      // Just refresh the list; filteredConversations will use _messageSearchRoomIds
      conversations.refresh();
    }, time: const Duration(milliseconds: 250));
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
        _firestoreService.usersCollection.doc(_currentUserId!),
      );

      if (userData != null &&
          userData['lastActiveWorkspaceId'] != null &&
          userData['lastActiveWorkspaceId'].toString().isNotEmpty) {
        final lastActiveWorkspaceId =
            userData['lastActiveWorkspaceId'] as String;

        // Check if the last active workspace still exists in user's workspaces
        if (userData['workspaces'] != null) {
          final workspaces = userData['workspaces'] as List<dynamic>?;
          if (workspaces != null) {
            final workspaceExists = workspaces.any(
              (ws) =>
                  (ws as Map<String, dynamic>)['id'] == lastActiveWorkspaceId,
            );

            if (workspaceExists) {
              _currentWorkspaceId = lastActiveWorkspaceId;
              _logger.info(
                'Got workspace ID from user document: $_currentWorkspaceId',
              );
              return;
            }
          }
        }
      }

      // Fallback: Get first workspace from user's workspaces array (index 0)
      if (userData != null && userData['workspaces'] != null) {
        final workspaces = userData['workspaces'] as List<dynamic>?;
        if (workspaces != null && workspaces.isNotEmpty) {
          final firstWorkspace = workspaces[0] as Map<String, dynamic>;
          _currentWorkspaceId =
              firstWorkspace['id'] as String? ??
              firstWorkspace['workspaceId'] as String?;
          if (_currentWorkspaceId != null) {
            _logger.info(
              'Got workspace ID from first workspace (index 0): $_currentWorkspaceId',
            );
            getUsersFromChatroom(_currentWorkspaceId);
            return;
          }
        }
      }

      // Last fallback: Get workspace ID from BoardController if available
      if (Get.isRegistered<BoardController>()) {
        final boardController = Get.find<BoardController>();
        _currentWorkspaceId = boardController.currentWorkspaceId.value;
        _logger.info(
          'Got workspace ID from BoardController: $_currentWorkspaceId',
        );
      } else {
        _logger.warning(
          'BoardController not registered and no workspace found',
        );
      }
    } catch (e) {
      _logger.failure('Failed to get workspace ID', e);

      // Last resort: try BoardController
      try {
        if (Get.isRegistered<BoardController>()) {
          final boardController = Get.find<BoardController>();
          _currentWorkspaceId = boardController.currentWorkspaceId.value;
          _logger.info(
            'Fallback: Got workspace ID from BoardController: $_currentWorkspaceId',
          );
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
      _workspaceData = await _firestoreService.getWorkspace(
        _currentWorkspaceId!,
      );
      final ws = _workspaceData ?? {};
      final connections =
          (ws['connections'] ?? ws['companyProfile']?['connections'])
              as Map<String, dynamic>?;

      List<Map<String, dynamic>> asList(dynamic v) {
        if (v is List) return v.cast<Map<String, dynamic>>();
        return const [];
      }

      _wsFacebook = asList(connections?['facebook']);
      _wsInstagram = asList(connections?['instagram']);
      _wsLine = asList(connections?['line']);

      // Load hashtag settings (master list)
      final hs =
          (ws['hashtagSettings'] ?? ws['companyProfile']?['hashtagSettings'])
              as Map<String, dynamic>?;
      final master = asList(hs?['masterList']);
      _hashtagById.clear();
      _hashtagByNameLower.clear();
      for (final item in master) {
        final id = (item['id'] ?? '').toString();
        final name = (item['name'] ?? '').toString();
        if (id.isNotEmpty) _hashtagById[id] = item;
        if (name.isNotEmpty) _hashtagByNameLower[name.toLowerCase()] = item;
      }

      _logger.info(
        'Loaded workspace connections: fb=${_wsFacebook.length}, ig=${_wsInstagram.length}, line=${_wsLine.length}; hashtags=${master.length}',
      );
    } catch (e) {
      _logger.warning('Failed to load workspace connections: $e');
    }
  }

  List<Map<String, String>> _buildHashtagMeta(Map<String, dynamic> chatData) {
    // Prefer hashtagIds for exact match; fallback to names
    final List ids = (chatData['hashtagIds'] is List)
        ? (chatData['hashtagIds'] as List)
        : const [];
    final List namesRaw = (chatData['hashtags'] is List)
        ? (chatData['hashtags'] as List)
        : const [];

    final List<Map<String, String>> out = [];

    if (ids.isNotEmpty) {
      for (final v in ids) {
        final id = v.toString();
        final item = _hashtagById[id];
        if (item != null) {
          final name = (item['name'] ?? id).toString();
          final color = (item['color'] ?? '').toString();
          if (name.isNotEmpty) {
            out.add({
              'name': name.startsWith('#') ? name : '#$name',
              'color': color,
            });
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
      final already = out.any(
        (m) => (m['name'] ?? '').replaceFirst('#', '') == norm,
      );
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
    String platform = (data['source_type'] ?? data['sourceType'] ?? '')
        .toString()
        .toLowerCase();

    Map<String, dynamic>? firstWhereOrNull(
      List<Map<String, dynamic>> list,
      bool Function(Map<String, dynamic>) test,
    ) {
      for (final e in list) {
        if (test(e)) return e;
      }
      return null;
    }

    Map<String, dynamic>? matched;

    final docConnections =
        (data['connections'] ?? data['companyProfile']?['connections'])
            as Map<String, dynamic>?;
    List<Map<String, dynamic>> asList(dynamic v) =>
        (v is List) ? v.cast<Map<String, dynamic>>() : const [];

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
      final hasLineIds =
          (data['channelId']?.toString().isNotEmpty ?? false) ||
          (data['botId']?.toString().isNotEmpty ?? false) ||
          (data['lineUserId']?.toString().isNotEmpty ?? false);

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
      final pageId = (data['pageId'] ?? data['connection']?['pageId'])
          ?.toString();
      if (pageId != null && pageId.isNotEmpty) {
        matched = firstWhereOrNull(
          fbCandidates,
          (e) => (e['pageId']?.toString() ?? '') == pageId,
        );
      }
      matched ??= fbCandidates.length == 1
          ? (fbCandidates.isNotEmpty ? fbCandidates.first : null)
          : null;
      matched ??= fbCandidates.isNotEmpty ? fbCandidates.first : null;
    } else if (platform.contains('instagram') || platform == 'ig') {
      final igUserId = (data['igUserId'] ?? data['connection']?['igUserId'])
          ?.toString();
      final pageId = (data['pageId'] ?? data['connection']?['pageId'])
          ?.toString();
      if (igUserId != null && igUserId.isNotEmpty) {
        matched = firstWhereOrNull(
          igCandidates,
          (e) => (e['igUserId']?.toString() ?? '') == igUserId,
        );
      }
      if (matched == null && pageId != null && pageId.isNotEmpty) {
        matched = firstWhereOrNull(
          igCandidates,
          (e) => (e['pageId']?.toString() ?? '') == pageId,
        );
      }
      matched ??= igCandidates.length == 1
          ? (igCandidates.isNotEmpty ? igCandidates.first : null)
          : null;
      matched ??= igCandidates.isNotEmpty ? igCandidates.first : null;
    } else if (platform.contains('line')) {
      final channelId = (data['channelId'] ?? data['connection']?['channelId'])
          ?.toString();
      final botId = (data['botId'] ?? data['connection']?['botId'])?.toString();
      final userId = (data['lineUserId'] ?? data['connection']?['userId'])
          ?.toString();

      if (channelId != null && channelId.isNotEmpty) {
        matched = firstWhereOrNull(
          lineCandidates,
          (e) => (e['channelId']?.toString() ?? '') == channelId,
        );
      }
      matched ??= (botId != null && botId.isNotEmpty)
          ? firstWhereOrNull(
              lineCandidates,
              (e) => (e['botId']?.toString() ?? '') == botId,
            )
          : null;
      matched ??= (userId != null && userId.isNotEmpty)
          ? firstWhereOrNull(
              lineCandidates,
              (e) => (e['userId']?.toString() ?? '') == userId,
            )
          : null;

      if (matched == null && lineCandidates.isNotEmpty) {
        final title =
            (data['name'] ?? data['customerName'] ?? data['who_name'] ?? '')
                .toString();
        if (title.isNotEmpty) {
          matched = firstWhereOrNull(lineCandidates, (e) {
            final dn = (e['displayName'] ?? e['statusMessage'] ?? '')
                .toString();
            return dn.isNotEmpty && title.contains(dn);
          });
        }
      }

      matched ??= lineCandidates.length == 1
          ? (lineCandidates.isNotEmpty ? lineCandidates.first : null)
          : null;
      matched ??= lineCandidates.isNotEmpty ? lineCandidates.first : null;
    } else {
      final all = <Map<String, dynamic>>[]
        ..addAll(fbCandidates)
        ..addAll(igCandidates)
        ..addAll(lineCandidates);
      if (all.length == 1) {
        matched = all.first;
        final p = (docFacebook.isNotEmpty
            ? 'facebook'
            : docInstagram.isNotEmpty
            ? 'instagram'
            : docLine.isNotEmpty
            ? 'line'
            : (_wsFacebook.isNotEmpty
                  ? 'facebook'
                  : _wsInstagram.isNotEmpty
                  ? 'instagram'
                  : _wsLine.isNotEmpty
                  ? 'line'
                  : 'unknown'));
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
      final effectivePlatform = (data['source_type'] ?? platform)
          .toString()
          .toLowerCase();
      final platformLabel = effectivePlatform.contains('facebook')
          ? 'facebook'
          : effectivePlatform.contains('instagram') || effectivePlatform == 'ig'
          ? 'instagram'
          : effectivePlatform.contains('line')
          ? 'line'
          : 'unknown';

      data['connection'] = {...matched, 'platform': platformLabel};

      final existingPageName = (data['pageName'] ?? '').toString().trim();
      final matchedPageName =
          (matched['pageName'] ??
                  matched['displayName'] ??
                  matched['igUsername'] ??
                  '')
              .toString()
              .trim();
      if (existingPageName.isEmpty && matchedPageName.isNotEmpty) {
        data['pageName'] = matchedPageName;
      }

      data['pageId'] = data['pageId'] ?? matched['pageId'];
      data['igUserId'] = data['igUserId'] ?? matched['igUserId'];
      data['channelId'] = data['channelId'] ?? matched['channelId'];
      data['botId'] = data['botId'] ?? matched['botId'];

      data['avatarUrl'] =
          data['avatarUrl'] ??
          data['avatar'] ??
          matched['pageImageUrl'] ??
          matched['profilePictureUrl'] ??
          matched['pictureUrl'];

      _logger.info(
        'Provider matched for chatroom ${data['id']}: ${data['pageName']} ($platformLabel)',
      );
    } else {
      String candidateName = '';
      Map<String, dynamic>? candidate;
      if (platform.contains('facebook') && fbCandidates.isNotEmpty) {
        candidate = fbCandidates.first;
        candidateName = (candidate['pageName'] ?? '').toString();
      } else if ((platform.contains('instagram') || platform == 'ig') &&
          igCandidates.isNotEmpty) {
        candidate = igCandidates.first;
        candidateName = (candidate['pageName'] ?? candidate['igUsername'] ?? '')
            .toString();
      } else if (platform.contains('line') && lineCandidates.isNotEmpty) {
        candidate = lineCandidates.first;
        candidateName = (candidate['displayName'] ?? '').toString();
      }

      if ((data['pageName'] ?? '').toString().isEmpty &&
          candidateName.isNotEmpty) {
        data['pageName'] = candidateName;
        data['connection'] = {
          ...?candidate,
          'platform': platform.isEmpty ? 'unknown' : platform,
        };
        data['avatarUrl'] =
            data['avatarUrl'] ??
            data['avatar'] ??
            candidate?['pageImageUrl'] ??
            candidate?['profilePictureUrl'] ??
            candidate?['pictureUrl'];
        _logger.info(
          'Provider fallback set for chatroom ${data['id']}: ${data['pageName']} ($platform)',
        );
      } else {
        _logger.warning(
          'No provider matched for chatroom ${data['id']} (platform: ${platform.isEmpty ? 'unknown' : platform})',
        );
      }
    }

    return data;
  }

  // Start realtime listener for chatrooms in current workspace
  Future<void> startRealtime() async {
    if (useVisibleApi.value) {
      // In API mode we don't start Firestore realtime stream
      return;
    }
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
      final col = _firestoreService.getChatroomsCollection(
        _currentWorkspaceId!,
      );
      _chatroomsSub = _firestoreService
          .getDocumentsStream(
            col,
            queryBuilder: (q) => q
                .where('is_deleted', isEqualTo: 'N')
                .orderBy('last_message_info.last_upd', descending: true),
          )
          .listen(
            (qs) async {
              // Determine if permission-based filtering depends on assignee resolution
              final perms = MobilePermissionsService.to;
              final bool requiresAssigneeForFilter =
                  !(perms.isOwner || perms.can('chat:view:all')) &&
                  (perms.can('chat:view:assigned') ||
                      perms.can('chat:view:unassigned'));

              // Preserve previous assignee info to avoid flicker on permission filters
              final Map<String, Map<String, dynamic>> prevById = {
                for (final c in conversations) (c['id']?.toString() ?? ''): c,
              }..removeWhere((k, v) => k.isEmpty);

              final items = qs.docs.map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['id'] = doc.id;

                final lastMessageInfo =
                    data['last_message_info'] as Map<String, dynamic>? ?? {};

                data['name'] =
                    data['name'] ??
                    data['customerName'] ??
                    lastMessageInfo['who_name'] ??
                    'Unknown';
                data['type'] =
                    (data['dialog_type']?.toString().toUpperCase() == 'GROUP')
                    ? 'group'
                    : 'direct';
                data['lastMessage'] =
                    lastMessageInfo['message'] ?? data['message'] ?? '';
                data['avatarUrl'] = data['avatar'];
                data['status'] = data['chatroom_status'] ?? 'active';
                data['unreadCount'] =
                    int.tryParse(data['count']?.toString() ?? '0') ?? 0;
                data['isOnline'] = (data['bot_status'] == 'Y');
                data['sourceType'] = data['source_type'] ?? 'unknown';
                data['isPinned'] = data['chat_pin'] == 'Y';
                data['isNew'] = data['is_new'] == 'Y';

                DateTime? parseDate(dynamic v) {
                  if (v == null) return null;
                  if (v is Timestamp) return v.toDate();
                  if (v is String) {
                    try {
                      return DateTime.parse(v);
                    } catch (_) {}
                  }
                  return null;
                }

                data['lastMessageAt'] = parseDate(lastMessageInfo['last_upd']);
                data['createdAt'] = parseDate(data['created']);

                // Attach provider info if possible
                final enriched = _attachProviderInfo(data);

                // Carry chatroom-level assignees (when no customer linked)
                try {
                  final ids = ((enriched['assignees'] as List?) ?? [])
                      .map((e) => e.toString())
                      .toList();
                  if (ids.isNotEmpty) {
                    enriched['assigneeIds'] = ids;
                    enriched['assigneesKnown'] = true;
                  } else {
                    enriched['assigneesKnown'] = false;
                  }
                } catch (_) {
                  enriched['assigneesKnown'] = false;
                }

                // Preserve previous assignee info if we don't have fresh info yet
                try {
                  final prev = prevById[enriched['id']?.toString() ?? ''];
                  if (prev != null) {
                    // Only overwrite if new info is available; otherwise keep previous
                    if (!(enriched['assigneesKnown'] == true)) {
                      if (prev['assigneeIds'] is List &&
                          (prev['assigneeIds'] as List).isNotEmpty) {
                        enriched['assigneeIds'] = (prev['assigneeIds'] as List)
                            .map((e) => e.toString())
                            .toList();
                      }
                      if (prev['assigneeNames'] is List &&
                          (prev['assigneeNames'] as List).isNotEmpty) {
                        enriched['assigneeNames'] =
                            (prev['assigneeNames'] as List)
                                .map((e) => e.toString())
                                .toList();
                      }
                      if (prev['assigneesKnown'] == true) {
                        enriched['assigneesKnown'] = true;
                      }
                    }
                  }
                } catch (_) {}

                // Attach hashtag meta (name + color from master list)
                try {
                  enriched['hashtagMeta'] = _buildHashtagMeta(enriched);
                } catch (_) {}
                return enriched;
              }).toList();

              // Hide items marked as hidden unless they have unread > 0 (new messages)
              final filtered = <Map<String, dynamic>>[];
              for (final it in items) {
                final hiddenRaw = it['is_hidden'];
                final hidden = hiddenRaw == true || hiddenRaw == 'Y';
                final unread = (it['unreadCount'] as int?) ?? 0;
                if (!hidden || unread > 0) {
                  filtered.add(it);
                }
                // Auto-unhide when a hidden chat gets new messages
                if (hidden && unread > 0) {
                  try {
                    final id = it['id']?.toString();
                    if (id != null &&
                        id.isNotEmpty &&
                        _currentWorkspaceId != null) {
                      _firestoreService
                          .getChatroomsCollection(_currentWorkspaceId!)
                          .doc(id)
                          .set({'is_hidden': false}, SetOptions(merge: true));
                    }
                  } catch (_) {}
                }
              }

              // Preserve list identity to reduce widget rebuild/flicker
              conversations.assignAll(filtered);
              isLoading.value = false;
              error.value = '';

              // If first entry depends on assignee filtering, show loading until we resolve assignees once
              if (requiresAssigneeForFilter && !_assigneeInitialSettled) {
                isAssigneeLoading.value = true;
                try {
                  await _augmentAssignees(filtered);
                } finally {
                  _assigneeInitialSettled = true;
                  isAssigneeLoading.value = false;
                }
                // Also kick off customer hashtags after assignees
                // (non-blocking for UI)
                // ignore: unawaited_futures
                _augmentCustomerHashtags(filtered);
              } else {
                // Asynchronously enrich with assignee display names
                // ignore: unawaited_futures
                _augmentAssignees(filtered);
                // Asynchronously enrich with customer hashtags (merge with chatroom hashtags)
                // ignore: unawaited_futures
                _augmentCustomerHashtags(filtered);
              }
            },
            onError: (e) {
              isLoading.value = false;
              error.value = 'Failed to get realtime chatrooms: $e';
              isAssigneeLoading.value = false;
            },
          );
    } catch (e) {
      isLoading.value = false;
      error.value = 'Failed to start realtime: $e';
      isAssigneeLoading.value = false;
    }
  }

  Future<void> stopRealtime() async {
    await _chatroomsSub?.cancel();
    _chatroomsSub = null;
  }

  Future<void> loadConversations() async {
    if (useVisibleApi.value) {
      await fetchVisibleChatrooms(initial: true);
    } else {
      await startRealtime();
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setFilter(String filter) {
    activeFilter.value = filter;
    // No server reload; filter is applied client-side on conversations stream
  }

  void refresh() {
    if (useVisibleApi.value) {
      fetchVisibleChatrooms(initial: true, force: true);
    } else {
      // Avoid restarting stream to prevent UI flicker
      _logger.info('ChatController.refresh: soft refresh (no restart)');
      conversations.refresh();
    }
  }

  List<Map<String, dynamic>> get filteredConversations {
    final perms = MobilePermissionsService.to;
    final bool isOwnerOrAll = perms.isOwner || perms.can('chat:view:all');
    final bool canAssigned = perms.can('chat:view:assigned');
    final bool canUnassigned = perms.can('chat:view:unassigned');
    final String uid = _currentUserId ?? '';

    var filtered = conversations.where((conv) {
      try {
        final hiddenRaw = conv['is_hidden'];
        final hidden =
            hiddenRaw == true ||
            hiddenRaw == 'Y' ||
            (hiddenRaw is String && hiddenRaw.toLowerCase() == 'true') ||
            hiddenRaw == 1;
        final unread =
            (conv['unreadCount'] as int?) ??
            int.tryParse(conv['count']?.toString() ?? '0') ??
            0;
        if (hidden && unread <= 0) return false;
      } catch (_) {}

      // Permission gating
      if (!isOwnerOrAll) {
        final ids = (conv['assigneeIds'] is List)
            ? (conv['assigneeIds'] as List).map((e) => e.toString()).toSet()
            : <String>{};
        final bool assigneesKnown = (conv['assigneesKnown'] == true);
        // If assignees are not known yet, optimistically include the item so the list doesn't disappear
        if (!assigneesKnown) {
          // Only include if the user has any chat view permission (assigned or unassigned)
          if (canAssigned || canUnassigned) {
            return true;
          } else {
            return false;
          }
        }
        final bool assignedToMe =
            canAssigned && uid.isNotEmpty && ids.contains(uid);
        final bool unassigned = canUnassigned && ids.isEmpty;
        if (!(assignedToMe || unassigned)) return false;
      }

      // Ensure hashtagMeta exists so UI can render tags even after search/first paint
      try {
        final rawMeta = conv['hashtagMeta'];
        final isEmptyMeta = rawMeta is! List || rawMeta.isEmpty;
        if (isEmptyMeta) {
          conv['hashtagMeta'] = _buildHashtagMeta(conv);
        }
      } catch (_) {}

      // Search filter (room meta fields + message mirror match)
      if (searchQuery.value.isNotEmpty) {
        final rawQ = searchQuery.value.trim();
        final query = rawQ.toLowerCase();
        String normHash(String s) => s.replaceAll('#', '').toLowerCase();
        final queryNoHash = normHash(rawQ);

        bool contains(String? s) => (s ?? '').toLowerCase().contains(query);
        bool containsNoHash(String? s) =>
            normHash(s ?? '').contains(queryNoHash);

        final fields = <String?>[
          conv['name']?.toString(),
          conv['customerName']?.toString(),
          conv['lastMessage']?.toString() ?? conv['last_message']?.toString(),
          conv['who_name']?.toString(),
          conv['displayName']?.toString(),
          conv['pageName']?.toString(),
          conv['company']?.toString(),
          conv['companyName']?.toString(),
          conv['company_name']?.toString(),
          conv['customerCompany']?.toString(),
        ];
        final rawTags = conv['hashtags'];
        if (rawTags is List) {
          for (final t in rawTags) {
            final s = t.toString();
            fields.add(s);
            fields.add(s.startsWith('#') ? s.substring(1) : s);
          }
        }
        final meta = conv['hashtagMeta'];
        if (meta is List) {
          for (final m in meta) {
            if (m is Map) {
              final n = (m['name'] ?? m['title'] ?? '').toString();
              if (n.isNotEmpty) {
                fields.add(n);
                fields.add(n.startsWith('#') ? n.substring(1) : n);
              }
            }
          }
        }
        final assignees = conv['assigneeNames'];
        if (assignees is List) {
          for (final a in assignees) {
            fields.add(a.toString());
          }
        }
        bool matched = fields.any((s) => contains(s) || containsNoHash(s));
        if (!matched) {
          final rid = (conv['id'] ?? conv['chatroomId'] ?? conv['chat_id'])
              ?.toString();
          if (rid != null && rid.isNotEmpty) {
            matched = _messageSearchRoomIds.contains(rid);
          }
        }
        if (!matched) return false;
      }

      // Platform filters
      if (platformFilters.isNotEmpty) {
        String platform = '';
        try {
          final conn = conv['connection'];
          if (conn is Map &&
              (conn['platform']?.toString().isNotEmpty ?? false)) {
            platform = conn['platform'].toString().toLowerCase();
          } else {
            platform = (conv['source_type'] ?? conv['sourceType'] ?? '')
                .toString()
                .toLowerCase();
          }
        } catch (_) {}
        if (platform.isEmpty &&
            (conv['pageId']?.toString().isNotEmpty ?? false))
          platform = 'facebook';
        if (platform.isEmpty &&
            (conv['igUserId']?.toString().isNotEmpty ?? false))
          platform = 'instagram';
        if (platform.isEmpty &&
            ((conv['channelId'] ?? conv['botId'])?.toString().isNotEmpty ??
                false))
          platform = 'line';
        if (!platformFilters.contains(platform)) return false;
      }

      // Status filter
      final sf = statusFilter.value;
      if (sf.isNotEmpty) {
        final isNew = (conv['is_new'] ?? conv['isNew']) == 'Y';
        final status = (conv['chatroom_status'] ?? '').toString().toUpperCase();
        bool ok;
        switch (sf) {
          case 'NEW':
            ok = isNew;
            break;
          case 'DONE':
            ok = status == 'DONE';
            break;
          case 'IN_PROGRESS':
            ok = status == 'IN_PROGRESS' || status == 'ACTIVE';
            break;
          default:
            ok = true;
        }
        if (!ok) return false;
      }

      // Hashtag filter (IDs)
      if (hashtagIdFilters.isNotEmpty) {
        final ids = (conv['hashtagIds'] is List)
            ? (conv['hashtagIds'] as List).map((e) => e.toString()).toSet()
            : <String>{};
        bool ok = ids.intersection(hashtagIdFilters.toSet()).isNotEmpty;
        // Fallback: match by names via hashtagMeta if no ids present
        if (!ok && (conv['hashtagMeta'] is List)) {
          final meta = (conv['hashtagMeta'] as List)
              .whereType<Map>()
              .map(
                (m) => (m['name'] ?? '')
                    .toString()
                    .replaceFirst('#', '')
                    .toLowerCase(),
              )
              .toSet();
          final selectedNames = hashtagIdFilters
              .map((id) => _hashtagById[id]?['name']?.toString().toLowerCase())
              .whereType<String>()
              .toSet();
          if (selectedNames.isNotEmpty) {
            ok = meta.intersection(selectedNames).isNotEmpty;
          }
        }
        if (!ok) return false;
      }

      // Sales filter (single uid)
      final sid = salesIdFilter.value;
      if (sid.isNotEmpty) {
        final assigneeIds = (conv['assigneeIds'] is List)
            ? (conv['assigneeIds'] as List).map((e) => e.toString()).toSet()
            : <String>{};
        if (!assigneeIds.contains(sid)) return false;
      }

      // Customer filter
      final cidFilter = customerIdFilter.value;
      if (cidFilter.isNotEmpty) {
        final cid =
            (conv['customerId'] ??
                    conv['customer_id'] ??
                    conv['customer']?['id'])
                ?.toString() ??
            '';
        if (cid != cidFilter) return false;
      }

      // Legacy activeFilter: keep any additional filters if used
      switch (activeFilter.value) {
        case 'unread':
          final unreadCount =
              int.tryParse(conv['count']?.toString() ?? '0') ?? 0;
          return unreadCount > 0;
        case 'assigned':
          return conv['chatroom_status'] == 'assigned';
        case 'inProgress':
          return conv['chatroom_status'] == 'in_progress' ||
              conv['chatroom_status'] == 'active';
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
      // Pinned first
      final aPinned =
          (a['isPinned'] == true) ||
          ((a['chat_pin'] ?? '').toString().toUpperCase() == 'Y');
      final bPinned =
          (b['isPinned'] == true) ||
          ((b['chat_pin'] ?? '').toString().toUpperCase() == 'Y');
      if (aPinned != bPinned) {
        return bPinned ? 1 : -1; // true first
      }

      // Then by last message time (newest first)
      DateTime _asDt(dynamic v) {
        if (v is DateTime) return v;
        if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
        if (v is String) {
          final d = DateTime.tryParse(v);
          if (d != null) return d;
        }
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      final aTime = _asDt(
        a['lastMessageAt'] ??
            a['last_message_info']?['last_upd'] ??
            a['updatedAt'],
      );
      final bTime = _asDt(
        b['lastMessageAt'] ??
            b['last_message_info']?['last_upd'] ??
            b['updatedAt'],
      );
      final timeCmp = bTime.compareTo(aTime);
      if (timeCmp != 0) return timeCmp;

      // Fallback: pinned equal + time equal -> by name to keep stable
      final aName = (a['name'] ?? '').toString();
      final bName = (b['name'] ?? '').toString();
      return aName.compareTo(bName);
    });

    return filtered;
  }

  // Run search against mirror collection to find room ids that contain the text
  Future<void> _runMessageSearch(String q) async {
    final query = q.trim();
    if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) {
      await _getCurrentWorkspaceId();
    }
    if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) return;
    if (query.isEmpty) {
      _messageSearchRoomIds.clear();
      return;
    }
    try {
      final svc = _firestoreService;
      final ids = await svc.searchChatMessages(
        workspaceId: _currentWorkspaceId!,
        query: query,
        limit: 50,
      );
      _messageSearchRoomIds
        ..clear()
        ..addAll(ids);
    } catch (e) {
      // ignore errors, keep previous set
      _logger.warning('message search failed: $e');
    }
  }

  Future<void> markAsRead(String conversationId) async {
    if (_currentUserId == null) return;

    try {
      await _firestoreService.markConversationAsRead(
        conversationId,
        _currentUserId!,
      );

      // Update local state
      final index = conversations.indexWhere(
        (conv) => conv['id'] == conversationId,
      );
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
    _wsListener?.dispose();
    _searchDebounce?.dispose();
    stopRealtime();
    super.onClose();
  }

  // ===== Visible Chatrooms API integration =====
  Dio _dio = Dio();

  void _resetApiPagination() {
    _nextCursor = null;
    _apiHasMore = true;
    _apiWorkspaceBound = _currentWorkspaceId;
  }

  Future<void> fetchVisibleChatrooms({
    bool initial = false,
    bool force = false,
    int limit = 1000,
  }) async {
    if (!useVisibleApi.value) return;
    if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) {
      await _getCurrentWorkspaceId();
      if (_currentWorkspaceId == null || _currentWorkspaceId!.isEmpty) {
        error.value = 'No workspace selected';
        return;
      }
    }

    // Workspace changed externally without listener (safety)
    if (_apiWorkspaceBound != _currentWorkspaceId) {
      _resetApiPagination();
    }

    if (initial) {
      if (isApiLoading.value) return; // prevent double initial
      isApiLoading.value = true;
      error.value = '';
      // When forcing refresh, reset pagination
      if (force) {
        _resetApiPagination();
      }
    } else {
      // Load more path
      if (!_apiHasMore) return; // nothing more
      if (isApiLoadingMore.value) return; // already loading
      final now = DateTime.now();
      if (now.difference(_lastLoadMoreAt).inMilliseconds < 600)
        return; // debounce
      _lastLoadMoreAt = now;
      isApiLoadingMore.value = true;
    }

    try {
      final auth = Get.find<FirebaseAuthService>();
      final token = await MobileApiAuth.getIdTokenOrThrow(auth);
      final params = {
        'workspaceId': _currentWorkspaceId,
        'limit': limit.toString(),
        if (_nextCursor != null && _nextCursor!.isNotEmpty)
          'after': _nextCursor,
      };
      // Apply status filter if set (mapping to API spec: NEW, INPROGRESS, DONE)
      final sf = statusFilter.value;
      if (sf.isNotEmpty) {
        // Convert internal IN_PROGRESS to INPROGRESS per API spec
        if (sf == 'IN_PROGRESS') {
          params['status'] = 'INPROGRESS';
        } else {
          params['status'] = sf;
        }
      }

      final resp = await _dio.get(
        '${MobileApiConfig.baseUrl}/api/mobile/chatrooms/visible',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        queryParameters: params,
      );

      final data = resp.data is Map<String, dynamic>
          ? resp.data as Map<String, dynamic>
          : (resp.data is Map
                ? Map<String, dynamic>.from(resp.data as Map)
                : <String, dynamic>{});
      final success = data['success'] == true;
      if (!success) {
        throw Exception(data['message'] ?? 'Unknown API error');
      }
      final List roomsRaw = (data['rooms'] as List?) ?? const [];
      final nextCursor = data['nextCursor']?.toString();

      // Transform rooms to match internal shape used by UI (reuse logic similar to realtime path)
      List<Map<String, dynamic>> transformed = roomsRaw.map((r) {
        final m = r is Map ? Map<String, dynamic>.from(r) : <String, dynamic>{};
        // Ensure id present
        m['id'] = m['id'] ?? m['chatroomId'] ?? m['chat_id'] ?? m['cid'];
        final lastInfo =
            (m['last_message_info'] as Map?)?.cast<String, dynamic>() ?? {};
        m['name'] =
            m['name'] ?? m['customerName'] ?? lastInfo['who_name'] ?? 'Unknown';
        m['type'] = (m['dialog_type']?.toString().toUpperCase() == 'GROUP')
            ? 'group'
            : 'direct';
        m['lastMessage'] = lastInfo['message'] ?? m['message'] ?? '';
        m['avatarUrl'] = m['avatarUrl'] ?? m['avatar'];
        m['status'] = m['chatroom_status'] ?? m['status'] ?? 'active';
        m['unreadCount'] =
            int.tryParse(m['count']?.toString() ?? '0') ??
            (m['unread'] is int ? m['unread'] as int : 0);
        m['isOnline'] = (m['bot_status'] == 'Y');
        m['sourceType'] = m['source_type'] ?? m['sourceType'] ?? 'unknown';
        m['isPinned'] = m['chat_pin'] == 'Y' || m['isPinned'] == true;
        m['isNew'] = m['is_new'] == 'Y' || m['isNew'] == true;

        DateTime? parseDate(dynamic v) {
          if (v == null) return null;
          if (v is Timestamp) return v.toDate();
          if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
          if (v is String) {
            try {
              return DateTime.parse(v);
            } catch (_) {}
          }
          return null;
        }

        m['lastMessageAt'] = parseDate(
          lastInfo['msg_timestamp'] ?? lastInfo['last_upd'],
        );
        m['createdAt'] = parseDate(m['created']);

        // Permission gating already enforced by API: treat as known
        try {
          final aIds = ((m['assignees'] as List?) ?? [])
              .map((e) => e.toString())
              .toList();
          if (aIds.isNotEmpty) {
            m['assigneeIds'] = aIds;
            m['assigneesKnown'] = true;
          } else {
            m['assigneesKnown'] =
                true; // even if empty, it's authoritative result
            m['assigneeIds'] = const <String>[];
          }
        } catch (_) {
          m['assigneeIds'] = const <String>[];
          m['assigneesKnown'] = true;
        }

        // Build hashtag meta
        try {
          m['hashtagMeta'] = _buildHashtagMeta(m);
        } catch (_) {}

        // Attempt provider attach for icons
        try {
          _attachProviderInfo(m);
        } catch (_) {}

        return m;
      }).toList();

      if (initial) {
        conversations.assignAll(transformed);
      } else {
        // Append avoiding duplicates
        final existingIds = conversations
            .map((e) => (e['id'] ?? '').toString())
            .toSet();
        for (final m in transformed) {
          final id = (m['id'] ?? '').toString();
          if (id.isEmpty) continue;
          if (existingIds.contains(id)) {
            // update existing (merge some fields)
            final idx = conversations.indexWhere(
              (c) => (c['id'] ?? '').toString() == id,
            );
            if (idx >= 0) {
              conversations[idx].addAll(m);
            }
          } else {
            conversations.add(m);
          }
        }
      }

      _nextCursor = nextCursor;
      _apiHasMore = nextCursor != null && nextCursor.isNotEmpty;
      if (initial) {
        isApiLoading.value = false;
      } else {
        isApiLoadingMore.value = false;
      }

      // Enrich assignees / hashtags asynchronously (non-blocking)
      // ignore: unawaited_futures
      _augmentAssignees(conversations);
      // ignore: unawaited_futures
      _augmentCustomerHashtags(conversations);
    } catch (e) {
      if (initial) {
        isApiLoading.value = false;
      } else {
        isApiLoadingMore.value = false;
      }
      error.value = 'Failed to load chatrooms: $e';
    }
  }

  bool get canLoadMoreVisible =>
      useVisibleApi.value &&
      _apiHasMore &&
      !isApiLoadingMore.value &&
      !isApiLoading.value;

  Future<void> loadMoreVisible() async {
    if (!canLoadMoreVisible) return;
    await fetchVisibleChatrooms(initial: false);
  }

  // Provide public API to force refresh
  Future<void> refreshVisible() async {
    if (!useVisibleApi.value) return;
    await fetchVisibleChatrooms(initial: true, force: true);
  }

  Future<void> _augmentAssignees(List<Map<String, dynamic>> items) async {
    final wsId = _currentWorkspaceId;
    if (wsId == null || wsId.isEmpty) return;

    for (final item in items) {
      // Resolve customerId from various fields
      final cid =
          (item['customerId'] ?? item['customer_id'] ?? item['customer']?['id'])
              ?.toString();

      if (cid != null && cid.isNotEmpty) {
        List<String>? names = _assigneesCache[cid];
        List<String> uids = const [];
        if (names == null) {
          try {
            final cSnap = await FirestoreService.to
                .getWorkspaceCustomersCollection(wsId)
                .doc(cid)
                .get();
            final cData = cSnap.data() ?? {};
            uids = ((cData['assignees'] as List?) ?? [])
                .map((e) => e.toString())
                .toList();
            if (uids.isEmpty) {
              names = const [];
            } else {
              final map = await UserCacheService.to.getDisplayNames(uids);
              names = uids.map((id) => (map[id] ?? id)).toList();
            }
            _assigneesCache[cid] = names;
            _assigneeUidsCache[cid] = uids; // cache UIDs too
          } catch (_) {
            names = const [];
            uids = const [];
          }
        } else {
          // Use cached UIDs if available; fallback to existing item/conversation IDs to avoid wiping
          uids =
              _assigneeUidsCache[cid] ??
              () {
                try {
                  final existing = conversations.firstWhere(
                    (c) =>
                        (c['id']?.toString() ?? '') ==
                        (item['id']?.toString() ?? ''),
                    orElse: () => const {} as Map<String, dynamic>,
                  );
                  final raw = existing['assigneeIds'];
                  if (raw is List) {
                    return raw.map((e) => e.toString()).toList();
                  }
                } catch (_) {}
                return const <String>[];
              }();
        }

        // Update the item in conversations list
        final idx = conversations.indexWhere(
          (c) => (c['id']?.toString() ?? '') == (item['id']?.toString() ?? ''),
        );
        if (idx >= 0) {
          conversations[idx]['assigneeNames'] = names;
          // Always set ids (can be empty) and known flag
          conversations[idx]['assigneeIds'] = uids;
          conversations[idx]['assigneesKnown'] = true;
          conversations.refresh();
        }
      } else {
        // No customer linked: use chatroom-level assigneeIds
        try {
          List<String> uids = const [];
          final raw = item['assigneeIds'];
          if (raw is List) {
            uids = raw
                .map((e) => e.toString())
                .where((s) => s.trim().isNotEmpty)
                .toList();
          } else {
            // Fallback: read from chatroom doc
            final id = (item['id'] ?? '').toString();
            if (id.isNotEmpty) {
              // Avoid read here; rely on stream data carrying assignees in most cases
              // If really needed, this could be toggled by a flag, but we skip extra get() to reduce reads.
              uids = const [];
            }
          }
          final names = (uids.isEmpty)
              ? const <String>[]
              : (await UserCacheService.to.getDisplayNames(uids)).entries
                    .where((e) => uids.contains(e.key))
                    .map((e) => e.value)
                    .toList();
          final idx = conversations.indexWhere(
            (c) =>
                (c['id']?.toString() ?? '') == (item['id']?.toString() ?? ''),
          );
          if (idx >= 0) {
            conversations[idx]['assigneeNames'] = names;
            conversations[idx]['assigneeIds'] = uids;
            conversations[idx]['assigneesKnown'] = true;
            conversations.refresh();
          }
        } catch (_) {
          // ignore errors for UX
        }
      }
    }
  }

  // Fetch and merge customer-level hashtags into conversations (two-way view)
  Future<void> _augmentCustomerHashtags(
    List<Map<String, dynamic>> items,
  ) async {
    final wsId = _currentWorkspaceId;
    if (wsId == null || wsId.isEmpty) return;

    for (final item in items) {
      final chatId = (item['id'] ?? '').toString();
      if (chatId.isEmpty) continue;
      final cid =
          (item['customerId'] ?? item['customer_id'] ?? item['customer']?['id'])
              ?.toString();
      if (cid == null || cid.isEmpty) continue;

      List<String>? ids = _customerHashtagIdsCache[cid];
      List<Map<String, String>>? meta = _customerHashtagMetaCache[cid];

      if (ids == null || meta == null) {
        try {
          final cSnap = await FirestoreService.to
              .getWorkspaceCustomersCollection(wsId)
              .doc(cid)
              .get();
          final cData = cSnap.data() ?? {};
          final raw = (cData['hashtags'] as List?) ?? const [];
          final tmpIds = <String>[];
          final tmpMeta = <Map<String, String>>[];
          for (final it in raw) {
            if (it is String) {
              final id = it.trim();
              if (id.isEmpty) continue;
              tmpIds.add(id);
              final master = _hashtagById[id];
              final name = ((master?['name'] ?? id).toString());
              final color = (master?['color'] ?? '').toString();
              tmpMeta.add({
                'name': name.startsWith('#') ? name : '#$name',
                if (color.isNotEmpty) 'color': color,
              });
            } else if (it is Map) {
              final id = (it['id'] ?? it['text'] ?? '').toString().trim();
              if (id.isEmpty) continue;
              tmpIds.add(id);
              final rawName = (it['text'] ?? it['name'] ?? id).toString();
              final color = (it['color'] ?? '').toString();
              tmpMeta.add({
                'name': rawName.startsWith('#') ? rawName : '#$rawName',
                if (color.isNotEmpty) 'color': color,
              });
            }
          }
          ids = tmpIds;
          meta = tmpMeta;
          _customerHashtagIdsCache[cid] = ids;
          _customerHashtagMetaCache[cid] = meta;
        } catch (_) {
          ids = const [];
          meta = const [];
        }
      }

      // Merge into conversation: union ids and union meta by normalized name
      try {
        final idx = conversations.indexWhere(
          (c) => (c['id']?.toString() ?? '') == chatId,
        );
        if (idx < 0) continue;
        final currentIds = (conversations[idx]['hashtagIds'] is List)
            ? (conversations[idx]['hashtagIds'] as List)
                  .map((e) => e.toString())
                  .toSet()
            : <String>{};
        final List<String> idsToAdd = ids;
        final mergedIds = <String>{}
          ..addAll(currentIds)
          ..addAll(idsToAdd);
        conversations[idx]['hashtagIds'] = mergedIds.toList();
        List<Map<String, String>> currentMeta = const [];
        try {
          currentMeta =
              (conversations[idx]['hashtagMeta'] as List?)
                  ?.whereType<Map>()
                  .map(
                    (m) => {
                      'name': (m['name'] ?? m['title'] ?? '').toString(),
                      if ((m['color']?.toString().isNotEmpty ?? false))
                        'color': m['color'].toString(),
                    },
                  )
                  .toList() ??
              const [];
        } catch (_) {}

        String norm(String s) => s.replaceFirst('#', '').toLowerCase();
        final namesSet = currentMeta.map((m) => norm(m['name'] ?? '')).toSet();
        final List<Map<String, String>> metaToAdd = meta;
        final toAdd = <Map<String, String>>[];
        for (final m in metaToAdd) {
          final n = norm(m['name'] ?? '');
          if (n.isEmpty || namesSet.contains(n)) continue;
          toAdd.add(m);
        }
        conversations[idx]['hashtagMeta'] = [...currentMeta, ...toAdd];
        conversations.refresh();
      } catch (_) {}
    }
  }

  // Optimistically add an assignee to a conversation and refresh UI
  void addAssigneeLocal(String chatId, String uid, String displayName) {
    final idx = conversations.indexWhere(
      (c) => (c['id']?.toString() ?? '') == chatId,
    );
    if (idx < 0) return;
    final existingIds = (conversations[idx]['assigneeIds'] is List)
        ? (conversations[idx]['assigneeIds'] as List)
              .map((e) => e.toString())
              .toSet()
        : <String>{};
    final existingNames = (conversations[idx]['assigneeNames'] is List)
        ? (conversations[idx]['assigneeNames'] as List)
              .map((e) => e.toString())
              .toSet()
        : <String>{};
    existingIds.add(uid);
    if (displayName.trim().isNotEmpty) existingNames.add(displayName.trim());
    conversations[idx]['assigneeIds'] = existingIds.toList();
    conversations[idx]['assigneeNames'] = existingNames.toList();
    conversations.refresh();
  }

  // Optimistically update hashtags of a conversation and refresh UI
  void updateHashtagsLocal(
    String chatId,
    List<String> ids,
    List<String> names,
  ) {
    final idx = conversations.indexWhere(
      (c) => (c['id']?.toString() ?? '') == chatId,
    );
    if (idx < 0) return;
    // Normalize names to include '#'
    final normNames = names
        .map((n) => n.toString().trim())
        .where((n) => n.isNotEmpty)
        .map((n) => n.startsWith('#') ? n : '#$n')
        .toList();

    conversations[idx]['hashtagIds'] = ids.toList();
    conversations[idx]['hashtags'] = normNames.toList();

    // Rebuild meta using master list when possible
    final temp = {'hashtagIds': ids, 'hashtags': normNames};
    final meta = _buildHashtagMeta(temp);

    // If customer-level meta cached exists, merge it too
    final cid =
        (conversations[idx]['customerId'] ??
                conversations[idx]['customer_id'] ??
                conversations[idx]['customer']?['id'])
            ?.toString();
    List<Map<String, String>> mergedMeta = meta;
    if (cid != null && cid.isNotEmpty) {
      final cMeta = _customerHashtagMetaCache[cid];
      if (cMeta != null && cMeta.isNotEmpty) {
        String norm(String s) => s.replaceFirst('#', '').toLowerCase();
        final namesSet = mergedMeta.map((m) => norm(m['name'] ?? '')).toSet();
        for (final m in cMeta) {
          final n = norm(m['name'] ?? '');
          if (n.isEmpty || namesSet.contains(n)) continue;
          mergedMeta.add(m);
        }
      }
    }

    conversations[idx]['hashtagMeta'] = mergedMeta;
    conversations.refresh();
  }
}
