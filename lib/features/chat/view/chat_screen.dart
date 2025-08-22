import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../../data/services/chat_service.dart';
import '../widgets/chat_header_line.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/show_bottom_modal.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> conversationData;
  final String workspaceId;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.conversationData,
    required this.workspaceId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // final ScrollController _scrollController = ScrollController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final ChatService _chatService = ChatService.to;
  bool _isLoading = false;
  String? _error;
  // Use reversed list to show newest at bottom
  final bool _isReversed = true;
  // Search state
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // Match navigation state
  List<String> _matchedIds = [];
  int _focusedMatchIndex = 0;
  String _lastFocusedQuery = '';
  // Visual index tracking for alignment logic
  final Map<String, int> _listIndexById = {};
  int _lastItemCount = 0;
  // Cache latest messages to allow instant recompute on user typing
  List<QueryDocumentSnapshot> _currentMessages = const [];

  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;
  String get _chatroomName => _chatroomNameState ?? (widget.conversationData['name'] ?? 'แชท');
  String? get _avatarUrl => widget.conversationData['avatar'];
  String get _sourceType => widget.conversationData['source_type'] ?? 'unknown';

  String? _chatroomNameState; // refreshed name after reset

  @override
  void initState() {
    super.initState();
    _markAsRead();
    // เพิ่ม delay เล็กน้อยเพื่อให้ ListView build เสร็จก่อน
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _scrollToBottom();
      });
    });
  }

  @override
  void dispose() {
    // _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _markAsRead() async {
    // อัพเดท count เป็น 0 เมื่อเข้าแชท
    try {
      await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .update({'count': '0'});
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_itemScrollController.isAttached) return;
    final duration = const Duration(milliseconds: 300);
    if (animate) {
      _itemScrollController.scrollTo(
        index: 0, // with reverse=true, index 0 is bottom (newest)
        duration: duration,
        curve: Curves.easeOut,
        alignment: 0.0,
      );
    } else {
      try {
        _itemScrollController.jumpTo(index: 0, alignment: 0.0);
      } catch (_) {}
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    setState(() => _error = null); // Clear previous errors

    try {
      final result = await _chatService.sendTextMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        text: text.trim(),
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Mobile User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      if (result['success'] == true) {
        print('Message sent successfully. ID: ${result['messageId']}');
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _error = 'ส่งข้อความไม่สำเร็จ: $e');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendImageMessage(String imageUrl) async {
    setState(() => _isLoading = true);
    setState(() => _error = null);

    try {
      final result = await _chatService.sendImageMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        imageUrl: imageUrl,
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Mobile User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      if (result['success'] == true) {
        print('Image sent successfully. ID: ${result['messageId']}');
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _error = 'ส่งรูปภาพไม่สำเร็จ: $e');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendFileMessage(String fileUrl, String fileName) async {
    setState(() => _isLoading = true);
    setState(() => _error = null);


    try {
      final result = await _chatService.sendFileMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        fileUrl: fileUrl,
        fileName: fileName,
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Mobile User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      if (result['success'] == true) {
        print('File sent successfully. ID: ${result['messageId']}');
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _error = 'ส่งไฟล์ไม่สำเร็จ: $e');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // เพิ่มฟังก์ชันส่งข้อความประเภทอื่นๆ
  Future<void> _sendVideoMessage(String videoUrl) async {
    setState(() => _isLoading = true);
    setState(() => _error = null);

    try {
      final result = await _chatService.sendVideoMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        videoUrl: videoUrl,
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Mobile User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      if (result['success'] == true) {
        print('Video sent successfully. ID: ${result['messageId']}');
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _error = 'ส่งวิดีโอไม่สำเร็จ: $e');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendStickerMessage(String stickerId, String stickerPackageId) async {
    if (_sourceType.toLowerCase() != 'line') {
      _showErrorSnackBar('สติ๊กเกอร์รองรับเฉพาะ LINE เท่านั้น');
      return;
    }

    setState(() => _isLoading = true);
    setState(() => _error = null);

    try {
      final result = await _chatService.sendStickerMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        stickerId: stickerId,
        stickerPackageId: stickerPackageId,
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'Mobile User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );


      if (result['success'] == true) {
        print('Sticker sent successfully. ID: ${result['messageId']}');
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _error = 'ส่งสติ๊กเกอร์ไม่สำเร็จ: $e');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

  }

  void _recomputeMatches(List<QueryDocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) {
      _matchedIds = [];
      _focusedMatchIndex = 0;
      return;
    }
    final ids = <String>[];
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      if (_matchesQuery(data, _searchQuery)) ids.add(d.id);
    }
    final queryChanged = _searchQuery != _lastFocusedQuery;
    _matchedIds = ids;
    if (queryChanged) {
      _focusedMatchIndex = 0;
      _lastFocusedQuery = _searchQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentMatch());
    } else if (_focusedMatchIndex >= _matchedIds.length && _matchedIds.isNotEmpty) {
      _focusedMatchIndex = _matchedIds.length - 1;
    }
  }

  void _focusCurrentMatch() {
    if (_matchedIds.isEmpty) return;
    final id = _matchedIds[_focusedMatchIndex];

    double _calcAlignment() {
      final idx = _listIndexById[id];
      if (idx == null || _lastItemCount == 0) {
        return 0.5;
      }
      final isInFirstTen = _isReversed
          ? idx >= (_lastItemCount - 10)
          : idx <= 9;
      return isInFirstTen ? 0.1 : 0.5;
    }

    int _indexOfId() {
      final byMap = _listIndexById[id];
      if (byMap != null) return byMap;
      final i = _currentMessages.indexWhere((d) => d.id == id);
      return i >= 0 ? i : 0;
    }

    void _scroll() {
      if (!_itemScrollController.isAttached) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scroll());
        return;
      }
      final idx = _indexOfId();
      _itemScrollController.scrollTo(
        index: idx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: _calcAlignment(),
      );
    }

    _scroll();
  }

  void _gotoPrevMatch() {
    if (_matchedIds.isEmpty) return;
    setState(() {
      _focusedMatchIndex = (_focusedMatchIndex - 1) < 0
          ? _matchedIds.length - 1
          : _focusedMatchIndex - 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentMatch());
  }

  void _gotoNextMatch() {
    if (_matchedIds.isEmpty) return;
    setState(() {
      _focusedMatchIndex = (_focusedMatchIndex + 1) % _matchedIds.length;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentMatch());
  }

  // Helpers for bottom sheet actions
  Future<void> _updateStatus(ChatStatus status) async {
    final map = {
      ChatStatus.autoReply: 'AUTO_REPLY',
      ChatStatus.inProgress: 'IN_PROGRESS',
      ChatStatus.done: 'DONE',
    };
    try {
      await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .update({'chatroom_status': map[status]});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปเดตสถานะแล้ว')));
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('อัปเดตสถานะไม่สำเร็จ: $e');
    }
  }

  Future<void> _updatePinned(bool pinned) async {
    try {
      await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .update({'chat_pin': pinned ? 'Y' : 'N'});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pinned ? 'ปักหมุดแล้ว' : 'ยกเลิกปักหมุดแล้ว')));
    } catch (e) {
      _showErrorSnackBar('อัปเดตปักหมุดไม่สำเร็จ: $e');
    }
  }

  Future<void> _deleteChatroom() async {
    try {
      await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .update({'is_deleted': 'Y'});
      if (mounted) {
        Navigator.of(context).pop(); // ออกจากหน้าแชท
      }
    } catch (e) {
      _showErrorSnackBar('ลบแชทไม่สำเร็จ: $e');
    }
  }

  Future<void> _reloadChatroomName() async {
    try {
      final doc = await _chatService.getChatroomsCollection(widget.workspaceId)
          .doc(widget.conversationId)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _chatroomNameState = data['name'] ?? data['who_name'] ?? 'แชท';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('โหลดข้อมูลห้องแชทใหม่แล้ว')));
      }
    } catch (e) {
      _showErrorSnackBar('ดึงข้อมูลไม่สำเร็จ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: ChatHeaderLine(
        title: _chatroomName,
        avatarUrl: _avatarUrl,
        platform: 'LINE',
        showBack: false,
        onSearch: () {
          setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) {
              _searchQuery = '';
              _searchController.clear();
              _matchedIds = [];
              _focusedMatchIndex = 0;
              _lastFocusedQuery = '';
            }
          });
        },
        onMore: () {
          ShowBottomModal.open(
            context,
            current: ChatStatus.inProgress,
            pinned: false,
            assignOptions: const ['ทีม A', 'ทีม B', 'ทีม C'],
            selectedAssign: null,
            onStatusChange: _updateStatus,
            onPinChanged: _updatePinned,
            onAssignChanged: (v) {},
            onNote: () {},
            onAddSale: () {},
            onRename: () {},
            onResetName: _reloadChatroomName,
            onDelete: _deleteChatroom,
          );
        },
      ),
      body: Column(
        children: [
          // Error display
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.red.shade100,
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade800),
                textAlign: TextAlign.center,
              ),
            ),

          // In-chat search bar
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'ค้นหาในแชท...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (v) {
                        setState(() {
                          final q = v.trim();
                          _searchQuery = q;
                          if (q.isEmpty) {
                            _matchedIds = [];
                            _focusedMatchIndex = 0;
                            _lastFocusedQuery = '';
                          } else {
                            // recompute immediately against current messages
                            _lastFocusedQuery = '';
                            _recomputeMatches(_currentMessages);
                          }
                        });
                        if (_searchQuery.isNotEmpty) {
                          // focus after layout updates
                          WidgetsBinding.instance.addPostFrameCallback((_) => _focusCurrentMatch());
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'ล้าง',
                    onPressed: () {
                      setState(() {
                        _showSearch = false;
                        _searchQuery = '';
                        _searchController.clear();
                        _matchedIds = [];
                        _focusedMatchIndex = 0;
                        _lastFocusedQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear),
                  ),
                ],
              ),
            ),

          // แสดงแถบสรุปผลเฉพาะเมื่อมีคำค้นหา (ไม่ว่าง)
          if (_showSearch && _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    _matchedIds.isEmpty ? 'ไม่พบผลลัพธ์' : '${_focusedMatchIndex + 1}/${_matchedIds.length}',
                    style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'ก่อนหน้า',
                    onPressed: _matchedIds.isEmpty ? null : _gotoPrevMatch,
                    icon: const Icon(Icons.keyboard_arrow_up),
                  ),
                  IconButton(
                    tooltip: 'ถัดไป',
                    onPressed: _matchedIds.isEmpty ? null : _gotoNextMatch,
                    icon: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessagesStream(
                workspaceId: widget.workspaceId,
                chatroomId: widget.conversationId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
                }

                final messages = snapshot.data?.docs ?? [];
                // cache latest messages for instant search recompute
                _currentMessages = messages;
                // Recompute matches when data changes
                _recomputeMatches(messages);
                // reset visual index map for this build
                _listIndexById.clear();
                _lastItemCount = messages.length;

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('ยังไม่มีข้อความในแชทนี้\nเริ่มต้นการสนทนาได้เลย!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }

                // Keep auto-scroll to bottom for non-search state
                if (_searchQuery.isEmpty) {
                  SchedulerBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                }

                return ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  reverse: _isReversed,
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final messageId = messages[index].id;

                    // register visual index for alignment logic
                    _listIndexById[messageId] = index;

                    final isHighlighted = _searchQuery.isNotEmpty && _matchesQuery(messageData, _searchQuery);
                    final isFocused = _searchQuery.isNotEmpty &&
                        _matchedIds.isNotEmpty &&
                        messageId == _matchedIds[_focusedMatchIndex];

                    return MessageBubble(
                      key: ValueKey(messageId),
                      messageId: messageId,
                      messageData: messageData,
                      isFromCurrentUser: _isMessageFromCurrentUser(messageData),
                      highlight: isHighlighted,
                      highlightQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
                      focused: isFocused,
                    );
                  },
                );
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('กำลังส่งข้อความ...'),
                ],
              ),
            ),

          // Input area
          ChatInput(
            onSendText: _sendMessage,
            onSendImage: _sendImageMessage,
            onSendFile: (fileUrl, fileName) => _sendFileMessage(fileUrl, fileName),
            workspaceId: widget.workspaceId,
            chatroomId: widget.conversationId,
            enabled: !_isLoading,
          ),
        ],
      ),
    );
  }

  bool _matchesQuery(Map<String, dynamic> m, String q) {
    final query = q.toLowerCase();
    String collectText() {
      final t = (m['text'] ?? m['message'] ?? '').toString();
      if (t.isNotEmpty) return t;
      // fallback for other types with captions
      return (m['fileName'] ?? '').toString();
    }
    return collectText().toLowerCase().contains(query);
  }

  bool _isMessageFromCurrentUser(Map<String, dynamic> messageData) {
    // Check if message is from current user
    final senderId = messageData['sender']?['id'] as String?;
    return senderId == _currentUserId;
  }

  void _showChatInfo() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_avatarUrl != null)
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(_avatarUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 32,
                      child: Text(_chatroomName.substring(0, 1).toUpperCase()),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _chatroomName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'แพลตฟอร์ม: ${_sourceType.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          'สถานะ: ${widget.conversationData['chatroom_status'] ?? 'ไม่ระบุ'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('รายละเอียดแชท'),
                subtitle: Text('ID: ${widget.conversationId}'),
              ),
              ListTile(
                leading: const Icon(Icons.business),
                title: const Text('Workspace'),
                subtitle: Text('ID: ${widget.workspaceId}'),
              ),
              if (widget.conversationData['customerName'] != null)
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('ลูกค้า'),
                  subtitle: Text(widget.conversationData['customerName']),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
