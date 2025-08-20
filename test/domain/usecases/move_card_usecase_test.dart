import 'package:flutter_test/flutter_test.dart';
import 'package:sellstory/domain/entities/job_card.dart';
import 'package:sellstory/domain/entities/lane.dart';
import 'package:sellstory/domain/usecases/move_card_usecase.dart';

void main() {
  group('MoveCardUseCase', () {
    late MoveCardUseCase useCase;
    late List<Lane> lanes;
    late JobCard testCard;

    setUp(() {
      useCase = MoveCardUseCase();
      
      testCard = JobCard(
        id: 'JC001',
        title: 'Test Card',
        assignee: 'John Doe',
        badges: ['Test'],
        amount: 1000.0,
        laneId: 'lane1',
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      lanes = [
        Lane(
          id: 'lane1',
          title: 'Lane 1',
          boardId: 'board1',
          order: 0,
          cards: [testCard],
        ),
        Lane(
          id: 'lane2',
          title: 'Lane 2',
          boardId: 'board1',
          order: 1,
          cards: [],
        ),
      ];
    });

    test('should move card from one lane to another', () {
      final result = useCase.execute(
        lanes: lanes,
        cardId: 'JC001',
        fromLaneId: 'lane1',
        toLaneId: 'lane2',
        toIndex: 0,
      );

      expect(result[0].cards, isEmpty);
      expect(result[1].cards, hasLength(1));
      expect(result[1].cards[0].id, 'JC001');
      expect(result[1].cards[0].laneId, 'lane2');
      expect(result[1].cards[0].order, 0);
    });

    test('should update card order when moving to specific index', () {
      // Add another card to lane2
      final existingCard = JobCard(
        id: 'JC002',
        title: 'Existing Card',
        assignee: 'Jane Smith',
        badges: ['Existing'],
        amount: 2000.0,
        laneId: 'lane2',
        order: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      lanes[1] = lanes[1].copyWith(cards: [existingCard]);

      final result = useCase.execute(
        lanes: lanes,
        cardId: 'JC001',
        fromLaneId: 'lane1',
        toLaneId: 'lane2',
        toIndex: 0,
      );

      expect(result[1].cards, hasLength(2));
      expect(result[1].cards[0].id, 'JC001');
      expect(result[1].cards[0].order, 0);
      expect(result[1].cards[1].id, 'JC002');
      expect(result[1].cards[1].order, 1);
    });

    test('should return unchanged lanes when source lane not found', () {
      final result = useCase.execute(
        lanes: lanes,
        cardId: 'JC001',
        fromLaneId: 'nonexistent',
        toLaneId: 'lane2',
        toIndex: 0,
      );

      expect(result, equals(lanes));
    });

    test('should return unchanged lanes when destination lane not found', () {
      final result = useCase.execute(
        lanes: lanes,
        cardId: 'JC001',
        fromLaneId: 'lane1',
        toLaneId: 'nonexistent',
        toIndex: 0,
      );

      expect(result, equals(lanes));
    });

    test('should return unchanged lanes when card not found', () {
      final result = useCase.execute(
        lanes: lanes,
        cardId: 'nonexistent',
        fromLaneId: 'lane1',
        toLaneId: 'lane2',
        toIndex: 0,
      );

      expect(result, equals(lanes));
    });
  });
}
