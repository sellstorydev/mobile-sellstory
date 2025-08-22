import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/firestore_service.dart';
import '../../domain/entities/lane.dart';
import '../../domain/entities/job_card.dart';
import '../../domain/entities/customer.dart';
import '../../core/services/logger_service.dart';

class FirestoreRepository {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  final LoggerService _logger = Get.find<LoggerService>();
  
  // Create workspace with default structure
  Future<void> createWorkspace({
    required String name,
    required String ownerId,
    required String ownerEmail,
    required String ownerDisplayName,
  }) async {
    try {
      _logger.methodEntry('FirestoreRepository.createWorkspace', {
        'name': name,
        'ownerId': ownerId,
      });

      // Generate workspace ID
      final workspaceId = FirebaseFirestore.instance.collection('workspaces').doc().id;
      final boardId = FirebaseFirestore.instance.collection('boards').doc().id;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Create workspace document
      final workspaceData = {
        'name': name,
        'ownerId': ownerId,
        'members': {
          ownerId: 'owner',
        },
        'createdAt': now,
        'companyProfile': {
          'roles': [
            {
              'id': 'owner',
              'name': 'Owner',
              'permissions': ['*'],
            },
            {
              'id': 'admin',
              'name': 'Admin',
              'permissions': [
                'jobcard:view:all',
                'jobcard:create',
                'jobcard:edit:all',
                'jobcard:delete:all',
                'jobcard:move',
                'customer:view:all',
                'customer:create',
                'customer:edit:all',
                'customer:delete',
                'customer:import',
                'company:view',
                'company:create',
                'company:edit:all',
                'company:delete',
                'company:import',
                'product:view',
                'product:create',
                'product:edit:all',
                'product:delete',
                'product:import',
                'user:manage',
                'settings:board:manage',
                'settings:company:manage',
                'settings:id:manage',
                'settings:catalog:manage',
                'settings:roles:manage',
              ],
            },
            {
              'id': 'member',
              'name': 'Member',
              'permissions': [
                'jobcard:view:assigned',
                'jobcard:create',
              ],
            },
          ],
          'idGenerationRules': {
            'customer': {
              'prefix': 'CUS',
              'dateFormat': 'YYMMDD',
              'separator': '-',
              'minLength': 4,
              'generationMode': 'auto-editable',
            },
            'company': {
              'prefix': 'COM',
              'dateFormat': 'YYMMDD',
              'separator': '-',
              'minLength': 4,
              'generationMode': 'auto-editable',
            },
            'product': {
              'prefix': 'P',
              'dateFormat': 'YYMMDD',
              'separator': '-',
              'minLength': 4,
              'generationMode': 'auto-editable',
            },
            'jobCard': {
              'prefix': 'JB',
              'dateFormat': 'YYMMDD',
              'separator': '-',
              'minLength': 4,
              'generationMode': 'auto-editable',
            },
            'quotation': {
              'prefix': 'EST',
              'dateFormat': 'YYMMDD',
              'separator': '-',
              'minLength': 4,
              'generationMode': 'auto-editable',
            },
            'invoice': {
              'prefix': 'INV',
              'dateFormat': 'YYMMDD',
              'separator': '-',
              'minLength': 4,
              'generationMode': 'auto-editable',
            },
            'receipt': {
              'prefix': 'RE',
              'dateFormat': 'YYMMDD',
              'separator': '-',
              'minLength': 4,
              'generationMode': 'auto-editable',
            },
          },
          'lastUsedCounters': {
            'customer': 0,
            'company': 0,
            'product': 0,
            'jobCard': 0,
            'quotation': 0,
            'invoice': 0,
            'receipt': 0,
          },
          'customerCustomFieldTemplate': [],
          'todoTemplates': [],
          'customerSources': [],
          'hashtagSettings': {
            'isEnabled': true,
            'mode': 'global',
            'masterList': [],
            'automation': {
              'autoCreateFromChat': false,
            },
          },
          'catalogSettings': {
            'isPublished': false,
            'enableAddToCart': true,
          },
        },
      };

      // Create board document
      final boardData = {
        'name': 'My First Board',
        'workspaceId': workspaceId,
        'createdBy': ownerId,
        'members': [
          {
            'uid': ownerId,
            'email': ownerEmail,
            'displayName': ownerDisplayName,
            'photoURL': null,
            'role': 'owner',
            'language': 'en',
            'workspaces': [],
          },
        ],
        'memberUids': [ownerId],
        'lanes': [],
      };

      // Create default lanes
      final defaultLanes = [
        {'name': 'To Do', 'order': 0},
        {'name': 'In Progress', 'order': 1},
        {'name': 'Done', 'order': 2},
      ];

      // Use batch write to create all documents atomically
      final batch = FirebaseFirestore.instance.batch();

      // Add workspace document
      final workspaceRef = FirebaseFirestore.instance.collection('workspaces').doc(workspaceId);
      batch.set(workspaceRef, workspaceData);

      // Add board document
      final boardRef = FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('boards')
          .doc(boardId);
      batch.set(boardRef, boardData);

      // Add default lanes
      for (final laneData in defaultLanes) {
        final laneId = FirebaseFirestore.instance.collection('lanes').doc().id;
        final laneRef = FirebaseFirestore.instance
            .collection('workspaces')
            .doc(workspaceId)
            .collection('lanes')
            .doc(laneId);
        
        batch.set(laneRef, {
          'boardId': boardId,
          'workspaceId': workspaceId,
          'name': laneData['name'],
          'order': laneData['order'],
          'cards': [],
          'hasMoreCards': false,
        });
      }

      // Update user document to add workspace reference
      final userRef = FirebaseFirestore.instance.collection('users').doc(ownerId);
      batch.update(userRef, {
        'workspaces': FieldValue.arrayUnion([
          {
            'id': workspaceId,
            'name': name,
            'role': 'owner',
          },
        ]),
      });

      // Commit the batch
      await batch.commit();

      // Verify workspace was created successfully
      final createdWorkspace = await _firestoreService.workspacesCollection.doc(workspaceId).get();
      if (!createdWorkspace.exists) {
        throw Exception('Failed to create workspace - document not found after creation');
      }

      _logger.methodExit('FirestoreRepository.createWorkspace', {
        'workspaceId': workspaceId,
        'boardId': boardId,
        'workspaceName': name,
        'verification': 'success',
      });
    } catch (e) {
      _logger.error('Failed to create workspace', e);
      rethrow;
    }
  }

