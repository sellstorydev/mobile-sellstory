import 'package:flutter_test/flutter_test.dart';
import 'package:sellstory/domain/entities/job_card.dart';
import 'package:sellstory/domain/entities/lane.dart';
import 'package:sellstory/domain/usecases/reorder_card_in_lane_usecase.dart';

void main() {
  group('ReorderCardInLaneUseCase', () {
    late ReorderCardInLaneUseCase useCase;
    late List<Lane> lanes;
    late Lane testLane;

    setUp(() {
      useCase = ReorderCardInLaneUseCase();
      
      testLane = Lane(
        id: 'lane1',
        title: 'Test Lane',
        order: 0,
        cards: [
          JobCard(
            id: 'JC001',
            title: 'Card 1',
            assignee: 'John Doe',
            badges: ['Test'],
            amount: 1000.0,
            laneId: 'lane1',
            order: 0,
          ),
          JobCard(
            id: 'JC002',
            title: 'Card 2',
            assignee: 'Jane Smith',
            badges: ['Test'],
            amount: 2000.0,
            laneId: 'lane1',
            order: 1,
          ),
          JobCard(
            id: 'JC003',
            title: 'Card 3',
            assignee: 'Bob Wilson',
            badges: ['Test'],
            amount: 3000.0,
            laneId: 'lane1',
            order: 2,
          ),
        ],
      );

      lanes = [testLane];
    });

    test('should reorder cards within the same lane', () {
      final result = useCase.execute(
        lanes: lanes,
        laneId: 'lane1',
        oldIndex: 0,
        newIndex: 2,
      );

      expect(result[0].cards, hasLength(3));
      expect(result[0].cards[0].id, 'JC002');
      expect(result[0].cards[0].order, 0);
      expect(result[0].cards[1].id, 'JC003');
      expect(result[0].cards[1].order, 1);
      expect(result[0].cards[2].id, 'JC001');
      expect(result[0].cards[2].order, 2);
    });

    test('should maintain order when moving card to same position', () {
      final result = useCase.execute(
        lanes: lanes,
        laneId: 'lane1',
        oldIndex: 1,
        newIndex: 1,
      );

      expect(result[0].cards, hasLength(3));
      expect(result[0].cards[0].id, 'JC001');
      expect(result[0].cards[0].order, 0);
      expect(result[0].cards[1].id, 'JC002');
      expect(result[0].cards[1].order, 1);
      expect(result[0].cards[2].id, 'JC003');
      expect(result[0].cards[2].order, 2);
    });

    test('should move card to beginning of lane', () {
      final result = useCase.execute(
        lanes: lanes,
        laneId: 'lane1',
        oldIndex: 2,
        newIndex: 0,
      );

      expect(result[0].cards, hasLength(3));
      expect(result[0].cards[0].id, 'JC003');
      expect(result[0].cards[0].order, 0);
      expect(result[0].cards[1].id, 'JC001');
      expect(result[0].cards[1].order, 1);
      expect(result[0].cards[2].id, 'JC002');
      expect(result[0].cards[2].order, 2);
    });

    test('should return unchanged lanes when lane not found', () {
      final result = useCase.execute(
        lanes: lanes,
        laneId: 'nonexistent',
        oldIndex: 0,
        newIndex: 1,
      );

      expect(result, equals(lanes));
    });

    test('should return unchanged lanes when old index is invalid', () {
      final result = useCase.execute(
        lanes: lanes,
        laneId: 'lane1',
        oldIndex: -1,
        newIndex: 1,
      );

      expect(result, equals(lanes));
    });

    test('should return unchanged lanes when new index is invalid', () {
      final result = useCase.execute(
        lanes: lanes,
        laneId: 'lane1',
        oldIndex: 0,
        newIndex: 10,
      );

      expect(result, equals(lanes));
    });

    test('should return unchanged lanes when old index exceeds card count', () {
      final result = useCase.execute(
        lanes: lanes,
        laneId: 'lane1',
        oldIndex: 5,
        newIndex: 1,
      );

      expect(result, equals(lanes));
    });
  });
}
