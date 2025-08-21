// widgets/conversation_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final String currentUserId;
  final VoidCallback? onTap;

  const ConversationTile({
    Key? key,
    required this.conversation,
    required this.currentUserId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isGroup = (conversation['is_group'] == true || conversation['is_group'] == 'Y');
    final name = (conversation['name'] ?? 'Unknown').toString();
    final lastMsg = (conversation['last_message'] ?? conversation['lastMessage'] ?? '').toString();
    final updatedAt = conversation['updatedAt'] ?? conversation['last_message_info']?['last_upd'];
    final unread = (conversation['unreadCount'] ?? conversation['unread'] ?? 0) as int;

    String timeText = '';
    if (updatedAt is DateTime) {
      timeText = DateFormat('HH:mm').format(updatedAt);
    } else if (updatedAt is int) {
      timeText = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(updatedAt));
    } else if (updatedAt is String && updatedAt.isNotEmpty) {
      final dt = DateTime.tryParse(updatedAt);
      if (dt != null) timeText = DateFormat('HH:mm').format(dt);
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _AvatarWithBadge(
              imageUrl: conversation['avatarUrl'],
              platformIcon: Icons.chat_bubble, // ปรับเป็นไอคอน LINE/IG ตาม platform ถ้ามีฟิลด์
              showPlatform: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // บรรทัดชื่อ + เวลา + badge
                  Row(
                    children: [
                      if (isGroup)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1DB446), // เขียวแบบ LINE
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Group Chat',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeText,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // บรรทัดข้อความล่าสุด + badge ตัวเลขแดง
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg.isEmpty ? 'ส่งรูปภาพ' : lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : unread.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  final String? imageUrl;
  final IconData platformIcon;
  final bool showPlatform;

  const _AvatarWithBadge({
    Key? key,
    this.imageUrl,
    required this.platformIcon,
    this.showPlatform = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty) ? NetworkImage(imageUrl!) : null,
          child: (imageUrl == null || imageUrl!.isEmpty)
              ? const Icon(Icons.person, size: 28, color: Colors.grey)
              : null,
        ),
        if (showPlatform)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF00C300), // โทน LINE
                child: Icon(platformIcon, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
