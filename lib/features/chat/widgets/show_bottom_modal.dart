// show_bottom_modal.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:async';

import '../../board/controller/board_controller.dart';
import 'chat_status_button.dart';
import 'chat_menu_tile.dart';
import 'notes_sheet.dart';
import 'user_picker_sheet.dart';
import 'customer_picker_sheet.dart';
import '../../board/view/edit_card_page.dart';
import '../../board/view/create_card_page.dart';
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
  // Linked Job Card state (support multiple)
  List<String> _jobCardIds = [];
  List<String> _jobCardTitles = [];
  List<String> _jobCardDocNos = [];
  // Pending (unsaved) Job Card selection


  List<String> _pendingJobCardIds = [];
  List<String> _pendingJobCardTitles = [];
  List<String> _pendingJobCardDocNos = [];

  bool get _isJobCardDirty {
    if (_pendingJobCardIds.length != _jobCardIds.length) return true;
    for (int i = 0; i < _pendingJobCardIds.length; i++) {
      if (_pendingJobCardIds[i] != _jobCardIds[i]) return true;
    }
    if (_pendingJobCardTitles.length != _jobCardTitles.length) return true;
    for (int i = 0; i < _pendingJobCardTitles.length; i++) {
      if ((_pendingJobCardTitles[i]) != (_jobCardTitles[i])) return true;
    }
    if (_pendingJobCardDocNos.length != _jobCardDocNos.length) return true;
    for (int i = 0; i < _pendingJobCardDocNos.length; i++) {
      if ((_pendingJobCardDocNos[i]) != (_jobCardDocNos[i])) return true;
    }
    return false;
  }

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



  // Resolve an initial customer id to prefill on CreateCardPage when creating a Job Card from chat
  // Priority: current linked customer -> chatroom document -> first linked job card's customer -> null
  Future<String?> _resolveInitialCustomerId() async {
    // 1) If we already have a linked customer in state, use it
    final current = _currentCustomerId?.trim() ?? '';
    if (current.isNotEmpty) return current;

    try {
      // 2) Check chatroom document (fresh read)
      final snap = await _chatroomDoc.get();
      final m = snap.data() ?? {};
      final chatCid = (m['customerId'] ?? m['customer_id'] ?? m['customer']?['id'])?.toString();
      if (chatCid != null && chatCid.isNotEmpty) return chatCid;

      // 3) If any job card already linked, try to read its customer
      final sourceIds = _isJobCardDirty ? _pendingJobCardIds : _jobCardIds;
      if (sourceIds.isNotEmpty) {
        final firstId = sourceIds.first;
        try {
          final cSnap = await FirebaseFirestore.instance
              .collection('workspaces')
              .doc(widget.workspaceId)
              .collection('cards')
              .doc(firstId)
              .get();
          final cm = cSnap.data() ?? {};
          final cid = (cm['customerId'] ?? cm['customer']?['id'])?.toString();
          if (cid != null && cid.isNotEmpty) return cid;
        } catch (_) {/* ignore */}
      }
    } catch (_) {
      // ignore and fall through
    }

    // 4) Nothing found
    return null;
  }

  Future<void> _loadJobCardsByIds(List<String> cardIds) async {
    final titles = <String>[];
    final nos = <String>[];
    for (final id in cardIds) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('workspaces')
            .doc(widget.workspaceId)
            .collection('cards')
            .doc(id)
            .get();
        final m = snap.data() ?? {};
        final title = (m['title'] ?? m['name'] ?? '').toString();
        titles.add(title.isNotEmpty ? title : id);
        final docNo = (m['customId'] ?? '').toString();
        nos.add(docNo);
      } catch (_) {
        titles.add(id);
        nos.add('');
      }
    }
    if (!mounted) return;
    setState(() { _jobCardTitles = titles; _jobCardDocNos = nos; });
  }


  String _pickDisplayName(Map<String, dynamic> data) {
    return (data['name'] ?? data['who_name'] ?? data['displayName'] ?? data['customerName'] ?? '')
        .toString();
  }

  // Remove unused _hexToColor and add hex formatter
  String _colorToHexRGB(Color c) {
    String two(int n) => n.toRadixString(16).padLeft(2, '0');
    final r = ((c.r) * 255.0).round() & 0xff;
    final g = ((c.g) * 255.0).round() & 0xff;
    final b = ((c.b) * 255.0).round() & 0xff;
    return '#${two(r)}${two(g)}${two(b)}';
  }

  Future<void> _renameChat() async {
    try {
      final data = await _getChatroomData();
      final currentName = _pickDisplayName(data);
      final controller = TextEditingController(text: currentName);
      final newName = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('chat_rename'.tr),
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

  // Load hashtags for chatroom when no customer is linked
  Future<void> _loadChatroomHashtags() async {
    setState(() { _loadingHashtags = true; });
    try {
      final all = await _hashtagService.getWorkspaceHashtags(widget.workspaceId);
      // Allow chat if scopes empty or chat==true
      final filtered = all.where((h) {
        final s = h.scopes;
        return h.enabled && (s.isEmpty || (s['chat'] == true));
      }).toList();
      filtered.sort((a, b) {
        final byUsage = (b.totalUsage).compareTo(a.totalUsage);
        if (byUsage != 0) return byUsage;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      _availableHashtags = filtered;

      final snap = await _chatroomDoc.get();
      final m = snap.data() ?? {};
      final ids = ((m['hashtagIds'] as List?) ?? const []).map((e) => e.toString()).toList();
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

  // Persist hashtags to chatroom when no customer is linked
  Future<void> _persistChatroomHashtags(List<String> ids) async {
    try {
      // Compose display names with #
      final names = ids.map((id) {
        final h = _availableHashtags.firstWhere(
          (x) => x.id == id,
          orElse: () => HashtagOption(id: id, name: id, color: '#ef4444', totalUsage: 0, enabled: true, scopes: const {}),
        );
        final name = h.name.startsWith('#') ? h.name : '#${h.name}';
        return name;
      }).toList();

      await _chatroomDoc.set({
        'hashtagIds': ids,
        'hashtags': names,
      }, SetOptions(merge: true));

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
    // Allow creation even when no customer is linked; we'll refresh appropriate list after creating
    final controller = TextEditingController();
    Color selectedColor = const Color(0xFFF97316); // Default orange color
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('add_new_hashtag'.tr),
        content: StatefulBuilder(
          builder: (ctx, setStateDialog) {
            final presets = <Color>[
              const Color(0xFFF97316), // orange
              const Color(0xFFEF4444), // red
              const Color(0xFF22C55E), // green
              const Color(0xFF3B82F6), // blue
              const Color(0xFFA855F7), // purple
              const Color(0xFFEAB308), // yellow
              const Color(0xFF06B6D4), // cyan
              const Color(0xFF9CA3AF), // gray
              const Color(0xFF111827), // near-black
            ];

            void pickColor(Color color) {
              setStateDialog(() {
                selectedColor = color;
              });
            }

            void openColorPicker() {
              showDialog(
                context: ctx,
                builder: (context) => AlertDialog(
                  title: Text('select_color'.tr),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (Color color) {
                        selectedColor = color;
                      },
                      enableAlpha: false,
                      displayThumbColor: true,
                      labelTypes: const [], // Updated from deprecated showLabel
                      paletteType: PaletteType.hsv,
                      pickerAreaHeightPercent: 0.8,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('cancel'.tr),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setStateDialog(() {}); // Update parent dialog
                        Navigator.pop(context);
                      },
                      child: Text('select'.tr),
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(hintText: 'hashtag_name_hint'.tr),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                Text('select_color'.tr, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final color in presets)
                      InkWell(
                        onTap: () => pickColor(color),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (color == selectedColor) ? Colors.black87 : Colors.black12,
                              width: (color == selectedColor) ? 2.4 : 1,
                            ),
                          ),
                          child: (color == selectedColor)
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: openColorPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black26),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('select_more_color'.tr, style: Theme.of(ctx).textTheme.bodyMedium),
                        const SizedBox(width: 8),
                        const Icon(Icons.palette, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: selectedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_colorToHexRGB(selectedColor).toUpperCase(),
                         style: Theme.of(ctx).textTheme.bodySmall),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text('add'.tr)),
        ],
      ),
    );
    if (name == null) return;
    final safeName = name.replaceAll('#', '').trim();
    if (safeName.isEmpty) {
      _showTopSnack('enter_hashtag'.tr);
      return;
    }

    setState(() => _creatingHashtag = true);
    try {
      final color = _colorToHexRGB(selectedColor);
      final hasCustomer = (_currentCustomerId ?? '').isNotEmpty;
      final scopes = hasCustomer ? const {'customer': true} : const {'chat': true};
      final ok = await _hashtagService.createHashtag(
        widget.workspaceId,
        safeName,
        color,
        scopes,
      );
      if (!ok) {
        if (!mounted) return;
        _showTopSnack('chat_hashtag_create_failed'.tr, isError: true);
        return;
      }
      // Reload available hashtags and keep current selections; then add new tag to pending only
      if (hasCustomer) {
        await _loadCustomerHashtags(_currentCustomerId!);
      } else {
        await _loadChatroomHashtags();
      }
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

  Future<void> _confirmPersistJobCards() async {
    try {
      final svc = MobilePermissionsService.to;
      if (!(svc.isOwner || svc.can('chat:assign'))) {
        _showTopSnack('no_permission_link_jobcard'.tr, isError: true);
        return;
      }
      final ids = List<String>.from(_pendingJobCardIds);
      final titles = List<String>.from(_pendingJobCardTitles);
      final nos = List<String>.from(_pendingJobCardDocNos);
      // Build linkedJobCards array per spec
      final links = <Map<String, dynamic>>[];
      for (int i = 0; i < ids.length; i++) {
        final id = ids[i];
        final docNo = (i < nos.length && nos[i].isNotEmpty) ? nos[i] : (i < titles.length ? titles[i] : id);
        links.add({'id': id, 'docNo': docNo, 'type': 'JC'});
      }

      await _chatroomDoc.set({
        'linkedJobCards': links,
        // Legacy fields for backward compatibility
        'jobCardIds': ids,
        'jobCardTitles': nos.isNotEmpty ? nos : titles,
        if (ids.isNotEmpty) 'jobCardId': ids.first else 'jobCardId': FieldValue.delete(),
        if ((nos.isNotEmpty ? nos : titles).isNotEmpty) 'jobCardTitle': (nos.isNotEmpty ? nos : titles).first else 'jobCardTitle': FieldValue.delete(),
      }, SetOptions(merge: true));

      // If chatroom has no customer linked, try to link from the first selected card
      if ((_currentCustomerId ?? '').isEmpty && ids.isNotEmpty) {
        try {
          final firstId = ids.first;
          final snap = await FirebaseFirestore.instance
              .collection('workspaces')
              .doc(widget.workspaceId)
              .collection('cards')
              .doc(firstId)
              .get();
          final m = snap.data() ?? {};
          final cid = (m['customerId'] ?? m['customer']?['id'])?.toString();
          final cname = (m['customer'] is Map) ? (m['customer']['name']?.toString() ?? '') : (m['customerName']?.toString() ?? '');
          if (cid != null && cid.isNotEmpty) {
            await _chatroomDoc.set({'customerId': cid, if (cname.isNotEmpty) 'customerName': cname}, SetOptions(merge: true));
            if (mounted) {
              await _migrateNotesToCustomer(cid);
              await _migrateHashtagsFromChatroomToCustomer(cid);
              setState(() { _currentCustomerId = cid; _currentCustomerName = cname.isNotEmpty ? cname : _currentCustomerName; });
              _loadAssignees();
              _loadCustomerHashtags(cid);
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _jobCardIds = List<String>.from(ids);
        _jobCardTitles = List<String>.from(titles);
        _jobCardDocNos = List<String>.from(nos);
      });
      _showTopSnack('jobcard_linked_latest'.tr);
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('jobcard_open_failed'.trParams({'error': '$e'}), isError: true);
    }
  }

  Future<void> _migrateNotesToCustomer(String customerId) async {
    try {
      final ws = FirebaseFirestore.instance.collection('workspaces').doc(widget.workspaceId);
      final chatRef = ws.collection('chatrooms').doc(widget.chatroomId);
      final custRef = ws.collection('customers').doc(customerId);
      final chatSnap = await chatRef.get();
      final custSnap = await custRef.get();
      final chatData = chatSnap.data() ?? {};
      final custData = custSnap.data() ?? {};
      final List<dynamic> rawChat = (chatData['notes'] as List?) ?? const [];
      final List<dynamic> rawCust = (custData['notes'] as List?) ?? const [];
      // Normalize to Map<String,dynamic>
      List<Map<String, dynamic>> toMapList(List<dynamic> src) => src
          .map((e) => e is Map<String, dynamic> ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();
      final chatNotes = toMapList(rawChat);
      final custNotes = toMapList(rawCust);
      if (chatNotes.isEmpty && custNotes.isEmpty) return;

      String keyOf(Map<String, dynamic> n) {
        final sp = (n['storagePath'] ?? '').toString();
        if (sp.isNotEmpty) return 'sp:$sp';
        final url = (n['url'] ?? '').toString();
        if (url.isNotEmpty) return 'url:$url';
        final id = (n['id'] ?? '').toString();
        if (id.isNotEmpty) return 'id:$id';
        final ts = (n['timestamp'] ?? 0).toString();
        final title = (n['title'] ?? n['fileName'] ?? '').toString();
        return 't:$ts|$title';
      }

      final combined = <String, Map<String, dynamic>>{};
      // Seed with existing customer notes
      for (final n in custNotes) {
        combined[keyOf(n)] = n;
      }
      // Merge chat notes; prefer newest timestamp on conflict
      for (final n in chatNotes) {
        final k = keyOf(n);
        final existing = combined[k];
        if (existing == null) {
          combined[k] = n;
        } else {
          final a = (existing['timestamp'] ?? 0) as int? ?? 0;
          final b = (n['timestamp'] ?? 0) as int? ?? 0;
          combined[k] = b >= a ? n : existing;
        }
      }
      // Sort desc by timestamp
      final merged = combined.values.toList()
        ..sort((a, b) => ((b['timestamp'] ?? 0) as int).compareTo((a['timestamp'] ?? 0) as int));

      await custRef.set({'notes': merged}, SetOptions(merge: true));
      // Clear notes from chatroom to avoid confusion
      await chatRef.set({'notes': FieldValue.delete()}, SetOptions(merge: true));

      if (mounted) _showTopSnack('moved_notes_chat_to_customer'.tr);
    } catch (e) {
      if (mounted) _showTopSnack('move_notes_failed'.trParams({'error': '$e'}), isError: true);
    }
  }

  Future<void> _migrateHashtagsFromChatroomToCustomer(String customerId) async {
    try {
      final ws = FirebaseFirestore.instance.collection('workspaces').doc(widget.workspaceId);
      final chatRef = ws.collection('chatrooms').doc(widget.chatroomId);
      final custRef = ws.collection('customers').doc(customerId);

      final chatSnap = await chatRef.get();
      final custSnap = await custRef.get();
      final chatData = chatSnap.data() ?? {};
      final custData = custSnap.data() ?? {};

      final chatIds = ((chatData['hashtagIds'] as List?) ?? const []).map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
      if (chatIds.isEmpty) return; // nothing to migrate

      // Parse existing customer hashtags (strings or objects)
      final rawCustTags = (custData['hashtags'] as List?) ?? const [];
      final existingIds = <String>{};
      final existingMapList = <Map<String, dynamic>>[];
      for (final it in rawCustTags) {
        if (it is String) {
          existingIds.add(it);
          existingMapList.add({'id': it, 'text': it, 'color': '#6B7280'});
        } else if (it is Map) {
          final m = Map<String, dynamic>.from(it);
          final id = (m['id'] ?? m['text'] ?? '').toString();
          if (id.isNotEmpty) {
            existingIds.add(id);
            existingMapList.add({'id': id, 'text': (m['text'] ?? id).toString(), 'color': (m['color'] ?? '#6B7280').toString()});
          }
        }
      }

      // Union
      final unionIds = {...existingIds, ...chatIds};

      // Build full objects using workspace master list for nice names/colors
      final master = await _hashtagService.getWorkspaceHashtags(widget.workspaceId);
      Map<String, HashtagOption> byId = {for (final h in master) h.id: h};

      final mergedObjects = <Map<String, dynamic>>[];
      for (final id in unionIds) {
        final existing = existingMapList.firstWhere(
          (e) => e['id'] == id,
          orElse: () => <String, dynamic>{},
        );
        if (existing.isNotEmpty) {
          mergedObjects.add(existing);
        } else {
          final h = byId[id];
          final name = h?.name ?? id;
          final color = h?.color ?? '#6B7280';
          mergedObjects.add({'id': id, 'text': name, 'color': color});
        }
      }

      await custRef.set({'hashtags': mergedObjects}, SetOptions(merge: true));

      // Mirror to chatroom names with # (ids remain same union)
      final displayNames = mergedObjects
          .map((m) => (m['text']?.toString() ?? ''))
          .where((s) => s.isNotEmpty)
          .map((s) => s.startsWith('#') ? s : '#$s')
          .toList();
      await chatRef.set({'hashtagIds': unionIds.toList(), 'hashtags': displayNames}, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _selectedHashtagIds = unionIds.toList();
          _pendingHashtagIds = unionIds.toList();
        });
      }
    } catch (_) {
      // silent fail to avoid blocking link flow
    }
  }

  Future<void> _migrateNotesFromCustomerToChatroom(String customerId) async {
    try {
      final ws = FirebaseFirestore.instance.collection('workspaces').doc(widget.workspaceId);
      final chatRef = ws.collection('chatrooms').doc(widget.chatroomId);
      final custRef = ws.collection('customers').doc(customerId);
      final chatSnap = await chatRef.get();
      final custSnap = await custRef.get();
      final chatData = chatSnap.data() ?? {};
      final custData = custSnap.data() ?? {};
      final List<dynamic> rawChat = (chatData['notes'] as List?) ?? const [];
      final List<dynamic> rawCust = (custData['notes'] as List?) ?? const [];
      List<Map<String, dynamic>> toMapList(List<dynamic> src) => src
          .map((e) => e is Map<String, dynamic> ? Map<String, dynamic>.from(e) : <String, dynamic>{})
          .where((m) => m.isNotEmpty)
          .toList();
      final chatNotes = toMapList(rawChat);
      final custNotes = toMapList(rawCust);
      if (chatNotes.isEmpty && custNotes.isEmpty) return;

      String keyOf(Map<String, dynamic> n) {
        final sp = (n['storagePath'] ?? '').toString();
        if (sp.isNotEmpty) return 'sp:$sp';
        final url = (n['url'] ?? '').toString();
        if (url.isNotEmpty) return 'url:$url';
        final id = (n['id'] ?? '').toString();
        if (id.isNotEmpty) return 'id:$id';
        final ts = (n['timestamp'] ?? 0).toString();
        final title = (n['title'] ?? n['fileName'] ?? '').toString();
        return 't:$ts|$title';
      }

      final combined = <String, Map<String, dynamic>>{};
      // Seed with existing customer notes
      for (final n in custNotes) {
        combined[keyOf(n)] = n;
      }
      // Merge chat notes; prefer newest timestamp on conflict
      for (final n in chatNotes) {
        final k = keyOf(n);
        final existing = combined[k];
        if (existing == null) {
          combined[k] = n;
        } else {
          final a = (existing['timestamp'] ?? 0) as int? ?? 0;
          final b = (n['timestamp'] ?? 0) as int? ?? 0;
          combined[k] = b >= a ? n : existing;
        }
      }
      // Sort desc by timestamp
      final merged = combined.values.toList()
        ..sort((a, b) => ((b['timestamp'] ?? 0) as int).compareTo((a['timestamp'] ?? 0) as int));

      await chatRef.set({'notes': merged}, SetOptions(merge: true));
      // Clear notes from customer to avoid confusion
      await custRef.set({'notes': FieldValue.delete()}, SetOptions(merge: true));

      if (mounted) _showTopSnack('moved_notes_customer_to_chat'.tr);
    } catch (e) {
      if (mounted) _showTopSnack('move_notes_failed'.trParams({'error': '$e'}), isError: true);
    }
  }


  Future<void> _unlinkCustomer() async {
    final cid = _currentCustomerId?.trim() ?? '';
    if (cid.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('unlink_customer_title'.tr),
        content: Text('unlink_customer_description'.tr),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('confirm'.tr)),
        ],
      ),
    );
    if (ok != true) return;

    try {
      // Copy customer notes back into chatroom notes
      await _migrateNotesFromCustomerToChatroom(cid);
      // Remove customer link fields
      await _chatroomDoc.set({
        'customerId': FieldValue.delete(),
        'customerName': FieldValue.delete(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() { _currentCustomerId = null; _currentCustomerName = null; });
      await _loadAssignees();
      _showTopSnack('unlink_customer_success'.tr);
    } catch (e) {
      if (mounted) _showTopSnack('unlink_customer_failed'.trParams({'error': '$e'}), isError: true);
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
    } else {
      // Load chatroom-level hashtags when no customer is linked
      _loadChatroomHashtags();
    }


    // Realtime sync with chatroom document
    _chatroomSub = _chatroomDoc.snapshots().listen((snap) {
      final wasDirty = _isJobCardDirty; // capture before applying remote changes
      final data = snap.data() ?? {};
      final pinned = (data['chat_pin'] ?? 'N') == 'Y';
      final bot = (data['bot_status'] ?? 'N') == 'Y';
      final statusRaw = (data['chatroom_status'] ?? '').toString().toUpperCase();
      final status = statusRaw == 'DONE' ? ChatStatus.done : ChatStatus.inProgress;
      final cid = (data['customerId'] ?? data['customer_id'] ?? data['customer']?['id'])?.toString();
      final cname = (data['customerName'] ?? '').toString();

      // Multi job card fields with legacy fallback
      List<String> jobCardIds = (data['jobCardIds'] as List?)?.map((e) => e.toString()).toList() ?? [];
      List<String> jobCardTitles = (data['jobCardTitles'] as List?)?.map((e) => e.toString()).toList() ?? [];
      List<String> jobCardDocNos = <String>[];
      // New spec: linkedJobCards: [{id, docNo, type:'JC'}]
      if (data['linkedJobCards'] is List) {
        final arr = (data['linkedJobCards'] as List);
        final ids = <String>[];
        final nos = <String>[];
        for (final it in arr) {
          if (it is Map) {
            final id = (it['id'] ?? '').toString();
            if (id.isNotEmpty) ids.add(id);
            final docNo = (it['docNo'] ?? '').toString();
            nos.add(docNo);
          }
        }
        if (ids.isNotEmpty) {
          jobCardIds = ids;
          jobCardDocNos = nos;
          // If no explicit titles, use docNo as display titles
          if (jobCardTitles.isEmpty) {
            jobCardTitles = List<String>.from(nos);
          }
        }
      }
      // Try alternative shapes/fields
      if (jobCardIds.isEmpty) {
        jobCardIds = (data['linkedCardIds'] as List?)?.map((e) => e.toString()).toList() ??
            (data['cardIds'] as List?)?.map((e) => e.toString()).toList() ??
            (data['cards'] as List?)?.map((e) => e.toString()).toList() ?? [];
      }
      if (jobCardTitles.isEmpty) {
        jobCardTitles = (data['linkedCardTitles'] as List?)?.map((e) => e.toString()).toList() ??
            (data['cardTitles'] as List?)?.map((e) => e.toString()).toList() ?? [];
      }
      // objects array fallback e.g., jobCards: [{id, title}]
      if (jobCardIds.isEmpty && data['jobCards'] is List) {
        final arr = (data['jobCards'] as List);
        final ids = <String>[];
        final titles = <String>[];
        for (final it in arr) {
          if (it is Map) {
            final id = (it['id'] ?? '').toString();
            if (id.isNotEmpty) ids.add(id);
            final t = (it['title'] ?? it['name'] ?? '').toString();
            if (t.isNotEmpty) titles.add(t);
          }
        }
        if (ids.isNotEmpty) {
          jobCardIds = ids;
          if (titles.isNotEmpty) jobCardTitles = titles;
        }
      }
      final prevCid = _currentCustomerId ?? '';
      if (!mounted) return;
      setState(() {
        _pinned = pinned;
        _botEnabled = bot;
        _status = status;
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
            _loadChatroomHashtags();
          }
        } else {
          if (cname.isNotEmpty) _currentCustomerName = cname;
          if ((_currentCustomerId ?? '').isEmpty) {
            _loadAssignees();
          }
        }
        if (jobCardIds.toString() != _jobCardIds.toString()) {
          _jobCardIds = jobCardIds;
          if (jobCardTitles.isNotEmpty) {
            _jobCardTitles = jobCardTitles;
          } else if (_jobCardIds.isNotEmpty) {
            _loadJobCardsByIds(_jobCardIds);
          } else {
            _jobCardTitles = [];
          }
          // Update docNos if present; otherwise load
          if (jobCardDocNos.isNotEmpty) {
            _jobCardDocNos = jobCardDocNos;
          } else if (_jobCardIds.isNotEmpty) {
            _loadJobCardsByIds(_jobCardIds);
          } else {
            _jobCardDocNos = [];
          }
          // Use pre-captured dirty state to decide syncing pending
          if (!wasDirty) {
            _pendingJobCardIds = List<String>.from(_jobCardIds);
            _pendingJobCardTitles = List<String>.from(_jobCardTitles);
            _pendingJobCardDocNos = List<String>.from(_jobCardDocNos);
          }
        } else {
          if (jobCardTitles.isNotEmpty && jobCardTitles.toString() != _jobCardTitles.toString()) {
            _jobCardTitles = jobCardTitles;
            if (!wasDirty) {
              _pendingJobCardTitles = List<String>.from(_jobCardTitles);
            }
          }
          if (jobCardDocNos.isNotEmpty && jobCardDocNos.toString() != _jobCardDocNos.toString()) {
            _jobCardDocNos = jobCardDocNos;
            if (!wasDirty) {
              _pendingJobCardDocNos = List<String>.from(_jobCardDocNos);
            }
          }
        }
      });
      final newCid = (cid ?? '');
      if (prevCid.isEmpty && newCid.isNotEmpty) {
        _migrateHashtagsFromChatroomToCustomer(newCid).then((_) => _loadCustomerHashtags(newCid));
      }
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
    // Open notes directly; if no customer is linked, save notes at chatroom level
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
            chatroomId: widget.chatroomId,
            customerId: _currentCustomerId, // may be null; NotesSheet will fallback to chatroom-level
          ),
        );
      },
    );
  }

  Future<void> _openUserPicker() async {
    // Open in multi-select mode with current assignees preselected
    final preselected = _assignees.map((e) => e.uid).toList();
    final pickedUids = await showModalBottomSheet<List<String>>(
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
          child: UserPickerSheet(
            workspaceId: widget.workspaceId,

            multiSelect: true,
            initialSelectedUids: preselected,
          ),
        );
      },
    );
    if (pickedUids != null && pickedUids.isNotEmpty) {
      final unique = pickedUids.toSet().toList();
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
                .set({'assignees': FieldValue.arrayUnion(unique)}, SetOptions(merge: true));
          } else {
            await _chatroomDoc.set({'assignees': FieldValue.arrayUnion(unique)}, SetOptions(merge: true));
          }
          await _loadAssignees();
          // Notify external listener if needed (send first uid to keep backward compatibility)
          if (unique.isNotEmpty) widget.onAssignChanged?.call(unique.first);
          if (mounted) {
            _showTopSnack('assign_sales_success_count'.trParams({'count': '${unique.length}'}));
          }
        } catch (e) {
          if (mounted) {
            _showTopSnack('assign_sales_failed'.trParams({'error': '$e'}), isError: true);
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
      _showTopSnack('remove_assignee_success'.tr);
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('remove_assignee_failed'.trParams({'error': '$e'}), isError: true);
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
          child: CustomerPickerSheet(
            workspaceId: widget.workspaceId,
            initialSelectedId: _currentCustomerId,
          ),
        );
      },
    );

    if (pickedCustomerId == null || pickedCustomerId.isEmpty) return;

    try {
      // Permission to link customer to chat
      final svc = MobilePermissionsService.to;
      if (!(svc.isOwner || svc.can('chat:assign'))) {
        _showTopSnack('no_permission_link_customer'.tr, isError: true);
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
      // Migrate any existing chat-level notes into the newly linked customer, then refresh
      await _migrateNotesToCustomer(pickedCustomerId);
      // Migrate chat-level hashtags into the newly linked customer
      await _migrateHashtagsFromChatroomToCustomer(pickedCustomerId);
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
          final docNo = (dm['customId'] ?? title).toString();
          final link = {'id': d.id, 'docNo': docNo, 'type': 'JC'};
          await _chatroomDoc.set({
            'linkedJobCards': [link],
            'jobCardIds': [d.id],
            'jobCardTitles': [docNo],
            'jobCardId': d.id,
            'jobCardTitle': docNo,
          }, SetOptions(merge: true));
          if (mounted) {
            setState(() { _jobCardIds = [d.id]; _jobCardTitles = [title]; _jobCardDocNos = [docNo]; });
            _showTopSnack('jobcard_linked_latest'.tr);
          }
        }
      } catch (_) {}

      _showTopSnack('link_customer_success'.tr);
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('link_customer_failed'.trParams({'error': '$e'}), isError: true);
    }
  }

  Future<void> _openJobCardPicker() async {
    // Require a customer to be selected before creating/linking a Job Card
    Future<bool> _ensureCustomerSelectedForJobCard() async {
      if ((_currentCustomerId ?? '').isNotEmpty) return true;
      // Check permission to view customers before opening picker
      final svc = MobilePermissionsService.to;
      final canViewCustomers = svc.isOwner || svc.can('customer:view:all') || svc.can('customer:view:assigned');
      if (!canViewCustomers) {
        _showTopSnack('no_permission_view_customers'.tr, isError: true);
        return false;
      }
      // Inform user and open customer picker
      _showTopSnack('link_customer_first_for_jobcard'.tr);
      await _openCustomerPicker();
      return ((_currentCustomerId ?? '').isNotEmpty);
    }




    // Guard: ensure customer is selected
    final okProceed = await _ensureCustomerSelectedForJobCard();
    if (!okProceed) return;

    // Open Create Job Card page instead of picker; upon success, link to chatroom and customer automatically
    try {
      // Ensure BoardController is on the right workspace context (same as _openJobCardDetail)
      final boardController = Get.isRegistered<BoardController>() ? Get.find<BoardController>() : Get.put(BoardController());
      if (boardController.currentWorkspaceId.value != widget.workspaceId) {
        await boardController.switchWorkspace(widget.workspaceId);
      }

      // Resolve a non-null initial customer id when possible
      final initCid = await _resolveInitialCustomerId();

      final String? cardId = await Get.to<String>(() => CreateCardPage(
            workspaceId: widget.workspaceId,
            initialCustomerId: initCid,
          ));
      if (cardId == null || cardId.isEmpty) return;

      // Fetch the created card to collect docNo/title and customer info
      final snap = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('cards')
          .doc(cardId)
          .get();
      if (!snap.exists) {
        _showTopSnack('jobcard_not_found'.tr, isError: true);
        return;
      }
      final m = snap.data() ?? {};
      final title = (m['title'] ?? m['name'] ?? 'Card').toString();
      final docNo = (m['customId'] ?? title).toString();
      final cid = (m['customerId'] ?? m['customer']?['id'])?.toString();
      final cname = (m['customer'] is Map) ? (m['customer']['name']?.toString() ?? '') : (m['customerName']?.toString() ?? '');

      // Persist linkage to chatroom (append)
      final newIds = [..._jobCardIds, cardId];
      final newNos = [..._jobCardDocNos, docNo];
      final links = [
        for (int i = 0; i < _jobCardIds.length; i++)
          {'id': _jobCardIds[i], 'docNo': (_jobCardDocNos.length > i ? _jobCardDocNos[i] : (_jobCardTitles.length > i ? _jobCardTitles[i] : _jobCardIds[i])), 'type': 'JC'},
        {'id': cardId, 'docNo': docNo, 'type': 'JC'},
      ];
      await _chatroomDoc.set({
        'linkedJobCards': links,
        'jobCardIds': newIds,
        'jobCardTitles': newNos,
        'jobCardId': newIds.isNotEmpty ? newIds.first : FieldValue.delete(),
        'jobCardTitle': newNos.isNotEmpty ? newNos.first : FieldValue.delete(),
      }, SetOptions(merge: true));

      // Auto-link customer from job card
      if (cid != null && cid.isNotEmpty) {
        await _chatroomDoc.set({
          'customerId': cid,
          'customer': cname.isNotEmpty ? {'id': cid, 'name': cname} : FieldValue.delete(),
        }, SetOptions(merge: true));
        if (mounted) setState(() => _currentCustomerId = cid);
      }

      if (!mounted) return;
      setState(() {
        _jobCardIds = newIds;
        _jobCardDocNos = newNos;
        _jobCardTitles = newNos; // titles used as docNos above
      });
      _showTopSnack('jobcard_linked_success'.tr);
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('jobcard_link_failed'.trParams({'error': '$e'}), isError: true);
    }
  }

  Future<void> _openJobCardDetail([String? id]) async {
    final sourceIds = _isJobCardDirty ? _pendingJobCardIds : _jobCardIds;
    final cardId = id ?? (sourceIds.isNotEmpty ? sourceIds.first : '');
    if (cardId.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(widget.workspaceId)
          .collection('cards')
          .doc(cardId)
          .get();
      if (!snap.exists) {
        if (!mounted) return;
        _showTopSnack('jobcard_not_found'.tr, isError: true);
        return;
      }
      final data = snap.data() ?? {};
      final job = JobCard.fromMap(data, snap.id);

      final boardController = Get.isRegistered<BoardController>()
          ? Get.find<BoardController>()
          : Get.put(BoardController());
      if (boardController.currentWorkspaceId.value != widget.workspaceId) {
        await boardController.switchWorkspace(widget.workspaceId);
      }

      if (Get.isOverlaysOpen) {
        try { Get.back(); } catch (_) { /* ignore */ }
      } else if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      await Future.microtask(() {});
      Get.to(() => EditCardPage(card: job));
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('jobcard_open_failed'.trParams({'error': '$e'}), isError: true);
    }
  }

  Widget _buildLinkedJobCards() {
    // If no customer is linked, do not show Job Cards section
    if ((_currentCustomerId ?? '').isEmpty) {
      return const SizedBox.shrink();
    }


    final ids = _isJobCardDirty ? _pendingJobCardIds : _jobCardIds;
    final titles = _isJobCardDirty ? _pendingJobCardTitles : _jobCardTitles;
    final docNos = _isJobCardDirty ? _pendingJobCardDocNos : _jobCardDocNos;
    if (ids.isEmpty) return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add button even when no cards yet
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PermissionGuard(
              anyOf: const ['jobcard:create'],
              child: OutlinedButton.icon(
                onPressed: _openJobCardPicker,
                icon: const Icon(Icons.add, size: 14),
                label: Padding(padding: EdgeInsets.only(left: 5,right: 10),child: Text('add_jobcard'.tr,style: TextStyle(fontSize: 14)),),

              ),
              fallback: const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header add button
        ...List.generate(ids.length, (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Card(
            color: Colors.white,
            child: ListTile(
              title: Text((docNos.length > i && docNos[i].isNotEmpty) ? docNos[i] : (titles.length > i && titles[i].isNotEmpty ? titles[i] : ids[i])),
              onTap: () => _openJobCardDetail(ids[i]),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'delete'.tr,
                onPressed: () async {
                  // Delete the job card document instead of just unlinking
                  final svc = MobilePermissionsService.to;
                  final canDelete = svc.isOwner || svc.can('jobcard:delete:all') || svc.can('jobcard:delete:assigned');
                  if (!canDelete) {
                    _showTopSnack('no_permission_delete_jobcard'.tr, isError: true);
                    return;
                  }
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('confirm_delete'.tr),
                      content: Text('confirm_delete_jobcard_message'.tr),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr)),
                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text('delete'.tr)),
                      ],
                    ),
                  );
                  if (ok != true) return;
                  final cardId = ids[i];
                  try {
                    // Delete card doc
                    await FirebaseFirestore.instance
                        .collection('workspaces')
                        .doc(widget.workspaceId)
                        .collection('cards')
                        .doc(cardId)
                        .delete();

                    // Remove from chatroom linkage
                    final newIds = List<String>.from(_jobCardIds)..remove(cardId);
                    final newNos = <String>[];
                    final newLinks = <Map<String, dynamic>>[];
                    for (int k = 0; k < _jobCardIds.length; k++) {
                      final idk = _jobCardIds[k];
                      final nok = (_jobCardDocNos.length > k && _jobCardDocNos[k].isNotEmpty)
                          ? _jobCardDocNos[k]
                          : (_jobCardTitles.length > k ? _jobCardTitles[k] : idk);
                      if (idk == cardId) continue;
                      newNos.add(nok);
                      newLinks.add({'id': idk, 'docNo': nok, 'type': 'JC'});
                    }
                    await _chatroomDoc.set({
                      'linkedJobCards': newLinks,
                      'jobCardIds': newIds,
                      'jobCardTitles': newNos,
                      if (newIds.isNotEmpty) 'jobCardId': newIds.first else 'jobCardId': FieldValue.delete(),
                      if (newNos.isNotEmpty) 'jobCardTitle': newNos.first else 'jobCardTitle': FieldValue.delete(),
                    }, SetOptions(merge: true));

                    if (!mounted) return;
                    setState(() {
                      _jobCardIds = newIds;
                      _jobCardDocNos = newNos;
                      if (_jobCardTitles.length > newIds.length) {
                        _jobCardTitles = _jobCardTitles.take(newIds.length).toList();
                      }
                      _pendingJobCardIds = List<String>.from(_jobCardIds);
                      _pendingJobCardTitles = List<String>.from(_jobCardTitles);
                      _pendingJobCardDocNos = List<String>.from(_jobCardDocNos);
                    });
                    _showTopSnack('jobcard_deleted'.tr);
                  } catch (e) {
                    if (mounted) _showTopSnack('jobcard_delete_failed'.trParams({'error': '$e'}), isError: true);
                  }
                },
              ),
            ),
          ),
        )),

        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Align(
            alignment: Alignment.centerLeft,
            child: PermissionGuard(
              anyOf: const ['jobcard:create'],
              child: OutlinedButton.icon(
                onPressed: _openJobCardPicker,
                icon: const Icon(Icons.add, size: 14),
                label: Padding(padding: EdgeInsets.only(left: 5,right: 10),child: Text('add_jobcard'.tr,style: TextStyle(fontSize: 14)),),

              ),
              fallback: const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildHashtagsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E7EB))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  (_currentCustomerId ?? '').isNotEmpty ? 'customer_hashtags'.tr : 'hashtags'.tr,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
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
                  label: 'hashtags'.tr,
                  hintText: 'select_hashtags'.tr,
                  workspaceId: widget.workspaceId,
                ),
                const SizedBox(height: 8),
                if (_isHashtagDirty)
                  ((_currentCustomerId ?? '').isNotEmpty)
                      ? PermissionGuard(
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
                        )
                      : PermissionGuard(
                          anyOf: const ['chat:manage', 'chat:assign', 'chat:send'],
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
                                  onPressed: () => _persistChatroomHashtags(_pendingHashtagIds),
                                  child: Text('confirm'.tr),
                                ),
                              ),
                            ],
                          ),
                          fallback: const SizedBox.shrink(),
                        ),
                const SizedBox(height: 8),

                // Always allow adding a new hashtag, even if no customer is selected
                Align(
                  alignment: Alignment.centerLeft,
                  child: PermissionGuard(
                    anyOf: ((_currentCustomerId ?? '').isNotEmpty)
                        ? const ['customer:edit:all', 'customer:edit:assigned']
                        : const ['chat:manage', 'chat:assign', 'chat:send'],
                    child: OutlinedButton.icon(
                      onPressed: _creatingHashtag ? null : _createNewCustomerHashtag,
                      icon: const Icon(Icons.add, size: 14),
                      label: Padding(padding: EdgeInsets.only(left: 5,right: 10),child: Text(_creatingHashtag ? 'loading'.tr : 'add_new_hashtag'.tr,style: TextStyle(fontSize: 14)),),
                    ),
                    fallback: const SizedBox.shrink(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
                      Text('more_menu'.tr,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          )),
                      const SizedBox(height: 6),
                      Text('change_chat_status'.tr,
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
                  label: 'auto_reply'.tr,
                  selected: _botEnabled,
                  tooltip: 'toggle_auto_reply'.tr,
                  onTap: () async {
                    guardAction(context, 'chat:assign', () async {
                      setState(() => _botEnabled = !_botEnabled);
                      if (widget.onBotStatusChanged != null) {
                        widget.onBotStatusChanged!(_botEnabled);
                      } else {
                        try {
                          await _chatroomDoc.update({'bot_status': _botEnabled ? 'Y' : 'N'});
                          if (mounted) {
                            _showTopSnack(_botEnabled ? 'bot_enabled'.tr : 'bot_disabled'.tr);
                          }
                        } catch (e) {
                          if (mounted) {
                            _showTopSnack('bot_update_failed'.tr + ': $e', isError: true);
                          }
                        }
                      }
                    }, deniedMessage: 'no_permission_chat_bot'.tr);
                  },
                ),
                ChatStatusButton(
                  icon: Icons.chat_bubble,
                  label: 'chat_status_in_progress'.tr,
                  selected: _status == ChatStatus.inProgress,
                  tooltip: 'chat_in_progress_tooltip'.tr,
                  onTap: () async {
                    guardAction(context, 'chat:assign', () async {
                      setState(() => _status = ChatStatus.inProgress);
                      widget.onStatusChange(_status);
                    }, deniedMessage: 'no_permission_chat_status'.tr);
                  },
                ),
                ChatStatusButton(
                  icon: Icons.check,
                  label: 'chat_status_done'.tr,
                  selected: _status == ChatStatus.done,
                  tooltip: 'chat_done_tooltip'.tr,
                  onTap: () async {
                    guardAction(context, 'chat:assign', () async {
                      setState(() => _status = ChatStatus.done);
                      widget.onStatusChange(_status);
                    }, deniedMessage: 'no_permission_chat_status'.tr);
                  },
                ),
                ChatStatusButton(
                  icon: Icons.push_pin_outlined,
                  label: 'pinned'.tr,
                  selected: _pinned,
                  tooltip: 'pin'.tr,
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
                            _showTopSnack(_pinned ? 'chat_pinned'.tr : 'chat_unpinned'.tr);
                          }
                        } catch (e) {
                          if (mounted) {
                            _showTopSnack('pin_update_failed'.tr + ': $e', isError: true);
                          }
                        }
                      }
                    }, deniedMessage: 'no_permission_chat_status'.tr);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 24),
            ChatMenuTile(
              icon: Icons.sticky_note_2_outlined,
              text: 'notes'.tr,
              onTap: () {
                final svc = MobilePermissionsService.to;
                final hasCustomer = (_currentCustomerId ?? '').isNotEmpty;
                final canCustomerEdit = svc.isOwner || svc.can('customer:edit:all') || svc.can('customer:edit:assigned');
                final canChatNote = svc.isOwner || svc.can('chat:manage') || svc.can('chat:assign') || svc.can('chat:send');
                if ((hasCustomer && canCustomerEdit) || (!hasCustomer && canChatNote)) {
                  _openNotes();
                } else {
                  _showTopSnack('no_permission_edit_note'.tr, isError: true);
                }
              },
              closeOnTap: false,
            ),

            ChatMenuTile(
              icon: Icons.supervised_user_circle_outlined,
              text: 'select_customer'.tr,
              onTap: () {
                final svc = MobilePermissionsService.to;
                if (svc.isOwner || svc.can('customer:view:all') || svc.can('customer:view:assigned')) {
                  _openCustomerPicker();
                } else {
                  _showTopSnack('no_permission_view_customers'.tr, isError: true);
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
                                    : 'search_placeholder_customers'.tr,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'chat_rename'.tr,
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
                          label: Text('change'.tr, style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if ((_currentCustomerId ?? '').isNotEmpty)
                ChatMenuTile(
                  icon: Icons.link_off,
                  text: 'unlink_customer'.tr,
                  danger: true,
                  onTap: () {
                    final svc = MobilePermissionsService.to;
                    if (svc.isOwner || svc.can('chat:assign')) {
                      _unlinkCustomer();
                    } else {
                      _showTopSnack('no_permission_unlink_customer'.tr, isError: true);
                    }
                  },
                  closeOnTap: false,
                ),
            ],
            // Always show hashtags picker (customer-linked or not)
            _buildHashtagsSection(),
            ChatMenuTile(
              icon: Icons.card_travel_outlined,
              text: 'link_job_card'.tr,
              onTap: () {
                final svc = MobilePermissionsService.to;
                if (svc.isOwner || svc.can('jobcard:create')) {
                  _openJobCardPicker();
                } else {
                  _showTopSnack('no_permission_link_jobcard'.tr, isError: true);
                }
              },
              closeOnTap: false,
            ),
            _buildLinkedJobCards(),
            ChatMenuTile(
              icon: Icons.badge_outlined,
              text: 'select_assignee'.tr,
              onTap: () => guardAction(context, 'chat:assign', _openUserPicker, deniedMessage: 'no_permission_chat_assign'.tr),
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
                          'no_assignees_hint'.tr,
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
                        tooltip: 'delete'.tr,
                        onPressed: () => guardAction(context, 'chat:assign', () => _removeAssignee(u), deniedMessage: 'no_permission_chat_assign'.tr),
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
              text: 'chat_rename'.tr,
              onTap: () => guardAction(context, 'chat:assign', _renameChat, deniedMessage: 'no_permission_chat_assign'.tr),
            ),
            ChatMenuTile(
              icon: Icons.refresh_outlined,
              text: 'chat_reset_name'.tr,
              onTap: () => guardAction(context, 'chat:assign', _resetChatName, deniedMessage: 'no_permission_chat_assign'.tr),
            ),
            ChatMenuTile(
              icon: Icons.delete_outline,
              text: 'delete'.tr,
              danger: true,
              onTap: () => guardAction(context, 'chat:assign', () {
                if (widget.onDelete != null) widget.onDelete!();
              }, deniedMessage: 'no_permission_chat_assign'.tr),
            ),
          ],

        ),
      ),
    );
  }
}
