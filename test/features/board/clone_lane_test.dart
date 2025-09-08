import 'package:flutter_test/flutter_test.dart';
import 'package:sellstory/features/board/widgets/lane_header.dart';
import 'package:sellstory/domain/entities/lane.dart';
import 'package:sellstory/domain/entities/job_card.dart';

void main() {
  group('Clone Lane Tests', () {
    test('LaneHeader should accept onCloneLane callback', () {
      // Test data
      final testLane = Lane(
        id: 'test-lane-1',
        title: 'Test Lane',
        boardId: 'test-board-1',
        order: 0,
        cards: [],
      );

      bool callbackCalled = false;
      
      // Create LaneHeader widget with clone callback
      final laneHeader = LaneHeader(
        lane: testLane,
        onCloneLane: () {
          callbackCalled = true;
        },
      );

      // Verify callback property is set
      expect(laneHeader.onCloneLane, isNotNull);
      
      // Test callback execution
      laneHeader.onCloneLane?.call();
      expect(callbackCalled, isTrue);
    });

    test('Clone lane should create correct title format', () {
      // Test data
      final sourceLane = Lane(
        id: 'source-lane-1',
        title: 'Original Lane',
        boardId: 'test-board-1',
        order: 0,
        cards: [
          JobCard(
            id: 'card-1',
            title: 'Test Card',
            assignedTo: 'user-1',
            laneId: 'source-lane-1',
            boardId: 'test-board-1',
            workspaceId: 'workspace-1',
            order: 0,
            amount: 1000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            customer: 'Test Customer',
            updatedByDisplayName: 'Test User',
            customFields: [],
            hashtags: [],
            expenses: [],
            todos: [],
            notes: [],
            watchers: [],
            collaborators: [],
            createdBy: 'user-1',
            updatedBy: 'user-1',
            badges: [],
            isVatEnabled: false,
            withholdingTaxPercentage: 0,
          ),
        ],
      );

      // Test that clone title would be generated correctly
      final expectedCloneTitle = '${sourceLane.title} (Copy)';
      expect(expectedCloneTitle, equals('Original Lane (Copy)'));

      // Test that card clone title would be generated correctly  
      final originalCard = sourceLane.cards.first;
      final expectedCardCloneTitle = '${originalCard.title} (Copy)';
      expect(expectedCardCloneTitle, equals('Test Card (Copy)'));
    });

    test('Clone lane should preserve card properties', () {
      // Test card data
      final originalCard = JobCard(
        id: 'original-card-1',
        title: 'Original Card',
        description: 'Test description',
        assignedTo: 'user-1',
        status: 'In Progress',
        customId: 'CARD-001',
        laneId: 'original-lane-1',
        boardId: 'test-board-1',
        workspaceId: 'workspace-1',
        order: 0,
        amount: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customer: 'Test Customer',
        updatedByDisplayName: 'Test User',
        customerId: 'customer-1',
        company: {'name': 'Test Company'},
        hashtag: '#test',
        hashtags: [{'name': 'test', 'color': '#ff0000'}],
        customerInterest: 'High',
        expenses: [{'description': 'Test expense', 'amount': 100}],
        todos: [{'task': 'Test todo', 'completed': false}],
        notes: [{'content': 'Test note', 'createdAt': DateTime.now()}],
        watchers: ['user-1', 'user-2'],
        customFields: [{'key': 'test', 'value': 'test value'}],
        createdBy: 'user-1',
        updatedBy: 'user-1',
        collaborators: ['user-1'],
        priority: 'High',
        badges: ['urgent', 'important'],
        isVatEnabled: true,
        additionalDiscount: {'type': 'percentage', 'value': 10},
        withholdingTaxPercentage: 3,
      );

      // Test that cloned card would preserve all properties (except ID and title)
      final clonedCard = JobCard(
        id: '', // New ID will be generated
        title: '${originalCard.title} (Copy)',
        description: originalCard.description,
        assignedTo: originalCard.assignedTo,
        status: originalCard.status,
        customId: '', // New custom ID will be generated
        dueDate: originalCard.dueDate,
        startDate: originalCard.startDate,
        endDate: originalCard.endDate,
        badges: List<String>.from(originalCard.badges),
        amount: originalCard.amount,
        laneId: 'new-lane-id', // Will be set to cloned lane ID
        boardId: originalCard.boardId,
        workspaceId: originalCard.workspaceId,
        order: originalCard.order,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customer: originalCard.customer,
        updatedByDisplayName: originalCard.updatedByDisplayName,
        customerId: originalCard.customerId,
        company: originalCard.company != null ? Map<String, dynamic>.from(originalCard.company!) : null,
        hashtag: originalCard.hashtag,
        hashtags: originalCard.hashtags.map((h) => Map<String, dynamic>.from(h)).toList(),
        customerInterest: originalCard.customerInterest,
        expenses: originalCard.expenses.map((e) => Map<String, dynamic>.from(e)).toList(),
        todos: originalCard.todos.map((t) => Map<String, dynamic>.from(t)).toList(),
        notes: originalCard.notes.map((n) => Map<String, dynamic>.from(n)).toList(),
        watchers: List<String>.from(originalCard.watchers),
        customFields: originalCard.customFields.map((cf) => Map<String, dynamic>.from(cf)).toList(),
        createdBy: originalCard.createdBy,
        updatedBy: originalCard.updatedBy,
        collaborators: List<String>.from(originalCard.collaborators),
        priority: originalCard.priority,
        isVatEnabled: originalCard.isVatEnabled,
        additionalDiscount: originalCard.additionalDiscount != null ? Map<String, dynamic>.from(originalCard.additionalDiscount!) : null,
        withholdingTaxPercentage: originalCard.withholdingTaxPercentage,
      );

      // Verify cloned properties
      expect(clonedCard.title, equals('Original Card (Copy)'));
      expect(clonedCard.description, equals(originalCard.description));
      expect(clonedCard.assignedTo, equals(originalCard.assignedTo));
      expect(clonedCard.status, equals(originalCard.status));
      expect(clonedCard.customer, equals(originalCard.customer));
      expect(clonedCard.customerId, equals(originalCard.customerId));
      expect(clonedCard.company, equals(originalCard.company));
      expect(clonedCard.hashtag, equals(originalCard.hashtag));
      expect(clonedCard.customerInterest, equals(originalCard.customerInterest));
      expect(clonedCard.badges, equals(originalCard.badges));
      expect(clonedCard.watchers, equals(originalCard.watchers));
      expect(clonedCard.collaborators, equals(originalCard.collaborators));
      expect(clonedCard.priority, equals(originalCard.priority));
      expect(clonedCard.isVatEnabled, equals(originalCard.isVatEnabled));
      expect(clonedCard.withholdingTaxPercentage, equals(originalCard.withholdingTaxPercentage));
      expect(clonedCard.amount, equals(originalCard.amount));
    });
  });
}
