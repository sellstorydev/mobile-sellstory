import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart'; // Add this import
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controller/chat_screen_controller.dart';
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
  late final ChatScreenController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(ChatScreenController());
    _initializeChat();
  }

  void _initializeChat() {
    _controller.initializeChat(
      conversationId: widget.conversationId,
      workspaceId: widget.workspaceId,
      conversationData: widget.conversationData,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationName = widget.conversationData['name'] ?? 'Unknown';
    final isOnline = widget.conversationData['isOnline'] ?? false;
    final sourceType = widget.conversationData['sourceType'] ?? 'unknown';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.conversationData['avatarUrl'] != null
                      ? NetworkImage(widget.conversationData['avatarUrl'])
                      : null,
                  child: widget.conversationData['avatarUrl'] == null
                      ? Text(
                          _getInitials(conversationName),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Name and status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (sourceType == 'line')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LINE',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    isOnline ? 'ออนไลน์' : 'ออฟไลน์',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.black),
            onPressed: () {
              // TODO: Implement call functionality
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              switch (value) {
                case 'info':
                  _showConversationInfo();
                  break;
                case 'pin':
                  _controller.togglePin();
                  break;
                case 'mute':
                  _controller.toggleMute();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'info', child: Text('ข้อมูลแชท')),
              PopupMenuItem(
                value: 'pin',
                child: Text(widget.conversationData['isPinned'] == true ? 'ยกเลิกปักหมุด' : 'ปักหมุด'),
              ),
              const PopupMenuItem(value: 'mute', child: Text('ปิดการแจ้งเตือน')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(child: _buildMessagesList()),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.error.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(_controller.error.value),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.loadMessages(),
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        );
      }

      final messages = _controller.messages;

      if (messages.isEmpty) {
        return const Center(
          child: Text(
            'ยังไม่มีข้อความในแชทนี้',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(16),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return MessageBubble(
            message: message,
            currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
          );
        },
      );
    });
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: ChatInput(
        onSendMessage: (message) => _controller.sendMessage(message),
        onSendImage: () => _controller.sendImage(),
        onSendFile: () => _controller.sendFile(),
      ),
    );
  }

  void _showConversationInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration:  BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ข้อมูลแชท',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoItem('ชื่อ', widget.conversationData['name'] ?? 'Unknown'),
                  _buildInfoItem('ประเภท', widget.conversationData['sourceType'] ?? 'Unknown'),
                  _buildInfoItem('สถานะ', widget.conversationData['status'] ?? 'Unknown'),
                  _buildInfoItem('สร้างเมื่อ', _formatDate(widget.conversationData['createdAt'])),
                  _buildInfoItem('อัพเดทล่าสุด', _formatDate(widget.conversationData['lastMessageAt'])),
                  if (widget.conversationData['salespersonName'] != null)
                    _buildInfoItem('พนักงานขาย', widget.conversationData['salespersonName']),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
    }
    return (parts[0].isNotEmpty ? parts[0][0] : '') +
           (parts[1].isNotEmpty ? parts[1][0] : '');
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'ไม่ทราบ';
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }
}
