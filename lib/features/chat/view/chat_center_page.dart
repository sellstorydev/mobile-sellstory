// chat_center_page.dart (Firestore only)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/chat_controller.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/chat_filter_chips.dart';
import '../../../core/services/logger_service.dart'; // Add this import
import '../widgets/customer_picker_sheet.dart';
import 'chat_screen.dart'; // Import ChatScreen
import '../../../data/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/user_picker_sheet.dart';
import '../widgets/hashtag_picker_sheet.dart';


class ChatCenterPage extends StatefulWidget {
  const ChatCenterPage({Key? key}) : super(key: key);

  @override
  State<ChatCenterPage> createState() => _ChatCenterPageState();
}

class _ChatCenterPageState extends State<ChatCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  final LoggerService _logger = Get.find<LoggerService>(); // Add logger instance

  late final ChatController _controller;
  String? _currentUserId;
  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ChatController());
    _initializeUser();
  }

  void _initializeUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
       _currentUserId = currentUser.uid;
      _controller.setCurrentUser(_currentUserId!);
      _controller.loadConversations();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  // Helpers to update chatroom document
  DocumentReference<Map<String, dynamic>>? _chatroomRef(Map<String, dynamic> conversation) {
    final wsId = _controller.getCurrentWorkspaceId();
    final chatId = conversation['id']?.toString();
    if (wsId == null || wsId.isEmpty || chatId == null || chatId.isEmpty) return null;
    return FirestoreService.to.getChatroomsCollection(wsId).doc(chatId);
  }

  Future<void> _onAddHashtag(Map<String, dynamic> conversation) async {
    final wsId = _controller.getCurrentWorkspaceId();
    final chatId = (conversation['id'] ?? '').toString();
    if (wsId == null || wsId.isEmpty || chatId.isEmpty) {
      _logger.warning('No workspace/chatroom id for add hashtag');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบ workspace หรือ chatroom')));
      return;
    }

    // Load existing hashtags from chatroom doc for pre-selection
    List<String> initialIds = const [];
    List<String> initialNames = const [];
    try {
      final snap = await FirestoreService.to
          .getChatroomsCollection(wsId)
          .doc(chatId)
          .get();
      final m = snap.data() ?? {};
      initialIds = ((m['hashtagIds'] as List?) ?? []).map((e) => e.toString()).toList();
      initialNames = ((m['hashtags'] as List?) ?? []).map((e) => e.toString()).toList();
    } catch (_) {}

    // Open picker sheet
    final result = await showModalBottomSheet<HashtagPickerResult>(
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
          child: HashtagPickerSheet(
            workspaceId: wsId,
            initialIds: initialIds,
            initialNames: initialNames,
          ),
        );
      },
    );

    if (result == null) return;

    // Normalize names to include '#'
    final ids = result.ids.toSet().toList();
    final names = result.names
        .map((n) => n.toString().trim())
        .where((n) => n.isNotEmpty)
        .map((n) => n.startsWith('#') ? n : '#$n')
        .toSet()
        .toList();

    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(wsId)
          .collection('chatrooms')
          .doc(chatId)
          .set({
            'hashtagIds': ids,
            'hashtags': names,
          }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดต Hashtag แล้ว (${names.length})')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดต Hashtag ไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _onAssignSale(Map<String, dynamic> conversation) async {
    final wsId = _controller.getCurrentWorkspaceId();
    final chatId = (conversation['id'] ?? '').toString();
    if (wsId == null || wsId.isEmpty || chatId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบ workspace หรือ chatroom')));
      return;
    }

    // Pick a user via bottom sheet
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
          child: UserPickerSheet(workspaceId: wsId),
        );
      },
    );
    if (pickedUid == null || pickedUid.isEmpty) return;

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
    if (ok != true) return;

    // Resolve current customerId from conversation or chatroom doc
    String? customerId = (conversation['customerId'] ?? conversation['customer_id'] ?? conversation['customer']?['id'])?.toString();
    if (customerId == null || customerId.isEmpty) {
      try {
        final snap = await FirestoreService.to
            .getChatroomsCollection(wsId)
            .doc(chatId)
            .get();
        final m = snap.data();
        customerId = (m != null ? (m['customerId'] ?? m['customer_id'] ?? m['customer']?['id']) : null)?.toString();
      } catch (_) {}
    }

    if (customerId == null || customerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเชื่อมลูกค้ากับห้องแชทก่อน')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('workspaces')
          .doc(wsId)
          .collection('customers')
          .doc(customerId)
          .set({'assignees': FieldValue.arrayUnion([pickedUid])}, SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ผูกเซลเรียบร้อย')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ผูกเซลไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _onChangeStatus(Map<String, dynamic> conversation) async {
    final ref = _chatroomRef(conversation);
    if (ref == null) {
      _logger.warning('No workspace/chatroom id for status');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบ workspace หรือ chatroom')));
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('สถานะแชท', style: TextStyle(fontWeight: FontWeight.w700))),
            ListTile(
              leading: const Icon(Icons.play_arrow, color: Colors.blue),
              title: const Text('กำลังดำเนินการ'),
              onTap: () => Navigator.pop(ctx, 'IN_PROGRESS'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('เสร็จสิ้น'),
              onTap: () => Navigator.pop(ctx, 'DONE'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || choice.isEmpty) return;

    try {
      await ref.set({'chatroom_status': choice}, SetOptions(merge: true));
      final label = choice == 'DONE' ? 'เสร็จสิ้น' : 'กำลังดำเนินการ';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปเดตสถานะ: $label')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปเดตสถานะไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Text(
            'Chat Center',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.refresh(),
            color: Colors.black87,
          ),
          IconButton(
            tooltip: 'กรอง',
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _openFilterSheet(context),
            color: Colors.black87,
          ),
          const SizedBox(width: 4),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('ตั้งค่า')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(theme),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(child: _buildConversationsList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'ค้นหาด้วย ชื่อ นามสกุล ชื่อบริษัท หรือ ข้อความแชท hashtag เซล',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.blue, width: 1.8),
                ),
              ),
              onChanged: (value) => _controller.updateSearchQuery(value),
            ),

          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openFilterSheet(context),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.tune_rounded),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    // ใช้ Obx เพื่อเชื่อมกับตัวควบคุมเดิม
    return Obx(
          () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
        child: ChatFilterChips(
          activeFilter: _controller.activeFilter.value,
          onFilterChanged: (filter) => _controller.setFilter(filter),
          // แนะนำ: ภายใน ChatFilterChips ปรับให้เป็น ChoiceChip/ActionChip โทนเดียวกับภาพ
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return Obx(() {
      final loading = _controller.isLoading.value;
      final errorText = _controller.error.value;
      final conversations = _controller.filteredConversations;

      // First-time load: no data yet -> full-screen loader
      if (loading && conversations.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      // Error state only when no data to show
      if (!loading && errorText.isNotEmpty && conversations.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                errorText,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.refresh(),
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        );
      }

      if (conversations.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'ไม่มีแชทที่ตรงกับเงื่อนไข',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      // Keep current list visible; show thin progress bar while loading
      return Stack(
        children: [
          ListView.separated(
            key: const PageStorageKey('chat_center_list'),
            controller: _listScrollController,
            cacheExtent: 800,
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.shade200,
              indent: 76,
            ),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return RepaintBoundary(
                child: ConversationTile(
                  key: ValueKey(conversation['id'] ?? index),
                  conversation: conversation,
                  currentUserId: _currentUserId ?? '',
                  onTap: () => _onConversationTap(conversation),
                  onAddHashtag: () => _onAddHashtag(conversation),
                  onAssignSale: () => _onAssignSale(conversation),
                  onChangeStatus: () => _onChangeStatus(conversation),
                ),
              );
            },
          ),
          if (loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      );
    });
  }

  void _onConversationTap(Map<String, dynamic> conversation) {
    final conversationId = conversation['id'] as String;

    // Mark as read
    _controller.markAsRead(conversationId);

    // Get the actual workspace ID from the controller
    final workspaceId = _controller.getCurrentWorkspaceId();

    _logger.info('Opening chat: $conversationId in workspace: $workspaceId');

    // Navigate to chat screen with conversation data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversationId,
          conversationData: conversation,
          workspaceId: workspaceId ?? _currentUserId ?? '',
        ),
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    final wsId = _controller.getCurrentWorkspaceId() ?? '';

    // Snapshot current filters
    final initialPlatforms = Set<String>.from(_controller.platformFilters);
    String status = _controller.statusFilter.value; // '', NEW, IN_PROGRESS, DONE
    final List<String> initialHashtagIds = List<String>.from(_controller.hashtagIdFilters);
    String salesUid = _controller.salesIdFilter.value;
    String customerId = _controller.customerIdFilter.value;

    // Local display states
    List<String> selectedHashtagIds = List<String>.from(initialHashtagIds);
    List<String> selectedHashtagNames = const [];
    String? salesName;
    String? customerName;

    Future<void> _loadUserName(String uid) async {
      if (uid.isEmpty) { salesName = null; return; }
      try {
        final u = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final m = u.data() ?? {};
        salesName = (m['displayName'] ?? m['name'] ?? uid).toString();
      } catch (_) {}
    }

    Future<void> _loadCustomerName(String cid) async {
      if (cid.isEmpty || wsId.isEmpty) { customerName = null; return; }
      try {
        final c = await FirebaseFirestore.instance.collection('workspaces').doc(wsId).collection('customers').doc(cid).get();
        final m = c.data() ?? {};
        customerName = (m['name'] ?? m['displayName'] ?? m['customerName'] ?? cid).toString();
      } catch (_) {}
    }

    // Preload names for current selections
    if (salesUid.isNotEmpty) {
      // fire and forget; UI will update on setState below when future completes
      _loadUserName(salesUid);
    }
    if (customerId.isNotEmpty) {
      _loadCustomerName(customerId);
    }

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final theme = Theme.of(context);
        Set<String> platforms = Set<String>.from(initialPlatforms);
        return

          FractionallySizedBox(
              heightFactor: 0.92, // leave a small gap at the top for easier dismiss
              child:
          StatefulBuilder(
          builder: (ctx, setState) {
            Widget _platformCheckbox(String key, String label) {
              final checked = platforms.contains(key);
              return CheckboxListTile(
                value: checked,
                onChanged: (v) {
                  setState(() {
                    if (v == true) { platforms.add(key); } else { platforms.remove(key); }
                  });
                },
                title: Text(label),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }

            Widget _statusRadio(String value, String label) {
              return RadioListTile<String>(
                value: value,
                groupValue: status,
                onChanged: (v) => setState(() => status = v ?? ''),
                title: Text(label),
                contentPadding: EdgeInsets.zero,
              );
            }

            Widget _pickerTile({required IconData icon, required String label, required String placeholder, String? value, VoidCallback? onTap}) {
              return InkWell(
                onTap: onTap,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 20, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (value != null && value.isNotEmpty) ? value : placeholder,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: (value != null && value.isNotEmpty) ? Colors.black87 : Colors.grey),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black45),
                    ],
                  ),
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(ctx).viewInsets.bottom),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('ค้นหา', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                          TextButton(
                            onPressed: () {
                              // Clear all local selections
                              setState(() {
                                platforms.clear();
                                status = '';
                                selectedHashtagIds = [];
                                selectedHashtagNames = [];
                                salesUid = '';
                                salesName = null;
                                customerId = '';
                                customerName = null;
                              });
                              // Apply to controller and close
                              _controller.clearAllFilters();
                              Navigator.pop(ctx);
                            },
                            child: const Text('ล้างค่า'),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),


                      const Text('ช่องทาง', style: TextStyle(fontWeight: FontWeight.w700)),
                      _platformCheckbox('facebook', 'ช่องทาง Facebook'),
                      _platformCheckbox('instagram', 'ช่องทาง Instagram'),
                      _platformCheckbox('line', 'ช่องทาง LINE'),

                      const SizedBox(height: 8),
                      const Text('สถานะ', style: TextStyle(fontWeight: FontWeight.w700)),
                      _statusRadio('NEW', 'ใหม่'),
                      _statusRadio('IN_PROGRESS', 'กำลังดำเนินการ'),
                      _statusRadio('DONE', 'เสร็จสิ้น'),

                      const SizedBox(height: 8),
                      const Text('Hashtag', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      _pickerTile(
                        icon: Icons.tag,
                        label: '',
                        placeholder: 'เลือก Hashtag',
                        value: selectedHashtagNames.isNotEmpty ? selectedHashtagNames.map((n) => '#$n').join(', ') : null,
                        onTap: () async {
                          if (wsId.isEmpty) return;
                          final result = await showModalBottomSheet<HashtagPickerResult>(
                            context: ctx,
                            useSafeArea: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (c) {
                              final h = MediaQuery.of(c).size.height;
                              return SizedBox(
                                height: h * 0.9,
                                child: HashtagPickerSheet(
                                  workspaceId: wsId,
                                  initialIds: selectedHashtagIds,
                                  initialNames: selectedHashtagNames,
                                ),
                              );
                            },
                          );
                          if (result != null) {
                            setState(() {
                              selectedHashtagIds = result.ids;
                              selectedHashtagNames = result.names;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),
                      const Text('เซล', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      _pickerTile(
                        icon: Icons.person_outline,
                        label: '',
                        placeholder: 'เลือกเซลผู้รับผิดชอบ',
                        value: salesName,
                        onTap: () async {
                          if (wsId.isEmpty) return;
                          final pickedUid = await showModalBottomSheet<String>(
                            context: ctx,
                            useSafeArea: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (c) {
                              final h = MediaQuery.of(c).size.height;
                              return SizedBox(height: h * 0.9, child: UserPickerSheet(workspaceId: wsId));
                            },
                          );
                          if (pickedUid != null && pickedUid.isNotEmpty) {
                            await _loadUserName(pickedUid);
                            setState(() {
                              salesUid = pickedUid;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),
                      const Text('ลูกค้า', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      _pickerTile(
                        icon: Icons.people_outline,
                        label: '',
                        placeholder: 'เลือกลูกค้า',
                        value: customerName,
                        onTap: () async {
                          if (wsId.isEmpty) return;
                          final pickedCustomerId = await showModalBottomSheet<String>(
                            context: ctx,
                            useSafeArea: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (c) {
                              final h = MediaQuery.of(c).size.height;
                              return SizedBox(height: h * 0.9, child: CustomerPickerSheet(workspaceId: wsId));
                            },
                          );
                          if (pickedCustomerId != null && pickedCustomerId.isNotEmpty) {
                            await _loadCustomerName(pickedCustomerId);
                            setState(() {
                              customerId = pickedCustomerId;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _controller.setPlatformFilters(platforms);
                            _controller.setStatusFilter(status);
                            _controller.setHashtagFilters(selectedHashtagIds);
                            _controller.setSalesFilter(salesUid);
                            _controller.setCustomerFilter(customerId);
                            Navigator.pop(ctx);
                          },
                          child: const Text('ยืนยัน'),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              );
            },
          ))
        ;
      },
    );
  }
}
