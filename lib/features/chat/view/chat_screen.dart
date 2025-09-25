import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../data/services/chat_service.dart';
import '../widgets/chat_header_line.dart';
import '../widgets/chat_status_button.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/show_bottom_modal.dart';
import '../../../data/services/firestore_service.dart';
import '../widgets/user_picker_sheet.dart';
import '../../../core/widgets/top_snack.dart';
import '../../../core/widgets/permission_guard.dart';
import '../../../core/services/logger_service.dart';
import 'package:intl/intl.dart';
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> conversationData;
  final String workspaceId;
  // Optional: if provided, the in-chat search UI will open and search for this term on load
  final String? initialSearchTerm;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.conversationData,
    required this.workspaceId,
    this.initialSearchTerm,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // final ScrollController _scrollController = ScrollController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final ChatService _chatService = ChatService.to;
  final LoggerService _logger = LoggerService.to;
  bool _isLoading = false;
  String? _error;
  // Use reversed list to show newest at bottom
  final bool _isReversed = true;
  // Search state
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // Match navigation state
  List<String> _matchedIds = [];
  int _focusedMatchIndex = 0;
  String _lastFocusedQuery = '';
  // Cache last rendered match count to avoid redundant refreshes
  int _lastRenderedMatchCount = -1;
  // Visual index tracking for alignment logic
  final Map<String, int> _listIndexById = {}; // docId -> list index
  final Map<String, int> _altIdIndex = {}; // alternative internal ids -> list index
  int _lastItemCount = 0;
  // Cache latest messages to allow instant recompute on user typing
  List<QueryDocumentSnapshot> _currentMessages = const [];

  // Quote reply state
  String? _replyPreviewText; // existing
  String? _replyToMessageId;
  String? _replyToMessageType;
  String? _replyOriginalSenderName; // NEW: sender name of original message
  String? _focusedReplyMessageId; // currently highlighted original
  Timer? _replyFocusClearTimer;
  String? _replyQuoteToken; // NEW: quoteToken for LINE replies

  // Track previous message count to avoid redundant auto-scrolls that cause flicker
  int _prevMessageCount = -1;
  // Track if user is already near bottom; gate auto-scroll to reduce jumps
  bool _nearBottom = true;

  // dynamic fetch limit
  int _messageLimit = 100;
  final int _maxMessageLimit = 300;
  String? _pendingFocusMessageId; // message id waiting to focus after loading more

  // === New: upward pagination state ===
  bool _isLoadingMore = false; // loading older messages when scrolled up
  final int _loadMoreStep = 100; // how many to add per page
  DateTime? _lastLoadMoreAt; // throttle timestamp
  int _lastRequestedLimit = 500; // avoid duplicate requests
  String? _anchorMessageId; // preserve scroll position when loading more
  Timer? _loadMoreGuardTimer; // timeout to release loading state
  int _lastLoadAttemptItemCount = 0;

  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;
  String get _chatroomName => _chatroomNameState ?? (widget.conversationData['name'] ?? 'chat_default_name'.tr);
  String? get _avatarUrl => widget.conversationData['avatar'];
  String get _sourceType => widget.conversationData['source_type'] ?? 'unknown';

  String? _chatroomNameState; // refreshed name after reset

  // Cache salesperson names (assignees) for header display
  List<String>? _assigneeNames;
  // Track last seen chatroom-level assignee UIDs to avoid redundant lookups
  List<String> _lastChatAssigneeUids = const [];
  // Stream sub for customer updates
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _customerSub;
  // Simple cache for userId -> displayName
  final Map<String, String> _userNameCache = {};
  // Track currently subscribed customerId to allow dynamic re-subscription
  String? _subscribedCustomerId;
  // Cached current user profile from Firestore
  Map<String, dynamic>? _currentUserProfile;

  Future<void> _ensureCurrentUserProfile() async {
    if (_currentUserProfile != null) return;
    try {
      final uid = _currentUserId;
      final snap = await FirestoreService.to.usersCollection.doc(uid).get();
      _currentUserProfile = snap.data() ?? {};
    } catch (_) {
      _currentUserProfile = {};
    }
  }

  Map<String, dynamic> _buildSenderPayload() {
    final p = _currentUserProfile;
    final authUser = FirebaseAuth.instance.currentUser;
    final name = (p?['displayName'] ?? p?['name'] ?? authUser?.displayName ?? 'Mobile User').toString();
    final avatar = (p?['photoURL'] ?? p?['photoUrl'] ?? p?['avatar'] ?? authUser?.photoURL);
    return {
      'id': _currentUserId,
      'name': name,
      'avatar': avatar,
    };
  }

  


  Future<void> _openAddSales() async {
    try {
      // Get latest chatroom snapshot to know current customer linkage
      final chatSnap = await _chatService
          .getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .get();
      final chatData = (chatSnap.data() ?? <String, dynamic>{});
      final customerId = (chatData['customerId'] ?? chatData['customer_id'] ?? chatData['customer']?['id'])?.toString();

      final pickedUid = await showModalBottomSheet<String>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          final h = MediaQuery.of(ctx).size.height;
          return SizedBox(
            height: h * 0.9,
            child: UserPickerSheet(workspaceId: widget.workspaceId),
          );
        },
      );

      if (pickedUid == null || pickedUid.isEmpty) return;

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('chat_confirm_assign_sale'.tr),
          content: Text('chat_confirm_assign_sale_message'.tr),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('confirm'.tr)),
          ],
        ),
      );
      if (ok != true) return;

      // Persist to customer if linked, otherwise to chatroom-level assignees
      if (customerId != null && customerId.isNotEmpty) {
        await FirestoreService.to
            .getWorkspaceCustomersCollection(widget.workspaceId)
            .doc(customerId)
            .set({'assignees': FieldValue.arrayUnion([pickedUid])}, SetOptions(merge: true));
      } else {
        await _chatService
            .getChatroomsCollection(widget.workspaceId)
            .doc(widget.conversationId)
            .set({'assignees': FieldValue.arrayUnion([pickedUid])}, SetOptions(merge: true));
      }

      // Optimistically resolve and update header names; live listeners will reconcile
      try {
        final u = await FirestoreService.to.usersCollection.doc(pickedUid).get();
        final m = u.data() ?? {};
        final dn = (m['displayName'] ?? m['name'] ?? '').toString();
        if (dn.isNotEmpty) {
          _userNameCache[pickedUid] = dn;
          if (mounted) {
            setState(() {
              final existing = _assigneeNames ?? const <String>[];
              final next = <String>{...existing, dn}.toList();
              _assigneeNames = next;
            });
          }
        }
      } catch (_) {}

      if (mounted) {
        _showSuccessSnackBar('chat_assign_sale_success'.tr);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('chat_assign_sale_failed'.tr);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // If a search term was provided (from chat list message search), open search and apply it
    final term = widget.initialSearchTerm?.trim();
    if (term != null && term.isNotEmpty) {
      _showSearch = true;
      _searchQuery = term;
      _searchController.text = term;
      setState(() {});
      // Reset focus tracker so first recompute will focus the first match
      _lastFocusedQuery = '';
    }
    _markAsRead();
    _loadAssigneesIfNeeded();
    _ensureCurrentUserProfile();
    // If a customerId is known, subscribe for live changes
    final data = widget.conversationData;
    final cid = (data['customerId'] ?? data['customer_id'] ?? data['customer']?['id'])?.toString();
    if (cid != null && cid.isNotEmpty) {
      _subscribeCustomerAssignees(cid);
    }
    // Listen for visible positions to detect if user is near bottom
    _itemPositionsListener.itemPositions.addListener(() {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;
      // With reverse=true, bottom is index 0. If any visible index <= 2, treat as near bottom
      int minIndex = positions.map((p) => p.index).fold<int>(999999, (a, b) => b < a ? b : a);
      final near = minIndex <= 2; // threshold
      // No rebuild needed; used only to decide auto-scroll later
      _nearBottom = near;

      // Detect near top (older messages) to load more
      // With reverse=true, top corresponds to the largest visible index
      int maxIndex = positions.map((p) => p.index).fold<int>(-1, (a, b) => b > a ? b : a);
      if (_lastItemCount > 0) {
        final nearTop = maxIndex >= (_lastItemCount - 3); // threshold near oldest
        if (nearTop) {
          // Capture anchor: current top-most visible id, if available
          if (_currentMessages.isNotEmpty && maxIndex >= 0 && maxIndex < _currentMessages.length) {
            try { _anchorMessageId = _currentMessages[maxIndex].id; } catch (_) {}
          }
          _maybeLoadMoreOlder();
        }
      }
    });

    // If initial term exists and messages are already present, recompute now
    if ((term != null && term.isNotEmpty) && _currentMessages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _recomputeMatches(_currentMessages);
        if (!mounted) return;
        setState(() {});
      });
    }
  }

  void _maybeLoadMoreOlder() {
    // Throttling and guards
    if (_isLoadingMore) return;
    if (_messageLimit >= _maxMessageLimit) return;
    if (_lastRequestedLimit > _messageLimit) return; // already requested a larger page
    final now = DateTime.now();
    if (_lastLoadMoreAt != null && now.difference(_lastLoadMoreAt!) < const Duration(milliseconds: 600)) {
      return;
    }
    _lastLoadMoreAt = now;
    _isLoadingMore = true;
    _lastLoadAttemptItemCount = _lastItemCount; // observe baseline count
    final next = (_messageLimit + _loadMoreStep).clamp(0, _maxMessageLimit);
    setState(() {
      _messageLimit = next;
      _lastRequestedLimit = next;
    });
    // Guard timer: if no growth after timeout, release loading state
    _loadMoreGuardTimer?.cancel();
    _loadMoreGuardTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      if (_isLoadingMore && _lastItemCount <= _lastLoadAttemptItemCount) {
        setState(() { _isLoadingMore = false; });
      }
    });
    // We'll turn off _isLoadingMore after we observe data length growth in the stream builder
  }

  @override
  void dispose() {
    _replyFocusClearTimer?.cancel();
    // _scrollController.dispose();
    _searchController.dispose();
    _customerSub?.cancel();
    _loadMoreGuardTimer?.cancel();
    super.dispose();
  }

  void _markAsRead() async {
    // อัพเดท count เป็น 0 เมื่อเข้าแชท
    try {
      await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .update({'count': '0'});
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_itemScrollController.isAttached) return;
    final duration = const Duration(milliseconds: 300);
    if (animate) {
      _itemScrollController.scrollTo(
        index: 0, // with reverse=true, index 0 is bottom (newest)
        duration: duration,
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    } else {
      try {
        _itemScrollController.jumpTo(index: 0, alignment: 0.0);
      } catch (_) {}
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    await _ensureCurrentUserProfile();
    final sender = _buildSenderPayload();
    if (_replyToMessageId != null && _replyToMessageId!.isNotEmpty) {
      _logger.ui('Sending REPLY (text)', {
        'platform': _sourceType,
        'chatroomId': widget.conversationId,
        'workspaceId': widget.workspaceId,
        'replyTo.messageId': _replyToMessageId,
        'reply.quoteToken': _replyQuoteToken,
        'reply.type': _replyToMessageType,
        'text.length': text.trim().length,
      });
    }

    try {
      if (mounted) setState(() { _isLoading = true; _error = null; });
      final result = await _chatService.sendTextMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        text: text.trim(),
        replyText: _replyPreviewText,
        replyToMessageId: _replyToMessageId,
        replyToMessageType: _replyToMessageType,
        replyOriginalSenderName: _replyOriginalSenderName,
        replyQuoteToken: _replyQuoteToken,
        sender: sender,
      );
      if (result['success'] == true && mounted) {
        setState(() { _replyPreviewText = null; _replyToMessageId = null; _replyToMessageType = null; _replyOriginalSenderName = null; _replyQuoteToken = null; });
      }
    } catch (e, st) {
      _logger.failure('Send text failed', e, st);
      setState(() { _error = 'error_occurred_details'.tr.replaceFirst('{error}', '$e'); });
      _showErrorSnackBar(_error!);
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }


  Future<void> _sendImageMessage(String imageUrl) async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    await _ensureCurrentUserProfile();
    try {
      final sender = _buildSenderPayload();
      if (_replyToMessageId != null && _replyToMessageId!.isNotEmpty) {
        _logger.ui('Sending REPLY (image)', {
          'platform': _sourceType,
          'chatroomId': widget.conversationId,
          'workspaceId': widget.workspaceId,
          'replyTo.messageId': _replyToMessageId,
          'reply.quoteToken': _replyQuoteToken,
          'imageUrl': imageUrl,
        });
      }
      final result = await _chatService.sendImageMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        imageUrl: imageUrl,
        replyText: _replyPreviewText,
        replyToMessageId: _replyToMessageId,
        replyToMessageType: _replyToMessageType,
        replyOriginalSenderName: _replyOriginalSenderName,
        replyQuoteToken: _replyQuoteToken,
        sender: sender,
      );
      if (result['success'] == true && mounted) {
        setState(() { _replyPreviewText = null; _replyToMessageId = null; _replyToMessageType = null; _replyOriginalSenderName = null; _replyQuoteToken = null; });
      }
    } catch (e) { setState(() => _error = 'error_occurred'.tr); _showErrorSnackBar(_error!); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _sendFileMessage(String fileUrl, String fileName) async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    await _ensureCurrentUserProfile();
    try {
      final sender = _buildSenderPayload();
      if (_replyToMessageId != null && _replyToMessageId!.isNotEmpty) {
        _logger.ui('Sending REPLY (file)', {
          'platform': _sourceType,
          'chatroomId': widget.conversationId,
          'workspaceId': widget.workspaceId,
          'replyTo.messageId': _replyToMessageId,
          'reply.quoteToken': _replyQuoteToken,
          'fileName': fileName,
        });
      }
      final result = await _chatService.sendFileMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        fileUrl: fileUrl,
        fileName: fileName,
        replyText: _replyPreviewText,
        replyToMessageId: _replyToMessageId,
        replyToMessageType: _replyToMessageType,
        replyOriginalSenderName: _replyOriginalSenderName,
        replyQuoteToken: _replyQuoteToken,
        sender: sender,
      );
      if (result['success'] == true && mounted) {
        setState(() { _replyPreviewText = null; _replyToMessageId = null; _replyToMessageType = null; _replyOriginalSenderName = null; _replyQuoteToken = null; });
      }
    } catch (e) { setState(() => _error = 'error_occurred'.tr); _showErrorSnackBar(_error!); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // เพิ่มฟังก์ชั่นส่งข้อความประเภทอื่นๆ
  Future<void> _sendVideoMessage(String videoUrl) async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
    await _ensureCurrentUserProfile();
    try {
      final sender = _buildSenderPayload();
      if (_replyToMessageId != null && _replyToMessageId!.isNotEmpty) {
        _logger.ui('Sending REPLY (video)', {
          'platform': _sourceType,
          'chatroomId': widget.conversationId,
          'workspaceId': widget.workspaceId,
          'replyTo.messageId': _replyToMessageId,
          'reply.quoteToken': _replyQuoteToken,
          'videoUrl': videoUrl,
        });
      }
      final result = await _chatService.sendVideoMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        videoUrl: videoUrl,
        replyText: _replyPreviewText,
        replyToMessageId: _replyToMessageId,
        replyToMessageType: _replyToMessageType,
        replyOriginalSenderName: _replyOriginalSenderName,
        replyQuoteToken: _replyQuoteToken,
        sender: sender,
      );
      if (result['success'] == true && mounted) {
        setState(() { _replyPreviewText = null; _replyToMessageId = null; _replyToMessageType = null; _replyOriginalSenderName = null; _replyQuoteToken = null; });
      }
    } catch (e) { setState(() => _error = 'error_occurred'.tr); _showErrorSnackBar(_error!); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  // ignore: unused_element
  Future<void> _sendStickerMessage(String stickerId, String stickerPackageId) async {
    if (_sourceType.toLowerCase() != 'line') { _showErrorSnackBar('sticker_line_only'.tr); return; }
    if (mounted) setState(() { _isLoading = true; _error = null; });
    await _ensureCurrentUserProfile();
    try {
      final sender = _buildSenderPayload();
      if (_replyToMessageId != null && _replyToMessageId!.isNotEmpty) {
        _logger.ui('Sending REPLY (sticker)', {
          'platform': _sourceType,
          'chatroomId': widget.conversationId,
          'workspaceId': widget.workspaceId,
          'replyTo.messageId': _replyToMessageId,
          'reply.quoteToken': _replyQuoteToken,
          'stickerId': stickerId,
          'stickerPackageId': stickerPackageId,
        });
      }
      final result = await _chatService.sendStickerMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        stickerId: stickerId,
        stickerPackageId: stickerPackageId,
        replyText: _replyPreviewText,
        replyToMessageId: _replyToMessageId,
        replyToMessageType: _replyToMessageType,
        replyOriginalSenderName: _replyOriginalSenderName,
        replyQuoteToken: _replyQuoteToken,
        sender: sender,
      );
      if (result['success'] == true && mounted) {
        setState(() { _replyPreviewText = null; _replyToMessageId = null; _replyToMessageType = null; _replyOriginalSenderName = null; _replyQuoteToken = null; });
      }
    } catch (e) { setState(() => _error = 'error_occurred_details'.tr.replaceFirst('{error}', '$e')); _showErrorSnackBar(_error!); }
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  void _showErrorSnackBar(String message) {

    TopSnack.error(message);
  }
  void _showSuccessSnackBar(String message) {

    TopSnack.success(message);
  }

  void _recomputeMatches(List<QueryDocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) {
      _matchedIds = [];
      _focusedMatchIndex = 0;
      return;
    }
    final ids = <String>[];
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      if (_matchesQuery(data, _searchQuery)) ids.add(d.id);
    }
    final queryChanged = _searchQuery != _lastFocusedQuery;
    _matchedIds = ids;
    if (queryChanged) {
      _focusedMatchIndex = 0;
      _lastFocusedQuery = _searchQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentMatch());
    } else if (_focusedMatchIndex >= _matchedIds.length && _matchedIds.isNotEmpty) {
      _focusedMatchIndex = _matchedIds.length - 1;
    }
  }

  void _focusCurrentMatch() {
    if (_matchedIds.isEmpty) return;
    final id = _matchedIds[_focusedMatchIndex];

    double _calcAlignment() {
      final idx = _listIndexById[id];
      if (idx == null || _lastItemCount == 0) {
        return 0.5;
      }
      final isInFirstTen = _isReversed
          ? idx >= (_lastItemCount - 10)
          : idx <= 9;
      return isInFirstTen ? 0.1 : 0.5;
    }

    int _indexOfId() {
      final byMap = _listIndexById[id];
      if (byMap != null) return byMap;
      final i = _currentMessages.indexWhere((d) => d.id == id);
      return i >= 0 ? i : 0;
    }

    void _scroll() {
      if (!_itemScrollController.isAttached) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scroll());
        return;
      }
      final idx = _indexOfId();
      _itemScrollController.scrollTo(
        index: idx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: _calcAlignment(),
      );
    }

    _scroll();
  }

  void _gotoPrevMatch() {
    if (_matchedIds.isEmpty) return;
    setState(() {
      _focusedMatchIndex = (_focusedMatchIndex - 1) < 0
          ? _matchedIds.length - 1
          : _focusedMatchIndex - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentMatch());
  }

  void _gotoNextMatch() {
    if (_matchedIds.isEmpty) return;
    setState(() {
      _focusedMatchIndex = (_focusedMatchIndex + 1) % _matchedIds.length;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentMatch());
  }



  // Helpers for bottom sheet actions
  Future<void> _updateStatus(ChatStatus status) async {
    // Only map business statuses; auto-reply is stored separately in bot_status
    final map = {
      ChatStatus.inProgress: 'IN_PROGRESS',
      ChatStatus.done: 'DONE',
    };
    try {
      await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .update({'chatroom_status': map[status]});
      _showSuccessSnackBar('chat_status_updated'.tr);
    } catch (e) {
      _showErrorSnackBar('chat_status_update_failed'.tr + ': $e');
    }
  }

  Future<void> _updatePinned(bool pinned) async {
    try {
      final docRef = _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId);
      // Read current bot_status to persist alongside pin
      final snap = await docRef.get();
      final data = snap.data();
      final currentBot = (data != null ? (data['bot_status'] ?? 'N') : 'N') == 'Y';
      await docRef.update({
        'chat_pin': pinned ? 'Y' : 'N',
        'bot_status': currentBot ? 'Y' : 'N',
      });
      _showSuccessSnackBar(pinned ? 'chat_pinned'.tr : 'chat_unpinned'.tr);
    } catch (e) {
      _showErrorSnackBar('pin_update_failed'.tr + ': $e');
    }
  }
  void _showTopSnack(String message, {bool isError = false, String? title}) {
    // Delegate to centralized TopSnack helper for consistent UI
    TopSnack.show(message, isError: isError, title: title);
  }
  Future<void> _updateBotStatus(bool enabled) async {
    try {
      await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .update({'bot_status': enabled ? 'Y' : 'N'});
      _showTopSnack(enabled ? 'bot_enabled'.tr : 'bot_disabled'.tr);
    } catch (e) {
      _showErrorSnackBar('error_occurred_details'.tr.replaceFirst('{error}', '$e'));
    }
  }

  Future<void> _deleteChatroom() async {
    try {
      await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .set({
            'is_hidden': true,
            'hidden_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('error_occurred_details'.tr.replaceFirst('{error}', '$e'));
    }
  }

  Future<void> _reloadChatroomName() async {
    try {
      final doc = await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _chatroomNameState = data['name'] ?? data['who_name'] ?? 'chat_default_name'.tr;
        });
        _showSuccessSnackBar('chatroom_reloaded'.tr);
      }
    } catch (e) {
      _showErrorSnackBar('error_occurred_details'.tr.replaceFirst('{error}', '$e'));
    }
  }

  void _subscribeCustomerAssignees(String customerId) {
    _customerSub?.cancel();
    _customerSub = FirestoreService.to
        .getWorkspaceCustomersCollection(widget.workspaceId)
        .doc(customerId)
        .snapshots()
        .listen((snap) async {
      final cData = snap.data() ?? {};
      final uids = ((cData['assignees'] as List?) ?? []).map((e) => e.toString()).toList();
      if (uids.isEmpty) {
        if (!mounted) return;
        setState(() => _assigneeNames = const []);
        return;
      }
      // Resolve names with cache
      final names = <String>[];
      for (final uid in uids) {
        final cached = _userNameCache[uid];
        if (cached != null && cached.isNotEmpty) {
          names.add(cached);
          continue;
        }
        try {
          final u = await FirestoreService.to.usersCollection.doc(uid).get();
          final m = u.data() ?? {};
          final dn = (m['displayName'] ?? m['name'] ?? '').toString();
          final resolved = dn.isNotEmpty ? dn : uid;
          _userNameCache[uid] = resolved;
          names.add(resolved);
        } catch (_) {
          names.add(uid);
        }
      }
      if (!mounted) return;
      setState(() => _assigneeNames = names);
    });
  }

  // Load assignee display names from workspace customers -> users
  Future<void> _loadAssigneesIfNeeded() async {
    try {
      // Prefer any names already carried in conversationData
      final carried = widget.conversationData['assigneeNames'];
      if (carried is List && carried.isNotEmpty) {
        final names = carried.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
        if (names.isNotEmpty) {
          setState(() => _assigneeNames = names);
          return;
        }
      }

      final wsId = widget.workspaceId;
      final data = widget.conversationData;
      final customerId = (data['customerId'] ?? data['customer_id'] ?? data['customer']?['id'])?.toString();
      if (wsId.isEmpty || customerId == null || customerId.isEmpty) return;

      final cSnap = await FirestoreService.to
          .getWorkspaceCustomersCollection(wsId)
          .doc(customerId)
          .get();
      final cData = cSnap.data() ?? {};
      final assignees = ((cData['assignees'] as List?) ?? []).map((e) => e.toString()).toList();
      if (assignees.isEmpty) return;

      final futures = assignees.map((uid) async {
        final u = await FirestoreService.to.usersCollection.doc(uid).get();
        final m = u.data() ?? {};
        final dn = (m['displayName'] ?? m['name'] ?? '').toString();
        return dn.isNotEmpty ? dn : uid;
      }).toList();

      final names = await Future.wait(futures);
      if (!mounted) return;
      setState(() => _assigneeNames = names);
    } catch (_) {}
  }

  Future<void> _resolveUserNames(List<String> uids) async {
    // Use cache where possible, fetch missing, preserve input order
    final names = <String>[];
    final toFetch = <String>[];
    for (final uid in uids) {
      final cached = _userNameCache[uid];
      if (cached != null && cached.isNotEmpty) {
        names.add(cached);
      } else {
        toFetch.add(uid);
      }
    }
    for (final uid in toFetch) {
      try {
        final u = await FirestoreService.to.usersCollection.doc(uid).get();
        final m = u.data() ?? {};
        final dn = (m['displayName'] ?? m['name'] ?? '').toString();
        final resolved = dn.isNotEmpty ? dn : uid;
        _userNameCache[uid] = resolved;
        names.add(resolved);
      } catch (_) {
        names.add(uid);
      }
    }
    if (!mounted) return;
    setState(() => _assigneeNames = names);
  }

  void _maybeUpdateAssigneesFromChatroom(Map<String, dynamic> data) {
    final raw = data['assignees'];
    if (raw is! List) return;
    final uids = raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
    // Compare with last to avoid redundant fetches
    final same = uids.length == _lastChatAssigneeUids.length &&
        Set<String>.from(uids).containsAll(_lastChatAssigneeUids) &&
        Set<String>.from(_lastChatAssigneeUids).containsAll(uids);
    if (same) return;
    _lastChatAssigneeUids = List<String>.from(uids);
    if (uids.isEmpty) {
      if (mounted) setState(() => _assigneeNames = const []);
      return;
    }
    // Resolve names asynchronously after this frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveUserNames(uids));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _chatService
              .getChatroomsCollection(widget.workspaceId)
              .doc(widget.conversationId)
              .snapshots(),
          builder: (context, snap) {
            final data = snap.data?.data() ?? widget.conversationData;
            String pickName() => (data['name'] ?? data['who_name'] ?? data['displayName'] ?? data['customerName'] ?? 'chat_default_name'.tr).toString();
            final title = _chatroomNameState ?? pickName();
            final avatar = (data['avatar'] ?? widget.conversationData['avatar']) as String?;
            final platformRaw = (data['source_type'] ?? widget.conversationData['source_type'] ?? 'LINE').toString();
            final platform = platformRaw.toUpperCase();

            String pickPageTitle() {
              // 1) direct fields
              final direct = (data['pageName'] ?? widget.conversationData['pageName'] ?? '').toString();
              if (direct.isNotEmpty) return direct;

              // 2) legacy single connection object
              final conn = data['connection'] ?? widget.conversationData['connection'];
              if (conn is Map) {
                final nested = (conn['pageName'] ?? conn['name'] ?? conn['displayName'] ?? conn['igUsername'] ?? '').toString();
                if (nested.isNotEmpty) return nested;
              }

              // 3) nested connections map (facebook/instagram/line arrays)
              final connections = data['connections'] ?? widget.conversationData['connections'];
              if (connections is Map) {
                switch (platform) {
                  case 'FACEBOOK':
                    final fb = connections['facebook'];
                    if (fb is List && fb.isNotEmpty && fb.first is Map) {
                      final v = (fb.first['pageName'] ?? fb.first['name'] ?? '').toString();
                      if (v.isNotEmpty) return v;
                    }
                    break;
                  case 'INSTAGRAM':
                    final ig = connections['instagram'];
                    if (ig is List && ig.isNotEmpty && ig.first is Map) {
                      final v = (ig.first['pageName'] ?? ig.first['igUsername'] ?? ig.first['name'] ?? '').toString();
                      if (v.isNotEmpty) return v;
                    }
                    break;
                  case 'LINE':
                    final line = connections['line'];
                    if (line is List && line.isNotEmpty && line.first is Map) {
                      final v = (line.first['displayName'] ?? line.first['name'] ?? '').toString();
                      if (v.isNotEmpty) return v;
                    }
                    break;
                }
              }

              // 4) Fallback to platform label if nothing else
              switch (platform) {
                case 'FACEBOOK':
                  return 'Facebook';
                case 'INSTAGRAM':
                  return 'Instagram';
                case 'LINE':
                  return 'LINE';
                default:
                  return '';
              }
            }
            final pageTitle = pickPageTitle();
            // Determine if chat is in-progress (Thai: กำลังดำเนินการ) only when status == IN_PROGRESS.
            final statusRaw = (data['chatroom_status'] ?? '').toString().toUpperCase();
            final bool isInProgress = statusRaw == 'IN_PROGRESS';

            // If no customer is linked, resolve assignees from chatroom-level 'assignees' array
            final customerId = (data['customerId'] ?? data['customer_id'] ?? data['customer']?['id'])?.toString();
            if (customerId == null || customerId.isEmpty) {
              _maybeUpdateAssigneesFromChatroom(data);
            } else {
              // Ensure live subscription when a customer becomes linked dynamically
              if (_subscribedCustomerId != customerId) {
                _subscribedCustomerId = customerId;
                _subscribeCustomerAssignees(customerId);
              }
            }


            // Prefer state-loaded names, fallback to any carried list on the map
            final List<String>? headerAssignees = _assigneeNames ?? (() {
              final raw = widget.conversationData['assigneeNames'];
              if (raw is List) {
                final v = raw.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList();
                return v.isEmpty ? null : v;
              }
              return null;
            })();

            return ChatHeaderLine(
              title: title,
              avatarUrl: avatar,
              platform: platform,
              pageTitle: pageTitle,
              showBack: false,
              showAutoReplyBubble: isInProgress,
              assigneeNames: headerAssignees,
              onSearch: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchQuery = '';
                    _searchController.clear();
                    _matchedIds = [];
                    _focusedMatchIndex = 0;
                    _lastFocusedQuery = '';
                    setState(() {});
                  }
                });
              },
              onMore: () {
                // Derive current flags from latest data
                final statusRaw = (data['chatroom_status'] ?? '').toString().toUpperCase();
                final currentStatus = statusRaw == 'DONE' ? ChatStatus.done : ChatStatus.inProgress;
                final pinned = (data['chat_pin'] ?? 'N') == 'Y';
                final bot = (data['bot_status'] ?? 'N') == 'Y';

                ShowBottomModal.open(
                  context,
                  current: currentStatus,
                  pinned: pinned,
                  botEnabled: bot,
                  assignOptions: const ['ทีม A', 'ทีม B', 'ทีม C'],
                  selectedAssign: null,
                  onStatusChange: (s) => guardActionAnyOf(context, ['chat:manage', 'chat:assign'], () => _updateStatus(s)),
                  onPinChanged: (p) => guardActionAnyOf(context, ['chat:manage', 'chat:assign'], () => _updatePinned(p)),
                  onBotStatusChanged: (b) => guardActionAnyOf(context, ['chat:bot:manage', 'chat:assign'], () => _updateBotStatus(b)),
                  onAssignChanged: (v) {},
                  onNote: () {},
                  onAddSale: () => guardAction(context, 'chat:assign', _openAddSales),
                  onRename: () => guardAction(context, 'chat:manage', _reloadChatroomName),
                  onResetName: () => guardAction(context, 'chat:manage', _reloadChatroomName),
                  onDelete: () => guardAction(context, 'chat:delete', _deleteChatroom),
                  workspaceId: widget.workspaceId,
                  chatroomId: widget.conversationId,
                   customerId: (data['customerId'] ?? data['customer_id'] ?? data['customer']?['id'])?.toString(),
                );
              },
              onAddSales: () => guardAction(context, 'chat:assign', _openAddSales),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [

              // Realtime auto-reply banner (moved to top under header)
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _chatService
                    .getChatroomsCollection(widget.workspaceId)
                    .doc(widget.conversationId)
                    .snapshots(),
                builder: (context, snap) {
                  final m = (snap.data?.data() ?? widget.conversationData);
                  final bool bot = (m['bot_status'] ?? 'N') == 'Y';
                  if (!bot) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9CA3AF), // closer to screenshot gray bar
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.smart_toy_outlined, color: Colors.white),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'bot_in_progress'.tr,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          PermissionGuard(
                            anyOf: const ['chat:bot:manage', 'chat:assign'],
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF111827),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                              ),
                              onPressed: () => guardActionAnyOf(context, ['chat:bot:manage', 'chat:assign'], () => _updateBotStatus(false)),
                              child: Text('manual_chat'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Error display
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade800),
                    textAlign: TextAlign.center,
                  ),
                ),

              // In-chat search bar
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'search_in_chat'.tr,
                            prefixIcon: const Icon(Icons.search),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (v) {
                            setState(() {
                              final q = v.trim();
                              _searchQuery = q;
                              if (q.isEmpty) {
                                _matchedIds = [];
                                _focusedMatchIndex = 0;
                                _lastFocusedQuery = '';
                              } else {
                                // recompute immediately against current messages
                                _lastFocusedQuery = '';
                                _recomputeMatches(_currentMessages);
                              }
                            });
                            if (_searchQuery.isNotEmpty) {
                              // focus after layout updates
                              WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentMatch());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'clear_value'.tr,
                        onPressed: () {
                          setState(() {
                            _showSearch = false;
                            _searchQuery = '';
                            _searchController.clear();
                            _matchedIds = [];
                            _focusedMatchIndex = 0;
                            _lastFocusedQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ],
                  ),
                ),

              // แสดงแถบสรุปผลเฉพาะเมื่อมีคำค้นหา (ไม่ว่าง)
              if (_showSearch && _searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(
                        _matchedIds.isEmpty ? 'no_results_found'.tr : '${_focusedMatchIndex + 1}/${_matchedIds.length}',
                        style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'previous'.tr,
                        onPressed: _matchedIds.isEmpty ? null : _gotoPrevMatch,
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      IconButton(
                        tooltip: 'next'.tr,
                        onPressed: _matchedIds.isEmpty ? null : _gotoNextMatch,
                        icon: const Icon(Icons.keyboard_arrow_down),
                      ),
                    ],
                  ),
                ),

              // Messages list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessagesStream(
                    workspaceId: widget.workspaceId,
                    chatroomId: widget.conversationId,
                    limit: _messageLimit,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('error_occurred_details'.tr.replaceFirst('{error}', '${snapshot.error}')));
                    }

                    final messages = snapshot.data?.docs ?? [];
                    // cache latest messages for instant search recompute
                    _currentMessages = messages;
                    // Recompute matches when data changes
                    _recomputeMatches(messages);
                    // If match count changed, refresh UI so summary row above updates
                    if (_searchQuery.isNotEmpty) {
                      final count = _matchedIds.length;
                      if (count != _lastRenderedMatchCount) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() {
                            _lastRenderedMatchCount = count;
                          });
                        });
                      }
                    }

                    // determine if we should autoscroll (only when new messages arrive and not searching)
                    final prevCount = _prevMessageCount;
                    final hasNew = messages.length > (prevCount < 0 ? 0 : prevCount);
                    final shouldAutoScroll = !_isLoadingMore && _searchQuery.isEmpty && hasNew && _nearBottom;

                    // reset visual index map for this build
                    _listIndexById.clear();
                    _altIdIndex.clear();
                    // If we were loading more and we see growth, clear the flag after frame
                    if (_isLoadingMore && messages.length > _lastItemCount) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() { _isLoadingMore = false; });
                        // Restore anchor position if captured
                        final anchorId = _anchorMessageId;
                        _anchorMessageId = null;

                        if (anchorId != null && _itemScrollController.isAttached) {
                          try {
                            final idx = _listIndexById[anchorId] ?? _currentMessages.indexWhere((d) => d.id == anchorId);
                            if (idx >= 0) {
                              _itemScrollController.jumpTo(index: idx, alignment: 0.0); // keep near top
                            }
                          } catch (_) {}
                        }
                      });
                    }
                    _lastItemCount = messages.length;
                    _prevMessageCount = messages.length;

                    if (messages.isEmpty) {
                      return Center(
                        child: Text('no_messages_yet'.tr, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      );
                    }

                    // Keep auto-scroll to bottom only when new messages came in and user is near bottom
                    if (shouldAutoScroll) {
                      // Decide animation: if newest is from current user, jump without animation to avoid flicker
                      bool newestFromSelf = false;
                      try {
                        if (messages.isNotEmpty) {
                          final m0 = messages[0].data() as Map<String, dynamic>;
                          final sid = m0['sender']?['id']?.toString();
                          newestFromSelf = sid != null && sid == _currentUserId;
                        }
                      } catch (_) {}
                      final animate = !newestFromSelf;
                      SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: animate));
                    }

                    // if pending focus and message list changed attempt focus
                    if (_pendingFocusMessageId != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final ok = _tryScrollToMessageId(_pendingFocusMessageId!, silent: true);
                        if (ok) {
                          setState(() { _pendingFocusMessageId = null; });
                        } else {
                          if (_messageLimit < _maxMessageLimit) {
                            setState(() { _messageLimit = (_messageLimit + 100).clamp(0, _maxMessageLimit); });
                          } else {
                            _showErrorSnackBar('original_message_not_found'.tr);
                            setState(() { _pendingFocusMessageId = null; });
                          }
                        }
                      });
                    }

                    return Stack(
                      children: [
                        ScrollablePositionedList.builder(
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          padding: const EdgeInsets.all(16),
                          itemCount: messages.length,
                          reverse: _isReversed,
                          itemBuilder: (context, index) {
                            final messageData = messages[index].data() as Map<String, dynamic>;
                            final messageId = messages[index].id;
                            final messageType = (messageData['type'] ?? '').toString();
                            _listIndexById[messageId] = index; // map

                            // index alternative IDs for quicker reply navigation
                            void addAlt(dynamic v) { if (v == null) return; final s = v.toString(); if (s.isEmpty) return; _altIdIndex[s] = index; }
                            addAlt(messageData['id']);
                            addAlt(messageData['messageId']);
                            addAlt(messageData['platformMessageId']); // NEW ensure platform id focus works
                            addAlt(messageData['internalId']);
                            addAlt(messageData['clientMessageId']);
                            addAlt(messageData['originalMessageId']);
                            final isSearchHighlighted = _searchQuery.isNotEmpty && _matchesQuery(messageData, _searchQuery);
                            final isSearchFocused = _searchQuery.isNotEmpty && _matchedIds.isNotEmpty && messageId == _matchedIds[_focusedMatchIndex];
                            final replyFocused = _focusedReplyMessageId != null && messageId == _focusedReplyMessageId;
                            final highlight = isSearchHighlighted || replyFocused;
                            final focused = isSearchFocused || replyFocused;

                            // Date separator logic
                            DateTime? _toDate(dynamic ts) {
                              try {
                                if (ts == null) return null;
                                if (ts is Timestamp) return ts.toDate();
                                if (ts is int) {
                                  // Heuristic: seconds vs millis
                                  final int v = ts;
                                  final bool isSeconds = v < 100000000000; // 1e11
                                  return DateTime.fromMillisecondsSinceEpoch(isSeconds ? v * 1000 : v);
                                }
                                if (ts is String) {
                                  final parsed = int.tryParse(ts);
                                  if (parsed != null) {
                                    final bool isSeconds = parsed < 100000000000;
                                    return DateTime.fromMillisecondsSinceEpoch(isSeconds ? parsed * 1000 : parsed);
                                  }
                                }
                              } catch (_) {}
                              return null;
                            }

                            bool _isSameDay(DateTime a, DateTime b) {
                              final aa = a.toLocal();
                              final bb = b.toLocal();
                              return aa.year == bb.year && aa.month == bb.month && aa.day == bb.day;
                            }

                            String _formatDay(DateTime d) {
                              final local = d.toLocal();
                              return DateFormat('d MMM yyyy').format(local);
                            }

                            Widget _buildDaySeparator(String text) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    const Expanded(child: Divider(thickness: 1)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(child: Divider(thickness: 1)),
                                  ],
                                ),
                              );
                            }

                            final DateTime? curTs = _toDate(messageData['timestamp']);
                            bool showDayHeader = false;
                            String headerText = '';
                            if (curTs != null) {
                              final int prevIndex = _isReversed ? index + 1 : index - 1;
                              if (prevIndex < 0 || prevIndex >= messages.length) {
                                showDayHeader = true;
                              } else {
                                final prevData = messages[prevIndex].data() as Map<String, dynamic>;
                                final DateTime? prevTs = _toDate(prevData['timestamp']);
                                if (prevTs == null || !_isSameDay(curTs, prevTs)) {
                                  showDayHeader = true;
                                }
                              }
                              if (showDayHeader) {
                                headerText = _formatDay(curTs);
                              }
                            }

                            final bubble = RepaintBoundary(
                              child: MessageBubble(
                                key: ValueKey(messageId),
                                messageId: messageId,
                                messageData: messageData,
                                isFromCurrentUser: _isMessageFromCurrentUser(messageData),
                                highlight: highlight,
                                highlightQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                                focused: focused,
                                onLongPress: () => _onLongPressMessage(messageId, messageData, messageType),
                                onTapReply: (origId) {
                                  // Hide keyboard when user taps reply block
                                  FocusScope.of(context).unfocus();
                                  _focusReplyOriginal(origId);
                                },
                                onTap: () {
                                  // Unfocus input when tapping text/image/video/file/audio bubbles
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                            );

                            if (showDayHeader && headerText.isNotEmpty) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildDaySeparator(headerText),
                                  bubble,
                                ],
                              );
                            }
                            return bubble;
                          },
                        ),
                        // Top loading indicator when fetching older messages
                        if (_isLoadingMore)
                          Positioned(
                            top: 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                    const SizedBox(width: 8),
                                    Text('loading_older'.tr, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),

                          ),
                      ],
                    );
                  },
                ),
              ),

              // Input area guarded by permission
              PermissionGuard(
                permission: 'chat:send',
                fallback: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'no_permission_send_message'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                child: ChatInput(
                  onSendText: (t) => guardAction(context, 'chat:send', () => _sendMessage(t)),
                  onSendImage: (u) => guardAction(context, 'chat:send', () => _sendImageMessage(u)),
                  onSendFile: (fileUrl, fileName) => guardAction(context, 'chat:send', () => _sendFileMessage(fileUrl, fileName)),
                  onSendVideo: (u) => guardAction(context, 'chat:send', () => _sendVideoMessage(u)),
                  workspaceId: widget.workspaceId,
                  chatroomId: widget.conversationId,
                  enabled: !_isLoading,
                  replyPreview: _replyPreviewText,
                  replyToMessageId: _replyToMessageId,
                  onTapReplyPreview: () {
                    if (_replyToMessageId != null && _replyToMessageId!.isNotEmpty) {
                      _focusReplyOriginal(_replyToMessageId!);
                    }
                  },
                  onCancelReply: () => setState(() { _replyPreviewText = null; _replyToMessageId = null; _replyToMessageType = null; _replyOriginalSenderName = null; _replyQuoteToken = null; }),
                ),
              ),
            ],
          ),


          // Loading indicator overlay (does not shift layout)
          if (_isLoading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 64, // slightly above input
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      const SizedBox(width: 8),
                      Text('sending'.tr, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _matchesQuery(Map<String, dynamic> m, String q) {
    final query = q.toLowerCase();
    String collectText() {
      final t = (m['text'] ?? m['message'] ?? '').toString();
      if (t.isNotEmpty) return t;
      // fallback for other types with captions
      return (m['fileName'] ?? '').toString();
    }
    return collectText().toLowerCase().contains(query);
  }

  bool _isMessageFromCurrentUser(Map<String, dynamic> messageData) {
    // Right align when message is from current user OR from bot (per web behavior)
    final sender = (messageData['sender'] as Map<String, dynamic>?) ?? const {};
    final senderId = sender['id']?.toString();
    final senderType = (sender['type'] ?? '').toString().toLowerCase();
    final isBot = senderType == 'bot' || (senderId != null && senderId.startsWith('bot-'));
    return isBot || senderId == _currentUserId;
  }

  // ignore: unused_element
  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_avatarUrl != null)
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(_avatarUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 32,
                      child: Text(_chatroomName.substring(0, 1).toUpperCase()),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _chatroomName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${'platform'.tr}: ${_sourceType.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${'status'.tr}: ${widget.conversationData['chatroom_status'] ?? 'not_specified'.tr}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text('chat_details'.tr),
                subtitle: Text('ID: ${widget.conversationId}'),
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: Text('workspace'.tr),
                subtitle: Text('ID: ${widget.workspaceId}'),
              ),
              if (widget.conversationData['customerName'] != null)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('customer'.tr),
                  subtitle: Text(widget.conversationData['customerName']),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Build reply preview string from a message
  String _makeReplyPreview(Map<String, dynamic> m) {
    final type = (m['type'] ?? 'text').toString();
    String text = (m['text'] ?? m['message'] ?? '').toString().trim();
    switch (type) {
      case 'text':
        return text.isNotEmpty ? text : 'text_message'.tr;
      case 'image':
        if (text.isNotEmpty) return text;
        return 'image_message'.tr;
      case 'video':
        if (text.isNotEmpty) return text;
        return 'video_message'.tr;
      case 'audio':
        final name = (m['fileName'] ?? '').toString();
        return name.isNotEmpty ? 'audio_file'.tr.replaceFirst('{name}', name) : 'audio_message'.tr;
      case 'file':
        final name = (m['fileName'] ?? '').toString();
        return name.isNotEmpty ? 'file_with_name'.tr.replaceFirst('{name}', name) : 'file_message'.tr;
      case 'sticker':
        return 'sticker_message'.tr;
      default:
        return text.isNotEmpty ? text : 'unknown_file'.tr;
    }
  }

  void _clearReplyFocusLater() {
    _replyFocusClearTimer?.cancel();
    _replyFocusClearTimer = Timer(const Duration(seconds: 3), () { if (!mounted) return; setState(() { _focusedReplyMessageId = null; }); });
  }
  bool _tryScrollToMessageId(String id, {bool silent = false}) {
    int? idx = _listIndexById[id];
    idx ??= _altIdIndex[id];
    if (idx == null) {
      // Fallback scan among currently loaded messages only (no expansion here)
      for (int i = 0; i < _currentMessages.length; i++) {
        try {
          final data = _currentMessages[i].data() as Map<String, dynamic>;
          if (_currentMessages[i].id == id ||
              (data['id']?.toString() == id) ||
              (data['messageId']?.toString() == id) ||
              (data['internalId']?.toString() == id) ||
              (data['clientMessageId']?.toString() == id) ||
              (data['originalMessageId']?.toString() == id)) {
            idx = i; break; }
        } catch (_) {}
      }
    }
    if (idx == null) {
      if (!silent) _showErrorSnackBar('original_message_not_found'.tr);
      return false;
    }
    if (!_itemScrollController.isAttached) return false;
    _itemScrollController.scrollTo(index: idx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut, alignment: 0.2);
    setState(() { _focusedReplyMessageId = _currentMessages[idx!].id; });
    _clearReplyFocusLater();
    return true;
  }

  void _focusReplyOriginal(String id) {
    final ok = _tryScrollToMessageId(id, silent: true);
    if (ok) return;
    // need to load more messages
    if (_messageLimit < _maxMessageLimit) {
      setState(() { _pendingFocusMessageId = id; _messageLimit = (_messageLimit + 100).clamp(0, _maxMessageLimit); });
    } else {
      _showErrorSnackBar('original_message_not_found'.tr);
    }
  }

  // Replace old _scrollToMessageId usages
  Future<void> _onLongPressMessage(String messageId, Map<String, dynamic> messageData, String messageType) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.reply), title: Text('quote_reply'.tr), onTap: () => Navigator.pop(ctx, 'reply')),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (picked == 'reply') {
      final preview = _makeReplyPreview(messageData);
      final originalSenderName = (messageData['sender']?['name'] ?? '').toString();
      // Build best-effort original message ID depending on platform
      final p = _sourceType.toLowerCase();
      String platformMsgId = (messageData['platformMessageId'] ?? '').toString();
      if (platformMsgId.isEmpty) {
        platformMsgId = (messageData['messageId'] ?? '').toString();
      }
      if (platformMsgId.isEmpty) {
        platformMsgId = (messageData['originalMessageId'] ?? '').toString();
      }
      if (platformMsgId.isEmpty) {
        platformMsgId = (messageData['clientMessageId'] ?? '').toString();
      }
      // For LINE (and most connectors), prefer platform-level message id when available
      final chosenId = (p == 'line')
          ? (platformMsgId.isNotEmpty ? platformMsgId : messageId)
          : (platformMsgId.isNotEmpty ? platformMsgId : messageId);
      // Prefer LINE quoteToken; fallback to legacy replyToken if present in stored message
      final rawQuote = (messageData['quoteToken'] ?? messageData['replyToken'] ?? '').toString();
      final quoteToken = rawQuote;
      // log selection details to diagnose issues
      final qPreview = quoteToken.isEmpty ? '(none)' : '${quoteToken.substring(0, quoteToken.length > 6 ? 6 : quoteToken.length)}...(${quoteToken.length})';
      _logger.ui('Reply target selected', {
        'platform': p,
        'docId': messageId,
        'platformMessageId': platformMsgId,
        'chosenId': chosenId,
        'type': messageType,
        'hasQuoteToken': quoteToken.isNotEmpty,
        'quoteTokenPreview': qPreview,
      });
      setState(() { _replyPreviewText = preview; _replyToMessageId = chosenId; _replyToMessageType = messageType; _replyOriginalSenderName = originalSenderName; _replyQuoteToken = quoteToken.isNotEmpty ? quoteToken : null; });
    }
  }
}
