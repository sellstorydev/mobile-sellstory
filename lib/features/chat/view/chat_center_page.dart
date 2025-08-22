// chat_center_page.dart (Firestore only)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../data/services/chat_service.dart';
import 'chat_screen.dart';

class ChatCenterPage extends StatefulWidget {
  const ChatCenterPage({Key? key}) : super(key: key);

  @override
  State<ChatCenterPage> createState() => _ChatCenterPageState();
}

enum _ChatFilter { all, unread, assigned, inProgress, groupOnly }

class _ChatCenterPageState extends State<ChatCenterPage> {
  final _searchCtrl = TextEditingController();
  _ChatFilter _filter = _ChatFilter.all;
  final ChatService _chatService = ChatService.to;

  String? _currentWorkspaceId;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _initializeWorkspace();
  }

  void _initializeWorkspace() async {
    try {
      _currentWorkspaceId = await _chatService.getUserCurrentWorkspaceId(_uid);
      _currentWorkspaceId ??= await _chatService.getUserFirstWorkspaceId(_uid);
      if (mounted) setState(() {});
    } catch (e) {
      print('Error initializing workspace: $e');
    }
  }

  Stream<QuerySnapshot>? _getChatroomsStream() {
    if (_currentWorkspaceId == null) return null;

    Query q = _chatService.getChatroomsCollection(_currentWorkspaceId!)
        .where('is_deleted', isEqualTo: 'N')
        .orderBy('last_upd', descending: true);

    switch (_filter) {
      case _ChatFilter.unread:
        q = q.where('count', isNotEqualTo: '0');
        break;
      case _ChatFilter.assigned:
        q = q.where('salespersonId', isEqualTo: _uid);
        break;
      case _ChatFilter.inProgress:
        q = q.where('chatroom_status', isEqualTo: 'in_progress');
        break;
      case _ChatFilter.groupOnly:
        q = q.where('is_group', isEqualTo: 'Y');
        break;
      case _ChatFilter.all:
        break;
    }
    return q.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Center'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => _showNewChatDialog(context),
            tooltip: 'แชทใหม่',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Colors.black), // ปรับข้อความเป็นสีดำ
              decoration: InputDecoration(
                hintText: 'ค้นหาด้วย ชื่อ/บริษัท/ข้อความ',
                hintStyle: const TextStyle(color: Colors.grey), // ปรับ hint text
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Quick chips
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                _chip('ทั้งหมด', _ChatFilter.all),
                _chip('ยังไม่ได้อ่าน', _ChatFilter.unread),
                _chip('ได้รับมอบหมาย', _ChatFilter.assigned),
                _chip('กำลังดำเนินการ', _ChatFilter.inProgress),
                _chip('Group Chat', _ChatFilter.groupOnly, leading: const Icon(Icons.groups, size: 16)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Realtime list
          Expanded(
            child: _currentWorkspaceId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _getChatroomsStream(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      final keyword = _searchCtrl.text.trim().toLowerCase();

                      final chatrooms = docs.map((d) {
                        final data = d.data() as Map<String, dynamic>? ?? {};
                        return _Chatroom(
                          id: d.id,
                          name: (data['name'] ?? data['who_name'] ?? 'Unknown') as String,
                          isGroup: (data['is_group'] ?? 'N') == 'Y',
                          avatarUrl: data['avatar'] as String?,
                          contactId: data['contactId'] as String?,
                          lastMessage: data['last_message_info']?['message'] as String?,
                          lastMessageAt: _parseDate(data['last_upd']),
                          unreadCount: int.tryParse(data['count']?.toString() ?? '0') ?? 0,
                          sourceType: data['source_type'] as String?,
                          status: data['chatroom_status'] as String?,
                          isPinned: (data['chat_pin'] ?? 'N') == 'Y',
                          isNew: (data['is_new'] ?? 'N') == 'Y',
                          data: data, // เก็บข้อมูลทั้งหมดไว้ส่งต่อ
                        );
                      }).where((c) {
                        if (keyword.isEmpty) return true;
                        return c.name.toLowerCase().contains(keyword) ||
                            (c.lastMessage ?? '').toLowerCase().contains(keyword);
                      }).toList();

                      if (chatrooms.isEmpty) {
                        return const Center(child: Text('ไม่มีแชทที่ตรงกับเงื่อนไข'));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        itemCount: chatrooms.length,
                        separatorBuilder: (_, __) => const Divider(height: 0),
                        itemBuilder: (context, i) => _ChatroomTile(
                          chatroom: chatrooms[i],
                          onTap: () => _openChat(chatrooms[i]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      try { return DateTime.parse(v); } catch (_) {}
    }
    return null;
  }

  void _openChat(_Chatroom chatroom) {
    if (_currentWorkspaceId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: chatroom.id,
            conversationData: chatroom.data,
            workspaceId: _currentWorkspaceId!,
          ),
        ),
      );
    }
  }

  Widget _chip(String label, _ChatFilter value, {Widget? leading}) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(mainAxisSize: MainAxisSize.min, children: [
          if (leading != null) ...[leading, const SizedBox(width: 6)],
          Text(label),
        ]),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(title: const Text('ทั้งหมด'), onTap: () { setState(() => _filter = _ChatFilter.all); Navigator.pop(context); }),
            ListTile(title: const Text('ยังไม่ได้อ่าน'), onTap: () { setState(() => _filter = _ChatFilter.unread); Navigator.pop(context); }),
            ListTile(title: const Text('ได้รับมอบหมาย'), onTap: () { setState(() => _filter = _ChatFilter.assigned); Navigator.pop(context); }),
            ListTile(title: const Text('กำลังดำเนินการ'), onTap: () { setState(() => _filter = _ChatFilter.inProgress); Navigator.pop(context); }),
            ListTile(title: const Text('Group Chat'), onTap: () { setState(() => _filter = _ChatFilter.groupOnly); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แชทใหม่'),
        content: const Text('ฟีเจอร์นี้จะพร้อมใช้งานเร็วๆ นี้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }
}

// ===== helper models / widgets =====

class _Chatroom {
  final String id;
  final String name;
  final bool isGroup;
  final String? avatarUrl;
  final String? contactId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? sourceType;
  final String? status;
  final bool isPinned;
  final bool isNew;
  final Map<String, dynamic> data;

  _Chatroom({
    required this.id,
    required this.name,
    required this.isGroup,
    this.avatarUrl,
    this.contactId,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
    this.sourceType,
    this.status,
    required this.isPinned,
    required this.isNew,
    required this.data,
  });
}

class _ChatroomTile extends StatelessWidget {
  final _Chatroom chatroom;
  final VoidCallback? onTap;
  const _ChatroomTile({required this.chatroom, this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: chatroom.avatarUrl != null ? NetworkImage(chatroom.avatarUrl!) : null,
            child: chatroom.avatarUrl == null
                ? Text(_initials(chatroom.name), style: const TextStyle(fontWeight: FontWeight.w600))
                : null,
          ),
          if (chatroom.contactId != null)
            // Positioned(right: 0, bottom: 0, child: _PresenceDot(uid: chatroom.contactId!)),
          if (chatroom.isPinned)
            Positioned(left: 0, top: 0, child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              child: const Icon(Icons.push_pin, size: 10, color: Colors.white),
            )),
        ],
      ),
      title: Row(
        children: [
          if (chatroom.isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(12)),
              child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          if (chatroom.isGroup)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(12)),
              child: const Text('Group', style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
          if (chatroom.sourceType != null)
            Container(
              margin: const EdgeInsets.only(left: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: _getSourceColor(chatroom.sourceType!), borderRadius: BorderRadius.circular(12)),
              child: Text(chatroom.sourceType!.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(chatroom.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      subtitle: Text(chatroom.lastMessage ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(chatroom.lastMessageAt != null ? timeago.format(chatroom.lastMessageAt!) : '', style: t.bodySmall),
          const SizedBox(height: 6),
          if (chatroom.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
              child: Text('${chatroom.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].isNotEmpty ? parts[0][0] : '') + (parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '');
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'line': return Colors.green;
      case 'facebook': return Colors.blue;
      case 'instagram': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
//
// class _PresenceDot extends StatelessWidget {
//   final String uid;
//   const _PresenceDot({required this.uid});
//
//   @override
//   Widget build(BuildContext context) {
//     final ref = FirebaseDatabase.instance.ref('presences/$uid/lastSeen');
//     return StreamBuilder<DatabaseEvent>(
//       stream: ref.onValue,
//       builder: (_, snap) {
//         int? lastSeenMs;
//         if (snap.hasData && snap.data!.snapshot.value != null && snap.data!.snapshot.value is int) {
//           lastSeenMs = snap.data!.snapshot.value as int;
//         }
//         final online = lastSeenMs != null &&
//             DateTime.now().millisecondsSinceEpoch - lastSeenMs! < 2 * 60 * 1000;
//         return Container(
//           width: 14,
//           height: 14,
//           decoration: BoxDecoration(
//             color: online ? Colors.green : Colors.grey,
//             shape: BoxShape.circle,
//             border: Border.all(color: Colors.white, width: 2),
//           ),
//         );
//       },
//     );
//   }
// }
