import 'dart:async';
import 'package:flutter/material.dart';
import '../config/drag_config.dart';

class BoardAutoScrollWrapper extends StatefulWidget {
  final Widget child;
  final ScrollController? horizontalController;
  final Map<String, ScrollController>? laneControllers;
  final DragAutoScrollConfig config;
  final VoidCallback? onScrollStart;
  final VoidCallback? onScrollEnd;

  const BoardAutoScrollWrapper({
    super.key,
    required this.child,
    this.horizontalController,
    this.laneControllers,
    this.config = const DragAutoScrollConfig(),
    this.onScrollStart,
    this.onScrollEnd,
  });

  @override
  State<BoardAutoScrollWrapper> createState() => _BoardAutoScrollWrapperState();
}

class _BoardAutoScrollWrapperState extends State<BoardAutoScrollWrapper>
    with TickerProviderStateMixin {
  Timer? _scrollTimer;
  bool _isScrolling = false;
  RenderBox? _renderBox;

  @override
  void dispose() {
    _stopScrolling();
    super.dispose();
  }

  void _stopScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    if (_isScrolling) {
      _isScrolling = false;
      widget.onScrollEnd?.call();
    }
  }

  void onGlobalPointerMove(Offset globalPosition) {
    if (!mounted) return;
    
    _renderBox ??= context.findRenderObject() as RenderBox?;
    if (_renderBox == null) return;

    final localPosition = _renderBox!.globalToLocal(globalPosition);
    final size = _renderBox!.size;

    // Check if pointer is in edge zones
    final isInHorizontalEdge = widget.horizontalController != null &&
        (localPosition.dx < widget.config.edgeExtent ||
         localPosition.dx > size.width - widget.config.edgeExtent);

    final isInVerticalEdge = widget.laneControllers != null &&
        (localPosition.dy < widget.config.edgeExtent ||
         localPosition.dy > size.height - widget.config.edgeExtent);

    if (isInHorizontalEdge || isInVerticalEdge) {
      _startScrolling(localPosition, size);
    } else {
      _stopScrolling();
    }
  }

  void _startScrolling(Offset localPosition, Size size) {
    if (_isScrolling) return;

    _isScrolling = true;
    widget.onScrollStart?.call();

    _scrollTimer = Timer.periodic(widget.config.tick, (timer) {
      if (!mounted || !_isScrolling) {
        _stopScrolling();
        return;
      }

      _performScroll(localPosition, size);
    });
  }

  void _performScroll(Offset localPosition, Size size) {
    // Horizontal scrolling
    if (widget.horizontalController != null) {
      final controller = widget.horizontalController!;
      if (controller.hasClients) {
        double horizontalStep = 0;
        
        if (localPosition.dx < widget.config.edgeExtent) {
          // Left edge - scroll left
          final distanceToEdge = widget.config.edgeExtent - localPosition.dx;
          horizontalStep = -_calculateStep(distanceToEdge);
        } else if (localPosition.dx > size.width - widget.config.edgeExtent) {
          // Right edge - scroll right
          final distanceToEdge = localPosition.dx - (size.width - widget.config.edgeExtent);
          horizontalStep = _calculateStep(distanceToEdge);
        }

        if (horizontalStep != 0) {
          final newOffset = (controller.offset + horizontalStep)
              .clamp(0.0, controller.position.maxScrollExtent);
          controller.jumpTo(newOffset);
        }
      }
    }

    // Vertical scrolling - find the appropriate lane controller
    if (widget.laneControllers != null && widget.laneControllers!.isNotEmpty) {
      // For now, use the first available controller
      // In a more sophisticated implementation, you'd determine which lane is active
      final controller = widget.laneControllers!.values.first;
      if (controller.hasClients) {
        double verticalStep = 0;
        
        if (localPosition.dy < widget.config.edgeExtent) {
          // Top edge - scroll up
          final distanceToEdge = widget.config.edgeExtent - localPosition.dy;
          verticalStep = -_calculateStep(distanceToEdge);
        } else if (localPosition.dy > size.height - widget.config.edgeExtent) {
          // Bottom edge - scroll down
          final distanceToEdge = localPosition.dy - (size.height - widget.config.edgeExtent);
          verticalStep = _calculateStep(distanceToEdge);
        }

        if (verticalStep != 0) {
          final newOffset = (controller.offset + verticalStep)
              .clamp(0.0, controller.position.maxScrollExtent);
          controller.jumpTo(newOffset);
        }
      }
    }
  }

  double _calculateStep(double distanceToEdge) {
    final velocity = distanceToEdge * widget.config.velocityScalar;
    final step = velocity * widget.config.tick.inMilliseconds / 1000.0;
    return step.clamp(-widget.config.maxStep, widget.config.maxStep);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (PointerMoveEvent event) => onGlobalPointerMove(event.position),
      onPointerUp: (_) => _stopScrolling(),
      onPointerCancel: (_) => _stopScrolling(),
      child: widget.child,
    );
  }
}
