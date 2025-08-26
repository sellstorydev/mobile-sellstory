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


  String _detectPlatform(Map<String, dynamic> c) {
    final conn = c['connection'];
    final nestedPlatform = (conn is Map ? conn['platform'] : null)?.toString().toLowerCase();
    // Prefer explicit platform/source fields first, then fallbacks
    final candidates = <String?>[
      nestedPlatform,
      c['platform']?.toString(),
      c['sourceType']?.toString(),
      c['source_type']?.toString(),
      c['source']?.toString(),
      c['channel']?.toString(),
      c['connectionPlatform']?.toString(),
    ]
        .whereType<String>()
        .map((s) => s.toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    final raw = candidates.isNotEmpty ? candidates.first : '';

    if (raw.contains('facebook') || raw == 'fb') return 'facebook';
    if (raw.contains('instagram') || raw == 'ig') return 'instagram';
    if (raw.contains('line')) return 'line';
    // Heuristics by available IDs
    if ((c['pageId'] ?? '').toString().isNotEmpty) return 'facebook';
    if ((c['igUserId'] ?? '').toString().isNotEmpty) return 'instagram';
    if ((c['channelId'] ?? c['botId'] ?? '').toString().isNotEmpty) return 'line';
    return 'unknown';
  }

  String _pageName(Map<String, dynamic> c) {
    final direct = (c['pageName'] ?? '').toString();
    if (direct.isNotEmpty) return direct;
    final conn = c['connection'];
    if (conn is Map) {
      final nested = (conn['pageName'] ?? conn['name'] ?? conn['displayName'] ?? '').toString();
      if (nested.isNotEmpty) return nested;
    }
    // Other common aliases we might carry along
    final alt = (c['providerName'] ?? c['connectionName'] ?? c['igUsername'] ?? '').toString();
    if (alt.isNotEmpty) return alt;
    return '';
  }

  (_PlatformIconColor, IconData) _platformStyle(String platform) {
    switch (platform) {
      case 'facebook':
        return ((_PlatformIconColor(const Color(0xFF1877F2))), Icons.public);
      case 'instagram':
        return ((_PlatformIconColor(const Color(0xFFE1306C))), Icons.camera_alt_outlined);
      case 'line':
        return ((_PlatformIconColor(const Color(0xFF00C300))), Icons.chat);
      default:
        return ((_PlatformIconColor(Colors.grey.shade600)), Icons.chat_bubble_outline);
    }
  }

  String _platformLabel(String platform) {
    switch (platform) {
      case 'facebook':
        return 'Facebook';
      case 'instagram':
        return 'Instagram';
      case 'line':
        return 'LINE';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed unused isGroup variable
    final name = (conversation['name'] ?? 'Unknown').toString();
    final lastMsg = (conversation['last_message'] ?? conversation['lastMessage'] ?? '').toString();
    // Prefer the normalized field, fallback to raw sources
    final dynamic updatedAt = conversation['lastMessageAt'] ?? conversation['last_message_info']?['last_upd'] ?? conversation['updatedAt'];
    final unread = (conversation['unreadCount'] ?? conversation['unread'] ?? 0) as int;

    final platform = _detectPlatform(conversation);
    final pageTitle = _pageName(conversation);
    final style = _platformStyle(platform);
    final Color platformColor = style.$1.color;
    final IconData platformIcon = style.$2;

    // Title to show on the top line: prefer pageName/providerName, else platform label
    final topTitle = pageTitle.isNotEmpty ? pageTitle : _platformLabel(platform);

    String timeText = '';
    if (updatedAt is DateTime) {
      timeText = DateFormat('HH:mm').format(updatedAt);
    } else if (updatedAt is int) {
      timeText = DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(updatedAt));
    } else if (updatedAt is String && updatedAt.isNotEmpty) {
      final dt = DateTime.tryParse(updatedAt);
      if (dt != null) {
        timeText = DateFormat('HH:mm').format(dt);
      }
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
              platformIcon: platformIcon,
              platformColor: platformColor,
              showPlatform: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top line: provider/page name with platform icon
                  if (topTitle.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(platformIcon, size: 14, color: platformColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            topTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: platformColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                  ],

                  // Name row with time
                  Row(
                    children: [
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

                  // Last message + unread badge
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

class _PlatformIconColor {
  final Color color;
  const _PlatformIconColor(this.color);
}

class _AvatarWithBadge extends StatelessWidget {
  final String? imageUrl;
  final IconData platformIcon;
  final bool showPlatform;
  final Color platformColor;

  const _AvatarWithBadge({
    Key? key,
    this.imageUrl,
    required this.platformIcon,
    this.showPlatform = true,
    this.platformColor = const Color(0xFF00C300),
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
                backgroundColor: platformColor,
                child: Icon(platformIcon, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
