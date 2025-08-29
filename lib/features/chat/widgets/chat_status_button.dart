import 'package:flutter/material.dart';

const _accent = Color(0xFFFF7A00);

enum ChatStatus { inProgress, done,autoReply }

class ChatStatusButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? tooltip;

  const ChatStatusButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _accent.withValues(alpha: 0.1) : const Color(0xFFF3F4F6);
    final ic = selected ? _accent : Colors.black54;

    final content = InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 80,
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _accent : Colors.black12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: ic),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.15,
                color: ic,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,

              ),
              maxLines: 2,
            ),
            const SizedBox(height: 6),
            Opacity(
              opacity: selected ? 1 : 0,
              child: Icon(Icons.check_circle, size: 16, color: _accent),
            ),
          ],
        ),
      ),
    );

    return tooltip != null && tooltip!.isNotEmpty
        ? Tooltip(message: tooltip!, child: content)
        : content;
  }
}
