import '../entities/job_card.dart';
import '../entities/lane.dart';

class AddCardUseCase {
  List<Lane> execute({
    required List<Lane> lanes,
    required String laneId,
    required String title,
    required String assignee,
    required List<String> badges,
    required double amount,
    DateTime? dueDate,
  }) {
    // Find the lane
    final laneIndex = lanes.indexWhere((lane) => lane.id == laneId);
    
    if (laneIndex == -1) {
      return lanes; // Return unchanged if lane not found
    }

    final lane = lanes[laneIndex];
    
    // Generate unique ID for the new card
    final cardId = 'JC${DateTime.now().millisecondsSinceEpoch}';
    
    // Create new card
    final newCard = JobCard(
      id: cardId,
      title: title,
      assignedTo: assignee,
      dueDate: dueDate,
      badges: badges,
      amount: amount,
      laneId: laneId,
      order: lane.cards.length, // Add to the end
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Add card to lane
    final updatedCards = List<JobCard>.from(lane.cards)..add(newCard);

    // Create updated lanes
    final updatedLanes = List<Lane>.from(lanes);
    updatedLanes[laneIndex] = lane.copyWith(cards: updatedCards);

    return updatedLanes;
  }
}
