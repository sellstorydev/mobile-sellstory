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
class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> conversationData;
  final String workspaceId;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.conversationData,
    required this.workspaceId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // final ScrollController _scrollController = ScrollController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final ChatService _chatService = ChatService.to;
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
  // Visual index tracking for alignment logic
  final Map<String, int> _listIndexById = {};
  int _lastItemCount = 0;
  // Cache latest messages to allow instant recompute on user typing
  List<QueryDocumentSnapshot> _currentMessages = const [];

  // Quote reply state
  String? _replyPreviewText;



  // Track previous message count to avoid redundant auto-scrolls that cause flicker
  int _prevMessageCount = -1;
  // Track if user is already near bottom; gate auto-scroll to reduce jumps
  bool _nearBottom = true;

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
          title: Text('chat_confirm_assign_sales'.tr),
          content: Text('chat_confirm_assign_user_question'.tr),
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
        _showSuccessSnackBar("chat_assign_sales_success".tr);

      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("chat_assign_sales_failed".tr);

      }
    }
  }

  @override
  void initState() {
    super.initState();
    _markAsRead();
    _loadAssigneesIfNeeded();
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
    });


  }

  @override
  void dispose() {
    // _scrollController.dispose();
    _searchController.dispose();
    _customerSub?.cancel();
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

    // Do not toggle _isLoading for quick text sends to avoid UI flicker
    // setState(() => _error = null); // Clear previous errors


    // try {
      final result = await _chatService.sendTextMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        text: text.trim(),
        replyText: _replyPreviewText, // include quote when present
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Mobile User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      if (result['success'] == true) {
        // Clear reply state after successful send
        if(_replyPreviewText != null)
        if (mounted) setState(() => _replyPreviewText = null);
        // Don't call _scrollToBottom here; stream listener will autoscroll when appropriate
      }
    // } catch (e) {
    //   _error = 'ส่งข้อความไม่สำเร็จ';
    //   _showErrorSnackBar(_error!);
    // }
  }

  Future<void> _sendImageMessage(String imageUrl) async {
    _isLoading = true;
    _error = null;

    try {
      final result = await _chatService.sendImageMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        imageUrl: imageUrl,
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Mobile User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      if (result['success'] == true) {
        // Clear reply preview on successful send
        if(_replyPreviewText != null)
        if (mounted) setState(() => _replyPreviewText = null);
        // Don't force scroll; will autoscroll if user is near bottom
      }
    } catch (e) {
      setState(() => _error = 'ส่งรูปภาพไม่สำเร็จ');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendFileMessage(String fileUrl, String fileName) async {
    _isLoading = true;
    _error = null;

    try {
      final result = await _chatService.sendFileMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        fileUrl: fileUrl,
        fileName: fileName,
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Mobile User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      if (result['success'] == true) {
        // Clear reply preview on successful send
        if(_replyPreviewText != null)
        if (mounted) setState(() => _replyPreviewText = null);
        // No manual scroll
      }
    } catch (e) {
      setState(() => _error = 'ส่งไฟล์ไม่สำเร็จ');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // เพิ่มฟังก์��ันส่งข้อความประเภทอื่นๆ
  Future<void> _sendVideoMessage(String videoUrl) async {
    _isLoading = true;
    _error = null;

    try {
      final result = await _chatService.sendVideoMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        videoUrl: videoUrl,
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Mobile User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      if (result['success'] == true) {
        // Clear reply preview on successful send
        if(_replyPreviewText != null)
        if (mounted) setState(() => _replyPreviewText = null);
        // No manual scroll
      }
    } catch (e) {
      setState(() => _error = 'ส่งวิดีโอไม่สำเร็จ');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendStickerMessage(String stickerId, String stickerPackageId) async {
    if (_sourceType.toLowerCase() != 'line') {
      _showErrorSnackBar('สติ๊กเกอร์รองรับเฉพาะ LINE เท่านั้น');
      return;
    }
    _isLoading = true;
    _error = null;


    try {
      final result = await _chatService.sendStickerMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        stickerId: stickerId,
        stickerPackageId: stickerPackageId,
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Mobile User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );


      if (result['success'] == true) {
        // Clear reply preview on successful send
        if(_replyPreviewText != null)
        if (mounted) setState(() => _replyPreviewText = null);
        // No manual scroll
      }
    } catch (e) {
      setState(() => _error = 'ส่งสติ๊กเกอร์ไม่สำเร็จ: $e');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
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
      _showSuccessSnackBar("อัปเดตสถานะแล้ว");
      // setState(() {});
    } catch (e) {
      _showErrorSnackBar('อัปเดตสถานะไม่สำเร็จ: $e');
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
      _showSuccessSnackBar(pinned ? 'ปักหมุดแล้ว' : 'ยกเลิกปักหมุดแล้ว');
    } catch (e) {
      _showErrorSnackBar('อัปเดตปักหมุดไม่สำเร็จ: $e');
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
      _showTopSnack(enabled ? 'เปิดโหมดตอบกลับอัตโนมัติ' : 'ปิดโหมดตอบกลับอัตโนมัติ');

    } catch (e) {
      _showErrorSnackBar('อัปเดตตอบกลับอัตโนมัติไม่สำเร็จ: $e');
    }
  }

  Future<void> _deleteChatroom() async {
    try {
      await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .update({'is_deleted': 'Y'});
      if (mounted) {
        Navigator.of(context).pop(); // ออกจากหน้าแชท
      }
    } catch (e) {
      _showErrorSnackBar('ลบแชทไม่สำเร็จ: $e');
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
          _chatroomNameState = data['name'] ?? data['who_name'] ?? 'แชท';
        });
        _showSuccessSnackBar("โหลดข้อมูลห้องแชทใหม่แล้ว");

      }
    } catch (e) {
      _showErrorSnackBar('ดึงข้อมูลไม่สำเ��็จ: $e');
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
            String pickName() => (data['name'] ?? data['who_name'] ?? data['displayName'] ?? data['customerName'] ?? 'แชท').toString();
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
                  onStatusChange: (s) => guardAction(context, 'chat:manage', () => _updateStatus(s)),
                  onPinChanged: (p) => guardAction(context, 'chat:manage', () => _updatePinned(p)),
                  onBotStatusChanged: (b) => guardAction(context, 'chat:bot:manage', () => _updateBotStatus(b)),
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
                          const Expanded(
                            child: Text(
                              'กำลังใช้ข้อความตอบกลับอัตโนมัติ',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          PermissionGuard(
                            permission: 'chat:bot:manage',
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                foregroundColor: Colors.white,
                                backgroundColor: const Color(0xFF111827),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                              ),
                              onPressed: () => guardAction(context, 'chat:bot:manage', () => _updateBotStatus(false)),
                              child: const Text('แชทแบบแมนนวล', style: TextStyle(fontWeight: FontWeight.w700)),
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
                            hintText: 'ค้นหาในแชท...',
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
                        tooltip: 'ล้าง',
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
                        _matchedIds.isEmpty ? 'ไม่พบผลลัพธ์' : '${_focusedMatchIndex + 1}/${_matchedIds.length}',
                        style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'ก่อนหน้า',
                        onPressed: _matchedIds.isEmpty ? null : _gotoPrevMatch,
                        icon: const Icon(Icons.keyboard_arrow_up),
                      ),
                      IconButton(
                        tooltip: 'ถัด���ป',
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
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                    }

                    final messages = snapshot.data?.docs ?? [];
                    // cache latest messages for instant search recompute
                    _currentMessages = messages;
                    // Recompute matches when data changes
                    _recomputeMatches(messages);

                    // determine if we should autoscroll (only when new messages arrive and not searching)
                    final prevCount = _prevMessageCount;
                    final hasNew = messages.length > (prevCount < 0 ? 0 : prevCount);
                    final shouldAutoScroll = _searchQuery.isEmpty && hasNew && _nearBottom;

                    // reset visual index map for this build
                    _listIndexById.clear();
                    _lastItemCount = messages.length;
                    _prevMessageCount = messages.length;

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('ยังไม่มีข้อความในแชทนี้\nเริ่มต้นการสนทนาได้เลย!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
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

                    return ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      reverse: _isReversed,
                      itemBuilder: (context, index) {
                        final messageData = messages[index].data() as Map<String, dynamic>;
                        final messageId = messages[index].id;

                        // register visual index for alignment logic
                        _listIndexById[messageId] = index;

                        final isHighlighted = _searchQuery.isNotEmpty && _matchesQuery(messageData, _searchQuery);
                        final isFocused = _searchQuery.isNotEmpty &&
                            _matchedIds.isNotEmpty &&
                            messageId == _matchedIds[_focusedMatchIndex];
                        return RepaintBoundary(
                          child: MessageBubble(
                            key: ValueKey(messageId),
                            messageId: messageId,
                            messageData: messageData,
                            isFromCurrentUser: _isMessageFromCurrentUser(messageData),
                            highlight: isHighlighted,
                            highlightQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                            focused: isFocused,
                            onLongPress: () => _onLongPressMessage(messageData),
                          ),
                        );
                      },
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
                    child: const Text(
                      'คุณไม่มีสิทธิ์ส่งข้อความ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                child: ChatInput(
                  onSendText: (t) => guardAction(context, 'chat:send', () => _sendMessage(t)),
                  onSendImage: (u) => guardAction(context, 'chat:send', () => _sendImageMessage(u)),
                  onSendFile: (fileUrl, fileName) => guardAction(context, 'chat:send', () => _sendFileMessage(fileUrl, fileName)),
                  workspaceId: widget.workspaceId,
                  chatroomId: widget.conversationId,
                  enabled: !_isLoading,
                  replyPreview: _replyPreviewText,
                  onCancelReply: () => setState(() => _replyPreviewText = null),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 8),
                      Text('กำลังส่ง...', style: TextStyle(color: Colors.white)),
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
    // Check if message is from current user
    final senderId = messageData['sender']?['id'] as String?;
    return senderId == _currentUserId;
  }

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
                          'แพลตฟอร์ม: ${_sourceType.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'สถานะ: ${widget.conversationData['chatroom_status'] ?? 'ไม่ระบุ'}',
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
                title: const Text('รายละเอียดแชท'),
                subtitle: Text('ID: ${widget.conversationId}'),
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Workspace'),
                subtitle: Text('ID: ${widget.workspaceId}'),
              ),
              if (widget.conversationData['customerName'] != null)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('ลูกค้า'),
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
        return text.isNotEmpty ? text : '[ข้อความ]';
      case 'image':
        if (text.isNotEmpty) return text;
        return '[รูปภาพ]';
      case 'video':
        if (text.isNotEmpty) return text;
        return '[วิดีโอ]';
      case 'audio':
        final name = (m['fileName'] ?? '').toString();
        return name.isNotEmpty ? 'เสียง: $name' : '[ข้อความเสียง]';
      case 'file':
        final name = (m['fileName'] ?? '').toString();
        return name.isNotEmpty ? 'ไฟล์: $name' : '[ไฟล์]';
      case 'sticker':
        return '[สติ๊กเกอร์]';
      default:
        return text.isNotEmpty ? text : '[$type]';
    }
  }

  Future<void> _onLongPressMessage(Map<String, dynamic> messageData) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Quote Reply'),
              onTap: () => Navigator.pop(ctx, 'reply'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == 'reply') {
      final preview = _makeReplyPreview(messageData);
      setState(() => _replyPreviewText = preview);
    }
  }
}
