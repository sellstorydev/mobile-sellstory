import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCover extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const VideoCover({
    super.key,
    required this.url,
    this.width = 200,
    this.height = 120,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<VideoCover> createState() => _VideoCoverState();
}

class _VideoCoverState extends State<VideoCover> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await c.initialize().catchError((_) {});
    if (!mounted) return;
    setState(() {
      _controller = c;
      _initialized = c.value.isInitialized;
    });
    // Ensure paused state (cover only)
    if (_initialized) await c.pause();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = !_initialized || _controller == null
        ? Container(color: Colors.grey[300])
        : AspectRatio(
            aspectRatio: _controller!.value.aspectRatio == 0 ? 16 / 9 : _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          );

    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(width: widget.width, height: widget.height, child: child),
          Container(
            width: widget.width,
            height: widget.height,
            decoration: const BoxDecoration(color: Color.fromARGB(80, 0, 0, 0)),
          ),
          const Icon(Icons.play_circle_fill, size: 48, color: Colors.white),
        ],
      ),
    );
  }
}
