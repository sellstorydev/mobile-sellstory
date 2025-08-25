// show_bottom_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'chat_status_button.dart';
import 'chat_menu_tile.dart';
import 'notes_sheet.dart';
import 'user_picker_sheet.dart';
import 'customer_picker_sheet.dart';

const _accent = Color(0xFFFF7A00); // โทมส้มตามภาพ

class ShowBottomModal {
  static Future<void> open(
      BuildContext context, {
        ChatStatus current = ChatStatus.inProgress,
        bool pinned = false,
        bool botEnabled = false, // Add bot status parameter
        List<String> assignOptions = const [],
        String? selectedAssign,
        required ValueChanged<ChatStatus> onStatusChange,
        ValueChanged<bool>? onPinChanged,
        ValueChanged<bool>? onBotStatusChanged, // Add bot status callback
        ValueChanged<String?>? onAssignChanged,
        VoidCallback? onNote,
        VoidCallback? onAddSale,
        VoidCallback? onRename,
        VoidCallback? onResetName,
        VoidCallback? onDelete,
        required String workspaceId,
        required String chatroomId,
        String? customerId,
      }) {

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChatMoreSheet(
        current: current,
        pinned: pinned,
        botEnabled: botEnabled,
        assignOptions: assignOptions,
        selectedAssign: selectedAssign,
        onStatusChange: onStatusChange,
        onPinChanged: onPinChanged,
        onBotStatusChanged: onBotStatusChanged,
        onAssignChanged: onAssignChanged,
        onNote: onNote,
        onAddSale: onAddSale,
        onRename: onRename,
        onResetName: onResetName,
        onDelete: onDelete,
        workspaceId: workspaceId,
        chatroomId: chatroomId,
        customerId: customerId,
      ),
    );
  }
}

class _ChatMoreSheet extends StatefulWidget {
  final ChatStatus current;
  final bool pinned;
  final bool botEnabled; // Add bot status field
  final List<String> assignOptions;
  final String? selectedAssign;

  final ValueChanged<ChatStatus> onStatusChange;
  final ValueChanged<bool>? onPinChanged;
  final ValueChanged<bool>? onBotStatusChanged; // Add bot status callback
  final ValueChanged<String?>? onAssignChanged;

  final VoidCallback? onNote;
  final VoidCallback? onAddSale;
  final VoidCallback? onRename;
  final VoidCallback? onResetName;
  final VoidCallback? onDelete;

  final String workspaceId;
  final String chatroomId;
  final String? customerId;

  const _ChatMoreSheet({
    Key? key,
    required this.current,
    required this.pinned,
    required this.botEnabled, // Initialize bot status
    required this.assignOptions,
    required this.selectedAssign,
    required this.onStatusChange,
    this.onPinChanged,
    this.onBotStatusChanged, // Initialize bot status callback
    this.onAssignChanged,
    this.onNote,
    this.onAddSale,
    this.onRename,
    this.onResetName,
    this.onDelete,
    required this.workspaceId,
    required this.chatroomId,
    this.customerId,
  }) : super(key: key);

  @override
  State<_ChatMoreSheet> createState() => _ChatMoreSheetState();
}

class _ChatMoreSheetState extends State<_ChatMoreSheet> {
  late ChatStatus _status;
  late bool _pinned;
  late bool _botEnabled; // Add bot status variable
  String? _assign;
  bool _loadingAssignees = false;
  List<UserItem> _assignees = [];

  // Helper to get chatroom doc ref
  DocumentReference<Map<String, dynamic>> get _chatroomDoc => FirebaseFirestore.instance
      .collection('workspaces')
      .doc(widget.workspaceId)
      .collection('chatrooms')
      .doc(widget.chatroomId);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _chatroomSub;

  Future<Map<String, dynamic>> _getChatroomData() async {
    final snap = await _chatroomDoc.get();
    return snap.data() ?? <String, dynamic>{};
  }

  String _pickDisplayName(Map<String, dynamic> data) {
    return (data['name'] ?? data['who_name'] ?? data['displayName'] ?? data['customerName'] ?? '')
        .toString();
  }

