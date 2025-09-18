import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class FirestoreService extends GetxService {
  static FirestoreService get to => Get.find();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get Firestore instance
  FirebaseFirestore get firestore => _firestore;
  
  // Collection references - Updated to match actual Firestore structure
  CollectionReference<Map<String, dynamic>> get usersCollection => 
      _firestore.collection('users');
  
  CollectionReference<Map<String, dynamic>> get workspacesCollection => 
      _firestore.collection('workspaces');
  
  // Get workspace-specific collections
  CollectionReference<Map<String, dynamic>> getWorkspaceLanesCollection(String workspaceId) => 
      _firestore.collection('workspaces').doc(workspaceId).collection('lanes');
  
  CollectionReference<Map<String, dynamic>> getWorkspaceCardsCollection(String workspaceId) => 
      _firestore.collection('workspaces').doc(workspaceId).collection('cards');
  
  CollectionReference<Map<String, dynamic>> getWorkspaceCustomersCollection(String workspaceId) => 
      _firestore.collection('workspaces').doc(workspaceId).collection('customers');
      
  CollectionReference<Map<String, dynamic>> getWorkspaceCompaniesCollection(String workspaceId) => 
      _firestore.collection('workspaces').doc(workspaceId).collection('companies');
  
  CollectionReference<Map<String, dynamic>> getWorkspaceBoardsCollection(String workspaceId) => 
      _firestore.collection('workspaces').doc(workspaceId).collection('boards');
  
  CollectionReference<Map<String, dynamic>> getWorkspaceDocumentsCollection(String workspaceId) => 
      _firestore.collection('workspaces').doc(workspaceId).collection('documents');
  
  // Get user's workspaces
  Future<List<Map<String, dynamic>>> getUserWorkspaces(String userId) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final workspaces = userData['workspaces'] as List<dynamic>? ?? [];
        return workspaces.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get user workspaces: $e');
    }
  }

  // Get user's last active workspace ID
  Future<String?> getUserLastActiveWorkspaceId(String userId) async {
    try {
      final userDoc = await usersCollection.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return userData['lastActiveWorkspaceId'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user last active workspace: $e');
    }
  }

  // Update user's last active workspace ID
  Future<void> updateUserLastActiveWorkspaceId(String userId, String workspaceId) async {
    try {
      print('🔄 FirestoreService.updateUserLastActiveWorkspaceId:');
      print('  - User ID: $userId');
      print('  - Workspace ID: $workspaceId');
      
      await usersCollection.doc(userId).update({
        'lastActiveWorkspaceId': workspaceId,
      });
      
      print('✅ User last active workspace updated successfully');
    } catch (e) {
      print('❌ Failed to update user last active workspace: $e');
      throw Exception('Failed to update user last active workspace: $e');
    }
  }
  
  // Get workspace by ID
  Future<Map<String, dynamic>?> getWorkspace(String workspaceId) async {
    try {
      final doc = await workspacesCollection.doc(workspaceId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get workspace: $e');
    }
  }

  // Generic CRUD operations
  Future<DocumentReference<Map<String, dynamic>>> addDocument(
    CollectionReference<Map<String, dynamic>> collection,
    Map<String, dynamic> data,
  ) async {
    try {
      return await collection.add(data);
    } catch (e) {
      throw Exception('Failed to add document: $e');
    }
  }
  
  Future<void> updateDocument(
    DocumentReference<Map<String, dynamic>> document,
    Map<String, dynamic> data,
  ) async {
    try {
      print('🔄 FirestoreService.updateDocument:');
      print('  - Document path: ${document.path}');
      print('  - Data: $data');
      
      await document.update(data);
      
      print('✅ Document updated successfully');
    } catch (e) {
      print('❌ Failed to update document: $e');
      throw Exception('Failed to update document: $e');
    }
  }
  
  Future<void> deleteDocument(
    DocumentReference<Map<String, dynamic>> document,
  ) async {
    try {
      await document.delete();
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }
  
  Future<Map<String, dynamic>?> getDocument(
    DocumentReference<Map<String, dynamic>> document,
  ) async {
    try {
      final doc = await document.get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get document: $e');
    }
  }

  // Get document reference by ID
  DocumentReference<Map<String, dynamic>> getDocumentReference(
    String workspaceId,
    String documentId,
  ) {
    return getWorkspaceDocumentsCollection(workspaceId).doc(documentId);
  }


  Stream<QuerySnapshot<Map<String, dynamic>>> getDocumentsStream(
    CollectionReference<Map<String, dynamic>> collection, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    try {
      Query<Map<String, dynamic>> query = collection;
      if (queryBuilder != null ) {
        query = queryBuilder(query);
      }
      return query.snapshots();
    } catch (e) {
      throw Exception('Failed to get documents stream: $e');
    }
  }
  
  Future<QuerySnapshot<Map<String, dynamic>>> getDocuments(
    CollectionReference<Map<String, dynamic>> collection, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) async {
    try {
      Query<Map<String, dynamic>> query = collection;
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      return await query.get();
    } catch (e) {
      throw Exception('Failed to get documents: $e');
    }
  }
  
  // Batch operations
  Future<void> batchWrite(List<Future<void> Function(WriteBatch batch)> operations) async {
    try {
      final batch = _firestore.batch();
      for (final operation in operations) {
        await operation(batch);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to execute batch write: $e');
    }
  }
  
  // Transaction operations
  Future<T> runTransaction<T>(Future<T> Function(Transaction transaction) updateFunction) async {
    try {
      return await _firestore.runTransaction(updateFunction);
    } catch (e) {
      throw Exception('Failed to run transaction: $e');
    }
  }

  // Chat-related methods - Updated for workspace-based chatrooms

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

  // ===== Queries =====


  // เดิมชื่อ getConversationsForUser เปลี่ยนให้สื่อความเป็น workspace แทน
  Future<List<Map<String, dynamic>>> getChatroomsForWorkspace(String workspaceId) async {
    try {
      final qs = await getChatroomsCollection(workspaceId)
          .where('is_deleted', isEqualTo: 'N') // ตรงกับ field ในรูป
          .orderBy('last_message_info.last_upd', descending: true) // แก้ไข: last_upd อยู่ใน last_message_info
          .get();


      final items = qs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;


        // ดึงข้อมูลจาก last_message_info
        final lastMessageInfo = data['last_message_info'] as Map<String, dynamic>? ?? {};

        // map fields ให้เข้ากับ widget เดิมของคุณ
        data['name'] = data['name'] ?? data['customerName'] ?? lastMessageInfo['who_name'] ?? 'Unknown';
        data['type'] = (data['dialog_type']?.toString().toUpperCase() == 'GROUP') ? 'group' : 'direct';
        data['lastMessage'] = lastMessageInfo['message'] ?? data['message'] ?? '';
        data['avatarUrl'] = data['avatar']; // ถ้ามี
        data['status'] = data['chatroom_status'] ?? 'active';
        data['unreadCount'] = int.tryParse(data['count']?.toString() ?? '0') ?? 0;
        data['isOnline'] = (data['bot_status'] == 'Y');
        data['sourceType'] = data['source_type'] ?? 'unknown';
        data['isPinned'] = data['chat_pin'] == 'Y';
        data['isNew'] = data['is_new'] == 'Y';

        // แปลงเวลา (รองรับทั้ง String ISO และ Timestamp เผื่ออนาคต)
        DateTime? parseDate(dynamic v) {
          if (v == null) return null;
          if (v is Timestamp) return v.toDate();
          if (v is String) {
            try { return DateTime.parse(v); } catch (_) {}
          }
          return null;
        }
        data['lastMessageAt'] = parseDate(lastMessageInfo['last_upd']);
        data['createdAt'] = parseDate(data['created']);

        return data;
      }).toList();

      // ซ่อนแชทที่ถูกซ่อน (is_hidden) เว้นแต่จะมีข้อความค้างอ่าน (unread > 0)
      final filtered = items.where((m) {
        final hiddenRaw = m['is_hidden'];
        final hidden = hiddenRaw == true || hiddenRaw == 'Y';
        final unread = int.tryParse(m['count']?.toString() ?? '0') ?? (m['unreadCount'] as int? ?? 0);
        return !hidden || unread > 0;
      }).toList();

      return filtered;
    } catch (e) {
      throw Exception('Failed to get chatrooms: $e');
    }
  }

  // ใช้ดึงข้อความของห้อง
  Future<QuerySnapshot<Map<String, dynamic>>> getMessages({
    required String workspaceId,
    required String chatroomId,
    int limit = 50,
  }) {
    return getChatroomMessagesCollection(workspaceId: workspaceId, chatroomId: chatroomId)
        .orderBy('msg_timestamp', descending: true) // จากรูปเป็น string/epoch; ปรับตามจริง
        .limit(limit)
        .get();
  }

  // Mark chatroom as read - updated for workspace structure
  Future<void> markChatroomAsRead(String workspaceId, String chatroomId) async {
    try {
      await getChatroomsCollection(workspaceId).doc(chatroomId).update({
        'count': '0', // Reset count to 0 for read
        'is_new': 'N', // Mark as not new
      });
    } catch (e) {
      throw Exception('Failed to mark chatroom as read: $e');
    }
  }

  // Legacy method for backward compatibility - now properly gets workspace ID
  Future<List<Map<String, dynamic>>> getConversationsForUser(String userId) async {
    try {
      // Get user's current workspace ID instead of using userId directly
      final userWorkspaces = await getUserWorkspaces(userId);

      if (userWorkspaces.isEmpty) {
        throw Exception('User has no workspaces');
      }

      // Get the first workspace or current active workspace
      // You might want to add logic to get the current active workspace
      final currentWorkspaceId = userWorkspaces.first['id'] as String? ?? userWorkspaces.first['workspaceId'] as String?;

      if (currentWorkspaceId == null) {
        throw Exception('No valid workspace ID found');
      }

      return getChatroomsForWorkspace(currentWorkspaceId);
    } catch (e) {
      throw Exception('Failed to get conversations for user: $e');
    }
  }

  // Legacy method for backward compatibility - now uses proper workspace structure
  Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      // Get user's current workspace ID
      final userWorkspaces = await getUserWorkspaces(userId);

      if (userWorkspaces.isEmpty) {
        throw Exception('User has no workspaces');
      }

      final currentWorkspaceId = userWorkspaces.first['id'] as String? ?? userWorkspaces.first['workspaceId'] as String?;

      if (currentWorkspaceId == null) {
        throw Exception('No valid workspace ID found');
      }

      return markChatroomAsRead(currentWorkspaceId, conversationId);
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }
}
