// show_bottom_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import '../../board/controller/board_controller.dart';
import 'chat_status_button.dart';
import 'chat_menu_tile.dart';
import 'notes_sheet.dart';
import 'user_picker_sheet.dart';
import 'customer_picker_sheet.dart';
import 'jobcard_picker_sheet.dart';
import '../../board/view/card_detail_page.dart';
import '../../../domain/entities/job_card.dart';
import 'package:get/get.dart';

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
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92, // leave a small gap at the top for easier dismiss
        child: _ChatMoreSheet(
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
  bool _loadingAssignees = false;
  List<UserItem> _assignees = [];
  // Track current customerId locally to allow updating after picking a new one
  String? _currentCustomerId;
  String? _currentCustomerName;
  // Linked Job Card state
  String? _jobCardId;
  String? _jobCardTitle;


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

  Future<void> _loadCustomerNameById(String cid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('customers')
          .doc(cid)
          .get();
      final m = snap.data() ?? {};
      final name = (m['name'] ?? m['displayName'] ?? m['customerName'] ?? '').toString();
      if (!mounted) return;
      setState(() => _currentCustomerName = name.isNotEmpty ? name : null);
    } catch (_) {
      // ignore fetch errors for UX
    }
  }

  Future<void> _loadJobCardTitleById(String cardId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('cards')
          .doc(cardId)
          .get();
      final m = snap.data() ?? {};
      final title = (m['title'] ?? m['name'] ?? '').toString();
      if (!mounted) return;
      setState(() => _jobCardTitle = title.isNotEmpty ? title : null);
    } catch (_) {
      // ignore
    }
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
    _currentCustomerId = widget.customerId;
    if (_currentCustomerId != null && _currentCustomerId!.isNotEmpty) {
      _loadAssignees();
      _loadCustomerNameById(_currentCustomerId!);
    }
    // Realtime sync with chatroom document
    _chatroomSub = _chatroomDoc.snapshots().listen((snap) {
      final data = snap.data();
      if (data == null) return;
      final pinned = (data['chat_pin'] ?? 'N') == 'Y';
      final bot = (data['bot_status'] ?? 'N') == 'Y';
      final statusRaw = (data['chatroom_status'] ?? '').toString().toUpperCase();
      final status = statusRaw == 'DONE' ? ChatStatus.done : ChatStatus.inProgress;
      final cid = (data['customerId'] ?? data['customer_id'] ?? data['customer']?['id'])?.toString();
      final cname = (data['customerName'] ?? '').toString();
      final jobId = (data['jobCardId'] ?? data['jobCardID'] ?? '').toString();
      final jobTitle = (data['jobCardTitle'] ?? '').toString();
      if (!mounted) return;
      setState(() {
        _pinned = pinned;
        _botEnabled = bot;
        _status = status;
        // If customerId changed while sheet is open, update and reload assignees
        if ((cid ?? '') != (_currentCustomerId ?? '')) {
          _currentCustomerId = cid;
          _assignees = [];
          if (_currentCustomerId != null && _currentCustomerId!.isNotEmpty) {
            _loadAssignees();
            if (cname.isNotEmpty) {
              _currentCustomerName = cname;
            } else {
              _loadCustomerNameById(_currentCustomerId!);
            }
          } else {
            _currentCustomerName = null;
          }
        } else {
          // same id; update name if present in doc
          if (cname.isNotEmpty) _currentCustomerName = cname;
        }
        // Sync job card fields
        final prevJobId = _jobCardId ?? '';
        if (jobId != prevJobId) {
          _jobCardId = jobId.isNotEmpty ? jobId : null;
          if (_jobCardId != null) {
            if (jobTitle.isNotEmpty) {
              _jobCardTitle = jobTitle;
            } else {
              _loadJobCardTitleById(_jobCardId!);
            }
          } else {
            _jobCardTitle = null;
          }
        } else {
          if (jobTitle.isNotEmpty) _jobCardTitle = jobTitle;
        }
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
    if (_currentCustomerId == null || _currentCustomerId!.isEmpty) return;
    try {
      setState(() => _loadingAssignees = true);
      final doc = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('customers')
          .doc(_currentCustomerId)
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

    if (_currentCustomerId == null || _currentCustomerId!.isEmpty) {
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
            customerId: _currentCustomerId!,
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
      if (ok == true && _currentCustomerId != null && _currentCustomerId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('workspaces')
            .doc(widget.workspaceId)
            .collection('customers')
            .doc(_currentCustomerId)
            .set({'assignees': FieldValue.arrayUnion([pickedUid])}, SetOptions(merge: true));
        await _loadAssignees();
        widget.onAssignChanged?.call(pickedUid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ผูกเซลเรียบร้อย')),
          );
        }
      } else if (ok == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('กรุณาเชื่อมลูกค้ากับห้องแชทก่อน')),
          );
        }
      }
    }
  }

  Future<void> _removeAssignee(UserItem user) async {
    if (_currentCustomerId == null || _currentCustomerId!.isEmpty) return;
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
          .doc(_currentCustomerId)
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
      setState(() {
        _currentCustomerId = pickedCustomerId;
        _currentCustomerName = name.isNotEmpty ? name : null;
      });
      // Refresh assignees immediately for the newly linked customer
      await _loadAssignees();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เชื่อมลูกค้ากับห้องแชทแล้ว')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เชื่อมลูกค้าไม่สำเร็จ: $e')));
    }
  }

  Future<void> _openJobCardPicker() async {
    final result = await showModalBottomSheet<JobCardPickerResult>(
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
          child: JobCardPickerSheet(workspaceId: widget.workspaceId),
        );
      },
    );

    if (result == null) return;

    try {
      await _chatroomDoc.set({
        'jobCardId': result.cardId,
        'jobCardTitle': result.title,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() {
        _jobCardId = result.cardId;
        _jobCardTitle = result.title;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ผูก Job Card แล้ว')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ผูก Job Card ไม่สำเร็จ: $e')));
    }
  }

  Future<void> _openJobCardDetail() async {
    if (_jobCardId == null || _jobCardId!.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('cards')
          .doc(_jobCardId)
          .get();
      if (!snap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบ Job Card ที่เชื่อม')));
        return;
      }
      final data = snap.data() ?? {};
      final job = JobCard.fromMap(data, snap.id);

      // Ensure BoardController is ready with the current workspace for CardDetailPage
      final boardController = Get.isRegistered<BoardController>()
          ? Get.find<BoardController>()
          : Get.put(BoardController());
      if (boardController.currentWorkspaceId.value != widget.workspaceId) {
        await boardController.switchWorkspace(widget.workspaceId);
      }

      // Close the bottom sheet first, then navigate to detail page using Get.to
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      await Future.microtask(() {});
      if (!mounted) return;
      Get.to(() => CardDetailPage(card: job));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เปิด Job Card ไม่สำเร็จ: $e')));
    }
  }


  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: true,
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
                    if (widget.onBotStatusChanged != null) {
                      widget.onBotStatusChanged!(_botEnabled);
                    } else {
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
                    // onStatusChange is required; call directly
                    widget.onStatusChange(_status);
                  },
                ),
                ChatStatusButton(
                  icon: Icons.check,
                  label: 'สำเร็จ',
                  selected: _status == ChatStatus.done,
                  tooltip: 'คุยจบแล้ว',
                  onTap: () async {
                    setState(() => _status = ChatStatus.done);
                    // onStatusChange is required; call directly
                    widget.onStatusChange(_status);
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
                      // Fallback: persist both chat_pin and bot_status directly
                      try {
                        await _chatroomDoc.update({
                          'chat_pin': _pinned ? 'Y' : 'N',
                          'bot_status': _botEnabled ? 'Y' : 'N',
                        });
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
            if ((_currentCustomerId ?? '').isNotEmpty) ...[

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB))),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE9ECEF),
                          child: Text(
                            (_currentCustomerName?.isNotEmpty == true ? _currentCustomerName![0] : '?').toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (_currentCustomerName?.isNotEmpty == true)
                                    ? _currentCustomerName!
                                    : 'กำลังดึงชื่อลูกค้า...',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'แก้ไข/เปลี่ยนลูกค้า',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openCustomerPicker,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('เปลี่ยน', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            ChatMenuTile(
              icon: Icons.card_travel_outlined,
              text: 'ผูก Job Card',
              onTap: _openJobCardPicker,
              closeOnTap: false,
            ),
            if ((_jobCardId ?? '').isNotEmpty) ...[
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              //   child: Row(
              //     children: const [
              //       Icon(Icons.style_outlined, size: 16, color: Colors.black54),
              //       SizedBox(width: 6),
              //       Text('Job Card ที่เชื่อม', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
              //     ],
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: InkWell(
                  onTap: _openJobCardDetail,
                  borderRadius: BorderRadius.circular(12),
                  child: Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFE9ECEF),
                            child: Icon(Icons.style_outlined, color: Colors.black87),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (_jobCardTitle?.isNotEmpty == true)
                                      ? _jobCardTitle!
                                      : 'กำลังดึงชื่อการ์ด...',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'แตะเพื่อเปิดรายละเอียด',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _openJobCardPicker,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              minimumSize: const Size(0, 36),
                            ),
                            icon: const Icon(Icons.swap_horiz, size: 16),
                            label: const Text('เปลี่ยน', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            ChatMenuTile(
              icon: Icons.badge_outlined,
              text: 'เพิ่มเซล',
              onTap: _openUserPicker,
              closeOnTap: false,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB))),
                child: (_assignees.isEmpty)
                    ? Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ยังไม่มีเซลที่ดูแล กด “เพิ่มเซล” เพื่อเชื่อมผู้ดูแลลูกค้า',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _assignees.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final u = _assignees[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: CircleAvatar(
                        backgroundImage: (u.photoURL != null && u.photoURL!.isNotEmpty) ? NetworkImage(u.photoURL!) : null,
                        backgroundColor: const Color(0xFFE9ECEF),
                        child: (u.photoURL == null || u.photoURL!.isEmpty)
                            ? Text(u.displayName.isNotEmpty ? u.displayName[0].toUpperCase() : '?')
                            : null,
                      ),
                      title: Text(u.displayName, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: (u.email.isNotEmpty)
                          ? Text(u.email, maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        tooltip: 'ลบออก',
                        onPressed: () => _removeAssignee(u),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_loadingAssignees)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: LinearProgressIndicator(minHeight: 2),
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
