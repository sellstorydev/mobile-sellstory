import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/network/mobile_api.dart';

class ChatService extends GetxService {
  static ChatService get to => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _baseApiUrl = MobileApiConfig.baseUrl;

  // ===== Firestore refs =====
  CollectionReference<Map<String, dynamic>> getChatroomsCollection(String workspaceId) =>
      _firestore.collection('workspaces').doc(workspaceId).collection('chatrooms');

  CollectionReference<Map<String, dynamic>> getChatroomMessagesCollection({
    required String workspaceId,
    required String chatroomId,
  }) =>
      _firestore
          .collection('workspaces')
          .doc(workspaceId)
          .collection('chatrooms')
          .doc(chatroomId)
          .collection('messages');

  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection('users');

  // ===== User workspace management =====
  Future<String?> getUserCurrentWorkspaceId(String userId) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final lastActiveWorkspaceId = userData['lastActiveWorkspaceId'] as String?;
        
        // Check if the last active workspace still exists in user's workspaces
        if (lastActiveWorkspaceId != null && lastActiveWorkspaceId.isNotEmpty) {
          final workspaces = userData['workspaces'] as List<dynamic>? ?? [];
          final workspaceExists = workspaces.any((ws) => 
            (ws as Map<String, dynamic>)['id'] == lastActiveWorkspaceId
          );
          
          if (workspaceExists) {
            return lastActiveWorkspaceId;
          }
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user workspace: $e');
    }
  }

  Future<String?> getUserFirstWorkspaceId(String userId) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final workspaces = userData['workspaces'] as List<dynamic>? ?? [];
        if (workspaces.isNotEmpty) {
          return workspaces.first['id'] as String?;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get first workspace: $e');
    }
  }

  // Update user's last active workspace ID
  Future<void> updateUserLastActiveWorkspaceId(String userId, String workspaceId) async {
    try {
      await usersCollection.doc(userId).update({
        'lastActiveWorkspaceId': workspaceId,
      });
    } catch (e) {
      throw Exception('Failed to update user last active workspace: $e');
    }
  }

  // ===== Chatroom queries =====
  Future<List<Map<String, dynamic>>> getChatroomsForWorkspace(String workspaceId) async {
    try {
      final qs = await getChatroomsCollection(workspaceId)
          .where('is_deleted', isEqualTo: 'N')
          .orderBy('last_upd', descending: true)
          .get();

      return qs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Map fields to match widget expectations
        data['name'] = data['name'] ?? data['who_name'] ?? 'Unknown';
        data['type'] = (data['dialog_type']?.toString().toUpperCase() == 'GROUP') ? 'group' : 'direct';
        data['lastMessage'] = data['last_message_info']?['message'] ?? '';
        data['avatarUrl'] = data['avatar'];
        data['status'] = data['chatroom_status'] ?? 'active';
        data['unreadCount'] = int.tryParse(data['count']?.toString() ?? '0') ?? 0;
        data['isOnline'] = (data['bot_status'] == 'Y');
        data['sourceType'] = data['source_type'] ?? 'unknown';
        data['isPinned'] = data['chat_pin'] == 'Y';
        data['isNew'] = data['is_new'] == 'Y';

        // Parse dates
        DateTime? parseDate(dynamic v) {
          if (v == null) return null;
          if (v is Timestamp) return v.toDate();
          if (v is String) {
            try { return DateTime.parse(v); } catch (_) {}
          }
          return null;
        }

        data['lastMessageAt'] = parseDate(data['last_upd']);
        data['createdAt'] = parseDate(data['created']);

        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get chatrooms: $e');
    }
  }

  // Legacy method for backward compatibility
  Future<List<Map<String, dynamic>>> getConversationsForUser(String userId) async {
    try {
      // Get user's current workspace
      String? workspaceId = await getUserCurrentWorkspaceId(userId);
      workspaceId ??= await getUserFirstWorkspaceId(userId);

      if (workspaceId != null) {
        return getChatroomsForWorkspace(workspaceId);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  // ===== Messages =====
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream({
    required String workspaceId,
    required String chatroomId,
    int limit = 50,
  }) {
    return getChatroomMessagesCollection(workspaceId: workspaceId, chatroomId: chatroomId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getMessages({
    required String workspaceId,
    required String chatroomId,
    int limit = 50,
  }) async {
    try {
      final qs = await getChatroomMessagesCollection(workspaceId: workspaceId, chatroomId: chatroomId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return qs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Parse timestamp
        if (data['timestamp'] is num) {
          data['timestamp'] = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
        }

        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  // ===== Send message via API =====
  Future<Map<String, dynamic>> sendMessage({
    required String workspaceId,
    required String chatroomId,
    required String platform,
    required Map<String, dynamic> message,
    Map<String, dynamic>? sender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseApiUrl/api/mobile/send-message'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'workspaceId': workspaceId,
          'chatroomId': chatroomId,
          'platform': platform,
          'message': message,
          if (sender != null) 'sender': sender,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'messageId': responseData['messageId'],
        };
      } else {
        throw Exception(responseData['error'] ?? 'Failed to send message');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper methods for different message types
  Future<Map<String, dynamic>> sendTextMessage({
    required String workspaceId,
    required String chatroomId,
    required String platform,
    required String text,
    String? replyText, // optional quoted text
    Map<String, dynamic>? sender,
  }) {
    final p = platform.toLowerCase();
    String finalText = text;
    final msg = <String, dynamic>{
      'type': 'text',
    };

    if ((p == 'facebook' || p == 'instagram') && replyText != null && replyText.isNotEmpty) {
      // Format as per request for FB/IG
      finalText = 'ข้อความ $text\nตอบกลับ : $replyText';
    } else if (p == 'line' && replyText != null && replyText.isNotEmpty) {
      // Hint for server to perform proper quote reply for LINE (server-side implementation)
      msg['quoteText'] = replyText;
    }

    msg['text'] = finalText;

    return sendMessage(
      workspaceId: workspaceId,
      chatroomId: chatroomId,
      platform: platform,
      message: msg,
      sender: sender,
    );
  }

  Future<Map<String, dynamic>> sendImageMessage({
    required String workspaceId,
    required String chatroomId,
    required String platform,
    required String imageUrl,
    String? text,
    Map<String, dynamic>? sender,
  }) {
    return sendMessage(
      workspaceId: workspaceId,
      chatroomId: chatroomId,
      platform: platform,
      message: {
        'type': 'image',
        'imageUrl': imageUrl,
        if (text != null && text.isNotEmpty) 'text': text,
      },
      sender: sender,
    );
  }

  Future<Map<String, dynamic>> sendVideoMessage({
    required String workspaceId,
    required String chatroomId,
    required String platform,
    required String videoUrl,
    String? text,
    Map<String, dynamic>? sender,
  }) {
    return sendMessage(
      workspaceId: workspaceId,
      chatroomId: chatroomId,
      platform: platform,
      message: {
        'type': 'video',
        'videoUrl': videoUrl,
        if (text != null && text.isNotEmpty) 'text': text,
      },
      sender: sender,
    );
  }

  Future<Map<String, dynamic>> sendAudioMessage({
    required String workspaceId,
    required String chatroomId,
    required String platform,
    required String audioUrl,
    Map<String, dynamic>? sender,
  }) {
    return sendMessage(
      workspaceId: workspaceId,
      chatroomId: chatroomId,
      platform: platform,
      message: {
        'type': 'audio',
        'audioUrl': audioUrl,
      },
      sender: sender,
    );
  }

  Future<Map<String, dynamic>> sendFileMessage({
    required String workspaceId,
    required String chatroomId,
    required String platform,
    required String fileUrl,
    required String fileName,
    Map<String, dynamic>? sender,
  }) {
    return sendMessage(
      workspaceId: workspaceId,
      chatroomId: chatroomId,
      platform: platform,
      message: {
        'type': 'file',
        'fileUrl': fileUrl,
        'fileName': fileName,
      },
      sender: sender,
    );
  }

  Future<Map<String, dynamic>> sendStickerMessage({
    required String workspaceId,
    required String chatroomId,
    required String platform,
    required String stickerId,
    required String stickerPackageId,
    Map<String, dynamic>? sender,
  }) {
    if (platform.toLowerCase() != 'line') {
      throw Exception('Stickers are only supported on LINE platform');
    }

    return sendMessage(
      workspaceId: workspaceId,
      chatroomId: chatroomId,
      platform: platform,
      message: {
        'type': 'sticker',
        'stickerId': stickerId,
        'stickerPackageId': stickerPackageId,
      },
      sender: sender,
    );
  }
}
