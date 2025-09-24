import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get/get.dart';
import '../../../app/routes.dart';
import '../../board/controller/board_controller.dart';
import '../../../domain/entities/job_card.dart';
import '../../../data/services/mobile_permissions_service.dart';
import '../../../core/network/mobile_api.dart';
import '../../chat/view/chat_screen.dart';


class NotificationsPage extends StatefulWidget {
  final String workspaceId;
  const NotificationsPage({super.key, required this.workspaceId});


  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();
  final bool _debug = false; // set true for verbose logging

  // Pagination state
  final List<DocumentSnapshot<Map<String, dynamic>>> _docs = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _disposed = false;
  DateTime _lastLoadMoreAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    // Initialize Thai locale data for Intl formatting (safe to call multiple times)
    initializeDateFormatting('th_TH');
    _scrollController.addListener(_onScroll);
    _fetchInitial();
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      final now = DateTime.now();
      if (now.difference(_lastLoadMoreAt).inMilliseconds > 800) {
        _lastLoadMoreAt = now;
        _loadMore();
      }
    }
  }

  Future<void> _fetchInitial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoadingInitial = false);
      return;
    }
    try {
      if (_debug) debugPrint('🔄 INIT: Fetching first page');
      final snap = await _baseQuery(user.uid).limit(_pageSize).get();
      if (_disposed) return;
      setState(() {
        _docs.clear();
        _docs.addAll(snap.docs);
        _lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
        _hasMore = snap.docs.length == _pageSize;
        _isLoadingInitial = false;
      });
      if (_debug)
        debugPrint('✅ INIT: Loaded ${snap.docs.length} docs hasMore=$_hasMore');
    } catch (e) {
      if (_debug) debugPrint('❌ INIT ERROR: $e');
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _loadMore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      Query<Map<String, dynamic>> q = _baseQuery(user.uid).limit(_pageSize);
      if (_lastDoc != null) {
        q = q.startAfterDocument(_lastDoc!);
      }
      final snap = await q.get();
      if (_disposed) return;
      setState(() {
        _docs.addAll(snap.docs);
        if (snap.docs.isNotEmpty) {
          _lastDoc = snap.docs.last;
        }
        if (snap.docs.length < _pageSize) _hasMore = false;
        _isLoadingMore = false;
      });
      if (_debug)
        debugPrint(
          '➕ PAGE: +${snap.docs.length} total=${_docs.length} hasMore=$_hasMore',
        );
    } catch (e) {
      if (_debug) debugPrint('❌ LOAD MORE ERROR: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() async {
    _hasMore = true;
    _lastDoc = null;
    _isLoadingInitial = true;
    await _fetchInitial();
  }

  Query<Map<String, dynamic>> _baseQuery(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('workspaceId', isEqualTo: widget.workspaceId)
        .orderBy('timestamp', descending: true);
  }

  Future<void> _markAsRead(DocumentReference ref) async {
    try {
      await ref.update({'read': true});
    } catch (_) {}
  }

  String _formatThai(DateTime? dt) {
    if (dt == null) return '-';
    try {
      final local = dt.toLocal();
      return DateFormat('d MMM yyyy HH:mm', 'th_TH').format(local);
    } catch (_) {
      return dt.toLocal().toIso8601String();
    }
  }

  Uri? _parseLink(String link) {
    final trimmed = link.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('/?')) {
      // Convert "/?x=y" to a valid URI for parsing
      return Uri.parse('app://local$trimmed');
    }
    if (trimmed.startsWith('/')) {
      // Other app-internal paths
      return Uri.parse('app://local$trimmed');
    }
    // Try raw URI
    return Uri.tryParse(trimmed);
  }

  Future<String?> _getIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _openWebview({
    required String pathOrFullUrl,
    required String title,
    Map<String, String>? extraParams,
  }) async {
    // Build full URL
    final isFull = pathOrFullUrl.startsWith('http://') || pathOrFullUrl.startsWith('https://');
    final base = isFull ? '' : MobileApiConfig.baseUrl;
    final url = isFull ? pathOrFullUrl : '$base$pathOrFullUrl';

    // Attach token/workspaceId
    final params = <String, String>{
      'workspaceId': widget.workspaceId,
      ...?extraParams,
    };
    final token = await _getIdToken();
    if (token != null && token.isNotEmpty) {
      params['token'] = token;
    }

    Get.toNamed(
      AppRoutes.webview,
      parameters: {
        'url': url,
        'title': title,
      },
      arguments: params,
    );
  }

  Future<void> _openChat(String chatId) async {
    try {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: chatId,
            conversationData: {
              'id': chatId,
              'name': 'Chat',
            },
            workspaceId: widget.workspaceId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_open_chat'.tr}: $e')),
      );
    }
  }

  Future<void> _handleLinkTap(String rawLink) async {
    final uri = _parseLink(rawLink);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('invalid_link'.tr)));
      return;
    }

    // Handle board/card deep links from query
    final q = uri.queryParameters;
    final cardId = q['cardId'] ?? q['cardID'] ?? q['cid'];
    final boardId = q['boardId'] ?? q['boardID'] ?? q['bid'];

    if (cardId != null && cardId.isNotEmpty) {
      await _openCard(cardId: cardId, boardId: boardId);
      return;
    }

    if (boardId != null && boardId.isNotEmpty) {
      await _openBoard(boardId);
      return;
    }

    // Handle path-based routes
    final path = uri.path;

    // Live chat: /live-chat?chatId=xxx
    if (path == '/live-chat') {
      final chatId = q['chatId'] ?? q['chatID'] ?? q['cid'];
      if (chatId != null && chatId.isNotEmpty) {
        await _openChat(chatId);
        return;
      }
    }

    // Approvals: /approvals?quoteId=xxx
    if (path == '/approvals') {
      final quoteId = q['quoteId'] ?? q['quotationId'] ?? q['qid'];
      await _openWebview(
        pathOrFullUrl: '/approvals',
        title: 'Approvals',
        extraParams: {
          if (quoteId != null && quoteId.isNotEmpty) 'quoteId': quoteId,
        },
      );
      return;
    }

    // Sales documents: /sales-docs/...
    if (path.startsWith('/sales-docs/')) {
      await _openWebview(
        pathOrFullUrl: path,
        title: 'Document',
      );
      return;
    }

    // Fallback: if it's an absolute URL, open in webview; otherwise show unsupported
    if (rawLink.startsWith('http://') || rawLink.startsWith('https://')) {
      await _openWebview(pathOrFullUrl: rawLink, title: 'Web');
      return;
    }

    // Optional: ignore silently or notify
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text('${'unsupported_link'.tr}: ${uri.toString()}')),
    // );
  }

  Future<void> _ensureWorkspace(String workspaceId) async {
    final ctrl = Get.find<BoardController>();
    if (ctrl.currentWorkspaceId.value != workspaceId) {
      await ctrl.switchWorkspace(workspaceId);
    }
  }

  bool _canViewCard(JobCard card, String uid) {
    final svc = MobilePermissionsService.to;
    if (svc.isOwner || svc.can('jobcard:view:all')) return true;
    if (svc.can('jobcard:view:assigned')) {
      if (card.assignedTo == uid) return true;
      if (card.collaborators.contains(uid)) return true;
      if (card.watchers.contains(uid)) return true;
      if (card.createdBy == uid) return true;
    }
    return false;
  }

  Future<bool> _ensureCanOpenBoard() async {
    final svc = MobilePermissionsService.to;
    if (svc.isOwner || svc.can('jobcard:view:all') || svc.can('jobcard:view:assigned')) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('no_permission_open_board'.tr)),
    );
    return false;
  }


  Future<void> _openBoard(String boardId) async {
    try {
      if (!await _ensureCanOpenBoard()) return;
      final ctrl = Get.find<BoardController>();
      await _ensureWorkspace(widget.workspaceId);
      await ctrl.switchBoard(boardId);
      Get.toNamed(AppRoutes.board);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_goto_board'.tr}: $e')),
      );
    }
  }

  Future<void> _openCard({required String cardId, String? boardId}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';
      final ctrl = Get.find<BoardController>();
      await _ensureWorkspace(widget.workspaceId);
      if (boardId != null && boardId.isNotEmpty) {
        if (!await _ensureCanOpenBoard()) return;
        await ctrl.switchBoard(boardId);
      } else if (ctrl.currentBoardId.value.isEmpty && ctrl.boards.isNotEmpty) {
        if (!await _ensureCanOpenBoard()) return;
        await ctrl.switchBoard(ctrl.boards.first.id);
      }

      if (ctrl.lanes.isEmpty) {
        await ctrl.load();
      }


      JobCard? found;
      for (final lane in ctrl.lanes) {
        found = lane.cards.firstWhereOrNull((c) => c.id == cardId);
        if (found != null) break;
      }

      if (found != null) {
        // Permission check for viewing this card
        if (!_canViewCard(found, uid)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('no_permission_view_card'.tr)),
          );
          return;
        }
        Get.toNamed(AppRoutes.editCard, arguments: found);
      } else {
        // Try searching other boards if boardId was not provided
        if (boardId == null || boardId.isEmpty) {
          for (final b in ctrl.boards) {
            await ctrl.switchBoard(b.id);
            if (ctrl.lanes.isEmpty) await ctrl.load();
            for (final lane in ctrl.lanes) {
              final c = lane.cards.firstWhereOrNull((x) => x.id == cardId);
              if (c != null) {
                if (!_canViewCard(c, uid)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('no_permission_view_card'.tr)),
                  );
                  return;
                }
                Get.toNamed(AppRoutes.editCard, arguments: c);
                return;
              }
            }
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('card_not_found_in_board'.tr)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${'failed_open_card'.tr}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please sign in to view notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : _buildNotificationsList(_docs),
    );
  }

  Widget _buildNotificationsList(List<DocumentSnapshot<Map<String, dynamic>>> docs) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: docs.isEmpty ? 1 : docs.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        addAutomaticKeepAlives: true,
        addRepaintBoundaries: true,
        itemBuilder: (context, index) {
          if (docs.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(48.0),
              child: Center(child: Text('No notifications')),
            );
          }

          if (index == docs.length) {
            if (_isLoadingMore) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!_hasMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text('— End —', style: TextStyle(color: Colors.grey)),
                ),
              );
            }
            return const SizedBox(height: 24);
          }

          final doc = docs[index];
          final data = doc.data();
          final title = (data?['title'] ?? 'Notification').toString();
          final message = (data?['message'] ?? '').toString();
          final read = (data?['read'] ?? false) == true;
          final tsRaw = data?['timestamp'];
          DateTime? ts;
          if (tsRaw is int) {
            ts = DateTime.fromMillisecondsSinceEpoch(tsRaw);
          } else if (tsRaw is Timestamp) {
            ts = tsRaw.toDate();
          }

          return Container(
            key: ValueKey(doc.id),
            child: ListTile(
              leading: Icon(
                read ? Icons.notifications_none : Icons.notifications_active,
                color: read ? Colors.grey : Colors.orange,
              ),
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isNotEmpty)
                    Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (ts != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatThai(ts),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                ],
              ),
              trailing: read
                  ? null
                  : const Icon(Icons.brightness_1, size: 10, color: Colors.orange),
              onTap: () async {
                if (!read) await _markAsRead(doc.reference);
                final link = (data?['link'] ?? '').toString();
                if (link.isNotEmpty) {
                  await _handleLinkTap(link);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('no_link_for_notification'.tr)),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
