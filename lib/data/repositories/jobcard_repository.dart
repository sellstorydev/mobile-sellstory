import '../../domain/entities/job_card.dart';
import '../../domain/entities/lane.dart';

abstract class JobCardRepository {
  Future<List<Lane>> getLanes();
  Future<void> updateLanes(List<Lane> lanes);
  Future<void> addLane(Lane lane);
  Future<void> addCard(JobCard card);
}

class InMemoryJobCardRepository implements JobCardRepository {
  List<Lane> _lanes = [];

  InMemoryJobCardRepository() {
    _initializeSeedData();
  }

  void _initializeSeedData() {
    final now = DateTime.now();
    
    // Create seed lanes
    final newLane = Lane(
      id: 'new',
      title: 'New',
      boardId: 'board1',
      order: 0,
      cards: [
        JobCard(
          id: 'JC001',
          title: 'Website Redesign Project',
          assignee: 'John Doe',
          dueDate: now.add(const Duration(days: 7)),
          badges: ['High Priority', 'Design'],
          amount: 15000.0,
          laneId: 'new',
          order: 0,
          createdAt: now,
          updatedAt: now,
        ),
        JobCard(
          id: 'JC002',
          title: 'Mobile App Development',
          assignee: 'Jane Smith',
          dueDate: now.add(const Duration(days: 14)),
          badges: ['Development', 'iOS'],
          amount: 25000.0,
          laneId: 'new',
          order: 1,
          createdAt: now,
          updatedAt: now,
        ),
        JobCard(
          id: 'JC003',
          title: 'Marketing Campaign',
          assignee: 'Mike Johnson',
          dueDate: now.add(const Duration(days: 5)),
          badges: ['Marketing', 'Social Media'],
          amount: 8000.0,
          laneId: 'new',
          order: 2,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final doingLane = Lane(
      id: 'doing',
      title: 'Doing',
      boardId: 'board1',
      order: 1,
      cards: [
        JobCard(
          id: 'JC004',
          title: 'Database Optimization',
          assignee: 'Sarah Wilson',
          dueDate: now.add(const Duration(days: 3)),
          badges: ['Backend', 'Performance'],
          amount: 12000.0,
          laneId: 'doing',
          order: 0,
          createdAt: now,
          updatedAt: now,
        ),
        JobCard(
          id: 'JC005',
          title: 'UI/UX Design Review',
          assignee: 'Alex Brown',
          dueDate: now.add(const Duration(days: 2)),
          badges: ['Design', 'Review'],
          amount: 5000.0,
          laneId: 'doing',
          order: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final reviewLane = Lane(
      id: 'review',
      title: 'Review',
      boardId: 'board1',
      order: 2,
      cards: [
        JobCard(
          id: 'JC006',
          title: 'API Integration Testing',
          assignee: 'Tom Davis',
          dueDate: now.add(const Duration(days: 1)),
          badges: ['Testing', 'API'],
          amount: 18000.0,
          laneId: 'review',
          order: 0,
          createdAt: now,
          updatedAt: now,
        ),
        JobCard(
          id: 'JC007',
          title: 'Security Audit',
          assignee: 'Lisa Chen',
          dueDate: now.add(const Duration(days: 4)),
          badges: ['Security', 'Audit'],
          amount: 22000.0,
          laneId: 'review',
          order: 1,
          createdAt: now,
          updatedAt: now,
        ),
        JobCard(
          id: 'JC008',
          title: 'Content Creation',
          assignee: 'David Lee',
          dueDate: now,
          badges: ['Content', 'Copywriting'],
          amount: 6000.0,
          laneId: 'review',
          order: 2,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    final doneLane = Lane(
      id: 'done',
      title: 'Done',
      boardId: 'board1',
      order: 3,
      cards: [
        JobCard(
          id: 'JC009',
          title: 'Project Planning',
          assignee: 'Emma Taylor',
          dueDate: now.subtract(const Duration(days: 2)),
          badges: ['Planning', 'Complete'],
          amount: 3000.0,
          laneId: 'done',
          order: 0,
          createdAt: now,
          updatedAt: now,
        ),
        JobCard(
          id: 'JC010',
          title: 'Initial Setup',
          assignee: 'Chris Anderson',
          dueDate: now.subtract(const Duration(days: 1)),
          badges: ['Setup', 'Complete'],
          amount: 4000.0,
          laneId: 'done',
          order: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    _lanes = [newLane, doingLane, reviewLane, doneLane];
  }

  @override
  Future<List<Lane>> getLanes() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _lanes;
  }

  @override
  Future<void> updateLanes(List<Lane> lanes) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    _lanes = lanes;
  }

  @override
  Future<void> addLane(Lane lane) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    _lanes.add(lane);
  }

  @override
  Future<void> addCard(JobCard card) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    final laneIndex = _lanes.indexWhere((lane) => lane.id == card.laneId);
    if (laneIndex != -1) {
      final lane = _lanes[laneIndex];
      final updatedCards = List<JobCard>.from(lane.cards)..add(card);
      _lanes[laneIndex] = lane.copyWith(cards: updatedCards);
    }
  }
}
