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
  
  CollectionReference<Map<String, dynamic>> getWorkspaceBoardsCollection(String workspaceId) => 
      _firestore.collection('workspaces').doc(workspaceId).collection('boards');
  
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
  
  Stream<QuerySnapshot<Map<String, dynamic>>> getDocumentsStream(
    CollectionReference<Map<String, dynamic>> collection, {
    Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>> query)? queryBuilder,
  }) {
    try {
      Query<Map<String, dynamic>> query = collection;
      if (queryBuilder != null) {
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
}
