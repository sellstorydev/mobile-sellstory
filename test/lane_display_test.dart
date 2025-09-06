import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../lib/features/board/controllers/lane_display_controller.dart';
import '../lib/features/board/enums/lane_display_mode.dart';

void main() {
  group('Lane Display Controller Tests', () {
    late LaneDisplayController controller;

    setUp(() {
      Get.testMode = true;
      controller = LaneDisplayController();
    });

    tearDown(() {
      Get.reset();
    });

    test('should have default display mode as totalBeforeDiscount', () {
      final mode = controller.getDisplayMode('test-lane-id');
      expect(mode, LaneDisplayMode.totalBeforeDiscount);
    });

    test('should set and get display mode for a lane', () {
      const laneId = 'test-lane-id';
      const mode = LaneDisplayMode.grandTotal;
      
      controller.setDisplayMode(laneId, mode);
      final retrievedMode = controller.getDisplayMode(laneId);
      
      expect(retrievedMode, mode);
    });

    test('should apply mode to all lanes', () {
      final laneIds = ['lane1', 'lane2', 'lane3'];
      const mode = LaneDisplayMode.netTotal;
      
      controller.applyToAllLanes(laneIds, mode);
      
      for (final laneId in laneIds) {
        expect(controller.getDisplayMode(laneId), mode);
      }
    });

    test('should clear display mode for a lane', () {
      const laneId = 'test-lane-id';
      const mode = LaneDisplayMode.grandTotal;
      
      controller.setDisplayMode(laneId, mode);
      controller.clearDisplayMode(laneId);
      
      final retrievedMode = controller.getDisplayMode(laneId);
      expect(retrievedMode, LaneDisplayMode.totalBeforeDiscount); // Should fall back to default
    });
  });

  group('Lane Display Mode Tests', () {
    test('should convert from key correctly', () {
      expect(LaneDisplayMode.fromKey('before_discount'), LaneDisplayMode.totalBeforeDiscount);
      expect(LaneDisplayMode.fromKey('after_discount'), LaneDisplayMode.totalAfterDiscount);
      expect(LaneDisplayMode.fromKey('grand_total'), LaneDisplayMode.grandTotal);
      expect(LaneDisplayMode.fromKey('net_total'), LaneDisplayMode.netTotal);
      expect(LaneDisplayMode.fromKey('none'), LaneDisplayMode.none);
      expect(LaneDisplayMode.fromKey('invalid'), LaneDisplayMode.totalBeforeDiscount); // Should fall back to default
    });

    test('should have correct labels', () {
      expect(LaneDisplayMode.totalBeforeDiscount.label, 'Total (before discount)');
      expect(LaneDisplayMode.totalAfterDiscount.label, 'Total (after discount)');
      expect(LaneDisplayMode.grandTotal.label, 'Grand Total (after VAT)');
      expect(LaneDisplayMode.netTotal.label, 'Net Total (after VAT & WHT)');
      expect(LaneDisplayMode.none.label, 'None');
    });
  });
}
