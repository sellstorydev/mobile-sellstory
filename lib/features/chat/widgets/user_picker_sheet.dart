import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class UserItem {
  UserItem({required this.uid, required this.displayName, required this.email, this.photoURL, this.role});
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final String? role;
}

class UserPickerSheet extends StatefulWidget {
  const UserPickerSheet({Key? key, required this.workspaceId, this.initialSelectedUid, this.multiSelect = false, this.initialSelectedUids}) : super(key: key);
  final String workspaceId;
  final String? initialSelectedUid;
  final bool multiSelect;
  final List<String>? initialSelectedUids;

  @override
  State<UserPickerSheet> createState() => _UserPickerSheetState();
}

class _UserPickerSheetState extends State<UserPickerSheet> {
  late Future<List<UserItem>> _future;
  String _query = '';
  String? _selectedUid;
  final Set<String> _selectedUids = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _loadMembers();
    _selectedUid = widget.initialSelectedUid;
    if (widget.initialSelectedUids != null) {
      _selectedUids.addAll(widget.initialSelectedUids!);
    }
    if (widget.initialSelectedUid != null) {
      _selectedUids.add(widget.initialSelectedUid!);
    }
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
        title: Text(widget.multiSelect ? 'เลือกเซล (หลายคน)' : 'เลือกเซล'),
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
                    final selected = widget.multiSelect
                        ? _selectedUids.contains(u.uid)
                        : _selectedUid == u.uid;
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
                      trailing: selected
                          ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                          : (widget.multiSelect ? const Icon(Icons.radio_button_unchecked) : null),
                      selected: selected,
                      onTap: () async {
                        if (widget.multiSelect) {
                          setState(() {
                            if (_selectedUids.contains(u.uid)) {
                              _selectedUids.remove(u.uid);
                            } else {
                              _selectedUids.add(u.uid);
                            }
                          });
                        } else {
                          setState(() => _selectedUid = u.uid);
                          // Delay to show tick then close
                          await Future.delayed(const Duration(milliseconds: 120));
                          if (!mounted) return;
                          Navigator.pop<String>(context, u.uid);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (widget.multiSelect)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('cancel'.tr),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedUids.isEmpty
                            ? null
                            : () => Navigator.pop<List<String>>(context, _selectedUids.toList()),
                        child: Text('confirm'.tr),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
