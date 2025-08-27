import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../view/notifications_page.dart';

class NotificationsBellButton extends StatelessWidget {
  final String workspaceId;
  const NotificationsBellButton({super.key, required this.workspaceId});

  @override
  Widget build(BuildContext context) {
    if (workspaceId.isEmpty) return const SizedBox.shrink();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return IconButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to view notifications.')),
          );
        },
        icon: const Icon(Icons.notifications_none),
        tooltip: 'Notifications',
      );
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('workspaceId', isEqualTo: workspaceId)
        .where('read', isEqualTo: false)
        .limit(100)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final unread = snapshot.data?.docs.length ?? 0;
        return IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotificationsPage(workspaceId: workspaceId),
              ),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [

              const Icon(Icons.notifications_none, size: 24),
              if (unread > 0)
                Positioned(
                  right: 0,
                  top: 0,
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
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Notifications',
        );
      },
    );
  }
}

