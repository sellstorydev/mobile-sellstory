import 'package:flutter/material.dart';


class ChatHeaderLine extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? avatarUrl;
  final bool showBack;
  final bool showAutoReplyBubble; // จุดส้มมุมบนซ้าย
  final String platform;          // LINE / FACEBOOK / INSTAGRAM
  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final VoidCallback? onMore;

  const ChatHeaderLine({
    Key? key,
    required this.title,
    this.avatarUrl,
    this.platform = 'LINE',
    this.showBack = false,
    this.showAutoReplyBubble = true,
    this.onBack,
    this.onSearch,
    this.onMore,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final platformUpper = platform.toUpperCase();

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      centerTitle: false,
      titleSpacing: showBack ? 0 : 8,
      leading: showBack
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
        onPressed: onBack ?? () => Navigator.maybePop(context),
      )
          : null,
      title: Row(
        children: [
          // Avatar + overlays
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? NetworkImage(avatarUrl!)
                      : null,
                  backgroundColor: const Color(0xFFE9ECEF),
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? Text(
                    title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
                  )
                      : null,
                ),
              ),

              // bubble สีส้ม (มุมซ้ายบน)
              if (showAutoReplyBubble)
                Positioned(
                  left: -6, top: -6,
                  child: _OrangeBubble(),
                ),

              // Platform badge (มุมขวาล่าง) รองรับ LINE / FACEBOOK / INSTAGRAM
              if (_PlatformCircleBadge.supports(platformUpper))
                Positioned(
                  right: -2, bottom: -2,
                  child: _PlatformCircleBadge(platform: platformUpper),
                ),
            ],
          ),

          const SizedBox(width: 12),

          // ชื่อห้อง
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.black87),
          onPressed: onSearch,
          splashRadius: 22,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: onMore,
          splashRadius: 22,
        ),
        const SizedBox(width: 4),
      ],
      iconTheme: const IconThemeData(color: Colors.black87),
    );
  }
}

class _OrangeBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.chat_bubble, size: 12, color: Colors.white),
    );
  }
}

class _PlatformCircleBadge extends StatelessWidget {
  final String platform; // uppercase expected
  const _PlatformCircleBadge({required this.platform});

  static bool supports(String p) {
    switch (p) {
      case 'LINE':
      case 'FACEBOOK':
      case 'INSTAGRAM':
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (platform) {
      case 'LINE':
        return Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF06C755), // LINE green
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: const FittedBox(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                'LINE',
                style: TextStyle(
                    color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, height: 1),
              ),
            ),
          ),
        );
      case 'FACEBOOK':
        return Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2), // Facebook blue
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: const FittedBox(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                'FB',
                style: TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, height: 1),
              ),
            ),
          ),
        );
      case 'INSTAGRAM':
        return Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF), Color(0xFF515BD4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: const FittedBox(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3),
              child: Text(
                'IG',
                style: TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, height: 1),
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
