import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../view/chat_center_page.dart';

class ChatUnreadButton extends StatelessWidget {
  final String workspaceId;
  const ChatUnreadButton({super.key, required this.workspaceId});

  int _parseCount(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) {
      return int.tryParse(v) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (workspaceId.isEmpty) return const SizedBox.shrink();

    final stream = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('chatrooms')
        .where('is_deleted', isEqualTo: 'N')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        int unreadTotal = 0;
        final docs = snapshot.data?.docs ?? const [];
        for (final d in docs) {
          final data = d.data();
          unreadTotal += _parseCount(data['count']);
        }

        final badgeText = unreadTotal > 99 ? '99+' : (unreadTotal > 0 ? '$unreadTotal' : '');

        return IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatCenterPage(),
              ),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.chat_bubble_outline, size: 21),
              if (unreadTotal > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 5, minHeight: 5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'chat_center'.tr,
        );
      },
    );
  }
}
