import 'package:get/get.dart';
import 'firestore_service.dart';
import '../../domain/entities/board.dart';
import '../../domain/entities/lane.dart';
import '../../domain/entities/job_card.dart';

class FirestoreExample {
  final FirestoreService _firestoreService = Get.find<FirestoreService>();
  
  // Example: Create a new board
  Future<String> createExampleBoard(String userId) async {
    final board = Board(
      id: '',
      title: 'My First Board',
      userId: userId,
      lanes: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final boardId = await _firestoreService.addDocument(
      _firestoreService.boardsCollection,
      board.toMap(),
    );
    
    print('Created board with ID: ${boardId.id}');
    return boardId.id;
  }
  
  // Example: Create lanes for a board
  Future<List<String>> createExampleLanes(String boardId) async {
    final laneTitles = ['To Do', 'In Progress', 'Done'];
    final laneIds = <String>[];
    
    for (int i = 0; i < laneTitles.length; i++) {
      final lane = Lane(
        id: '',
        title: laneTitles[i],
        boardId: boardId,
        order: i,
        cards: [],
      );
      
      final laneId = await _firestoreService.addDocument(
        _firestoreService.lanesCollection,
        lane.toMap(),
      );
      
      laneIds.add(laneId.id);
      print('Created lane "${laneTitles[i]}" with ID: ${laneId.id}');
    }
    
    return laneIds;
  }
  
  // Example: Create cards for a lane
  Future<List<String>> createExampleCards(String laneId) async {
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
      final card = JobCard(
        id: '',
        title: cards[i]['title'] as String,
        assignee: cards[i]['assignee'] as String,
        dueDate: DateTime.now().add(Duration(days: 7 + i)),
        badges: List<String>.from(cards[i]['badges'] as List),
        amount: cards[i]['amount'] as double,
        laneId: laneId,
        order: i,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final cardId = await _firestoreService.addDocument(
        _firestoreService.cardsCollection,
        card.toMap(),
      );
      
      cardIds.add(cardId.id);
      print('Created card "${cards[i]['title']}" with ID: ${cardId.id}');
    }
    
    return cardIds;
  }
  
  // Example: Read all boards for a user
  Future<void> readUserBoards(String userId) async {
    try {
      final snapshot = await _firestoreService.getDocuments(
        _firestoreService.boardsCollection,
        queryBuilder: (query) => query.where('userId', isEqualTo: userId),
      );
      
      print('Found ${snapshot.docs.length} boards for user $userId:');
      for (final doc in snapshot.docs) {
        final board = Board.fromMap(doc.data(), doc.id);
        print('- ${board.title} (ID: ${board.id})');
      }
    } catch (e) {
      print('Error reading boards: $e');
    }
  }
  
  // Example: Stream boards in real-time
  void streamUserBoards(String userId) {
    _firestoreService.getDocumentsStream(
      _firestoreService.boardsCollection,
      queryBuilder: (query) => query.where('userId', isEqualTo: userId),
    ).listen(
      (snapshot) {
        print('Real-time update: ${snapshot.docs.length} boards');
        for (final doc in snapshot.docs) {
          final board = Board.fromMap(doc.data(), doc.id);
          print('- ${board.title} (ID: ${board.id})');
        }
      },
      onError: (error) {
        print('Error in stream: $error');
      },
    );
  }
  
  // Example: Update a card
  Future<void> updateCardExample(String cardId) async {
    try {
      final cardRef = _firestoreService.cardsCollection.doc(cardId);
      await _firestoreService.updateDocument(cardRef, {
        'title': 'Updated Card Title',
        'updatedAt': DateTime.now(),
      });
      print('Card updated successfully');
    } catch (e) {
      print('Error updating card: $e');
    }
  }
  
  // Example: Delete a card
  Future<void> deleteCardExample(String cardId) async {
    try {
      final cardRef = _firestoreService.cardsCollection.doc(cardId);
      await _firestoreService.deleteDocument(cardRef);
      print('Card deleted successfully');
    } catch (e) {
      print('Error deleting card: $e');
    }
  }
  
  // Example: Complete workflow
  Future<void> runCompleteExample(String userId) async {
    print('=== Starting Firestore Example ===');
    
    // Create a board
    final boardId = await createExampleBoard(userId);
    
    // Create lanes
    final laneIds = await createExampleLanes(boardId);
    
    // Create cards in the first lane
    if (laneIds.isNotEmpty) {
      await createExampleCards(laneIds[0]);
    }
    
    // Read all boards
    await readUserBoards(userId);
    
    // Start real-time stream
    streamUserBoards(userId);
    
    print('=== Firestore Example Complete ===');
  }
}
