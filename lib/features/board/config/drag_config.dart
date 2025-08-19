class DragAutoScrollConfig {
  final double edgeExtent;      // default 56
  final double velocityScalar;  // default 120
  final double maxStep;         // default 48
  final Duration tick;          // default 16ms
  
  const DragAutoScrollConfig({
    this.edgeExtent = 56.0,
    this.velocityScalar = 120.0,
    this.maxStep = 48.0,
    this.tick = const Duration(milliseconds: 16),
  });
}
