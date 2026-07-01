import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../providers/media_provider.dart';

class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({super.key, required this.videoId});

  final String videoId;

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  VideoPlayerController? _controller;
  Future<void>? _initialize;
  double _speed = 1;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ref
        .watch(mediaLibraryProvider)
        .items
        .where((item) => item.id == widget.videoId)
        .firstOrNull;
    if (item == null) {
      return const Scaffold(body: Center(child: Text('Video not found')));
    }
    final path = item.path;
    if (path == null || path.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(item.title),
        ),
        body: const Center(
          child: Text(
            'Video file path not available. Refresh device videos first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    if (_controller == null) {
      _controller = VideoPlayerController.file(File(path));
      _initialize = _controller!.initialize().then((_) {
        _controller!
          ..setLooping(false)
          ..play();
        final saved = item.lastPosition;
        if (saved != null) _controller!.seekTo(saved);
        if (mounted) setState(() {});
      });
      _controller!.addListener(() {
        if (!mounted) return;
        final value = _controller!.value;
        if (value.isInitialized) {
          ref
              .read(mediaLibraryProvider.notifier)
              .savePlaybackPosition(item.id, value.position);
        }
        setState(() {});
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(item.title),
      ),
      body: FutureBuilder<void>(
        future: _initialize,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final controller = _controller!;
          final value = controller.value;
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio == 0
                        ? 16 / 9
                        : value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton.filled(
                          onPressed: () {
                            value.isPlaying
                                ? controller.pause()
                                : controller.play();
                          },
                          icon: Icon(
                            value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_format(value.position)} / ${_format(value.duration)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const Spacer(),
                        DropdownButton<double>(
                          value: _speed,
                          dropdownColor: Colors.black,
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: .5, child: Text('0.5x')),
                            DropdownMenuItem(value: 1, child: Text('1x')),
                            DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                            DropdownMenuItem(value: 2, child: Text('2x')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _speed = value);
                            controller.setPlaybackSpeed(value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) return '${duration.inHours}:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
