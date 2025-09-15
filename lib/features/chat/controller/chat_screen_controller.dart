import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../data/services/firestore_service.dart';
import '../../../core/services/logger_service.dart';

class ChatScreenController extends GetxController {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final LoggerService _logger = Get.find<LoggerService>();

  // Observable states
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;

  // Chat data
  String? _conversationId;
  String? _workspaceId;
  Map<String, dynamic>? _conversationData;

  @override
  void onInit() {
    super.onInit();
    _logger.info('ChatScreenController initialized');
  }

  void initializeChat({
    required String conversationId,
    required String workspaceId,
    required Map<String, dynamic> conversationData,
  }) {
    _conversationId = conversationId;
    _workspaceId = workspaceId;
    _conversationData = conversationData;

    _logger.info('Initializing chat: $conversationId in workspace: $workspaceId');

    loadMessages();
  }

  Future<void> loadMessages() async {
    if (_conversationId == null || _workspaceId == null) {
      error.value = 'Missing conversation or workspace ID';
      _logger.failure('Missing conversation or workspace ID', null);
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';

      _logger.info('Loading messages for conversation: $_conversationId in workspace: $_workspaceId');

      // Get messages with proper ordering
      final result = await _firestoreService.getMessages(
        workspaceId: _workspaceId!,
        chatroomId: _conversationId!,
        limit: 50,
      );

      _logger.info('Firestore query returned ${result.docs.length} documents');

      final messageList = result.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        _logger.info('Processing message: ${doc.id} with type: ${data['type']} and sender: ${data['sender']}');

        // Parse timestamp - handle both string and number formats
        if (data['timestamp'] != null) {
          try {
            int timestamp;
            if (data['timestamp'] is String) {
              timestamp = int.parse(data['timestamp']);
            } else if (data['timestamp'] is int) {
              timestamp = data['timestamp'];
            } else {
              throw Exception('Invalid timestamp format');
            }
            data['parsedTimestamp'] = DateTime.fromMillisecondsSinceEpoch(timestamp);
          } catch (e) {
            _logger.warning('Failed to parse timestamp: ${data['timestamp']}, using current time');
            data['parsedTimestamp'] = DateTime.now();
          }
        } else {
          data['parsedTimestamp'] = DateTime.now();
        }

        // Ensure message has required fields
        data['type'] = data['type'] ?? 'text';

        // Handle different message types
        switch (data['type']) {
          case 'text':
            if (data['text'] == null || data['text'].toString().trim().isEmpty) {
              data['text'] = '[${'empty_message'.tr}]';
            }
            break;
          case 'image':
            // Ensure image messages have proper structure
            data['imageUrl'] = data['imageUrl'] ?? data['url'] ?? data['file_url'];
            break;
          case 'video':
            // Ensure video messages have proper structure
            data['videoUrl'] = data['videoUrl'] ?? data['url'] ?? data['file_url'];
            data['thumbnailUrl'] = data['thumbnailUrl'] ?? data['thumbnail'];
            break;
          case 'file':
            // Ensure file messages have proper structure
            data['fileUrl'] = data['fileUrl'] ?? data['url'] ?? data['file_url'];
            data['fileName'] = data['fileName'] ?? data['name'] ?? 'Unknown file';
            break;
        }

        // Ensure sender information exists
        if (data['sender'] == null) {
          data['sender'] = {
            'id': 'unknown',
            'name': 'Unknown User',
            'type': 'user',
            'avatar': null,
          };
        }

        return data;
      }).toList();

      // Sort by timestamp (oldest first for display)
      messageList.sort((a, b) {
        final aTime = a['parsedTimestamp'] as DateTime;
        final bTime = b['parsedTimestamp'] as DateTime;
        return aTime.compareTo(bTime);
      });

      messages.value = messageList;
      _logger.success('Loaded and processed ${messageList.length} messages');

      // Scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

    } catch (e) {
      error.value = 'Failed to load messages: $e';
      _logger.failure('Failed to load messages', e);

      // Add more detailed error logging
      _logger.failure('Error details', {
        'conversationId': _conversationId,
        'workspaceId': _workspaceId,
        'error': e.toString(),
      });
    } finally {
      isLoading.value = false;
    }
  }

  void _scrollToBottom() {
    // This will be called by the ChatScreen to scroll to bottom
    // Implementation will be in ChatScreen
  }

  Future<void> sendMessage(String messageText) async {
    if (_conversationId == null || _workspaceId == null || messageText.trim().isEmpty) {
      return;
    }

    try {
      _logger.info('Sending message: $messageText');

      final now = DateTime.now();
      final messageData = {
        'type': 'text',
        'text': messageText.trim(),
        'timestamp': now.millisecondsSinceEpoch,
        'sender': {
          'id': 'current_user', // You might want to get actual user ID
          'name': 'You',
          'type': 'user',
          'avatar': null,
        },
        'quoteToken': null,
        'replyToken': null,
        'created_at': now.toIso8601String(),
        'is_deleted': false,
      };

      await _firestoreService.addDocument(
        _firestoreService.getChatroomMessagesCollection(
          workspaceId: _workspaceId!,
          chatroomId: _conversationId!,
        ),
        messageData,
      );

      // Update chatroom's last message info
      await _firestoreService.updateDocument(
        _firestoreService.getChatroomsCollection(_workspaceId!).doc(_conversationId!),
        {
          'last_message_info.message': messageText.trim(),
          'last_message_info.last_upd': now.toIso8601String(),
          'last_message_info.who_name': 'You',
          'last_message_info.msg_timestamp': now.millisecondsSinceEpoch.toString(),
        },
      );

      // Reload messages to show the new one
      loadMessages();

    } catch (e) {
      error.value = 'Failed to send message: $e';
      _logger.failure('Failed to send message', e);
    }
  }

  Future<void> sendImage() async {
    // TODO: Implement image sending
    _logger.info('Send image requested');
    Get.snackbar('Coming Soon', 'Image sending will be implemented soon');
  }

  Future<void> sendFile() async {
    // TODO: Implement file sending
    _logger.info('Send file requested');
    Get.snackbar('Coming Soon', 'File sending will be implemented soon');
  }

  void togglePin() {
    if (_conversationData != null) {
      final isPinned = _conversationData!['isPinned'] ?? false;
      _logger.info('Toggle pin: $isPinned -> ${!isPinned}');

      // TODO: Update pin status in Firestore
      Get.snackbar(
        'pin'.tr,
        isPinned ? 'chat_unpin_success'.tr : 'chat_pin_success'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void toggleMute() {
    _logger.info('Toggle mute requested');
    Get.snackbar(
      'notifications'.tr,
      'chat_notification_toggle_success'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    _logger.info('ChatScreenController disposed');
    super.onClose();
  }
}
