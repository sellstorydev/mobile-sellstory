import 'package:flutter_test/flutter_test.dart';
import 'package:sellstory/core/config/drag_config.dart';

void main() {
  group('DragAutoScrollConfig', () {
    test('should create with default values', () {
      const config = DragAutoScrollConfig();
      
      expect(config.edgeExtent, 56.0);
      expect(config.velocityScalar, 120.0);
      expect(config.maxStep, 48.0);
      expect(config.tick, const Duration(milliseconds: 16));
    });

    test('should create with custom values', () {
      const config = DragAutoScrollConfig(
        edgeExtent: 80.0,
        velocityScalar: 150.0,
        maxStep: 60.0,
        tick: Duration(milliseconds: 20),
      );
      
      expect(config.edgeExtent, 80.0);
      expect(config.velocityScalar, 150.0);
      expect(config.maxStep, 60.0);
      expect(config.tick, const Duration(milliseconds: 20));
    });

    test('should be const constructible', () {
      const config1 = DragAutoScrollConfig();
      const config2 = DragAutoScrollConfig();
      
      expect(config1, config2);
    });
  });
}