  // Update workspace name
  Future<void> updateWorkspaceName({
    required String workspaceId,
    required String newName,
    required String userId,
  }) async {
    try {
      _logger.methodEntry('FirestoreRepository.updateWorkspaceName', {
        'workspaceId': workspaceId,
        'newName': newName,
        'userId': userId,
      });

      // Use batch write to update both workspace and user document
      final batch = FirebaseFirestore.instance.batch();

      // Update workspace document
      final workspaceRef = _firestoreService.workspacesCollection.doc(workspaceId);
      batch.update(workspaceRef, {
        'name': newName,
      });

      // Update user document to reflect the new workspace name
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      
      // Get current user data to update the workspace reference
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final workspacesList = userData['workspaces'] as List<dynamic>? ?? [];
        
        // Find and update the specific workspace in the user's workspace list
        final updatedWorkspaces = workspacesList.map((workspace) {
          final workspaceData = workspace as Map<String, dynamic>;
          if (workspaceData['id'] == workspaceId) {
            return {
              ...workspaceData,
              'name': newName,
            };
          }
          return workspace;
        }).toList();

        batch.update(userRef, {
          'workspaces': updatedWorkspaces,
        });
      }

      // Commit the batch
      await batch.commit();

      _logger.methodExit('FirestoreRepository.updateWorkspaceName', {
        'workspaceId': workspaceId,
        'newName': newName,
        'updateStatus': 'success',
      });
    } catch (e) {
      _logger.error('Failed to update workspace name', e);
      rethrow;
    }
  }

  // Delete workspace
  Future<void> deleteWorkspace({
    required String workspaceId,
    required String userId,
  }) async {
    try {
      _logger.methodEntry('FirestoreRepository.deleteWorkspace', {
        'workspaceId': workspaceId,
        'userId': userId,
      });

      // Use batch write to delete all related documents
      final batch = FirebaseFirestore.instance.batch();

      // Delete workspace document
      final workspaceRef = _firestoreService.workspacesCollection.doc(workspaceId);
      batch.delete(workspaceRef);

      // Delete all boards in the workspace
      final boardsCollection = FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('boards');
      
      final boardsSnapshot = await boardsCollection.get();
      for (final boardDoc in boardsSnapshot.docs) {
        batch.delete(boardDoc.reference);
      }

      // Delete all lanes in the workspace
      final lanesCollection = FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('lanes');
      
      final lanesSnapshot = await lanesCollection.get();
      for (final laneDoc in lanesSnapshot.docs) {
        batch.delete(laneDoc.reference);
      }

      // Delete all cards in the workspace
      final cardsCollection = FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('cards');
      
      final cardsSnapshot = await cardsCollection.get();
      for (final cardDoc in cardsSnapshot.docs) {
        batch.delete(cardDoc.reference);
      }

      // Delete all customers in the workspace
      final customersCollection = FirebaseFirestore.instance
          .collection('workspaces')
          .doc(workspaceId)
          .collection('customers');
      
      final customersSnapshot = await customersCollection.get();
      for (final customerDoc in customersSnapshot.docs) {
        batch.delete(customerDoc.reference);
      }

      // Update user document to remove workspace reference
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      
      // Get current user data to remove the workspace reference
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final workspacesList = userData['workspaces'] as List<dynamic>? ?? [];
        
        // Remove the specific workspace from the user's workspace list
        final updatedWorkspaces = workspacesList
            .where((workspace) {
              final workspaceData = workspace as Map<String, dynamic>;
              return workspaceData['id'] != workspaceId;
            })
            .toList();

        batch.update(userRef, {
          'workspaces': updatedWorkspaces,
        });
      }

      // Commit the batch
      await batch.commit();

      _logger.methodExit('FirestoreRepository.deleteWorkspace', {
        'workspaceId': workspaceId,
        'deleteStatus': 'success',
        'boardsDeleted': boardsSnapshot.docs.length,
        'lanesDeleted': lanesSnapshot.docs.length,
        'cardsDeleted': cardsSnapshot.docs.length,
        'customersDeleted': customersSnapshot.docs.length,
      });
    } catch (e) {
      _logger.error('Failed to delete workspace', e);
      rethrow;
    }
  }

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
          final workspaceId = workspaceData['id'] as String? ?? '';
          final workspaceName = workspaceData['name'] as String? ?? 'Untitled Workspace';
          
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
          final laneTitle = laneData['name'] as String? ?? 'Untitled Lane';
          final laneOrder = laneData['order'] as int? ?? 0;
          final boardId = laneData['boardId'] as String? ?? '';
          
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
          print('📋 Processing card: ${cardData['title']} (${doc.id}) - Custom ID: ${cardData['customId']}');
          
          // Map Firestore data to JobCard entity
          return JobCard(
            id: doc.id,
            title: cardData['title'] ?? '',
            assignee: cardData['assignedTo'] ?? '',
            status: cardData['status'] ?? 'To Do',
            customId: cardData['customId'] ?? '',
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
        print('📋 Processing card: ${cardData['title']} (${doc.id}) - Custom ID: ${cardData['customId']}');
        
        // Map Firestore data to JobCard entity
        return JobCard(
          id: doc.id,
          title: cardData['title'] ?? '',
          assignee: cardData['assignedTo'] ?? '',
          status: cardData['status'] ?? 'To Do',
          customId: cardData['customId'] ?? '',
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
          print('📋 Processing card: ${cardData['title']} (${doc.id}) - Custom ID: ${cardData['customId']}');
          
          return JobCard(
            id: doc.id,
            title: cardData['title'] ?? '',
            assignee: cardData['assignedTo'] ?? '',
            status: cardData['status'] ?? 'To Do',
            customId: cardData['customId'] ?? '',
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
            customId: cardData['customId'] ?? '',
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
            customId: cardData['customId'] ?? '',
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
  
  // Create a new lane
  Future<String> createLane(String workspaceId, Lane lane) async {
    try {
      _logger.methodEntry('FirestoreRepository.createLane', {
        'workspaceId': workspaceId,
        'laneTitle': lane.title,
      });
      
      final lanesCollection = _firestoreService.getWorkspaceLanesCollection(workspaceId);
      
      // Get base lane data from toMap()
      final laneData = lane.toMap();
      
      // Add missing fields to match backup structure
      laneData['workspaceId'] = workspaceId;
      laneData['name'] = lane.title; // Use 'name' instead of 'title' to match backup
      laneData['cards'] = [];
      laneData['hasMoreCards'] = false;
      
      print('🔄 Creating lane with data:');
      print('  - Name: ${lane.title}');
      print('  - Order: ${lane.order}');
      print('  - Board ID: ${lane.boardId}');
      
      final docRef = await lanesCollection.add(laneData);
      
      _logger.database('Lane created in repository');
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
      
      print('🔄 FirestoreRepository.updateLane:');
      print('  - Workspace ID: $workspaceId');
      print('  - Lane ID: $laneId');
      print('  - Data: $data');
      
      final lanesCollection = _firestoreService.getWorkspaceLanesCollection(workspaceId);
      final docRef = lanesCollection.doc(laneId);
      
      print('🔄 Updating document: ${docRef.path}');
      await _firestoreService.updateDocument(docRef, data);
      
      print('✅ Lane updated successfully');
      _logger.methodExit('FirestoreRepository.updateLane');
    } catch (e) {
      print('❌ Failed to update lane: $e');
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
      
      final cardData = card.toMap();
      
      // Debug logging
      print('🔄 Sending card data to Firebase:');
      print('  - customId: ${cardData['customId']}');
      print('  - assignedTo: ${cardData['assignedTo']}');
      print('  - status: ${cardData['status']}');
      print('  - customer: ${cardData['customer']}');
      print('  - title: ${cardData['title']}');
      
      // Use merge option to prevent overwriting existing fields
      await docRef.set(cardData, SetOptions(merge: true));
      
      _logger.methodExit('FirestoreRepository.updateCard');
    } catch (e) {
      _logger.error('Failed to update card', e);
      rethrow;
    }
  }

  // Get customers for workspace
  Future<List<Customer>> getCustomers(String workspaceId) async {
    try {
      _logger.methodEntry('FirestoreRepository.getCustomers', {
        'workspaceId': workspaceId
      });
      
      print('🔄 FirestoreRepository.getCustomers:');
      print('  - Workspace ID: $workspaceId');
      
      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);
      final querySnapshot = await _firestoreService.getDocuments(customersCollection);
      
      final customers = querySnapshot.docs.map((doc) {
        return Customer.fromMap(doc.data(), doc.id);
      }).toList();
      
      print('✅ Customers loaded successfully - ${customers.length} customers');
      _logger.methodExit('FirestoreRepository.getCustomers', {'count': customers.length});
      return customers;
    } catch (e) {
      print('❌ Failed to get customers: $e');
      _logger.error('Failed to get customers', e);
      rethrow;
    }
  }

  // Get customers stream for workspace
  Stream<List<Customer>> getCustomersStream(String workspaceId) {
    try {
      _logger.methodEntry('FirestoreRepository.getCustomersStream', {
        'workspaceId': workspaceId
      });
      
      print('🔄 FirestoreRepository.getCustomersStream:');
      print('  - Workspace ID: $workspaceId');
      
      final customersCollection = _firestoreService.getWorkspaceCustomersCollection(workspaceId);
      return _firestoreService.getDocumentsStream(customersCollection).map((querySnapshot) {
        final customers = querySnapshot.docs.map((doc) {
          return Customer.fromMap(doc.data(), doc.id);
        }).toList();
        
        print('✅ Customers stream updated - ${customers.length} customers');
        return customers;
      });
    } catch (e) {
      print('❌ Failed to get customers stream: $e');
      _logger.error('Failed to get customers stream', e);
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
