import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioViewerPage extends StatefulWidget {
  final String url;
  final String? title;
  const AudioViewerPage({super.key, required this.url, this.title});

  @override
  State<AudioViewerPage> createState() => _AudioViewerPageState();
}

class _AudioViewerPageState extends State<AudioViewerPage> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _state = PlayerState.stopped;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;

  @override
  void initState() {
    super.initState();
    _bind();
    _player.setSourceUrl(widget.url);
  }

  void _bind() {
    _player.onPlayerStateChanged.listen((s) => setState(() => _state = s));
    _player.onDurationChanged.listen((d) => setState(() => _dur = d));
    _player.onPositionChanged.listen((p) => setState(() => _pos = p));
  }

  @override
  void dispose() {
    try{
      _player.stop();
    _player.dispose();
    }catch(e){}
    super.dispose();
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Audio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.audiotrack, size: 96, color: Colors.blueGrey[400]),
            const SizedBox(height: 24),
            Slider(
              value: _pos.inMilliseconds.toDouble().clamp(0, _dur.inMilliseconds.toDouble()),
              max: _dur.inMilliseconds.toDouble() == 0 ? 1 : _dur.inMilliseconds.toDouble(),
              onChanged: (v) async {
                final d = Duration(milliseconds: v.toInt());
                await _player.seek(d);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format(_pos)),
                Text(_format(_dur)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.replay_10),
                  onPressed: () async {
                    await _player.seek(_pos - const Duration(seconds: 10));
                  },
                ),

                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () async {
                    if (_state == PlayerState.playing) {
                      await _player.pause();
                    } else {
                      await _player.resume();
                    }
                  },
                  icon: Icon(_state == PlayerState.playing ? Icons.pause : Icons.play_arrow),
                  label: Text(_state == PlayerState.playing ? 'Pause' : 'Play'),
                ),
                const SizedBox(width: 12),
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.forward_10),
                  onPressed: () async {
                    await _player.seek(_pos + const Duration(seconds: 10));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

