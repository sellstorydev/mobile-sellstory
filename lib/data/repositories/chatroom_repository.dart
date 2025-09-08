import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class ChatroomRepository {
  final FirestoreService _fs = FirestoreService.to;

  // Update hashtags on a chatroom document
  Future<void> setChatroomHashtags({
    required String workspaceId,
    required String chatroomId,
    required List<String> hashtagIds,
    required List<String> hashtagNames,
  }) async {
    await _fs
        .getChatroomsCollection(workspaceId)
        .doc(chatroomId)
        .set({
          'hashtagIds': hashtagIds,
          'hashtags': hashtagNames,
        }, SetOptions(merge: true));
  }

  // Update hashtags on a customer document (array of objects with id/text/color)
  Future<void> setCustomerHashtags({
    required String workspaceId,
    required String customerId,
    required List<Map<String, dynamic>> hashtags,
  }) async {
    await _fs
        .getWorkspaceCustomersCollection(workspaceId)
        .doc(customerId)
        .set({'hashtags': hashtags}, SetOptions(merge: true));
  }

  // Add a user as an assignee on a customer document
  Future<void> addAssigneeToCustomer({
    required String workspaceId,
    required String customerId,
    required String userId,
  }) async {
    await _fs
        .getWorkspaceCustomersCollection(workspaceId)
        .doc(customerId)
        .set({'assignees': FieldValue.arrayUnion([userId])}, SetOptions(merge: true));
  }

  // Add a user as an assignee on a chatroom (when no customer is linked)
  Future<void> addAssigneeToChatroom({
    required String workspaceId,
    required String chatroomId,
    required String userId,
  }) async {
    await _fs
        .getChatroomsCollection(workspaceId)
        .doc(chatroomId)
        .set({'assignees': FieldValue.arrayUnion([userId])}, SetOptions(merge: true));
  }

  // Set bot status (Y/N)
  Future<void> setBotStatus({
    required String workspaceId,
    required String chatroomId,
    required bool enabled,
  }) async {
    await _fs
        .getChatroomsCollection(workspaceId)
        .doc(chatroomId)
        .set({'bot_status': enabled ? 'Y' : 'N'}, SetOptions(merge: true));
  }

  // Set pin status (Y/N)
  Future<void> setPinned({
    required String workspaceId,
    required String chatroomId,
    required bool pinned,
  }) async {
    await _fs
        .getChatroomsCollection(workspaceId)
        .doc(chatroomId)
        .set({'chat_pin': pinned ? 'Y' : 'N'}, SetOptions(merge: true));
  }

  // Fetch a user's display name from users collection
  Future<String> getUserDisplayName(String userId) async {
    try {
      final snap = await _fs.usersCollection.doc(userId).get();
      final m = snap.data() ?? {};
      final dn = (m['displayName'] ?? m['name'] ?? '').toString();
      return dn.isNotEmpty ? dn : '';
    } catch (_) {
      return '';
    }
  }
}
