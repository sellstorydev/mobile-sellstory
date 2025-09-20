import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:get/get.dart';

class ImageViewer extends StatelessWidget {
  const ImageViewer({Key? key, required this.path}) : super(key: key);
  final String path;

  @override
  Widget build(BuildContext context) {
    final provider = path.startsWith('http') ? NetworkImage(path) as ImageProvider : FileImage(File(path));
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: InteractiveViewer(
          child: Image(image: provider),
        ),
      ),
    );
  }
}

class VideoViewer extends StatefulWidget {
  const VideoViewer({Key? key, required this.path, this.thumbnailPath}) : super(key: key);
  final String path;
  final String? thumbnailPath;

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  late VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.path.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: _ready
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : (widget.thumbnailPath != null)
                ? (widget.thumbnailPath!.startsWith('http')
                    ? Image.network(widget.thumbnailPath!, fit: BoxFit.contain)
                    : (File(widget.thumbnailPath!).existsSync()
                        ? Image.file(File(widget.thumbnailPath!), fit: BoxFit.contain)
                        : const CircularProgressIndicator()))
                : const CircularProgressIndicator(),
      ),
      floatingActionButton: _ready
          ? FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
              child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
            )
          : null,
    );
  }
}

class AudioViewer extends StatefulWidget {
  const AudioViewer({Key? key, required this.path}) : super(key: key);
  final String path;

  @override
  State<AudioViewer> createState() => _AudioViewerState();
}

class _AudioViewerState extends State<AudioViewer> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    if (widget.path.startsWith('http')) {
      _player.setSourceUrl(widget.path);
    } else {
      _player.setSourceDeviceFile(widget.path);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: IconButton(
          iconSize: 64,
          icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
          onPressed: () async {
            if (_playing) {
              await _player.pause();
            } else {
              await _player.resume();
            }
            if (!mounted) return;
            setState(() => _playing = !_playing);
          },
        ),
      ),
    );
  }
}

class PdfViewer extends StatefulWidget {
  const PdfViewer({Key? key, required this.path}) : super(key: key);
  final String path;

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  PdfController? _pdfController;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.path.startsWith('http')) {
        final res = await http.get(Uri.parse(widget.path));
        if (res.statusCode >= 200 && res.statusCode < 300) {
          _pdfController = PdfController(document: PdfDocument.openData(res.bodyBytes));
        } else {
          _error = 'failed_load_pdf'.trParams({'error': 'HTTP ${res.statusCode}'});
        }
      } else {
        _pdfController = PdfController(document: PdfDocument.openFile(widget.path));
      }
    } catch (e) {
      _error = 'failed_load_pdf'.trParams({'error': '$e'});
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_pdfController == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'cannot_open_file'.tr)),
      );
    }
    return Scaffold(
      appBar: AppBar(),
      body: PdfView(controller: _pdfController!),
    );
  }
}
