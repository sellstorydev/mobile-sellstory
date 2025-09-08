import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../services/firestore_service.dart';
import '../../domain/entities/lane.dart';
import '../../domain/entities/job_card.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/company.dart';
import '../../domain/entities/board.dart';
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

  // Get user's last active workspace ID
  Future<String?> getUserLastActiveWorkspaceId(String userId) async {
    try {
      print('🔄 Getting user last active workspace for user: $userId');
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('⚠️ User document not found for user: $userId');
        return null;
      }
      
      final userData = userDoc.data()!;
      final lastActiveWorkspaceId = userData['lastActiveWorkspaceId'] as String?;
      
      print('📋 Last active workspace ID: $lastActiveWorkspaceId');
      return lastActiveWorkspaceId;
    } catch (e) {
      print('❌ Failed to get user last active workspace: $e');
      rethrow;
    }
  }


  // Update user's last active workspace ID
  Future<void> updateUserLastActiveWorkspaceId(String userId, String workspaceId) async {
    try {
      print('🔄 Updating user last active workspace:');
      print('  - User ID: $userId');
      print('  - Workspace ID: $workspaceId');
      
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'lastActiveWorkspaceId': workspaceId,
      });
      
      print('✅ User last active workspace updated successfully');
    } catch (e) {
      print('❌ Failed to update user last active workspace: $e');
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
  Stream<List<Lane>> getLanesStream(String workspaceId, {String? boardId}) {
    try {
      print('🔄 Getting lanes stream for workspace: $workspaceId');
      final lanesCollection = _firestoreService.getWorkspaceLanesCollection(workspaceId);
      
      return _firestoreService.getDocumentsStream(
        lanesCollection,
        queryBuilder: (query) {
          var filteredQuery = query.orderBy('order', descending: false);
          if (boardId != null && boardId.isNotEmpty) {
            filteredQuery = filteredQuery.where('boardId', isEqualTo: boardId);
          }
          return filteredQuery;
        },
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
          print('📋 Card hashtags data: ${cardData['hashtags']}');
          
          // Use fromMap to ensure all fields including hashtags are properly mapped
          return JobCard.fromMap(cardData, doc.id);
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
        print('📋 Card hashtags data: ${cardData['hashtags']}');
        
        // Use fromMap to ensure all fields including hashtags are properly mapped
        return JobCard.fromMap(cardData, doc.id);
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
  Stream<List<JobCard>> getAllCardsStream(String workspaceId, {String? boardId}) {
    try {
      print('🔄 Getting all cards stream for workspace: $workspaceId');
      final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
      
      return _firestoreService.getDocumentsStream(
        cardsCollection,
        queryBuilder: (query) {
          if (boardId != null && boardId.isNotEmpty) {
            return query.where('boardId', isEqualTo: boardId);
          }
          return query;
        },
      ).map((cardsSnapshot) {
        print('📋 Found ${cardsSnapshot.docs.length} cards in workspace');
        
        final cards = cardsSnapshot.docs.map((doc) {
          final cardData = doc.data();
          print('📋 Processing card: ${cardData['title']} (${doc.id}) - Custom ID: ${cardData['customId']}');
          print('📋 Card hashtags data: ${cardData['hashtags']}');
          
          // Use fromMap to ensure all fields including hashtags are properly mapped
          return JobCard.fromMap(cardData, doc.id);
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
          print('📋 Lane card hashtags data: ${cardData['hashtags']}');
          
          // Use fromMap to ensure all fields including hashtags are properly mapped
          return JobCard.fromMap(cardData, doc.id);
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
          print('📋 User assigned card hashtags data: ${cardData['hashtags']}');
          
          // Use fromMap to ensure all fields including hashtags are properly mapped
          return JobCard.fromMap(cardData, doc.id);
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
      laneData['boardId'] = lane.boardId; // Ensure boardId is set correctly
      laneData['cards'] = [];
      laneData['hasMoreCards'] = false;
      laneData['createdAt'] = Timestamp.fromDate(DateTime.now());
      laneData['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
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

      // Use Firestore transaction to ensure atomic counter increment and card creation
      final cardId = await _firestoreService.runTransaction<String>((transaction) async {
        // Get workspace document to read current counter
        final workspaceRef = _firestoreService.workspacesCollection.doc(workspaceId);
        final workspaceDoc = await transaction.get(workspaceRef);
        
        if (!workspaceDoc.exists) {
          throw Exception('Workspace not found: $workspaceId');
        }

        final workspaceData = workspaceDoc.data()!;
        
        // Get current counter value
        int currentCounter = 1; // Default counter
        try {
          final companyProfile = workspaceData['companyProfile'] as Map<String, dynamic>?;
          final lastUsedCounters = companyProfile?['lastUsedCounters'] as Map<String, dynamic>?;
          final jobCardCounter = lastUsedCounters?['jobCard'];
          
          if (jobCardCounter is int) {
            currentCounter = jobCardCounter + 1;
          } else if (jobCardCounter is String) {
            currentCounter = (int.tryParse(jobCardCounter) ?? 0) + 1;
          }
        } catch (e) {
          print('⚠️ Error reading counter, using default: $e');
          currentCounter = 1;
        }

        // Generate Job ID with counter
        final now = DateTime.now();
        final dateStr = '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year.toString().substring(2)}';
        final jobId = 'JB-$dateStr-${currentCounter.toString().padLeft(4, '0')}';

        // Create card document
        final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
        final cardDocRef = cardsCollection.doc();
        final cardData = card.copyWith(
          id: cardDocRef.id,
          customId: jobId,
        ).toMap();

        // Debug logging for card data
        print('📝 FirestoreRepository.createCard - Debug Card Data:');
        print('  - Original card title: "${card.title}"');
        print('  - Original card updatedByDisplayName: "${card.updatedByDisplayName}"');
        print('  - Card data title: "${cardData['title']}"');
        print('  - Card data name: "${cardData['name']}"');
        print('  - Card data updatedByDisplayName: "${cardData['updatedByDisplayName']}"');
        print('  - Card data keys: ${cardData.keys.toList()}');

        // Set card document
        transaction.set(cardDocRef, cardData);

        // Update workspace counter
        transaction.update(workspaceRef, {
          'companyProfile.lastUsedCounters.jobCard': currentCounter,
        });

        print('✅ Created card with Job ID: $jobId (counter: $currentCounter)');
        return cardDocRef.id;
      });

      _logger.methodExit('FirestoreRepository.createCard', {'cardId': cardId});
      return cardId;
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
        assignedTo: assignee,
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

  // Get companies for workspace
  Future<List<Company>> getCompanies(String workspaceId) async {
    try {
      _logger.methodEntry('FirestoreRepository.getCompanies', {
        'workspaceId': workspaceId
      });
      
      print('🔄 FirestoreRepository.getCompanies:');
      print('  - Workspace ID: $workspaceId');
      
      final companiesCollection = _firestoreService.getWorkspaceCompaniesCollection(workspaceId);
      final querySnapshot = await _firestoreService.getDocuments(companiesCollection);
      final companies = querySnapshot.docs.map((doc) {
        return Company.fromMap(doc.data(), doc.id);
      }).toList();
      
      print('✅ Companies loaded successfully - ${companies.length} companies');
      return companies;
    } catch (e) {
      print('❌ Failed to get companies: $e');
      _logger.error('Failed to get companies', e);
      rethrow;
    }
  }

  // Get companies stream for workspace
  Stream<List<Company>> getCompaniesStream(String workspaceId) {
    try {
      _logger.methodEntry('FirestoreRepository.getCompaniesStream', {
        'workspaceId': workspaceId
      });
      
      print('🔄 FirestoreRepository.getCompaniesStream:');
      print('  - Workspace ID: $workspaceId');
      
      final companiesCollection = _firestoreService.getWorkspaceCompaniesCollection(workspaceId);
      return _firestoreService.getDocumentsStream(companiesCollection).map((querySnapshot) {
        final companies = querySnapshot.docs.map((doc) {
          return Company.fromMap(doc.data(), doc.id);
        }).toList();
        
        print('✅ Companies stream updated - ${companies.length} companies');
        return companies;
      });
    } catch (e) {
      print('❌ Failed to get companies stream: $e');
      _logger.error('Failed to get companies stream', e);
      rethrow;
    }
  }

  // Create a new company
  Future<void> createCompany(String workspaceId, Company company) async {
    try {
      _logger.methodEntry('FirestoreRepository.createCompany', {
        'workspaceId': workspaceId,
        'name': company.name,
      });

      final companiesCollection = _firestoreService.getWorkspaceCompaniesCollection(workspaceId);
      final data = company.copyWith(workspaceId: workspaceId).toMap();
      await companiesCollection.add(data);

      _logger.methodExit('FirestoreRepository.createCompany');
    } catch (e) {
      _logger.error('Failed to create company', e);
      rethrow;
    }
  }

  // Update an existing company
  Future<void> updateCompany(String workspaceId, Company company) async {
    try {
      _logger.methodEntry('FirestoreRepository.updateCompany', {
        'workspaceId': workspaceId,
        'companyId': company.id,
      });

      final companiesCollection = _firestoreService.getWorkspaceCompaniesCollection(workspaceId);
      final docRef = companiesCollection.doc(company.id);

      // Use merge to avoid overwriting arrays unintentionally
      await docRef.set(company.toMap(), SetOptions(merge: true));

      _logger.methodExit('FirestoreRepository.updateCompany');
    } catch (e) {
      _logger.error('Failed to update company', e);
      rethrow;
    }
  }

  // Delete a company
  Future<void> deleteCompany(String workspaceId, String companyId) async {
    try {
      _logger.methodEntry('FirestoreRepository.deleteCompany', {
        'workspaceId': workspaceId,
        'companyId': companyId,
      });

      final companiesCollection = _firestoreService.getWorkspaceCompaniesCollection(workspaceId);
      await companiesCollection.doc(companyId).delete();

      _logger.methodExit('FirestoreRepository.deleteCompany');
    } catch (e) {
      _logger.error('Failed to delete company', e);
      rethrow;
    }
  }

  // Link a customer to a company (two-way)
  Future<void> linkCustomerToCompany(String workspaceId, String companyId, String customerId) async {
    try {
      _logger.methodEntry('FirestoreRepository.linkCustomerToCompany', {
        'workspaceId': workspaceId,
        'companyId': companyId,
        'customerId': customerId,
      });

      await _firestoreService.runTransaction((transaction) async {
        final companiesCol = _firestoreService.getWorkspaceCompaniesCollection(workspaceId);
        final customersCol = _firestoreService.getWorkspaceCustomersCollection(workspaceId);
        final companyRef = companiesCol.doc(companyId);
        final customerRef = customersCol.doc(customerId);

        final companySnap = await transaction.get(companyRef);
        if (!companySnap.exists) {
          throw Exception('Company not found: $companyId');
        }
        final companyData = companySnap.data()!;

        final customerSnap = await transaction.get(customerRef);
        if (!customerSnap.exists) {
          throw Exception('Customer not found: $customerId');
        }
        final customerData = customerSnap.data()!;

        // Update company's associatedCustomerIds
        final assocIds = List<String>.from(companyData['associatedCustomerIds'] ?? []);
        if (!assocIds.contains(customerId)) {
          assocIds.add(customerId);
        }

        // Update customer's companyNames
        final existingCompanyNamesDynamic = customerData['companyNames'] ?? [];
        final companyNames = <Map<String, dynamic>>[];
        if (existingCompanyNamesDynamic is List) {
          for (final item in existingCompanyNamesDynamic) {
            if (item is Map<String, dynamic>) {
              companyNames.add({
                'id': item['id'] ?? '',
                'label': item['label'] ?? 'Main',
                'value': item['value'] ?? '',
              });
            }
          }
        }

        final alreadyLinked = companyNames.any((m) => (m['id']?.toString() ?? '') == companyId);
        if (!alreadyLinked) {
          companyNames.add({
            'id': companyId,
            'label': (companyData['branch'] as String?)?.isNotEmpty == true ? companyData['branch'] as String : 'Main',
            'value': (companyData['name'] as String?) ?? '',
          });
        }

        transaction.update(companyRef, {
          'associatedCustomerIds': assocIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(customerRef, {
          'companyNames': companyNames,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      _logger.methodExit('FirestoreRepository.linkCustomerToCompany');
    } catch (e) {
      _logger.error('Failed to link customer to company', e);
      rethrow;
    }
  }

  // Unlink a customer from a company (two-way)
  Future<void> unlinkCustomerFromCompany(String workspaceId, String companyId, String customerId) async {
    try {
      _logger.methodEntry('FirestoreRepository.unlinkCustomerFromCompany', {
        'workspaceId': workspaceId,
        'companyId': companyId,
        'customerId': customerId,
      });

      await _firestoreService.runTransaction((transaction) async {
        final companiesCol = _firestoreService.getWorkspaceCompaniesCollection(workspaceId);
        final customersCol = _firestoreService.getWorkspaceCustomersCollection(workspaceId);
        final companyRef = companiesCol.doc(companyId);
        final customerRef = customersCol.doc(customerId);

        final companySnap = await transaction.get(companyRef);
        if (!companySnap.exists) {
          throw Exception('Company not found: $companyId');
        }
        final companyData = companySnap.data()!;

        final customerSnap = await transaction.get(customerRef);
        if (!customerSnap.exists) {
          throw Exception('Customer not found: $customerId');
        }
        final customerData = customerSnap.data()!;

        // Remove customerId from company's associatedCustomerIds
        final assocIds = List<String>.from(companyData['associatedCustomerIds'] ?? []);
        assocIds.removeWhere((id) => id == customerId);

        // Remove company entry from customer's companyNames
        final existingCompanyNamesDynamic = customerData['companyNames'] ?? [];
        final companyNames = <Map<String, dynamic>>[];
        if (existingCompanyNamesDynamic is List) {
          for (final item in existingCompanyNamesDynamic) {
            if (item is Map<String, dynamic>) {
              final idVal = item['id']?.toString() ?? '';
              if (idVal != companyId) {
                companyNames.add({
                  'id': item['id'] ?? '',
                  'label': item['label'] ?? 'Main',
                  'value': item['value'] ?? '',
                });
              }
            }
          }
        }

        transaction.update(companyRef, {
          'associatedCustomerIds': assocIds,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(customerRef, {
          'companyNames': companyNames,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      _logger.methodExit('FirestoreRepository.unlinkCustomerFromCompany');
    } catch (e) {
      _logger.error('Failed to unlink customer from company', e);
      rethrow;
    }
  }

  // Get boards for workspace
  Future<List<Board>> getBoards(String workspaceId) async {
    try {
      _logger.methodEntry('FirestoreRepository.getBoards', {
        'workspaceId': workspaceId
      });

      print('🔄 FirestoreRepository.getBoards:');
      print('  - Workspace ID: $workspaceId');

      final boardsCollection = _firestoreService.getWorkspaceBoardsCollection(workspaceId);
      final querySnapshot = await _firestoreService.getDocuments(boardsCollection);
      final boards = querySnapshot.docs.map((doc) {
        return Board.fromMap(doc.data(), doc.id);
      }).toList();

      print('✅ Boards loaded successfully - ${boards.length} boards');
      return boards;
    } catch (e) {
      print('❌ Failed to get boards: $e');
      _logger.error('Failed to get boards', e);
      rethrow;
    }
  }

  // Get boards stream for workspace
  Stream<List<Board>> getBoardsStream(String workspaceId) {
    try {
      _logger.methodEntry('FirestoreRepository.getBoardsStream', {
        'workspaceId': workspaceId
      });

      print('🔄 FirestoreRepository.getBoardsStream:');
      print('  - Workspace ID: $workspaceId');

      final boardsCollection = _firestoreService.getWorkspaceBoardsCollection(workspaceId);
      return _firestoreService.getDocumentsStream(boardsCollection).map((querySnapshot) {
        final boards = querySnapshot.docs.map((doc) {
          return Board.fromMap(doc.data(), doc.id);
        }).toList();

        print('✅ Boards stream updated - ${boards.length} boards');
        return boards;
      });
    } catch (e) {
      print('❌ Failed to get boards stream: $e');
      _logger.error('Failed to get boards stream', e);
      rethrow;
    }
  }

  // Get documents for workspace
  Future<List<Map<String, dynamic>>> getDocuments({
    required String workspaceId,
    int? limit,
  }) async {
    try {
      _logger.methodEntry('FirestoreRepository.getDocuments', {
        'workspaceId': workspaceId,
        'limit': limit,
      });

      print('🔄 FirestoreRepository.getDocuments:');
      print('  - Workspace ID: $workspaceId');
      print('  - Limit: $limit');

      final documentsCollection = _firestoreService.getWorkspaceDocumentsCollection(workspaceId);

      Query<Map<String, dynamic>> query = documentsCollection;
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.orderBy('createdAt', descending: true).get();

      final documents = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return data;
      }).toList();

      print('✅ Documents loaded successfully - ${documents.length} documents');
      return documents;
    } catch (e) {
      print('❌ Failed to get documents: $e');
      _logger.error('Failed to get documents', e);
      rethrow;
    }
  }

  // Get documents with pagination support
  Future<Map<String, dynamic>> getDocumentsPaginated({
    required String workspaceId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      _logger.methodEntry('FirestoreRepository.getDocumentsPaginated', {
        'workspaceId': workspaceId,
        'limit': limit,
        'hasStartAfter': startAfter != null,
      });

      print('🔄 FirestoreRepository.getDocumentsPaginated:');
      print('  - Workspace ID: $workspaceId');
      print('  - Limit: $limit');
      print('  - Start after: ${startAfter != null ? 'Yes' : 'No'}');

      final documentsCollection = _firestoreService.getWorkspaceDocumentsCollection(workspaceId);

      Query<Map<String, dynamic>> query = documentsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      final documents = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return data;
      }).toList();

      final hasMore = documents.length == limit;
      final lastDocument = querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null;

      print('✅ Documents loaded successfully - ${documents.length} documents, hasMore: $hasMore');
      
      return {
        'documents': documents,
        'hasMore': hasMore,
        'lastDocument': lastDocument,
      };
    } catch (e) {
      print('❌ Failed to get paginated documents: $e');
      _logger.error('Failed to get paginated documents', e);
      rethrow;
    }
  }

  // Create new document
  Future<String> createDocument({
    required String workspaceId,
    required Map<String, dynamic> documentData,
  }) async {
    try {
      _logger.methodEntry('FirestoreRepository.createDocument', {
        'workspaceId': workspaceId,
        'type': documentData['type'],
      });

      print('🔄 FirestoreRepository.createDocument:');
      print('  - Workspace ID: $workspaceId');
      print('  - Document type: ${documentData['type']}');

      final documentsCollection = _firestoreService.getWorkspaceDocumentsCollection(workspaceId);
      final documentRef = await _firestoreService.addDocument(documentsCollection, documentData);

      print('✅ Document created successfully with ID: ${documentRef.id}');
      return documentRef.id;
    } catch (e) {
      print('❌ Failed to create document: $e');
      _logger.error('Failed to create document', e);
      rethrow;
    }
  }

  // Update existing document
  Future<void> updateDocument({
    required String workspaceId,
    required String documentId,
    required Map<String, dynamic> documentData,
  }) async {
    try {
      _logger.methodEntry('FirestoreRepository.updateDocument', {
        'workspaceId': workspaceId,
        'documentId': documentId,
        'type': documentData['type'],
      });

      print('🔄 FirestoreRepository.updateDocument:');
      print('  - Workspace ID: $workspaceId');
      print('  - Document ID: $documentId');
      print('  - Document type: ${documentData['type']}');

      final documentRef = _firestoreService.getDocumentReference(workspaceId, documentId);
      await _firestoreService.updateDocument(documentRef, documentData);

      print('✅ Document updated successfully');
    } catch (e) {
      print('❌ Failed to update document: $e');
      _logger.error('Failed to update document', e);
      rethrow;
    }
  }

  // Get users for a specific workspace
  Future<List<Map<String, dynamic>>> getWorkspaceUsers(String workspaceId) async {
    try {
      print('🔄 Getting users for workspace: $workspaceId');

      // Get all users from the users collection
      final usersCollection = _firestoreService.usersCollection;
      final usersSnapshot = await usersCollection.get();

      print('📋 Found ${usersSnapshot.docs.length} total users');

      final userList = <Map<String, dynamic>>[];

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final workspaces = userData['workspaces'] as List<dynamic>? ?? [];

        // Check if user belongs to the specified workspace
        final belongsToWorkspace = workspaces.any((workspace) {
          if (workspace is Map<String, dynamic>) {
            return workspace['id'] == workspaceId;
          }
          return false;
        });

        if (belongsToWorkspace) {
          // Get user's role in this specific workspace
          String userRole = 'member';
          try {
            final workspaceData = workspaces.firstWhere(
              (w) => w is Map<String, dynamic> && w['id'] == workspaceId,
              orElse: () => <String, dynamic>{}
            );
            if (workspaceData is Map<String, dynamic>) {
              userRole = workspaceData['role'] as String? ?? 'member';
            }
          } catch (e) {
            print('⚠️ Error getting user role for ${userData['uid']}: $e');
          }

          // Extract display name - prefer displayName, fallback to email
          String displayName = '';
          if (userData['displayName'] != null && userData['displayName'].toString().isNotEmpty) {
            displayName = userData['displayName'].toString();
          } else if (userData['email'] != null && userData['email'].toString().isNotEmpty) {
            displayName = userData['email'].toString();
          } else {
            displayName = 'Unknown User';
          }

          userList.add({
            'uid': userData['uid'] ?? '',
            'id': userData['uid'] ?? '', // Add id field for consistency
            'email': userData['email'] ?? '',
            'displayName': displayName,
            'name': displayName, // Add name field for UI compatibility
            'role': userRole,
          });

          print('👤 User found: ${displayName} (${userData['uid']}) - Role: $userRole');
        }
      }

      print('✅ Users loaded for workspace: ${userList.length} users');
      return userList;
    } catch (e) {
      print('❌ Failed to get workspace users: $e');
      rethrow;
    }
  }

  // Create board
  Future<String> createBoard(String workspaceId, String name, String createdBy) async {
    try {
      _logger.methodEntry('FirestoreRepository.createBoard', {
        'workspaceId': workspaceId,
        'name': name,
        'createdBy': createdBy
      });

      // Use Firestore transaction to ensure atomic board creation with default lanes
      final boardId = await _firestoreService.runTransaction<String>((transaction) async {
        // Create board document
        final boardsCollection = _firestoreService.getWorkspaceBoardsCollection(workspaceId);
        final boardDocRef = boardsCollection.doc();

        final boardData = {
          'name': name,
          'workspaceId': workspaceId,
          'createdBy': createdBy,
          'members': [
            {
              'uid': createdBy,
              'email': 'mobile-user@example.com',
              'displayName': 'Mobile User',
              'photoURL': null,
              'role': 'owner',
              'language': 'en',
              'workspaces': [],
            },
          ],
          'memberUids': [createdBy],
          'lanes': [],
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        };

        // Set board document
        transaction.set(boardDocRef, boardData);

        // Create default lanes
        final defaultLanes = [
          {'name': 'To Do', 'order': 0},
          {'name': 'In Progress', 'order': 1},
          {'name': 'Done', 'order': 2},
        ];

        final lanesCollection = _firestoreService.getWorkspaceLanesCollection(workspaceId);
        for (final laneData in defaultLanes) {
          final laneId = FirebaseFirestore.instance.collection('lanes').doc().id;
          final laneRef = lanesCollection.doc(laneId);

          transaction.set(laneRef, {
            'boardId': boardDocRef.id,
            'workspaceId': workspaceId,
            'name': laneData['name'],
            'order': laneData['order'],
            'cards': [],
            'hasMoreCards': false,
            'createdAt': Timestamp.fromDate(DateTime.now()),
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }

        print('✅ Created board with ID: ${boardDocRef.id}');
        return boardDocRef.id;
      });

      _logger.methodExit('FirestoreRepository.createBoard', {'boardId': boardId});
      return boardId;
    } catch (e) {
      _logger.error('Failed to create board', e);
      rethrow;
    }
  }

  // Update board
  Future<void> updateBoard(String workspaceId, String boardId, String newName) async {
    try {
      _logger.methodEntry('FirestoreRepository.updateBoard', {
        'workspaceId': workspaceId,
        'boardId': boardId,
        'newName': newName
      });

      final boardsCollection = _firestoreService.getWorkspaceBoardsCollection(workspaceId);
      final boardRef = boardsCollection.doc(boardId);

      await _firestoreService.updateDocument(boardRef, {
        'name': newName,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Updated board: $boardId with new name: $newName');
      _logger.methodExit('FirestoreRepository.updateBoard');
    } catch (e) {
      _logger.error('Failed to update board', e);
      rethrow;
    }
  }

  // Delete board
  Future<void> deleteBoard(String workspaceId, String boardId) async {
    try {
      _logger.methodEntry('FirestoreRepository.deleteBoard', {
        'workspaceId': workspaceId,
        'boardId': boardId
      });

      // Use Firestore transaction to ensure atomic deletion
      await _firestoreService.runTransaction<void>((transaction) async {
        // Delete board document
        final boardsCollection = _firestoreService.getWorkspaceBoardsCollection(workspaceId);
        final boardRef = boardsCollection.doc(boardId);
        transaction.delete(boardRef);

        // Delete all lanes in this board
        final lanesCollection = _firestoreService.getWorkspaceLanesCollection(workspaceId);
        final lanesQuery = await _firestoreService.getDocuments(
          lanesCollection,
          queryBuilder: (query) => query.where('boardId', isEqualTo: boardId),
        );

        for (final laneDoc in lanesQuery.docs) {
          transaction.delete(laneDoc.reference);
        }

        // Delete all cards in this board
        final cardsCollection = _firestoreService.getWorkspaceCardsCollection(workspaceId);
        final cardsQuery = await _firestoreService.getDocuments(
          cardsCollection,
          queryBuilder: (query) => query.where('boardId', isEqualTo: boardId),
        );

        for (final cardDoc in cardsQuery.docs) {
          transaction.delete(cardDoc.reference);
        }

        print('✅ Deleted board: $boardId with all lanes and cards');
      });

      _logger.methodExit('FirestoreRepository.deleteBoard');
    } catch (e) {
      _logger.error('Failed to delete board', e);
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
      final cardDocRef = cardsCollection.doc(cardId);

      // Check if card exists
      final cardDoc = await cardDocRef.get();
      if (!cardDoc.exists) {
        throw Exception('Card not found: $cardId');
      }

      // Delete the card
      await cardDocRef.delete();

      print('✅ Deleted card with ID: $cardId');
      _logger.methodExit('FirestoreRepository.deleteCard', {'cardId': cardId});
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

  // Update user's view settings for card display
  Future<void> updateUserViewSettings(String userId, Map<String, dynamic> viewSettings) async {
    try {
      _logger.methodEntry('FirestoreRepository.updateUserViewSettings', {
        'userId': userId,
        'viewSettingsKeys': viewSettings.keys.toList(),
      });

      final userRef = _firestoreService.firestore.collection('users').doc(userId);

      await userRef.update({
        'viewSettings': viewSettings,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.methodExit('FirestoreRepository.updateUserViewSettings');
    } catch (e) {
      _logger.error('Failed to update user view settings', e);
      rethrow;
    }
  }

  // Get user's view settings for card display
  Future<Map<String, dynamic>?> getUserViewSettings(String userId) async {
    try {
      _logger.methodEntry('FirestoreRepository.getUserViewSettings', {
        'userId': userId,
      });

      final userRef = _firestoreService.firestore.collection('users').doc(userId);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final viewSettings = userData?['viewSettings'] as Map<String, dynamic>?;

        _logger.methodExit('FirestoreRepository.getUserViewSettings', {
          'hasViewSettings': viewSettings != null,
          'settingsCount': viewSettings?.length ?? 0,
        });

        return viewSettings;
      }

      _logger.methodExit('FirestoreRepository.getUserViewSettings', {
        'userNotFound': true,
      });

      return null;
    } catch (e) {
      _logger.error('Failed to get user view settings', e);
      rethrow;
    }
  }
}
