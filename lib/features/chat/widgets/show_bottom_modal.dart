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
import '../../board/view/edit_card_page.dart';
import '../../../domain/entities/job_card.dart';
import 'package:get/get.dart';
import '../../../core/services/hashtag_service.dart';
import '../../../core/widgets/hashtag_input_field.dart';
import '../../../core/widgets/dialog_utils.dart';
import '../../../core/widgets/permission_guard.dart';
import '../../../data/services/mobile_permissions_service.dart';

const _accent = Color(0xFFFF7A00); // Orange tone as shown in the image

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

  // Hashtags state (for linked customer)
  final HashtagService _hashtagService = HashtagService();
  List<HashtagOption> _availableHashtags = [];
  List<String> _selectedHashtagIds = [];
  List<String> _pendingHashtagIds = [];
  bool _loadingHashtags = false;
  bool _creatingHashtag = false;


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

  void _showTopSnack(String message, {bool isError = false}) {

    // Dismiss existing to avoid stacking many
    try { Get.closeAllSnackbars(); } catch (_) {}

    Get.snackbar(
      isError ? 'error_occurred'.tr : 'notification'.tr,
      message,
      margin: const EdgeInsets.all(12),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      icon: Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),

    );
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
          title: Text('chat_rename_title'.tr),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'chat_rename_hint'.tr),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text('save'.tr),
            ),
          ],
        ),
      );
      if (newName == null) return;
      if (newName.isEmpty) {
        _showTopSnack('chat_name_cannot_be_empty'.tr, isError: true);
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
      _showTopSnack('chat_name_saved_success'.tr);
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('chat_rename_failed'.tr + ': $e', isError: true);
    }
  }

  Future<void> _resetChatName() async {
    try {
      final data = await _getChatroomData();
      final original = (data['original_name'] ?? data['who_name'] ?? data['displayName'] ?? data['customerName'] ?? data['name'])
          ?.toString() ?? '';
      if (original.isEmpty) {
        _showTopSnack('chat_original_name_not_found'.tr, isError: true);
        return;
      }
      await _chatroomDoc.set({'name': original}, SetOptions(merge: true));
      if (!mounted) return;
      _showTopSnack('chat_name_reset_success'.tr);
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('chat_reset_failed'.tr + ': $e', isError: true);
    }
  }

  Future<void> _loadCustomerHashtags(String cid) async {
    setState(() { _loadingHashtags = true; });
    try {
      // Load available hashtags from workspace master list, filter by customer scope, sort by totalUsage desc then name
      final all = await _hashtagService.getWorkspaceHashtags(widget.workspaceId);
      final filtered = all.where((h) => (h.scopes['customer'] == true) && h.enabled).toList();
      filtered.sort((a, b) {
        final byUsage = (b.totalUsage).compareTo(a.totalUsage);
        if (byUsage != 0) return byUsage;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      _availableHashtags = filtered;

      // Load current customer's hashtag ids
      final snap = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('customers')
          .doc(cid)
          .get();
      final m = snap.data() ?? {};
      final raw = (m['hashtags'] as List?) ?? const [];
      final ids = <String>[];
      for (final it in raw) {
        if (it is String) ids.add(it);
        else if (it is Map) {
          final id = (it['id'] ?? it['text'] ?? '').toString();
          if (id.isNotEmpty) ids.add(id);
        }
      }
      if (!mounted) return;
      setState(() {
        _selectedHashtagIds = ids;
        _pendingHashtagIds = List<String>.from(ids);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _availableHashtags = []; _selectedHashtagIds = []; _pendingHashtagIds = []; });
    } finally {
      if (mounted) setState(() { _loadingHashtags = false; });
    }
  }

  bool get _isHashtagDirty {
    final a = _selectedHashtagIds.toSet();
    final b = _pendingHashtagIds.toSet();
    return a.length != b.length || a.difference(b).isNotEmpty;
  }

  Future<void> _persistCustomerHashtags(List<String> ids) async {
    // Ensure we have a linked customer to save into
    final cid = _currentCustomerId?.trim() ?? '';
    if (cid.isEmpty) {
      _showTopSnack('chat_link_customer_before_hashtag'.tr, isError: true);
      return;
    }
    try {
      // Map to object format {id,text,color}
      final objects = ids.map((id) {
        final h = _availableHashtags.firstWhere(
          (x) => x.id == id,
          orElse: () => HashtagOption(id: id, name: id, color: '#ef4444', totalUsage: 0, enabled: true, scopes: const {}),
        );
        return {
          'id': h.id,
          'text': h.name,
          'color': h.color,
        };
      }).toList();

      // Persist to customer document (source of truth)
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('customers')
          .doc(cid)
          .set({'hashtags': objects}, SetOptions(merge: true));

      // Mirror to chatroom for instant UI reflection in the list (ids + display names with #)
      final names = objects
          .map((m) => (m['text']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .map((s) => s.startsWith('#') ? s : '#$s')
          .toList();
      await _chatroomDoc.set({
        'hashtagIds': ids,
        'hashtags': names,
      }, SetOptions(merge: true));
      final meta = objects.map((m) => {
        'name': (m['text'] is String && (m['text'] as String).startsWith('#')) ? m['text'] : '#${m['text']}',
        'color': m['color'] ?? '#64748B',
      }).toList();

      if (!mounted) return;
      setState(() {
        _selectedHashtagIds = List<String>.from(ids);
        _pendingHashtagIds = List<String>.from(ids);
      });
      _showTopSnack('chat_hashtag_updated_success'.tr);
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('chat_hashtag_update_failed'.tr + ': $e', isError: true);
    }
  }

  Future<void> _createNewCustomerHashtag() async {
    if ((_currentCustomerId ?? '').isEmpty) return;
    final controller = TextEditingController();
    final colorController = TextEditingController(text: '#f97316');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เพิ่มแฮชแท็กใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'เช่น VIP, Hot, ติดตาม'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(hintText: '#สี (เช่น #f97316)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('เพิ่ม')),
        ],
      ),
    );
    if (name == null) return;
    final safeName = name.replaceAll('#', '').trim();
    if (safeName.isEmpty) {
      _showTopSnack('กรอกชื่อแฮชแท็กก่อน');
      return;
    }

    setState(() => _creatingHashtag = true);
    try {
      final color = () {
        final raw = colorController.text.trim();
        if (RegExp(r'^#?(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(raw)) {
          return raw.startsWith('#') ? raw : '#$raw';
        }
        return '#f97316';
      }();
      final ok = await _hashtagService.createHashtag(
        widget.workspaceId,
        safeName,
        color,
        const {'customer': true},
      );
      if (!ok) {
        if (!mounted) return;
        _showTopSnack('สร้างแฮชแท็กไม่สำเร็จ', isError: true);
        return;
      }
      // Reload available hashtags and keep current selections; then add new tag to pending only
      await _loadCustomerHashtags(_currentCustomerId!);
      final newId = safeName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (!_pendingHashtagIds.contains(newId)) {
        setState(() => _pendingHashtagIds = [..._pendingHashtagIds, newId]);
      }
      if (!mounted) return;
      _showTopSnack('chat_hashtag_created_confirm_to_save'.tr);
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('chat_hashtag_create_failed'.tr + ': $e', isError: true);
    } finally {
      if (mounted) setState(() => _creatingHashtag = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _status = widget.current;
    _pinned = widget.pinned;
    _botEnabled = widget.botEnabled; // Initialize bot status
    _currentCustomerId = widget.customerId;
    // Always load assignees: from customer if present, otherwise from chatroom
    _loadAssignees();
    if (_currentCustomerId != null && _currentCustomerId!.isNotEmpty) {
      _loadCustomerNameById(_currentCustomerId!);
      _loadCustomerHashtags(_currentCustomerId!);
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
          _loadAssignees();
          if (_currentCustomerId != null && _currentCustomerId!.isNotEmpty) {
            if (cname.isNotEmpty) {
              _currentCustomerName = cname;
            } else {
              _loadCustomerNameById(_currentCustomerId!);
            }
            _loadCustomerHashtags(_currentCustomerId!);
          } else {
            _currentCustomerName = null;
            _selectedHashtagIds = [];
          }
        } else {
          // same id; update name if present in doc
          if (cname.isNotEmpty) _currentCustomerName = cname;
          // If no customer linked, update assignees from chatroom realtime
          if ((_currentCustomerId ?? '').isEmpty) {
            _loadAssignees();
          }
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
    setState(() => _loadingAssignees = true);
    try {
      List<String> ids = const [];
      if (_currentCustomerId != null && _currentCustomerId!.isNotEmpty) {
        // Load from customer doc
        final doc = await FirebaseFirestore.instance
            .collection('workspaces')
            .doc(widget.workspaceId)
            .collection('customers')
            .doc(_currentCustomerId)
            .get();
        final data = doc.data() ?? {};
        ids = ((data['assignees'] as List?) ?? []).map((e) => e.toString()).toList();
      } else {
        // Load from chatroom doc (no customer linked)
        final snap = await _chatroomDoc.get();
        final m = snap.data() ?? {};
        ids = ((m['assignees'] as List?) ?? []).map((e) => e.toString()).toList();
      }
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
      // Prompt to pick a customer first
      final prev = _currentCustomerId;
      await _openCustomerPicker();
      if (!mounted) return;
      if ((_currentCustomerId ?? '') == (prev ?? '') || (_currentCustomerId ?? '').isEmpty) {
        _showTopSnack('ไม่พบลูกค้าสำหรับบันทึกโน้ต', isError: true);
        return;
      }
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
      final ok = await DialogUtils.showConfirmDialog(
        context: context,
        title: 'chat_confirm_assign_sale'.tr,
        content: 'chat_confirm_assign_sale_message'.tr,
        cancelText: 'cancel'.tr,
        confirmText: 'confirm'.tr,
      );
      if (ok == true) {
        try {
          if (_currentCustomerId != null && _currentCustomerId!.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('workspaces')
                .doc(widget.workspaceId)
                .collection('customers')
                .doc(_currentCustomerId)
                .set({'assignees': FieldValue.arrayUnion([pickedUid])}, SetOptions(merge: true));
          } else {
            await _chatroomDoc.set({'assignees': FieldValue.arrayUnion([pickedUid])}, SetOptions(merge: true));
          }
          await _loadAssignees();
          widget.onAssignChanged?.call(pickedUid);
          if (mounted) {
            _showTopSnack('ผูกเซลเรียบร้อย');
          }
        } catch (e) {
          if (mounted) {
            _showTopSnack('ผูกเซลไม่สำเร็จ: $e', isError: true);
          }
        }
      }
    }
  }

  Future<void> _removeAssignee(UserItem user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm_remove_assignee'.tr),
        content: Text('confirm_remove_assignee_message'.tr.replaceAll('{name}', user.displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('delete'.tr)),
        ],
      ),
    );
    if (ok != true) return;

    try {
      if (_currentCustomerId != null && _currentCustomerId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('workspaces')
            .doc(widget.workspaceId)
            .collection('customers')
            .doc(_currentCustomerId)
            .set({'assignees': FieldValue.arrayRemove([user.uid])}, SetOptions(merge: true));
      } else {
        await _chatroomDoc.set({'assignees': FieldValue.arrayRemove([user.uid])}, SetOptions(merge: true));
      }
      if (!mounted) return;
      setState(() => _assignees.removeWhere((u) => u.uid == user.uid));
      _showTopSnack('ลบเซลเรียบร้อย');
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('ลบไม่สำเร็จ: $e', isError: true);
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
      // Permission to link customer to chat
      final svc = MobilePermissionsService.to;
      if (!(svc.isOwner || svc.can('chat:assign'))) {
        _showTopSnack('คุณไม่มีสิทธิ์เชื่อมลูกค้ากับแชท', isError: true);
        return;
      }
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
      // Refresh assignees and hashtags immediately for the newly linked customer
      await Future.wait([
        _loadAssignees(),
        _loadCustomerHashtags(pickedCustomerId),
      ]);

      // Auto-link a Job Card if one exists for this customer (pick most recent available)
      try {
        final qs = await FirebaseFirestore.instance
            .collection('workspaces')
            .doc(widget.workspaceId)
            .collection('cards')
            .where('customerId', isEqualTo: pickedCustomerId)
            .limit(1)
            .get();
        if (qs.docs.isNotEmpty) {
          final d = qs.docs.first;
          final dm = d.data();
          final title = (dm['title'] ?? dm['name'] ?? 'Card').toString();
          await _chatroomDoc.set({'jobCardId': d.id, 'jobCardTitle': title}, SetOptions(merge: true));
          if (mounted) {
            setState(() { _jobCardId = d.id; _jobCardTitle = title; });
            _showTopSnack('เชื่อม Job Card ล่าสุดแล้ว');
          }
        }
      } catch (_) {}

      _showTopSnack('เชื่อมลูกค้ากับห้องแชทแล้ว');
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('เชื่อมลูกค้าไม่สำเร็จ: $e', isError: true);
    }
  }

  Future<void> _openJobCardPicker() async {
    // Prevent opening picker if no customer is linked
    if (_currentCustomerId == null || _currentCustomerId!.isEmpty) {
      _showTopSnack('กรุณาเชื่อมลูกค้าก่อนผูก Job Card', isError: true);
      return;
    }
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
          child: JobCardPickerSheet(
            workspaceId: widget.workspaceId,
            customerId: _currentCustomerId, // Pass customerId
          ),
        );
      },
    );

    if (result == null) return;

    try {
      // Permission to link job card to chat
      final svc = MobilePermissionsService.to;
      if (!(svc.isOwner || svc.can('chat:assign'))) {
        _showTopSnack('คุณไม่มีสิทธิ์เชื่อม Job Card กับแชท', isError: true);
        return;
      }
      await _chatroomDoc.set({
        'jobCardId': result.cardId,
        'jobCardTitle': result.title,
      }, SetOptions(merge: true));

      // If chatroom has no customer linked, try to link from the selected card
      try {
        if ((_currentCustomerId ?? '').isEmpty) {
          final snap = await FirebaseFirestore.instance
              .collection('workspaces')
              .doc(widget.workspaceId)
              .collection('cards')
              .doc(result.cardId)
              .get();
          final m = snap.data() ?? {};
          final cid = (m['customerId'] ?? m['customer']?['id'])?.toString();
          final cname = (m['customer'] is Map) ? (m['customer']['name']?.toString() ?? '') : (m['customerName']?.toString() ?? '');
          if (cid != null && cid.isNotEmpty) {
            await _chatroomDoc.set({'customerId': cid, if (cname.isNotEmpty) 'customerName': cname}, SetOptions(merge: true));
            if (mounted) {
              setState(() { _currentCustomerId = cid; _currentCustomerName = cname.isNotEmpty ? cname : _currentCustomerName; });
              _loadAssignees();
              _loadCustomerHashtags(cid);
            }
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _jobCardId = result.cardId;
        _jobCardTitle = result.title;
      });
      _showTopSnack('ผูก Job Card แล้ว');
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('ผูก Job Card ไม่สำเร็จ: $e', isError: true);
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
        _showTopSnack('ไม่พบ Job Card ที่เชื่อม', isError: true);
        return;
      }
      final data = snap.data() ?? {};
      final job = JobCard.fromMap(data, snap.id);

      // Ensure BoardController is ready with the current workspace for EditCardPage
      final boardController = Get.isRegistered<BoardController>()
          ? Get.find<BoardController>()
          : Get.put(BoardController());
      if (boardController.currentWorkspaceId.value != widget.workspaceId) {
        await boardController.switchWorkspace(widget.workspaceId);
      }

      // Close the bottom sheet first, then navigate to detail page using Get.to
      // Use Get.back() to dismiss the sheet without depending on this context after pop
      if (Get.isOverlaysOpen) {
        // Best effort close; if it's not a Get dialog/sheet, also try Navigator.pop
        try { Get.back(); } catch (_) { /* ignore */ }
      } else if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Schedule navigation on next microtask/frame without checking mounted
      await Future.microtask(() {});
      Get.to(() => EditCardPage(card: job));
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('เปิด Job Card ไม่สำเร็จ', isError: true);
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
                    guardAction(context, 'chat:assign', () async {
                      setState(() => _botEnabled = !_botEnabled);
                      if (widget.onBotStatusChanged != null) {
                        widget.onBotStatusChanged!(_botEnabled);
                      } else {
                        try {
                          await _chatroomDoc.update({'bot_status': _botEnabled ? 'Y' : 'N'});
                          if (mounted) {
                            _showTopSnack(_botEnabled ? 'เปิดบอทตอบกลับอัตโนมัติ' : 'ปิดบอทตอบกลับอัตโนมัติ');
                          }
                        } catch (e) {
                          if (mounted) {
                            _showTopSnack('อัปเดตการตอบกลับอัตโนมัติไม่สำเร็จ: $e', isError: true);
                          }
                        }
                      }
                    }, deniedMessage: 'คุณไม่มีสิทธิ์จัดการบอทแชท');
                  },
                ),
                ChatStatusButton(
                  icon: Icons.chat_bubble,
                  label: 'กำลัง\nดำเนินการ',
                  selected: _status == ChatStatus.inProgress,
                  tooltip: 'ห้องแชทกำลังดำเนินการ',
                  onTap: () async {
                    guardAction(context, 'chat:assign', () async {
                      setState(() => _status = ChatStatus.inProgress);
                      widget.onStatusChange(_status);
                    }, deniedMessage: 'คุณไม่มีสิทธิ์เปลี่ยนสถานะห้องแชท');
                  },
                ),
                ChatStatusButton(
                  icon: Icons.check,
                  label: 'สำเร็จ\n',
                  selected: _status == ChatStatus.done,
                  tooltip: 'คุยจบแล้ว',
                  onTap: () async {
                    guardAction(context, 'chat:assign', () async {
                      setState(() => _status = ChatStatus.done);
                      widget.onStatusChange(_status);
                    }, deniedMessage: 'คุณไม่มีสิทธิ์เปลี่ยนสถานะห้องแชท');
                  },
                ),
                ChatStatusButton(
                  icon: Icons.push_pin_outlined,
                  label: 'ปักหมุด\n',
                  selected: _pinned,
                  tooltip: 'ปักหมุดห้องแชท',
                  onTap: () async {
                    guardAction(context, 'chat:assign', () async {
                      setState(() => _pinned = !_pinned);
                      if (widget.onPinChanged != null) {
                        widget.onPinChanged!(_pinned);
                      } else {
                        try {
                          await _chatroomDoc.update({
                            'chat_pin': _pinned ? 'Y' : 'N',
                            'bot_status': _botEnabled ? 'Y' : 'N',
                          });
                          if (mounted) {
                            _showTopSnack(_pinned ? 'ปักหมุดแล้ว' : 'ยกเลิกปักหมุดแล้ว');
                          }
                        } catch (e) {
                          if (mounted) {
                            _showTopSnack('อัปเดตปักหมุดไม่สำเร็จ: $e', isError: true);
                          }
                        }
                      }
                    }, deniedMessage: 'คุณไม่มีสิทธิ์ปักหมุดห้องแชท');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 24),
            ChatMenuTile(
              icon: Icons.sticky_note_2_outlined,
              text: 'โน้ต',
              onTap: () {
                final svc = MobilePermissionsService.to;
                if (svc.isOwner || svc.can('customer:edit:all') || svc.can('customer:edit:assigned')) {
                  _openNotes();
                } else {
                  _showTopSnack('คุณไม่มีสิทธิ์แก้ไขข้อมูลลูกค้า/บันทึกโน้ต', isError: true);
                }
              },
              closeOnTap: false,
            ),

            ChatMenuTile(
              icon: Icons.supervised_user_circle_outlined,
              text: 'เพิ่มลูกค้า',
              onTap: () {
                final svc = MobilePermissionsService.to;
                if (svc.isOwner || svc.can('customer:view:all') || svc.can('customer:view:assigned')) {
                  _openCustomerPicker();
                } else {
                  _showTopSnack('คุณไม่มีสิทธิ์ดูรายชื่อลูกค้า', isError: true);
                }
              },
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

              // Hashtags picker for linked customer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE5E7EB))),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('แฮชแท็กของลูกค้า', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        if (_loadingHashtags)
                          const LinearProgressIndicator(minHeight: 2)
                        else ...[
                          HashtagInputField(
                            selectedHashtags: _pendingHashtagIds,
                            availableHashtags: _availableHashtags,
                            onHashtagsChanged: (ids) {
                              setState(() => _pendingHashtagIds = ids);
                            },
                            label: 'แฮชแท็ก',
                            hintText: 'เลือกแฮชแท็กของลูกค้า',
                            workspaceId: widget.workspaceId,
                          ),
                          const SizedBox(height: 8),
                          if (_isHashtagDirty)
                            PermissionGuard(
                              anyOf: const ['customer:edit:all', 'customer:edit:assigned'],
                              child: Row(
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() => _pendingHashtagIds = List<String>.from(_selectedHashtagIds));
                                    },
                                    child: Text('cancel'.tr),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _persistCustomerHashtags(_pendingHashtagIds),
                                      child: Text('confirm'.tr),
                                    ),
                                  ),
                                ],
                              ),
                              fallback: const SizedBox.shrink(),
                            ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: PermissionGuard(
                              anyOf: const ['customer:edit:all', 'customer:edit:assigned'],
                              child: OutlinedButton.icon(
                                onPressed: _creatingHashtag ? null : _createNewCustomerHashtag,
                                icon: const Icon(Icons.add, size: 16),
                                label: Text(_creatingHashtag ? 'กำลังเพิ่ม...' : 'เพิ่มแฮชแท็กใหม่  '),
                              ),
                              fallback: const SizedBox.shrink(),
                            ),
                          ),
                        ],
                      ],

                    ),
                  ),
                ),
              ),
            ],
            ChatMenuTile(
              icon: Icons.card_travel_outlined,
              text: 'ผูก Job Card',
              onTap: () {
                final svc = MobilePermissionsService.to;
                if (svc.isOwner || svc.can('jobcard:view:all') || svc.can('jobcard:view:assigned')) {
                  _openJobCardPicker();
                } else {
                  _showTopSnack('คุณไม่มีสิทธิ์ดู/เชื่อม Job Card', isError: true);
                }
              },
              closeOnTap: false,
            ),
            if ((_jobCardId ?? '').isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: InkWell(
                  onTap: () {
                    final svc = MobilePermissionsService.to;
                    if (svc.isOwner || svc.can('jobcard:view:all') || svc.can('jobcard:view:assigned')) {
                      _openJobCardDetail();
                    } else {
                      _showTopSnack('คุณไม่มีสิทธิ์ดูรายละเอียด Job Card', isError: true);
                    }
                  },
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
              onTap: () => guardAction(context, 'chat:assign', _openUserPicker, deniedMessage: 'คุณไม่มีสิทธิ์มอบหมายห้องแชท'),
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
                        onPressed: () => guardAction(context, 'chat:assign', () => _removeAssignee(u), deniedMessage: 'คุณไม่มีสิทธิ์ลบผู้ดูแล'),
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
              onTap: () => guardAction(context, 'chat:assign', _renameChat, deniedMessage: 'คุณไม่มีสิทธิ์เปลี่ยนชื่อแชท'),
            ),
            ChatMenuTile(
              icon: Icons.refresh_outlined,
              text: 'รีเซ็ตชื่อแชท',
              onTap: () => guardAction(context, 'chat:assign', _resetChatName, deniedMessage: 'คุณไม่มีสิทธิ์รีเซ็ตชื่อแชท'),
            ),
            ChatMenuTile(
              icon: Icons.delete_outline,
              text: 'ลบแชท',
              danger: true,
              onTap: () => guardAction(context, 'chat:assign', () {
                if (widget.onDelete != null) widget.onDelete!();
              }, deniedMessage: 'คุณไม่มีสิทธิ์ลบแชท'),
            ),
          ],

        ),
      ),
    );
  }
}