  Future<void> _renameChat() async {
    try {
      final data = await _getChatroomData();
      final currentName = _pickDisplayName(data);
      final controller = TextEditingController(text: currentName);
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('เปลี่ยนชื่อแชท'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'กรอกชื่อใหม่'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('บันทึก'),
            ),
          ],
        ),
      );
      if (newName == null) return;
      if (newName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ชื่อห้ามว่าง')));
        return;
      }
      if (newName == currentName) return;

      final updates = <String, dynamic>{
        'name': newName,
      };
      // Keep original name for reset
      if ((data['original_name'] == null || (data['original_name'].toString().isEmpty)) &&
          currentName.isNotEmpty) {
        updates['original_name'] = currentName;
      }
      await _chatroomDoc.set(updates, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('บันทึกชื่อแชทเรียบร้อย')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เปลี่ยนชื่อไม่สำเร็จ: $e')));
    }
  }

  Future<void> _resetChatName() async {
    try {
      final data = await _getChatroomData();
      final original = (data['original_name'] ?? data['who_name'] ?? data['displayName'] ?? data['customerName'] ?? data['name'])
          ?.toString() ?? '';
      if (original.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบชื่อเดิมสำหรับรีเซ็ต')));
        return;
      }
      await _chatroomDoc.set({'name': original}, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รีเซ็ตชื่อแชทเรียบร้อย')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('รีเซ็ตไม่สำเร็จ: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _status = widget.current;
    _pinned = widget.pinned;
    _botEnabled = widget.botEnabled; // Initialize bot status
    _assign = widget.selectedAssign;
    if (widget.customerId != null && widget.customerId!.isNotEmpty) {
      _loadAssignees();
    }
    // Realtime sync with chatroom document
    _chatroomSub = _chatroomDoc.snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) return;
      final pinned = (data['chat_pin'] ?? 'N') == 'Y';
      final bot = (data['bot_status'] ?? 'N') == 'Y';
      final statusRaw = (data['chatroom_status'] ?? '').toString().toUpperCase();
      final status = statusRaw == 'DONE' ? ChatStatus.done : ChatStatus.inProgress;
      if (!mounted) return;
      setState(() {
        _pinned = pinned;
        _botEnabled = bot;
        _status = status;
      });
    });
  }

  @override
  void dispose() {
    _chatroomSub?.cancel();
    _chatroomSub = null;
    super.dispose();
  }

  Future<void> _loadAssignees() async {
    if (widget.customerId == null || widget.customerId!.isEmpty) return;
    try {
      setState(() => _loadingAssignees = true);
      final doc = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('customers')
          .doc(widget.customerId)
          .get();
      final data = doc.data() ?? {};
      final ids = ((data['assignees'] as List?) ?? []).cast<String>();
      final users = await Future.wait(ids.map((uid) async {
        final u = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final m = u.data() ?? {};
        return UserItem(
          uid: uid,
          displayName: (m['displayName'] ?? m['name'] ?? 'Unknown').toString(),
          email: (m['email'] ?? '').toString(),
          photoURL: (m['photoURL'] ?? m['avatar']) as String?,
          role: null,
        );
      }));
      if (!mounted) return;
      setState(() => _assignees = users);
    } finally {
      if (mounted) setState(() => _loadingAssignees = false);
    }
  }


  Future<void> _openNotes() async {

    if (widget.customerId == null || widget.customerId!.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบลูกค้าสำหรับบันทึกโน้ต')),
      );
      return;
    }
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final h = MediaQuery.of(ctx).size.height;
        return SizedBox(
          height: h * 0.9,
          child: NotesSheet(
            workspaceId: widget.workspaceId,
            customerId: widget.customerId!,
          ),
        );
      },
    );
  }

  Future<void> _openUserPicker() async {
    final pickedUid = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final h = MediaQuery.of(ctx).size.height;
        return SizedBox(
          height: h * 0.9,
          child: UserPickerSheet(workspaceId: widget.workspaceId),
        );
      },
    );
    if (pickedUid != null && pickedUid.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ยืนยันการผูกเซล'),
          content: const Text('ต้องการผูกผู้ใช้นี้เข้ากับลูกค้าหรือไม่?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ยืนยัน')),
          ],
        ),
      );
      if (ok == true && widget.customerId != null && widget.customerId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('workspaces')
            .doc(widget.workspaceId)
            .collection('customers')
            .doc(widget.customerId)
            .set({'assignees': FieldValue.arrayUnion([pickedUid])}, SetOptions(merge: true));
        await _loadAssignees();
        widget.onAssignChanged?.call(pickedUid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ผูกเซลเรียบร้อย')),
          );
        }
      }
    }
  }

  Future<void> _removeAssignee(UserItem user) async {
    if (widget.customerId == null || widget.customerId!.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบเซล'),
        content: Text('ยืนยันลบ ${user.displayName} ออกจากผู้รับผิดชอบลูกค้ารายนี้?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('customers')
          .doc(widget.customerId)
          .set({'assignees': FieldValue.arrayRemove([user.uid])}, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _assignees.removeWhere((u) => u.uid == user.uid));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบเซลเรียบร้อย')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
    }
  }

  Future<void> _openCustomerPicker() async {
    final pickedCustomerId = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final h = MediaQuery.of(ctx).size.height;
        return SizedBox(
          height: h * 0.9,
          child: CustomerPickerSheet(workspaceId: widget.workspaceId),
        );
      },
    );

    if (pickedCustomerId == null || pickedCustomerId.isEmpty) return;

    try {
      // Read customer to get display name
      final cDoc = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('customers')
          .doc(pickedCustomerId)
          .get();
      final cData = cDoc.data() ?? {};
      final name = (cData['name'] ?? cData['displayName'] ?? cData['customerName'] ?? '').toString();

      await _chatroomDoc.set({
        'customerId': pickedCustomerId,
        if (name.isNotEmpty) 'customerName': name,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เชื่อมลูกค้ากับห้องแชทแล้ว')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เชื่อมลูกค้าไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // จุดส้มตกแต่งซ้ายบนเหมือนภาพ
                Container(
                  width: 6, height: 22,
                  margin: const EdgeInsets.only(top: 6, right: 10),
                  decoration: BoxDecoration(
                    color: _accent, borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('เมนูเพิ่มเติม',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          )),
                      const SizedBox(height: 6),
                      Text('เปลี่ยนสถานะห้องแชท',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ChatStatusButton(
                  icon: Icons.smart_toy_outlined,
                  label: 'ตอบกลับ\nอัตโนมัติ',
                  selected: _botEnabled,
                  tooltip: 'ตอบกลับอัตโนมัติ: เปิด/ปิดการทำงานของแชตบอท',
                  onTap: () async {
                    setState(() => _botEnabled = !_botEnabled);
                    // Prefer parent callback

                    if (widget.onBotStatusChanged != null) {
                      widget.onBotStatusChanged!(_botEnabled);
                    } else {
                      // Fallback: persist directly
                      try {
                        await _chatroomDoc.update({'bot_status': _botEnabled ? 'Y' : 'N'});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_botEnabled ? 'เปิดบอทตอบกลับอัตโนมัติ' : 'ปิดบอทตอบกลับอัตโนมัติ')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('อัปเดตการตอบกลับอัตโนมัติไม่สำเร็จ: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
                ChatStatusButton(
                  icon: Icons.chat_bubble,
                  label: 'กำลัง\nดำเนินการ',
                  selected: _status == ChatStatus.inProgress,
                  tooltip: 'ห้องแชทกำลังดำเนินการ',
                  onTap: () async {
                    setState(() => _status = ChatStatus.inProgress);
                    if (widget.onStatusChange != null) {
                      widget.onStatusChange(_status);
                    } else {
                      try {
                        await _chatroomDoc.update({'chatroom_status': 'IN_PROGRESS'});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ตั้งค่าเป็นกำลังดำเนินการ')));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปเดตสถานะไม่สำเร็จ: $e')));
                        }
                      }
                    }
                  },
                ),
                ChatStatusButton(
                  icon: Icons.check,
                  label: 'สำเร็จ',
                  selected: _status == ChatStatus.done,
                  tooltip: 'คุยจบแล้ว',
                  onTap: () async {
                    setState(() => _status = ChatStatus.done);
                    if (widget.onStatusChange != null) {
                      widget.onStatusChange(_status);
                    } else {
                      try {
                        await _chatroomDoc.update({'chatroom_status': 'DONE'});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ตั้งค่าเป็นสำเร็จ')));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปเดตสถานะไม่สำเร็จ: $e')));
                        }
                      }
                    }
                  },
                ),
                ChatStatusButton(
                  icon: Icons.push_pin_outlined,
                  label: 'ปักหมุด',
                  selected: _pinned,
                  tooltip: 'ปักหมุดห้องแชท',
                  onTap: () async {
                    setState(() => _pinned = !_pinned);
                    // Prefer parent callback
                    if (widget.onPinChanged != null) {
                      widget.onPinChanged!(_pinned);
                    } else {
                      // Fallback: persist directly
                      try {
                        await _chatroomDoc.update({'chat_pin': _pinned ? 'Y' : 'N'});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_pinned ? 'ปักหมุดแล้ว' : 'ยกเลิกปักหมุดแล้ว')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('อัปเดตปักหมุดไม่สำเร็จ: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // เมนูรายการ
            const Divider(height: 24),
            ChatMenuTile(
              icon: Icons.sticky_note_2_outlined,
              text: 'โน้ต',
              onTap: _openNotes,
              closeOnTap: false,
            ),

            ChatMenuTile(
              icon: Icons.supervised_user_circle_outlined,
              text: 'เพิ่มลูกค้า',
              onTap: _openCustomerPicker,
              closeOnTap: false,
            ),
            ChatMenuTile(
              icon: Icons.badge_outlined,
              text: 'เพิ่มเซล',
              onTap: _openUserPicker,
              closeOnTap: false,
            ),
            if (_loadingAssignees)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_assignees.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _assignees.map((u) => Chip(
                      avatar: CircleAvatar(
                        backgroundImage: (u.photoURL != null && u.photoURL!.isNotEmpty)
                            ? NetworkImage(u.photoURL!)
                            : null,
                        child: (u.photoURL == null || u.photoURL!.isEmpty)
                            ? Text(u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : '?')
                            : null,
                      ),
                      label: Text(u.displayName),
                      deleteIcon: const Icon(Icons.close),
                      onDeleted: () => _removeAssignee(u),
                    )).toList(),
                  ),
                ),
              ),
            ChatMenuTile(
              icon: Icons.edit_outlined,
              text: 'เปลี่ยนชื่อแชท',
              onTap: _renameChat,
            ),
            ChatMenuTile(
              icon: Icons.refresh_outlined,
              text: 'รีเซ็ตชื่อแชท',
              onTap: _resetChatName,
            ),
            ChatMenuTile(
              icon: Icons.delete_outline,
              text: 'ลบแชท',
              danger: true,
              onTap: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
