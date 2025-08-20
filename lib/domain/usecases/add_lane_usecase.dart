import '../entities/lane.dart';

class AddLaneUseCase {
  List<Lane> execute({
    required List<Lane> lanes,
    required String title,
    required String boardId,
  }) {
    // Generate unique ID for the new lane
    final laneId = 'lane_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create new lane
    final newLane = Lane(
      id: laneId,
      title: title,
      boardId: boardId,
      order: lanes.length, // Add to the end
      cards: [],
    );

    // Add lane to the list
    final updatedLanes = List<Lane>.from(lanes)..add(newLane);

    return updatedLanes;
  }
}
