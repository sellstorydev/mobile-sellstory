import 'package:flutter/material.dart';

class ChatFilterChips extends StatelessWidget {
  final String activeFilter;
  final Function(String) onFilterChanged;

  const ChatFilterChips({
    Key? key,
    required this.activeFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('ทั้งหมด', 'all'),
          _buildChip('ยังไม่ได้อ่าน', 'unread'),
          _buildChip('ใหม่', 'new'),
          _buildChip('ปักหมุด', 'pinned', icon: Icons.push_pin),
          _buildChip('Group Chat', 'groupOnly', icon: Icons.groups),
          _buildChip('LINE', 'line', icon: Icons.chat),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, {IconData? icon}) {
    final isSelected = activeFilter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onFilterChanged(value),
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue.shade800,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
