import '../entities/job_card.dart';
import '../entities/lane.dart';

class MoveCardUseCase {
  List<Lane> execute({
    required List<Lane> lanes,
    required String cardId,
    required String fromLaneId,
    required String toLaneId,
    required int toIndex,
  }) {
    // Find the source and destination lanes
    final fromLaneIndex = lanes.indexWhere((lane) => lane.id == fromLaneId);
    final toLaneIndex = lanes.indexWhere((lane) => lane.id == toLaneId);
    
    if (fromLaneIndex == -1 || toLaneIndex == -1) {
      return lanes; // Return unchanged if lanes not found
    }

    // Find the card in the source lane
    final fromLane = lanes[fromLaneIndex];
    final cardIndex = fromLane.cards.indexWhere((card) => card.id == cardId);
    
    if (cardIndex == -1) {
      return lanes; // Return unchanged if card not found
    }

    // Remove card from source lane
    final card = fromLane.cards[cardIndex];
    final updatedFromCards = List<JobCard>.from(fromLane.cards)..removeAt(cardIndex);
    
    // Update order of remaining cards in source lane
    for (int i = 0; i < updatedFromCards.length; i++) {
      updatedFromCards[i] = updatedFromCards[i].copyWith(order: i);
    }

    // Add card to destination lane
    final toLane = lanes[toLaneIndex];
    final updatedToCards = List<JobCard>.from(toLane.cards);
    
    // Insert card at the specified index
    final adjustedToIndex = toIndex > updatedToCards.length ? updatedToCards.length : toIndex;
    updatedToCards.insert(adjustedToIndex, card.copyWith(
      laneId: toLaneId,
      order: adjustedToIndex,
    ));
    
    // Update order of all cards in destination lane
    for (int i = 0; i < updatedToCards.length; i++) {
      updatedToCards[i] = updatedToCards[i].copyWith(order: i);
    }

    // Create updated lanes
    final updatedLanes = List<Lane>.from(lanes);
    updatedLanes[fromLaneIndex] = fromLane.copyWith(cards: updatedFromCards);
    updatedLanes[toLaneIndex] = toLane.copyWith(cards: updatedToCards);

    return updatedLanes;
  }
}
