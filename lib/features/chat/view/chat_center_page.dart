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
import '../widgets/chat_search_bar.dart';
import '../widgets/chat_filter_sheet.dart';


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

  // Top snack helper (use GetX snackbar at top)
  void _showTopSnack(String message, {bool isError = false}) {
    // Dismiss existing to avoid stacking many
    try { Get.closeAllSnackbars(); } catch (_) {}
    Get.snackbar(
      isError ? 'เกิดข้อผิดพลาด' : 'แจ้งเตือน',
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      backgroundColor: isError ? Colors.redAccent : Colors.black87,
      colorText: Colors.white,
      icon: Icon(isError ? Icons.error_outline : Icons.check_circle, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

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
    // Clear search when leaving the page
    try { _controller.updateSearchQuery(''); } catch (_) {}
    _searchController.clear();
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
      _showTopSnack('ไม่พบ workspace หรือ chatroom', isError: true);
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
      _showTopSnack('อัปเดต Hashtag แล้ว (${names.length})');
    } catch (e) {
      if (!mounted) return;
      _showTopSnack('อัปเดต Hashtag ไม่สำเร็จ: $e', isError: true);
    }
  }

  Future<void> _onAssignSale(Map<String, dynamic> conversation) async {
    final wsId = _controller.getCurrentWorkspaceId();
    final chatId = (conversation['id'] ?? '').toString();
    if (wsId == null || wsId.isEmpty || chatId.isEmpty) {
      _showTopSnack('ไม่พบ workspace หรือ chatroom', isError: true);
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
        content: const Text('ต้องการผูกผู้ใช้นี้เข้ากับแชท/ลูกค้าหรือไม่?'),
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

    try {
      if (customerId != null && customerId.isNotEmpty) {
        // Assign to customer-level assignees
        await FirebaseFirestore.instance
            .collection('workspaces')
            .doc(wsId)
            .collection('customers')
            .doc(customerId)
            .set({'assignees': FieldValue.arrayUnion([pickedUid])}, SetOptions(merge: true));
      } else {
        // No customer linked: assign to chatroom-level assignees
        await FirestoreService.to
            .getChatroomsCollection(wsId)
            .doc(chatId)
            .set({'assignees': FieldValue.arrayUnion([pickedUid])}, SetOptions(merge: true));
      }

      // Optimistically update the list tile to show assignee immediately
      String displayName = '';
      try {
        final u = await FirebaseFirestore.instance.collection('users').doc(pickedUid).get();
        final m = u.data() ?? {};
        displayName = (m['displayName'] ?? m['name'] ?? '').toString();
      } catch (_) {}
      if (displayName.isEmpty) displayName = pickedUid;
      _controller.addAssigneeLocal(chatId, pickedUid, displayName);

      _showTopSnack('ผูกเซลเรียบร้อย');
    } catch (e) {
      _showTopSnack('ผูกเซลไม่สำเร็จ: $e', isError: true);
    }
  }


  Future<void> _onChangeStatus(Map<String, dynamic> conversation) async {
    final ref = _chatroomRef(conversation);
    if (ref == null) {
      _logger.warning('No workspace/chatroom id for status');
      _showTopSnack('ไม่พบ workspace หรือ chatroom', isError: true);
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
      _showTopSnack('อัปเดตสถานะ: $label');
    } catch (e) {
      _showTopSnack('อัปเดตสถานะไม่สำเร็จ: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
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

        ],
      ),
      body: Column(
        children: [
          ChatSearchBar(
            controller: _searchController,
            onChanged: (value) => _controller.updateSearchQuery(value),
            onOpenFilter: () => _openFilterSheet(context),
          ),
          _buildFilterChips(),
          const SizedBox(height: 8),
          Expanded(child: _buildConversationsList()),
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

  void _openFilterSheet(BuildContext context) async {
    final wsId = _controller.getCurrentWorkspaceId() ?? '';

    final result = await showModalBottomSheet<ChatFilterResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ChatFilterSheet(
          wsId: wsId,
          initialPlatforms: Set<String>.from(_controller.platformFilters),
          initialStatus: _controller.statusFilter.value,
          initialHashtagIds: List<String>.from(_controller.hashtagIdFilters),
          initialSalesUid: _controller.salesIdFilter.value,
          initialCustomerId: _controller.customerIdFilter.value,
        ),
      ),
    );

    if (result == null) return;

    if (result.cleared) {
      // Clear all filters and search
      _searchController.clear();
      _controller.updateSearchQuery('');
      _controller.clearAllFilters();
      return;
    }

    // Apply selected filters; keep search text as-is
    _controller.setPlatformFilters(result.platforms);
    _controller.setStatusFilter(result.status);
    _controller.setHashtagFilters(result.hashtagIds);
    _controller.setSalesFilter(result.salesUid);
    _controller.setCustomerFilter(result.customerId);
  }
}
