import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/firestore_service.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/lane.dart';
import '../../domain/entities/job_card.dart';

class FirestoreRepository {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  
  // Board operations
  Future<String> createBoard(Board board) async {
    final docRef = await _firestoreService.addDocument(
      _firestoreService.boardsCollection,
      board.toMap(),
    );
    return docRef.id;
  }
  
  Future<void> updateBoard(String boardId, Map<String, dynamic> data) async {
    final docRef = _firestoreService.boardsCollection.doc(boardId);
    await _firestoreService.updateDocument(docRef, data);
  }
  
  Future<void> deleteBoard(String boardId) async {
    final docRef = _firestoreService.boardsCollection.doc(boardId);
    await _firestoreService.deleteDocument(docRef);
  }
  
  Future<Board?> getBoard(String boardId) async {
    final docRef = _firestoreService.boardsCollection.doc(boardId);
    final data = await _firestoreService.getDocument(docRef);
    if (data != null) {
      return Board.fromMap(data, boardId);
    }
    return null;
  }
  
  Stream<List<Board>> getBoardsStream(String userId) {
    return _firestoreService.getDocumentsStream(
      _firestoreService.boardsCollection,
      queryBuilder: (query) => query.where('userId', isEqualTo: userId),
    ).map((snapshot) {
      return snapshot.docs.map((doc) {
        return Board.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
  
  // Lane operations
  Future<String> createLane(Lane lane) async {
    final docRef = await _firestoreService.addDocument(
      _firestoreService.lanesCollection,
      lane.toMap(),
    );
    return docRef.id;
  }
  
  Future<void> updateLane(String laneId, Map<String, dynamic> data) async {
    final docRef = _firestoreService.lanesCollection.doc(laneId);
    await _firestoreService.updateDocument(docRef, data);
  }
  
  Future<void> deleteLane(String laneId) async {
    final docRef = _firestoreService.lanesCollection.doc(laneId);
    await _firestoreService.deleteDocument(docRef);
  }
  
  Stream<List<Lane>> getLanesStream(String boardId) {
    return _firestoreService.getDocumentsStream(
      _firestoreService.lanesCollection,
      queryBuilder: (query) => query
          .where('boardId', isEqualTo: boardId)
          .orderBy('order', descending: false),
    ).map((snapshot) {
      return snapshot.docs.map((doc) {
        return Lane.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
  
  // Card operations
  Future<String> createCard(JobCard card) async {
    final docRef = await _firestoreService.addDocument(
      _firestoreService.cardsCollection,
      card.toMap(),
    );
    return docRef.id;
  }
  
  Future<void> updateCard(String cardId, Map<String, dynamic> data) async {
    final docRef = _firestoreService.cardsCollection.doc(cardId);
    await _firestoreService.updateDocument(docRef, data);
  }
  
  Future<void> deleteCard(String cardId) async {
    final docRef = _firestoreService.cardsCollection.doc(cardId);
    await _firestoreService.deleteDocument(docRef);
  }
  
  Stream<List<JobCard>> getCardsStream(String laneId) {
    return _firestoreService.getDocumentsStream(
      _firestoreService.cardsCollection,
      queryBuilder: (query) => query
          .where('laneId', isEqualTo: laneId)
          .orderBy('order', descending: false),
    ).map((snapshot) {
      return snapshot.docs.map((doc) {
        return JobCard.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
  
  // Batch operations for moving cards
  Future<void> moveCard(String cardId, String fromLaneId, String toLaneId, int newOrder) async {
    await _firestoreService.runTransaction((transaction) async {
      // Update the card's lane and order
      final cardRef = _firestoreService.cardsCollection.doc(cardId);
      transaction.update(cardRef, {
        'laneId': toLaneId,
        'order': newOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Reorder cards in the source lane
      final fromLaneCards = await _firestoreService.getDocuments(
        _firestoreService.cardsCollection,
        queryBuilder: (query) => query
            .where('laneId', isEqualTo: fromLaneId)
            .orderBy('order', descending: false),
      );
      
      int order = 0;
      for (final doc in fromLaneCards.docs) {
        if (doc.id != cardId) {
          transaction.update(doc.reference, {
            'order': order,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          order++;
        }
      }
      
      // Reorder cards in the destination lane
      final toLaneCards = await _firestoreService.getDocuments(
        _firestoreService.cardsCollection,
        queryBuilder: (query) => query
            .where('laneId', isEqualTo: toLaneId)
            .orderBy('order', descending: false),
      );
      
      order = 0;
      for (final doc in toLaneCards.docs) {
        if (order >= newOrder) {
          transaction.update(doc.reference, {
            'order': order + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        order++;
      }
    });
  }
  
  // Reorder cards within the same lane
  Future<void> reorderCardsInLane(String laneId, List<String> cardIds) async {
    await _firestoreService.runTransaction((transaction) async {
      for (int i = 0; i < cardIds.length; i++) {
        final cardRef = _firestoreService.cardsCollection.doc(cardIds[i]);
        transaction.update(cardRef, {
          'order': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
