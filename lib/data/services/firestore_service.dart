import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class FirestoreService extends GetxService {
  static FirestoreService get to => Get.find();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get Firestore instance
  FirebaseFirestore get firestore => _firestore;
  
  // Collection references
  CollectionReference<Map<String, dynamic>> get usersCollection => 
      _firestore.collection('users');
  
  CollectionReference<Map<String, dynamic>> get boardsCollection => 
      _firestore.collection('boards');
  
  CollectionReference<Map<String, dynamic>> get lanesCollection => 
      _firestore.collection('lanes');
  
  CollectionReference<Map<String, dynamic>> get cardsCollection => 
      _firestore.collection('cards');
  
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
      await document.update(data);
    } catch (e) {
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
