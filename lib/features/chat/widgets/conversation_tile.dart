// widgets/conversation_tile.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/widgets/permission_guard.dart';

class ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final String currentUserId;
  final VoidCallback? onTap;
  // Slide actions
  final VoidCallback? onAddHashtag;
  final VoidCallback? onAssignSale;
  final VoidCallback? onChangeStatus;
  // New: start (left-to-right) actions
  final VoidCallback? onToggleBot;
  final VoidCallback? onTogglePin;
  


  const ConversationTile({
    Key? key,
    required this.conversation,
    required this.currentUserId,
    this.onTap,
    this.onAddHashtag,
    this.onAssignSale,
    this.onChangeStatus,
    this.onToggleBot,
    this.onTogglePin,
  }) : super(key: key);


  String _detectPlatform(Map<String, dynamic> c) {
    final conn = c['connection'];

    // print("----------------");
    // print(c["source_type"]);
    // print("----------------");
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

    final raw = (candidates.isNotEmpty ? candidates.first : '' ) + c["source_type"];

    // print("platfrom : "+raw);

    // New channels detection
    if (raw.contains('lazada')) return 'lazada';
    if (raw.contains('unknown')) return 'unknown';
    if (raw.contains('shopee')) return 'shopee';
    if (raw.contains('tiktok')) return 'tiktok';
    if (raw.contains('whatsapp') || raw.contains('whatsapp')) return 'whatsapp';

    if (raw.contains('facebook') || raw == 'fb') return 'facebook';
    if (raw.contains('instagram') || raw == 'ig') return 'instagram';
    if (raw.contains('line')) return 'line';
    // Heuristics by available IDs
    if ((c['pageId'] ?? '').toString().isNotEmpty) return 'facebook';
    if ((c['igUserId'] ?? '').toString().isNotEmpty) return 'instagram';
    if ((c['channelId'] ?? c['botId'] ?? '').toString().isNotEmpty) return 'line';
    if ((c['tiktokUserId'] ?? '').toString().isNotEmpty) return 'tiktok';
    if ((c['lazadaShopId'] ?? '').toString().isNotEmpty) return 'lazada';
    if ((c['shopeeShopId'] ?? '').toString().isNotEmpty) return 'shopee';
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
    // print("platform :  "+platform);
    switch (platform) {
      case 'facebook':
        return ((_PlatformIconColor(const Color(0xFF1877F2))), FontAwesomeIcons.facebook);
      case 'instagram':
        return ((_PlatformIconColor(const Color(0xFFE1306C))), FontAwesomeIcons.instagram);
      case 'line':
        return ((_PlatformIconColor(const Color(0xFF00C300))), FontAwesomeIcons.line);
      case 'whatsapp': // WhatsApp like channel
        return ((_PlatformIconColor(const Color(0xFF25D366))), FontAwesomeIcons.whatsapp);
      case 'tiktok':
        return ((_PlatformIconColor(const Color(0xFF010101))), FontAwesomeIcons.tiktok);
      case 'lazada':
        return ((_PlatformIconColor(const Color(0xFFFF5C00))), Icons.shopping_bag_outlined);
      case 'shopee':
        return ((_PlatformIconColor(const Color(0xFFFA5300))), Icons.storefront_outlined);
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
      case 'whatsapp':
        return 'Whatsapp';
      case 'tiktok':
        return 'TikTok';
      case 'lazada':
        return 'Lazada';
      case 'shopee':
        return 'Shopee';
      default:
        return '';
    }
  }

  Color _parseHexColor(String? hex, {Color fallback = const Color(0xFFF1F5F9)}) {
    if (hex == null) return fallback;
    String h = hex.trim();
    if (h.isEmpty) return fallback;
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return fallback;
    try {
      final v = int.parse(h, radix: 16);
      return Color(v);
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    // print(conversation);
    // Removed unused isGroup variable
    final name = (conversation['name'] ?? 'Unknown').toString();
    final chat_provider_name = (conversation['chat_provider_name'] ?? '').toString();
    final lastMsg = (conversation['last_message'] ?? conversation['lastMessage'] ?? '').toString();
    // Prefer the normalized field, fallback to raw sources
    final dynamic updatedAt = conversation['lastMessageAt'] ?? conversation['last_message_info']?['last_upd'] ?? conversation['updatedAt'];
    final unread = (conversation['unreadCount'] ?? conversation['unread'] ?? 0) as int;

    final platform = _detectPlatform(conversation);
    // final pageTitle = _pageName(conversation);
    final style = _platformStyle(platform);
    final Color platformColor = style.$1.color;
    final IconData platformIcon = style.$2;

    final bool isPinned = (conversation['isPinned'] == true) ||
        ((conversation['chat_pin'] ?? '').toString().toUpperCase() == 'Y');

    // Bot status detection
    bool isBotEnabled = false;
    final dynamic botRaw = conversation['bot_status'] ?? conversation['isOnline'];
    if (botRaw is String) {
      isBotEnabled = botRaw.toUpperCase() == 'Y';
    } else if (botRaw is bool) {
      isBotEnabled = botRaw;
    }

    // Title to show on the top line: prefer pageName/providerName, else platform label
    // final topTitle = pageTitle.isNotEmpty ? pageTitle : _platformLabel(platform);

    String timeText = '';
    // Normalize updatedAt to UTC then shift to Thai time (UTC+7)
    DateTime? _asUtc(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v.isUtc ? v : v.toUtc();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
      if (v is String && v.isNotEmpty) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed.isUtc ? parsed : parsed.toUtc();
      }
      return null;
    }
    final utc = _asUtc(updatedAt);
    if (utc != null) {
      final thai = utc.add(const Duration(hours: 7)); // UTC+7
      timeText = DateFormat('HH:mm').format(thai);
    }


    final content = InkWell(
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
              showPlatform: platform != 'unknown', // hide icon if platform not recognized
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top line: provider/page name with platform icon
                  if (chat_provider_name.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(platformIcon, size: 14, color: platformColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            chat_provider_name,
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

                  // Name row with time and pin
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (isPinned) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.push_pin, size: 16, color: Colors.amber.shade700),
                      ],
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
                          lastMsg.isEmpty ? 'chat_sent_image'.tr : lastMsg,
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
                  // Hashtags
                  Builder(builder: (_) {
                    // Prefer enriched meta list: [{name: #Lead, color: #10b981}, ...]
                    final rawMeta = conversation['hashtagMeta'];
                    final List<Map<String, dynamic>> meta = (rawMeta is List)
                        ? rawMeta
                            .whereType<Map>()
                            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
                            .toList()
                        : const <Map<String, dynamic>>[];

                    List<({String name, String? color})> tagsWithColor;
                    if (meta.isNotEmpty) {
                      tagsWithColor = meta.map((m) {
                        final name = (m['name'] ?? m['title'] ?? '').toString();
                        final color = (m['color'] ?? '').toString();
                        return (name: name, color: color.isNotEmpty ? color : null);
                      }).where((t) => t.name.trim().isNotEmpty).toList();
                    } else {
                      // Fallback to legacy plain list without color
                      final rawTags = conversation['hashtags'];
                      final tags = (rawTags is List)
                          ? rawTags.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList()
                          : const <String>[];
                      tagsWithColor = tags.map((n) => (name: n, color: null)).toList();
                    }

                    if (tagsWithColor.isEmpty) return const SizedBox.shrink();
                    const maxShow = 3;
                    final show = tagsWithColor.take(maxShow).toList();
                    final more = tagsWithColor.length - show.length;

                    Color chipBg(String? hex) {
                      return _parseHexColor(hex, fallback: const Color(0xFF64748B));
                    }

                    Color chipBorder(String? hex) {
                      return _parseHexColor(hex, fallback: const Color(0xFF64748B));
                    }

                    Color chipText(String? hex) {
                      return Colors.white;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: -6,
                        children: [
                          for (final t in show)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: chipBg(t.color),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: chipBorder(t.color)),
                              ),
                              child: Text(
                                t.name.startsWith('#') ? t.name : '#${t.name}',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: chipText(t.color)),
                              ),
                            ),
                          if (more > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: Text(
                                '+$more',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  // Assignees
                  Builder(builder: (_) {
                    final rawNames = conversation['assigneeNames'];
                    final names = (rawNames is List)
                        ? rawNames.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList()
                        : const <String>[];
                    if (names.isNotEmpty) {
                      final joined = names.join(', ');
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline, size: 14, color: Colors.black54),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                joined,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      );
                    }


                    // Fallback: resolve from chatroom-level assignees (assigneeIds or assignees)
                    final rawIds = conversation['assigneeIds'] ?? conversation['assignees'];
                    final ids = (rawIds is List)
                        ? rawIds.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList()
                        : const <String>[];
                    if (ids.isEmpty) return const SizedBox.shrink();

                    Future<List<String>> _loadNames(List<String> uids) async {
                      // Limit to reduce reads; UI shows first few names
                      final limited = uids.take(5).toList();
                      final results = await Future.wait(limited.map((uid) async {
                        try {
                          final u = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                          final m = u.data() ?? {};
                          final dn = (m['displayName'] ?? m['name'] ?? '').toString().trim();
                          return dn.isNotEmpty ? dn : uid;
                        } catch (_) {
                          return uid;
                        }
                      }));
                      return results;
                    }

                    return FutureBuilder<List<String>>(
                      future: _loadNames(ids),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        final fetched = (snap.data ?? []).where((s) => s.trim().isNotEmpty).toList();
                        if (fetched.isEmpty) return const SizedBox.shrink();
                        final joined = fetched.join(', ');
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: Colors.black54),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  joined,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),


                  // Linked items (Customer, Job Card)
                  Builder(builder: (_) {
                    String? customerId = (conversation['customerId'] ?? conversation['customer_id'] ?? conversation['customer']?['id'])?.toString();
                    String customerName = (conversation['customerName'] ?? conversation['customer']?['name'] ?? '').toString();
                    if ((customerName).trim().isEmpty) customerName = '';

                    final jobCardId = (conversation['jobCardId'] ?? '').toString();
                    final jobCardTitle = (conversation['jobCardTitle'] ?? '').toString();

                    final chips = <Widget>[];

                    if ((customerId ?? '').isNotEmpty) {
                      final text = customerName.isNotEmpty ? customerName : '${'customer'.tr}: $customerId';
                      chips.add(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF334155)),
                              const SizedBox(width: 6),
                              Text(
                                text,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (jobCardId.isNotEmpty || jobCardTitle.isNotEmpty) {
                      final text = jobCardTitle.isNotEmpty ? jobCardTitle : 'Job Card: $jobCardId';
                      chips.add(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.assignment_outlined, size: 14, color: Color(0xFF1D4ED8)),
                              const SizedBox(width: 6),
                              Text(
                                text,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1D4ED8)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (chips.isEmpty) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: -6,
                        children: chips,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Slidable(
      key: ValueKey(conversation['id'] ?? name),
      closeOnScroll: true,
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.48, // 2 actions * 0.24
        children: [
          PermissionGuard(
            permission: 'chat:bot:manage',
            child: CustomSlidableAction(
              onPressed: (_) => onToggleBot?.call(),
              backgroundColor: const Color(0xFFFF7A00),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    isBotEnabled ? 'chat_bot_disable'.tr : 'chat_bot_enable'.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          PermissionGuard(
            permission: 'chat:manage',
            child: CustomSlidableAction(
              onPressed: (_) => onTogglePin?.call(),
              backgroundColor: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.push_pin, color: Colors.white, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    isPinned ? 'unpin'.tr : 'pin'.tr,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.72, // 3 actions * 0.24
        children: [
          PermissionGuard(
            permission: 'chat:manage',
            child: CustomSlidableAction(
              onPressed: (_) => onAddHashtag?.call(),
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.tag, color: Colors.white, size: 22),
                  SizedBox(height: 4),
                  Text(
                    'Hashtag',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          PermissionGuard(
            permission: 'customer:edit:all',
            child: CustomSlidableAction(
              onPressed: (_) => onAssignSale?.call(),
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.person_add, color: Colors.white, size: 22),
                  SizedBox(height: 4),
                  Text(
                    'Assign',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          PermissionGuard(
            permission: 'chat:manage',
            child: CustomSlidableAction(
              onPressed: (_) => onChangeStatus?.call(),
              backgroundColor: Colors.deepOrange,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.flag, color: Colors.white, size: 22),
                  SizedBox(height: 4),
                  Text(
                    'Status',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      child: content,
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
                    color: Colors.black.withValues(alpha: 0.06),
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
