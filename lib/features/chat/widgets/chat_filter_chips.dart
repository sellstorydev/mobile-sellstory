import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 0),
        scrollDirection: Axis.horizontal,
        children: [
          // _buildChip('ทั้งหมด', 'all'),
          _buildChip('unread'.tr, 'unread'),
          _buildChip('new'.tr, 'new'),
          _buildChip('pinned'.tr, 'pinned', icon: Icons.push_pin),
          _buildChip('group_chat'.tr, 'groupOnly', icon: Icons.groups),
          // _buildChip('LINE', 'line', icon: Icons.chat),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, {IconData? icon}) {
    // Don't visually select any chip when activeFilter == 'all'
    final isSelected = (activeFilter == value) && value != 'all';

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
        onSelected: (_) {
          // If tapping the same selected chip again, unselect by switching to 'all'
          if (isSelected && value != 'all') {
            onFilterChanged('all');
          } else {
            onFilterChanged(value);
          }
        },
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
