import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/firestore_service.dart';
import '../../domain/entities/lane.dart';
import '../../domain/entities/job_card.dart';
import '../../core/services/logger_service.dart';

class FirestoreRepository {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final LoggerService _logger = Get.find<LoggerService>();
  
  // Get user's workspaces
  Future<List<Map<String, dynamic>>> getUserWorkspaces(String userId) async {
    try {
      print('🔄 Getting user workspaces for user: $userId');
      
      // Get user document to find their workspaces
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('⚠️ User document not found for user: $userId');
        return [];
      }
      
      final userData = userDoc.data()!;
      final workspacesList = userData['workspaces'] as List<dynamic>? ?? [];
      
      print('📋 Found ${workspacesList.length} workspaces in user data');
      
      final workspaces = <Map<String, dynamic>>[];
      
      // Process workspace data directly from user document
      for (final workspaceItem in workspacesList) {
        try {
          final workspaceData = workspaceItem as Map<String, dynamic>;
          final workspaceId = workspaceData['id'] as String;
          final workspaceName = workspaceData['name'] as String;
          
          print('📋 Processing workspace: $workspaceName ($workspaceId)');
          
          workspaces.add({
            'id': workspaceId,
            'name': workspaceName,
            'role': 'member', // Default role, you might want to get this from user's workspace membership
          });
        } catch (e) {
          print('❌ Failed to process workspace data: $e');
        }
      }
      
      print('✅ User workspaces loaded: ${workspaces.length} workspaces');
      return workspaces;
    } catch (e) {
      print('❌ Failed to get user workspaces: $e');
      rethrow;
    }
  }
  
  // Get workspace data
  Future<Map<String, dynamic>?> getWorkspace(String workspaceId) async {
    try {
      _logger.methodEntry('FirestoreRepository.getWorkspace', {'workspaceId': workspaceId});
      final workspace = await _firestoreService.getWorkspace(workspaceId);
      _logger.methodExit('FirestoreRepository.getWorkspace', {'workspaceFound': workspace != null});
      return workspace;
    } catch (e) {
      _logger.error('Failed to get workspace', e);
      rethrow;
    }
  }
  
  // Get lanes for a specific workspace with real-time updates
  Stream<List<Lane>> getLanesStream(String workspaceId) {
    try {
      print('🔄 Getting lanes stream for workspace: $workspaceId');
      final lanesCollection = _firestoreService.getWorkspaceLanesCollection(workspaceId);
      
      return _firestoreService.getDocumentsStream(
        lanesCollection,
        queryBuilder: (query) => query.orderBy('order', descending: false),
      ).asyncMap((lanesSnapshot) async {
        print('📋 Found ${lanesSnapshot.docs.length} lanes in workspace');
        final lanes = <Lane>[];
        
        for (final laneDoc in lanesSnapshot.docs) {
          final laneData = laneDoc.data();
          final laneId = laneDoc.id;
          final laneTitle = laneData['name'] as String;
          final laneOrder = laneData['order'] as int? ?? 0;
          final boardId = laneData['boardId'] as String;
          
          print('📋 Processing lane: $laneTitle ($laneId)');
          
          // Get cards for this lane using stream
          final cards = await _getCardsStreamForLane(workspaceId, laneId).first;
          
          lanes.add(Lane(
            id: laneId,
            title: laneTitle,
            boardId: boardId,
            order: laneOrder,
            cards: cards,
          ));
        }
        
        // Sort lanes by order
        lanes.sort((a, b) => a.order.compareTo(b.order));
        
        print('✅ Lanes updated from Firestore: ${lanes.length} lanes');
        
        return lanes;
      });
    } catch (e) {
      print('❌ Failed to get lanes stream: $e');
      rethrow;
    }
  }
  
  // Helper method to get cards stream for a specific lane
  Stream<List<JobCard>> _getCardsStreamForLane(String workspaceId, String laneId) {
    try {
      final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      
      return _firestoreService.getDocumentsStream(
        cardsCollection,
        queryBuilder: (query) => query
            .where('laneId', isEqualTo: laneId),
      ).map((cardsSnapshot) {
        print('📋 Found ${cardsSnapshot.docs.length} cards for lane: $laneId');
        
        final cards = cardsSnapshot.docs.map((doc) {
          final cardData = doc.data();
          print('📋 Processing card: ${cardData['title']} (${doc.id}) - Status: ${cardData['status']}');
          
          // Map Firestore data to JobCard entity
          return JobCard(
            id: doc.id,
            title: cardData['title'] ?? '',
            assignee: cardData['assignedTo'] ?? '',
            status: cardData['status'] ?? 'To Do',
            dueDate: null, // Not in current data structure
            badges: [], // Not in current data structure
            amount: 0.0, // Not in current data structure
            laneId: cardData['laneId'] ?? '',
            boardId: cardData['boardId'] ?? '',
            workspaceId: workspaceId,
            order: cardData['order'] ?? 0,
            createdAt: _parseTimestamp(cardData['createdAt']),
            updatedAt: _parseTimestamp(cardData['updatedAt']),
            customer: cardData['customer'] ?? '',
            updatedByDisplayName: cardData['updatedByDisplayName'] ?? '',
          );
        }).toList();
        
        // Sort cards by order after fetching
        cards.sort((a, b) => a.order.compareTo(b.order));
        
        return cards;
      });
    } catch (e) {
      print('❌ Failed to get cards stream for lane $laneId: $e');
      return Stream.value([]);
    }
  }
  
  // Helper method to get cards for a specific lane (for backward compatibility)
  Future<List<JobCard>> _getCardsForLane(String workspaceId, String laneId) async {
    try {
      final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      final cardsSnapshot = await cardsCollection
          .where('laneId', isEqualTo: laneId)
          .get();
      
      print('📋 Found ${cardsSnapshot.docs.length} cards for lane: $laneId');
      
      final cards = cardsSnapshot.docs.map((doc) {
        final cardData = doc.data();
        print('📋 Processing card: ${cardData['title']} (${doc.id}) - Status: ${cardData['status']}');
        
        // Map Firestore data to JobCard entity
        return JobCard(
          id: doc.id,
          title: cardData['title'] ?? '',
          assignee: cardData['assignedTo'] ?? '',
          status: cardData['status'] ?? 'To Do',
          dueDate: null, // Not in current data structure
          badges: [], // Not in current data structure
          amount: 0.0, // Not in current data structure
          laneId: cardData['laneId'] ?? '',
          boardId: cardData['boardId'] ?? '',
          workspaceId: workspaceId,
          order: cardData['order'] ?? 0,
          createdAt: _parseTimestamp(cardData['createdAt']),
          updatedAt: _parseTimestamp(cardData['updatedAt']),
          customer: cardData['customer'] ?? '',
          updatedByDisplayName: cardData['updatedByDisplayName'] ?? '',
        );
      }).toList();
      
      // Sort cards by order after fetching
      cards.sort((a, b) => a.order.compareTo(b.order));
      
      return cards;
    } catch (e) {
      print('❌ Failed to get cards for lane $laneId: $e');
      return [];
    }
  }
  
  // Get all cards for a workspace with real-time updates
  Stream<List<JobCard>> getAllCardsStream(String workspaceId) {
    try {
      print('🔄 Getting all cards stream for workspace: $workspaceId');
      final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      
      return _firestoreService.getDocumentsStream(
        cardsCollection,
      ).map((cardsSnapshot) {
        print('📋 Found ${cardsSnapshot.docs.length} cards in workspace');
        
        final cards = cardsSnapshot.docs.map((doc) {
          final cardData = doc.data();
          print('📋 Processing card: ${cardData['title']} (${doc.id}) - Status: ${cardData['status']}');
          
          return JobCard(
            id: doc.id,
            title: cardData['title'] ?? '',
            assignee: cardData['assignedTo'] ?? '',
            status: cardData['status'] ?? 'To Do',
            dueDate: null,
            badges: [],
            amount: 0.0,
            laneId: cardData['laneId'] ?? '',
            boardId: cardData['boardId'] ?? '',
            workspaceId: workspaceId,
            order: cardData['order'] ?? 0,
            createdAt: _parseTimestamp(cardData['createdAt']),
            updatedAt: _parseTimestamp(cardData['updatedAt']),
            customer: cardData['customer'] ?? '',
            updatedByDisplayName: cardData['updatedByDisplayName'] ?? '',
          );
        }).toList();
        
        // Sort cards by order after fetching
        cards.sort((a, b) => a.order.compareTo(b.order));
        
        print('✅ All cards updated from Firestore: ${cards.length} cards');
        return cards;
      });
    } catch (e) {
      print('❌ Failed to get all cards stream: $e');
      rethrow;
    }
  }
  
  // Helper method to parse timestamp from different formats
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('❌ Failed to parse timestamp string: $timestamp');
        return DateTime.now();
      }
    }
    
    print('❌ Unknown timestamp format: ${timestamp.runtimeType}');
    return DateTime.now();
  }
  
  // Get cards for a specific workspace
  Stream<List<JobCard>> getCardsStream(String workspaceId) {
    try {
      _logger.methodEntry('FirestoreRepository.getCardsStream', {'workspaceId': workspaceId});
      final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      
      return _firestoreService.getDocumentsStream(
        cardsCollection,
        queryBuilder: (query) => query.orderBy('order', descending: false),
      ).map((snapshot) {
        final cards = snapshot.docs.map((doc) {
          final cardData = doc.data();
          return JobCard.fromMap(cardData, doc.id);
        }).toList();
        _logger.systemEvent('Cards loaded', {'workspaceId': workspaceId, 'cardsCount': cards.length});
        return cards;
      });
    } catch (e) {
      _logger.error('Failed to get cards stream', e);
      rethrow;
    }
  }
  
  // Get cards for a specific lane
  Stream<List<JobCard>> getCardsForLaneStream(String workspaceId, String laneId) {
    try {
      _logger.methodEntry('FirestoreRepository.getCardsForLaneStream', {
        'workspaceId': workspaceId,
        'laneId': laneId
      });
      final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      
      return _firestoreService.getDocumentsStream(
        cardsCollection,
        queryBuilder: (query) => query
            .where('laneId', isEqualTo: laneId),
      ).map((snapshot) {
        final cards = snapshot.docs.map((doc) {
          final cardData = doc.data();
          return JobCard(
            id: doc.id,
            title: cardData['title'] ?? '',
            assignee: cardData['assignedTo'] ?? '',
            status: cardData['status'] ?? 'To Do',
            dueDate: null,
            badges: [],
            amount: 0.0,
            laneId: cardData['laneId'] ?? '',
            boardId: cardData['boardId'] ?? '',
            workspaceId: workspaceId,
            order: cardData['order'] ?? 0,
            createdAt: _parseTimestamp(cardData['createdAt']),
            updatedAt: _parseTimestamp(cardData['updatedAt']),
            customer: cardData['customer'] ?? '',
            updatedByDisplayName: cardData['updatedByDisplayName'] ?? '',
          );
        }).toList();
        
        // Sort cards by order after fetching
        cards.sort((a, b) => a.order.compareTo(b.order));
        
        _logger.systemEvent('Lane cards loaded', {
          'workspaceId': workspaceId,
          'laneId': laneId,
          'cardsCount': cards.length
        });
        return cards;
      });
    } catch (e) {
      _logger.error('Failed to get cards for lane stream', e);
      rethrow;
    }
  }
  
  // Get user's assigned cards
  Stream<List<JobCard>> getUserAssignedCardsStream(String workspaceId, String userId) {
    try {
      _logger.methodEntry('FirestoreRepository.getUserAssignedCardsStream', {
        'workspaceId': workspaceId,
        'userId': userId
      });
      final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      
    return _firestoreService.getDocumentsStream(
        cardsCollection,
      queryBuilder: (query) => query
            .where('assignedTo', isEqualTo: userId),
    ).map((snapshot) {
        final cards = snapshot.docs.map((doc) {
          final cardData = doc.data();
          // Map Firestore data to JobCard entity
          return JobCard(
            id: doc.id,
            title: cardData['title'] ?? '',
            assignee: cardData['assignedTo'] ?? '',
            status: cardData['status'] ?? 'To Do',
            dueDate: null, // Not in current data structure
            badges: [], // Not in current data structure
            amount: 0.0, // Not in current data structure
            laneId: cardData['laneId'] ?? '',
            order: cardData['order'] ?? 0,
            createdAt: _parseTimestamp(cardData['createdAt']),
            updatedAt: _parseTimestamp(cardData['updatedAt']),
            customer: cardData['customer'] ?? '',
            updatedByDisplayName: cardData['updatedByDisplayName'] ?? '',
          );
      }).toList();
      
      // Sort cards by order after fetching
      cards.sort((a, b) => a.order.compareTo(b.order));
      
        _logger.systemEvent('User assigned cards loaded', {
          'workspaceId': workspaceId,
          'userId': userId,
          'cardsCount': cards.length
        });
        return cards;
      });
    } catch (e) {
      _logger.error('Failed to get user assigned cards stream', e);
      rethrow;
    }
  }
  
  // Create lane
  Future<String> createLane(String workspaceId, Lane lane) async {
    try {
      _logger.methodEntry('FirestoreRepository.createLane', {
        'workspaceId': workspaceId,
        'laneTitle': lane.title
      });
      final lanesCollection = _firestoreService.getWorkspaceLanesCollection(workspaceId);
      final docRef = await _firestoreService.addDocument(lanesCollection, lane.toMap());
      _logger.methodExit('FirestoreRepository.createLane', {'laneId': docRef.id});
    return docRef.id;
    } catch (e) {
      _logger.error('Failed to create lane', e);
      rethrow;
    }
  }
  
  // Update lane
  Future<void> updateLane(String workspaceId, String laneId, Map<String, dynamic> data) async {
    try {
      _logger.methodEntry('FirestoreRepository.updateLane', {
        'workspaceId': workspaceId,
        'laneId': laneId
      });
      final lanesCollection = _firestoreService.getWorkspaceLanesCollection(workspaceId);
      final docRef = lanesCollection.doc(laneId);
    await _firestoreService.updateDocument(docRef, data);
      _logger.methodExit('FirestoreRepository.updateLane');
    } catch (e) {
      _logger.error('Failed to update lane', e);
      rethrow;
    }
  }
  
  // Delete lane
  Future<void> deleteLane(String workspaceId, String laneId) async {
    try {
      _logger.methodEntry('FirestoreRepository.deleteLane', {
        'workspaceId': workspaceId,
        'laneId': laneId
      });
      final lanesCollection = _firestoreService.getWorkspaceLanesCollection(workspaceId);
      final docRef = lanesCollection.doc(laneId);
    await _firestoreService.deleteDocument(docRef);
      _logger.methodExit('FirestoreRepository.deleteLane');
    } catch (e) {
      _logger.error('Failed to delete lane', e);
      rethrow;
    }
  }
  
  // Create card
  Future<String> createCard(String workspaceId, JobCard card) async {
    try {
      _logger.methodEntry('FirestoreRepository.createCard', {
        'workspaceId': workspaceId,
        'cardTitle': card.title
      });
      final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      final docRef = await _firestoreService.addDocument(cardsCollection, card.toMap());
      _logger.methodExit('FirestoreRepository.createCard', {'cardId': docRef.id});
      return docRef.id;
    } catch (e) {
      _logger.error('Failed to create card', e);
      rethrow;
    }
  }

  // Add card (simplified version)
  Future<void> addCard(String workspaceId, String laneId, String title, String assignee) async {
    try {
      _logger.methodEntry('FirestoreRepository.addCard', {
        'workspaceId': workspaceId,
        'laneId': laneId,
        'title': title,
        'assignee': assignee
      });
      
      final card = JobCard(
        id: '',
        title: title,
        assignee: assignee,
        badges: [],
        amount: 0.0,
        laneId: laneId,
        workspaceId: workspaceId,
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await createCard(workspaceId, card);
      _logger.methodExit('FirestoreRepository.addCard');
    } catch (e) {
      _logger.error('Failed to add card', e);
      rethrow;
    }
  }

  // Update card
  Future<void> updateCard(String workspaceId, JobCard card) async {
    try {
      _logger.methodEntry('FirestoreRepository.updateCard', {
        'workspaceId': workspaceId,
        'cardId': card.id,
        'title': card.title
      });
      
      final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      final docRef = cardsCollection.doc(card.id);
      
      await _firestoreService.updateDocument(docRef, card.toMap());
      
      _logger.methodExit('FirestoreRepository.updateCard');
    } catch (e) {
      _logger.error('Failed to update card', e);
      rethrow;
    }
  }
  
  // Delete card
  Future<void> deleteCard(String workspaceId, String cardId) async {
    try {
      _logger.methodEntry('FirestoreRepository.deleteCard', {
        'workspaceId': workspaceId,
        'cardId': cardId
      });
      final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      final docRef = cardsCollection.doc(cardId);
      await _firestoreService.deleteDocument(docRef);
      _logger.methodExit('FirestoreRepository.deleteCard');
    } catch (e) {
      _logger.error('Failed to delete card', e);
      rethrow;
    }
  }
  
  // Move card between lanes
  Future<void> moveCard(String workspaceId, String cardId, String fromLaneId, String toLaneId, int newOrder) async {
    try {
      _logger.methodEntry('FirestoreRepository.moveCard', {
        'workspaceId': workspaceId,
        'cardId': cardId,
        'fromLaneId': fromLaneId,
        'toLaneId': toLaneId,
        'newOrder': newOrder
      });
      
    await _firestoreService.runTransaction((transaction) async {
        final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
        
      // Update the card's lane and order
        final cardRef = cardsCollection.doc(cardId);
      transaction.update(cardRef, {
        'laneId': toLaneId,
        'order': newOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Reorder cards in the source lane
      final fromLaneCards = await _firestoreService.getDocuments(
          cardsCollection,
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
          cardsCollection,
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
      
      _logger.methodExit('FirestoreRepository.moveCard');
    } catch (e) {
      _logger.error('Failed to move card', e);
      rethrow;
    }
  }
  
  // Reorder cards within the same lane
  Future<void> reorderCardsInLane(String workspaceId, String laneId, List<String> cardIds) async {
    try {
      _logger.methodEntry('FirestoreRepository.reorderCardsInLane', {
        'workspaceId': workspaceId,
        'laneId': laneId,
        'cardIdsCount': cardIds.length
      });
      
    await _firestoreService.runTransaction((transaction) async {
        final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      for (int i = 0; i < cardIds.length; i++) {
          final cardRef = cardsCollection.doc(cardIds[i]);
        transaction.update(cardRef, {
          'order': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
      
      _logger.methodExit('FirestoreRepository.reorderCardsInLane');
    } catch (e) {
      _logger.error('Failed to reorder cards in lane', e);
      rethrow;
    }
  }
  
  // Update lanes (for batch operations)
  Future<void> updateLanes(String workspaceId, List<Lane> lanes) async {
    try {
      _logger.methodEntry('FirestoreRepository.updateLanes', {
        'workspaceId': workspaceId,
        'lanesCount': lanes.length
      });
      
      final lanesCollection = _firestoreService.getWorkspaceLanesCollection(workspaceId);
      final batch = _firestoreService.firestore.batch();
      
      for (final lane in lanes) {
        final docRef = lanesCollection.doc(lane.id);
        batch.update(docRef, lane.toMap());
      }
      
      await batch.commit();
      _logger.methodExit('FirestoreRepository.updateLanes');
    } catch (e) {
      _logger.error('Failed to update lanes', e);
      rethrow;
    }
  }
}
