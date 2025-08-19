import '../entities/lane.dart';

class AddLaneUseCase {
  List<Lane> execute({
    required List<Lane> lanes,
    required String title,
  }) {
    // Generate unique ID for the new lane
    final laneId = 'lane_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create new lane
    final newLane = Lane(
      id: laneId,
      title: title,
      order: lanes.length, // Add to the end
      cards: [],
    );

    // Add lane to the list
    final updatedLanes = List<Lane>.from(lanes)..add(newLane);

    return updatedLanes;
  }
}
