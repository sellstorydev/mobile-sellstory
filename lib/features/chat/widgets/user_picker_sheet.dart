import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserItem {
  UserItem({required this.uid, required this.displayName, required this.email, this.photoURL, this.role});
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String? role;
}

class UserPickerSheet extends StatefulWidget {
  const UserPickerSheet({Key? key, required this.workspaceId}) : super(key: key);
  final String workspaceId;

  @override
  State<UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<UserPickerSheet> {
  late Future<List<UserItem>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _loadMembers();
  }

  Future<List<UserItem>> _loadMembers() async {
    final wsDoc = await FirebaseFirestore.instance
        .collection('workspaces')
        .doc(widget.workspaceId)
        .get();
    final data = wsDoc.data() ?? {};
    final members = (data['members'] as Map<String, dynamic>? ?? {});
    if (members.isEmpty) return [];

    final uids = members.keys.toList();
    final users = await Future.wait(uids.map((uid) async {
      final u = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final m = u.data() ?? {};
      return UserItem(
        uid: uid,
        displayName: (m['displayName'] ?? m['name'] ?? 'Unknown') as String,
        email: (m['email'] ?? '') as String,
        photoURL: (m['photoURL'] ?? m['avatar']) as String?,
        role: members[uid]?.toString(),
      );
    }));

    users.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return users;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกเซล'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'ค้นหาชื่อหรืออีเมล',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserItem>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = (snap.data ?? []);
                if (list.isEmpty) {
                  return const Center(child: Text('ไม่พบบัญชีผู้ใช้ในเวิร์กสเปซ'));
                }
                final q = _query.toLowerCase();
                final filtered = q.isEmpty
                    ? list
                    : list.where((u) =>
                        u.displayName.toLowerCase().contains(q) ||
                        (u.email.toLowerCase().contains(q))).toList();
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = filtered[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (u.photoURL != null && u.photoURL!.isNotEmpty)
                            ? NetworkImage(u.photoURL!)
                            : null,
                        child: (u.photoURL == null || u.photoURL!.isEmpty)
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(u.displayName),
                      subtitle: Text(u.email.isEmpty ? (u.role ?? '') : u.email),
                      onTap: () => Navigator.pop(context, u.uid),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
