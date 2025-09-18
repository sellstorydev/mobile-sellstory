import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_repository.dart';

extension FirestoreRepositoryExtras on FirestoreRepository {
  Future<void> updateUserViewSettings(String userId, Map<String, dynamic> viewSettings) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await userRef.set({
      'viewSettings': viewSettings,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserViewSettings(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final doc = await userRef.get();
    if (!doc.exists) return null;
    final data = doc.data();
    return (data?['viewSettings'] as Map<String, dynamic>?);
  }

  Future<Map<String, dynamic>?> getCurrentUserInfo(String userId) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final doc = await userRef.get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    String displayName = '';
    if ((data['displayName'] ?? '').toString().isNotEmpty) {
      displayName = data['displayName'];
    } else if ((data['email'] ?? '').toString().isNotEmpty) {
      displayName = data['email'];
    } else {
      displayName = 'Unknown User';
    }
    return {
      'uid': data['uid'] ?? userId,
      'email': data['email'] ?? '',
      'displayName': displayName,
      'photoURL': data['photoURL'],
    };
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<void> addNoteToCard(String workspaceId, String cardId, Map<String, dynamic> note) async {
    final cardRef = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('cards')
        .doc(cardId);
    await cardRef.update({
      'notes': FieldValue.arrayUnion([note])
    });
  }

  Future<void> deleteCard(String workspaceId, String cardId) async {
    final cardRef = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('cards')
        .doc(cardId);
    final snap = await cardRef.get();
    if (!snap.exists) {
      throw Exception('Card not found: $cardId');
    }
    await cardRef.delete();
  }

  Future<void> moveCard(String workspaceId, String cardId, String fromLaneId, String toLaneId, int newOrder) async {
    final cardsCol = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('cards');
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final cardRef = cardsCol.doc(cardId);
      transaction.update(cardRef, {
        'laneId': toLaneId,
        'order': newOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final fromLaneSnap = await cardsCol
          .where('laneId', isEqualTo: fromLaneId)
          .orderBy('order')
          .get();
      int order = 0;
      for (final doc in fromLaneSnap.docs) {
        if (doc.id != cardId) {
          transaction.update(doc.reference, {
            'order': order,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          order++;
        }
      }

      final toLaneSnap = await cardsCol
          .where('laneId', isEqualTo: toLaneId)
          .orderBy('order')
          .get();
      order = 0;
      for (final doc in toLaneSnap.docs) {
        if (order >= newOrder && doc.id != cardId) {
          transaction.update(doc.reference, {
            'order': order + 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        order++;
      }
    });
  }

  Future<void> reorderCardsInLane(String workspaceId, String laneId, List<String> cardIds) async {
    final cardsCol = FirebaseFirestore.instance
        .collection('workspaces')
        .doc(workspaceId)
        .collection('cards');
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      for (int i = 0; i < cardIds.length; i++) {
        final ref = cardsCol.doc(cardIds[i]);
        transaction.update(ref, {
          'order': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}

