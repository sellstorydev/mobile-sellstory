import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../core/services/logger_service.dart';
import 'firestore_service.dart';

class FirestoreExample {
  static final FirestoreService _firestoreService = Get.find<FirestoreService>();

  // Example: Create a workspace
  static Future<String> createExampleWorkspace() async {
    final workspaceData = {
      'name': 'Example Workspace',
      'ownerId': 'user123',
      'createdAt': FieldValue.serverTimestamp(),
      'members': {
        'user123': 'owner',
      },
    };
    
    final docRef = await _firestoreService.addDocument(
      _firestoreService.workspacesCollection,
      workspaceData,
    );
    
    LoggerService.to.info('Created workspace with ID: ${docRef.id}');
    return docRef.id;
  }
  
  // Example: Create lanes for a workspace
  static Future<List<String>> createExampleLanes(String workspaceId) async {
    final laneTitles = ['To Do', 'In Progress', 'Done'];
    final laneIds = <String>[];
    
    for (int i = 0; i < laneTitles.length; i++) {
      final laneData = {
        'name': laneTitles[i],
        'order': i,
        'workspaceId': workspaceId,
        'cards': [],
        'hasMoreCards': false,
      };
      
      final laneId = await _firestoreService.addDocument(
        _firestoreService.getWorkspaceLanesCollection(workspaceId),
        laneData,
      );
      
      laneIds.add(laneId.id);
      LoggerService.to.info('Created lane "${laneTitles[i]}" with ID: ${laneId.id}');
    }
    
    return laneIds;
  }
  
  // Example: Create cards for a lane
  static Future<List<String>> createExampleCards(String workspaceId, String laneId) async {
    final cards = [
      {
        'title': 'Design UI Mockups',
        'assignee': 'John Doe',
        'badges': ['Design', 'High Priority'],
        'amount': 1500.0,
      },
      {
        'title': 'Implement Authentication',
        'assignee': 'Jane Smith',
        'badges': ['Backend', 'Security'],
        'amount': 2000.0,
      },
      {
        'title': 'Write Unit Tests',
        'assignee': 'Mike Johnson',
        'badges': ['Testing', 'Quality'],
        'amount': 800.0,
      },
    ];
    
    final cardIds = <String>[];
    
    for (int i = 0; i < cards.length; i++) {
      final cardData = {
        'title': cards[i]['title'] as String,
        'assignee': cards[i]['assignee'] as String,
        'dueDate': Timestamp.fromDate(DateTime.now().add(Duration(days: 7 + i))),
        'badges': List<String>.from(cards[i]['badges'] as List),
        'amount': cards[i]['amount'] as double,
        'laneId': laneId,
        'order': i,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      
      final cardId = await _firestoreService.addDocument(
        _firestoreService.getWorkspaceCardsCollection(workspaceId),
        cardData,
      );
      
      cardIds.add(cardId.id);
      LoggerService.to.info('Created card "${cards[i]['title']}" with ID: ${cardId.id}');
    }
    
    return cardIds;
  }
  
  // Example: Read all workspaces for a user
  static Future<void> readUserWorkspaces(String userId) async {
    try {
      final workspaces = await _firestoreService.getUserWorkspaces(userId);
      
      LoggerService.to.info('Found ${workspaces.length} workspaces for user $userId:');
      for (final workspace in workspaces) {
        LoggerService.to.info('- ${workspace['name']} (ID: ${workspace['id']})');
      }
    } catch (e) {
      LoggerService.to.error('Error reading workspaces: $e');
    }
  }
  
  // Example: Real-time listener for workspaces
  static Stream<QuerySnapshot> listenToWorkspaces() {
    return _firestoreService.getDocumentsStream(
      _firestoreService.workspacesCollection,
    );
  }
  
  // Example: Update a card
  static Future<void> updateCardExample(String workspaceId, String cardId) async {
    try {
      final cardRef = _firestoreService.getWorkspaceCardsCollection(workspaceId).doc(cardId);
      await _firestoreService.updateDocument(cardRef, {
        'title': 'Updated Card Title',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      LoggerService.to.success('Card updated successfully');
    } catch (e) {
      LoggerService.to.error('Error updating card: $e');
    }
  }
  
  // Example: Delete a card
  static Future<void> deleteCardExample(String workspaceId, String cardId) async {
    try {
      final cardRef = _firestoreService.getWorkspaceCardsCollection(workspaceId).doc(cardId);
      await _firestoreService.deleteDocument(cardRef);
      
      LoggerService.to.success('Card deleted successfully');
    } catch (e) {
      LoggerService.to.error('Error deleting card: $e');
    }
  }
  
  // Example: Run the complete example
  static Future<void> runCompleteExample() async {
    LoggerService.to.info('=== Starting Firestore Example ===');
    
    try {
      // Create workspace
      final workspaceId = await createExampleWorkspace();
      
      // Create lanes
      final laneIds = await createExampleLanes(workspaceId);
      
      // Create cards for the first lane
      if (laneIds.isNotEmpty) {
        await createExampleCards(workspaceId, laneIds[0]);
      }
      
      // Read user workspaces
      await readUserWorkspaces('user123');
      
      LoggerService.to.info('=== Firestore Example Complete ===');
    } catch (e) {
      LoggerService.to.error('Error in complete example: $e');
    }
  }
}
