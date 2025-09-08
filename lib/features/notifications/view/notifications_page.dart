import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get/get.dart';
import '../../../app/routes.dart';
import '../../board/controller/board_controller.dart';
import '../../../domain/entities/job_card.dart';

class NotificationsPage extends StatefulWidget {
  final String workspaceId;
  const NotificationsPage({super.key, required this.workspaceId});


  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const int _pageSize = 20;
  int _limit = _pageSize;
  final ScrollController _scrollController = ScrollController();
  DateTime _lastLoadMoreAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    // Initialize Thai locale data for Intl formatting (safe to call multiple times)
    initializeDateFormatting('th_TH');
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      final now = DateTime.now();
      if (now.difference(_lastLoadMoreAt).inMilliseconds > 500) {
        setState(() {
          _limit += _pageSize;
          _lastLoadMoreAt = now;
        });
      }
    }
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

  Future<void> _handleLinkTap(String rawLink) async {
    final uri = _parseLink(rawLink);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลิงก์ไม่ถูกต้อง')));
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
    if (path.startsWith('/sales-docs/')) {
      // Not yet supported in-app; show info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปิดเอกสาร: $path')),
      );
      return;
    }

    // Fallback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ยังไม่รองรับลิงก์นี้: ${uri.toString()}')),
    );
  }

  Future<void> _ensureWorkspace(String workspaceId) async {
    final ctrl = Get.find<BoardController>();
    if (ctrl.currentWorkspaceId.value != workspaceId) {
      await ctrl.switchWorkspace(workspaceId);
    }
  }

  Future<void> _openBoard(String boardId) async {
    try {
      final ctrl = Get.find<BoardController>();
      await _ensureWorkspace(widget.workspaceId);
      await ctrl.switchBoard(boardId);
      Get.toNamed(AppRoutes.board);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไปที่บอร์ดไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _openCard({required String cardId, String? boardId}) async {
    try {
      final ctrl = Get.find<BoardController>();
      await _ensureWorkspace(widget.workspaceId);
      if (boardId != null && boardId.isNotEmpty) {
        await ctrl.switchBoard(boardId);
      } else if (ctrl.currentBoardId.value.isEmpty && ctrl.boards.isNotEmpty) {
        await ctrl.switchBoard(ctrl.boards.first.id);
      }

      // Ensure data is loaded
      if (ctrl.lanes.isEmpty) {
        await ctrl.load();
      }

      JobCard? found;
      for (final lane in ctrl.lanes) {
        found = lane.cards.firstWhereOrNull((c) => c.id == cardId);
        if (found != null) break;
      }

      if (found != null) {
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
                Get.toNamed(AppRoutes.editCard, arguments: c);
                return;
              }
            }
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบการ์ดนี้ในบอร์ด')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปิดการ์ดไม่สำเร็จ: $e')),
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

    final stream = _baseQuery(user.uid).limit(_limit).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? const [];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _limit = _pageSize);
              // Small delay to allow stream to reflect the new limit
              await Future.delayed(const Duration(milliseconds: 200));
            },
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: docs.isEmpty ? 1 : docs.length + 1,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('No notifications')),
                  );
                }

                if (index == docs.length) {
                  // Footer spacing; auto-load triggers via scroll listener
                  return const SizedBox(height: 24);
                }

                final doc = docs[index];
                final data = doc.data();
                final title = (data['title'] ?? 'Notification').toString();
                final message = (data['message'] ?? '').toString();
                final read = (data['read'] ?? false) == true;
                final tsRaw = data['timestamp'];
                DateTime? ts;
                if (tsRaw is int) {
                  ts = DateTime.fromMillisecondsSinceEpoch(tsRaw);
                } else if (tsRaw is Timestamp) {
                  ts = tsRaw.toDate();
                }

                return ListTile(
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
                    final link = (data['link'] ?? '').toString();
                    if (link.isNotEmpty) {
                      await _handleLinkTap(link);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ไม่มีลิงก์สำหรับการแจ้งเตือนนี้')),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
