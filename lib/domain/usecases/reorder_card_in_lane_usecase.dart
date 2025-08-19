import '../entities/job_card.dart';
import '../entities/lane.dart';

class ReorderCardInLaneUseCase {
  List<Lane> execute({
    required List<Lane> lanes,
    required String laneId,
    required int oldIndex,
    required int newIndex,
  }) {
    // Find the lane
    final laneIndex = lanes.indexWhere((lane) => lane.id == laneId);
    
    if (laneIndex == -1) {
      return lanes; // Return unchanged if lane not found
    }

    final lane = lanes[laneIndex];
    
    // Validate indices
    if (oldIndex < 0 || oldIndex >= lane.cards.length || 
        newIndex < 0 || newIndex >= lane.cards.length) {
      return lanes; // Return unchanged if indices are invalid
    }

    // Reorder cards within the lane
    final updatedCards = List<JobCard>.from(lane.cards);
    final card = updatedCards.removeAt(oldIndex);
    updatedCards.insert(newIndex, card);
    
    // Update order of all cards
    for (int i = 0; i < updatedCards.length; i++) {
      updatedCards[i] = updatedCards[i].copyWith(order: i);
    }

    // Create updated lanes
    final updatedLanes = List<Lane>.from(lanes);
    updatedLanes[laneIndex] = lane.copyWith(cards: updatedCards);

    return updatedLanes;
  }
}
