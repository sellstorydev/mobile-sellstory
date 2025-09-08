import 'lib/domain/entities/job_card.dart';

void main() {
  // Test case 1: Empty watchers and collaborators
  print('=== Test 1: Empty watchers and collaborators ===');
  final card1 = JobCard(
    id: 'test1',
    title: 'Test Card',
    assignedTo: 'user1',
    badges: [],
    amount: 0.0,
    laneId: 'lane1',
    workspaceId: 'workspace1',
    boardId: 'board1',
    order: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    watchers: [],
    collaborators: [],
  );
  
  final map1 = card1.toMap();
  print('Watchers: ${map1['watchers']}');
  print('Collaborators: ${map1['collaborators']}');
  print('');

  // Test case 2: With watchers and collaborators
  print('=== Test 2: With watchers and collaborators ===');
  final card2 = JobCard(
    id: 'test2',
    title: 'Test Card 2',
    assignedTo: 'user1',
    badges: [],
    amount: 0.0,
    laneId: 'lane1',
    workspaceId: 'workspace1',
    boardId: 'board1',
    order: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    watchers: ['user1', 'user2'],
    collaborators: ['user3', 'user4'],
  );
  
  final map2 = card2.toMap();
  print('Watchers: ${map2['watchers']}');
  print('Collaborators: ${map2['collaborators']}');
  print('');

  // Test case 3: Default case - user as watcher
  print('=== Test 3: Default case - user as watcher ===');
  final card3 = JobCard(
    id: 'test3',
    title: 'Test Card 3',
    assignedTo: 'user1',
    badges: [],
    amount: 0.0,
    laneId: 'lane1',
    workspaceId: 'workspace1',
    boardId: 'board1',
    order: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    watchers: ['currentUserId'], // This is what should happen when no watchers selected
    collaborators: [],
  );
  
  final map3 = card3.toMap();
  print('Watchers: ${map3['watchers']}');
  print('Collaborators: ${map3['collaborators']}');
}
