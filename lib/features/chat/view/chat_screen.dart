import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/services/chat_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';

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
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService.to;
  bool _isLoading = false;
  String? _error;

  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;
  String get _chatroomName => widget.conversationData['name'] ?? 'แชท';
  String? get _avatarUrl => widget.conversationData['avatar'];
  String get _sourceType => widget.conversationData['source_type'] ?? 'unknown';

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await _chatService.sendTextMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        text: text.trim(),
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      _scrollToBottom();
    } catch (e) {
      setState(() => _error = 'ส่งข้อความไม่สำเร็จ: $e');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendImageMessage(String imageUrl) async {
    setState(() => _isLoading = true);
    try {
      await _chatService.sendImageMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        imageUrl: imageUrl,
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      _scrollToBottom();
    } catch (e) {
      setState(() => _error = 'ส่งรูปภาพไม่สำเร็จ: $e');
      _showErrorSnackBar(_error!);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendFileMessage(String fileUrl, String fileName) async {
    setState(() => _isLoading = true);
    try {
      await _chatService.sendFileMessage(
        workspaceId: widget.workspaceId,
        chatroomId: widget.conversationId,
        platform: _sourceType,
        fileUrl: fileUrl,
        fileName: fileName,
        sender: {
          'id': _currentUserId,
          'name': FirebaseAuth.instance.currentUser?.displayName ?? 'User',
          'avatar': FirebaseAuth.instance.currentUser?.photoURL,
        },
      );

      _scrollToBottom();
    } catch (e) {
      setState(() => _error = 'ส่งไฟล์ไม่สำเร็จ: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (_avatarUrl != null)
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(_avatarUrl!),
              )
            else
              CircleAvatar(
                radius: 18,
                child: Text(_chatroomName.substring(0, 1).toUpperCase()),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chatroomName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _sourceType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showChatInfo(),
          ),
        ],
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'ยังไม่มีข้อความในแชทนี้\nเริ่มต้นการสนทนาได้เลย!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                // Auto scroll to bottom when new message arrives
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  reverse: true, // Show newest at bottom
                  itemBuilder: (context, index) {
                    final messageData = messages[index].data() as Map<String, dynamic>;
                    final messageId = messages[index].id;

                    return MessageBubble(
                      messageId: messageId,
                      messageData: messageData,
                      isFromCurrentUser: _isMessageFromCurrentUser(messageData),
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
            enabled: !_isLoading,
          ),
        ],
      ),
    );
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
