import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatFilterChips extends StatelessWidget {
  // Selected status filter: '', 'NEW', 'IN_PROGRESS', 'DONE'
  final String activeStatus;
  // Whether the Unread chip is active (maps to activeFilter == 'unread')
  final bool unreadSelected;
  // Callbacks
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onUnreadChanged;

  const ChatFilterChips({
    Key? key,
    required this.activeStatus,
    required this.unreadSelected,
    required this.onStatusChanged,
    required this.onUnreadChanged,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 0),
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatusChip(
            'status_todo'.tr,
            'NEW',
            isSelected: activeStatus == 'NEW',
            icon: Icons.pending_actions,
          ),
          _buildStatusChip(
            'status_in_progress'.tr,
            'IN_PROGRESS',
            isSelected: activeStatus == 'IN_PROGRESS',
            icon: Icons.play_arrow,
          ),
          _buildStatusChip(
            'status_completed'.tr,
            'DONE',
            isSelected: activeStatus == 'DONE',
            icon: Icons.check_circle,
          ),
          _buildUnreadChip(
            'unread'.tr,
            isSelected: unreadSelected,
            icon: Icons.mark_chat_unread,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    String statusValue, {
    required bool isSelected,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) {
          // Toggle: tap again to clear status
          if (isSelected) {
            onStatusChanged('');
          } else {
            onStatusChanged(statusValue);
          }
        },
        selectedColor: Colors.blue.shade100,
        checkmarkColor: Colors.blue.shade800,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue.shade800 : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 14, // Adjust font size based on label length (example
        ),
      ),
    );
  }

  Widget _buildUnreadChip(
    String label, {
    required bool isSelected,
    IconData? icon,
  }) {
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
          // Toggle unread filter on/off
          onUnreadChanged(!isSelected);
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
