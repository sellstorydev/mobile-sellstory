import 'package:flutter/material.dart';

class ChatMenuTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool danger;
  final VoidCallback? onTap;
  final bool closeOnTap;


  const ChatMenuTile({
    Key? key,
    required this.icon,
    required this.text,
    this.danger = false,
    this.onTap,
    this.closeOnTap = true,
  }) : super(key: key);

  Future<bool> _confirmDanger(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการทำรายการ'),
        content: Text('ต้องการ${text}หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ยืนยัน')),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red.shade700 : Colors.black87;
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: Icon(icon, color: danger ? Colors.red.shade400 : Colors.black54),
          title: Text(text, style: TextStyle(color: color, fontSize: 15)),
          onTap: () async {
            if (onTap == null) {
              if (closeOnTap) Navigator.pop(context);
              return;
            }

            // For dangerous actions, ask for confirmation first
            if (danger) {
              final ok = await _confirmDanger(context);
              if (!ok) return;
            }

            if (closeOnTap) {
              Navigator.pop(context);
              // Delay to ensure the previous sheet is dismissed before navigating further
              await Future.microtask(() {});
            }
            onTap?.call();
          },
        ),
        const Divider(height: 1),
      ],
    );
  }
}
