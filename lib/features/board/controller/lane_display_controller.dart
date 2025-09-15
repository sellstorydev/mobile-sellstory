import 'package:get/get.dart';
import 'package:sellstory/core/enums/lane_display_mode.dart';

class LaneDisplayController extends GetxController {
  // Local storage for each lane's display mode
  final Map<String, LaneDisplayMode> _laneDisplayModes = {};

  // Observable for UI updates
  final RxMap<String, LaneDisplayMode> laneDisplayModes =
      <String, LaneDisplayMode>{}.obs;

  LaneDisplayMode getDisplayMode(String laneId) {
    return laneDisplayModes[laneId] ?? LaneDisplayMode.totalBeforeDiscount;
  }

  void setDisplayMode(String laneId, LaneDisplayMode mode) {
    laneDisplayModes[laneId] = mode;
    _laneDisplayModes[laneId] = mode;
  }

  void applyToAllLanes(List<String> laneIds, LaneDisplayMode mode) {
    for (final laneId in laneIds) {
      setDisplayMode(laneId, mode);
    }
  }

  void clearDisplayMode(String laneId) {
    laneDisplayModes.remove(laneId);
    _laneDisplayModes.remove(laneId);
  }
}
