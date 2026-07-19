import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../../constants/app_url.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../models/media_item.dart';
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
  String? _controllerPath;
  late String _videoId;
  double _volume = 1;
  double _brightness = .5;
  double _playbackSpeed = 1;
  int _loopMode = 0; // 0=none, 1=loop one, 2=loop all, 3=shuffle
  bool _audioOnly = false;
  bool _locked = false;
  String? _gestureLabel;
  bool _landscape = false;
  bool _controlsVisible = true;
  bool _playlistVisible = false;
  Timer? _hideTimer;
  int _lastSavedSecond = -1;
  String? _resumePromptedFor;

  @override
  void initState() {
    super.initState();
    _videoId = widget.videoId;
    _loadBrightness();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    ScreenBrightness().resetScreenBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(mediaLibraryProvider);
    final library = ref.read(mediaLibraryProvider.notifier);
    final playlist = library.visibleItems(kind: MediaKind.video);
    final fallback = library.itemById(_videoId);
    final items = playlist.isEmpty && fallback != null ? [fallback] : playlist;
    final item = items.where((item) => item.id == _videoId).firstOrNull;

    if (item == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.tr('video_not_found'))),
      );
    }

    if (_initialize == null ||
        (_controllerPath != null &&
            item.path != null &&
            item.path != _controllerPath)) {
      _initialize = _prepareController(item);
    }

    final currentIndex = items.indexWhere((video) => video.id == item.id);

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initialize,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoadingView(color: Colors.white);
          }
          if (snapshot.hasError || _controller == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.tr('video_open_failed'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }

          final controller = _controller!;
          final value = controller.value;

          if (_landscape && _playlistVisible) {
            // Landscape with playlist sidebar (matching reference screenshots)
            return _buildLandscapeWithPlaylist(
              context,
              controller,
              value,
              item,
              items,
              currentIndex,
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _locked ? null : _toggleControls,
            onVerticalDragUpdate: _locked
                ? null
                : (details) => _handleVerticalGesture(details, context),
            onVerticalDragEnd: _locked ? null : (_) => _clearGestureLabel(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildVideoView(controller, value),
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: _buildPortraitControls(
                      context,
                      controller,
                      value,
                      item,
                      items,
                      currentIndex,
                    ),
                  ),
                ),
                // Lock button always visible when locked
                if (_locked)
                  Positioned(
                    left: 16,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _locked = false;
                        _controlsVisible = true;
                      }),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                if (_gestureLabel != null)
                  Center(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .68),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          child: Text(
                            _gestureLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoView(
    VideoPlayerController controller,
    VideoPlayerValue value,
  ) {
    return Center(
      child: AspectRatio(
        aspectRatio: value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio,
        child: _audioOnly
            ? const ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Icon(
                    Icons.headphones_rounded,
                    color: Colors.white,
                    size: 72,
                  ),
                ),
              )
            : VideoPlayer(controller),
      ),
    );
  }

  // ── Landscape + Playlist layout ──────────────────────────────────────────
  Widget _buildLandscapeWithPlaylist(
    BuildContext context,
    VideoPlayerController controller,
    VideoPlayerValue value,
    MediaItem item,
    List<MediaItem> items,
    int currentIndex,
  ) {
    return Row(
      children: [
        // Left: video player
        Expanded(
          flex: 3,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _locked ? null : _toggleControls,
            onVerticalDragUpdate: _locked
                ? null
                : (d) => _handleVerticalGesture(d, context),
            onVerticalDragEnd: _locked ? null : (_) => _clearGestureLabel(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _buildVideoView(controller, value),
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: _buildPortraitControls(
                      context,
                      controller,
                      value,
                      item,
                      items,
                      currentIndex,
                    ),
                  ),
                ),
                if (_locked)
                  Positioned(
                    left: 16,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _locked = false;
                        _controlsVisible = true;
                      }),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .55),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                if (_gestureLabel != null)
                  Center(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .68),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          child: Text(
                            _gestureLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Right: Playlist panel
        Container(
          width: 280,
          color: const Color(0xFF1A1A1A),
          child: _PlaylistPanel(
            items: items,
            currentId: _videoId,
            onSelect: (video) {
              _playItem(video);
            },
            onClose: () => setState(() => _playlistVisible = false),
          ),
        ),
      ],
    );
  }

  // ── Portrait controls overlay ─────────────────────────────────────────────
  Widget _buildPortraitControls(
    BuildContext context,
    VideoPlayerController controller,
    VideoPlayerValue value,
    MediaItem item,
    List<MediaItem> items,
    int currentIndex,
  ) {
    return Stack(
      children: [
        // Gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .72),
                  Colors.transparent,
                  Colors.black.withValues(alpha: .82),
                ],
              ),
            ),
          ),
        ),
        // Top bar
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Fullscreen / exit fullscreen
                  IconButton(
                    tooltip: context.l10n.tr(
                      _landscape ? 'exit_fullscreen' : 'fullscreen',
                    ),
                    onPressed: _toggleOrientation,
                    icon: Icon(
                      _landscape
                          ? Icons.fullscreen_exit_rounded
                          : Icons.fullscreen_rounded,
                      color: Colors.white,
                    ),
                  ),
                  // Playlist button
                  IconButton(
                    tooltip: context.l10n.tr('playlist'),
                    onPressed: _landscape
                        ? () => setState(
                            () => _playlistVisible = !_playlistVisible,
                          )
                        : _showPlaylist,
                    icon: const Icon(
                      Icons.queue_music_rounded,
                      color: Colors.white,
                    ),
                  ),
                  // More menu
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                    ),
                    color: const Color(0xFF1E1E1E),
                    onSelected: (v) => _handlePlayerMenu(v, item),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              context.l10n.tr('playback_settings'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'audio',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.headphones_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.l10n.tr(
                                _audioOnly ? 'show_video' : 'audio_only',
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'info',
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Text(
                              context.l10n.tr('video_info'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'lock',
                        child: Row(
                          children: [
                            Icon(
                              _locked
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.l10n.tr(
                                _locked ? 'unlock_controls' : 'lock_controls',
                              ),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Center play controls
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundControl(
                icon: Icons.replay_10_rounded,
                onPressed: () => _seekRelative(const Duration(seconds: -10)),
              ),
              const SizedBox(width: 20),
              _RoundControl(
                icon: value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 72,
                iconSize: 44,
                onPressed: () {
                  value.isPlaying ? controller.pause() : controller.play();
                  _scheduleControlsHide();
                },
              ),
              const SizedBox(width: 20),
              _RoundControl(
                icon: Icons.forward_10_rounded,
                onPressed: () => _seekRelative(const Duration(seconds: 10)),
              ),
            ],
          ),
        ),
        // Bottom controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress indicator
                  VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        tooltip: context.l10n.tr('previous'),
                        onPressed: currentIndex > 0
                            ? () => _playItem(items[currentIndex - 1])
                            : null,
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: currentIndex > 0
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                      IconButton.filled(
                        tooltip: context.l10n.tr(
                          value.isPlaying ? 'pause' : 'play',
                        ),
                        onPressed: () {
                          value.isPlaying
                              ? controller.pause()
                              : controller.play();
                          _scheduleControlsHide();
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .15),
                        ),
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.tr('next'),
                        onPressed:
                            currentIndex >= 0 && currentIndex < items.length - 1
                            ? () => _playItem(items[currentIndex + 1])
                            : null,
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: currentIndex < items.length - 1
                              ? Colors.white
                              : Colors.white38,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${_format(value.position)} / ${_format(value.duration)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      // Loop mode icon
                      IconButton(
                        tooltip: context.l10n.tr('loop_mode'),
                        onPressed: () => setState(() {
                          _loopMode = (_loopMode + 1) % 4;
                          _controller?.setLooping(_loopMode == 1);
                        }),
                        icon: Icon(
                          _loopModeIcon(_loopMode),
                          color: _loopMode > 0
                              ? const Color(0xFFFF4F4F)
                              : Colors.white54,
                          size: 20,
                        ),
                      ),
                      // Volume icon
                      IconButton(
                        tooltip: context.l10n.tr('volume'),
                        onPressed: () {
                          final newVol = _volume > 0 ? 0.0 : 1.0;
                          setState(() => _volume = newVol);
                          controller.setVolume(newVol);
                        },
                        icon: Icon(
                          _volume == 0
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  // Volume slider
                  Row(
                    children: [
                      const Icon(
                        Icons.volume_down_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 1,
                          activeColor: Colors.white,
                          inactiveColor: Colors.white24,
                          onChanged: (v) {
                            setState(() => _volume = v);
                            controller.setVolume(v);
                            _scheduleControlsHide();
                          },
                        ),
                      ),
                      const Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _loopModeIcon(int mode) {
    return switch (mode) {
      1 => Icons.repeat_one_rounded,
      2 => Icons.repeat_rounded,
      3 => Icons.shuffle_rounded,
      _ => Icons.repeat_rounded,
    };
  }

  Future<void> _prepareController(MediaItem item) async {
    final path = await ref
        .read(mediaLibraryProvider.notifier)
        .resolveFilePath(item.id);
    if (path == null || path.isEmpty) {
      throw StateError('Video file path not available');
    }

    unawaited(
      ref.read(mediaLibraryProvider.notifier).markVideoFolderSeen(item.albumId),
    );
    _controller?.removeListener(_onVideoTick);
    await _controller?.dispose();
    _controllerPath = path;
    _lastSavedSecond = -1;
    _controller = AppUrl.isNetworkResourceUrl(path)
        ? VideoPlayerController.networkUrl(
            Uri.parse(AppUrl.resolveResourceUrl(path)),
          )
        : VideoPlayerController.file(File(path));
    await _controller!.initialize();
    await _controller!.setVolume(_volume);
    final saved = await _savedPlaybackPosition(item);
    final shouldPromptResume =
        saved != null &&
        saved.inSeconds >= 5 &&
        saved < _controller!.value.duration - const Duration(seconds: 5) &&
        _resumePromptedFor != item.id;
    if (shouldPromptResume) {
      _resumePromptedFor = item.id;
      await _controller!.pause();
      final resume = await _showResumePrompt(item, saved);
      if (!mounted) return;
      if (resume) {
        await _controller!.seekTo(saved);
      } else {
        await _controller!.seekTo(Duration.zero);
        ref
            .read(mediaLibraryProvider.notifier)
            .savePlaybackPosition(item.id, Duration.zero);
        await _persistPlaybackPosition(item.id, Duration.zero);
      }
    }
    _controller!
      ..setLooping(_loopMode == 1)
      ..addListener(_onVideoTick)
      ..play();
    _scheduleControlsHide();
    if (mounted) setState(() {});
  }

  void _playItem(MediaItem item) {
    setState(() {
      _videoId = item.id;
      _controlsVisible = true;
      _controllerPath = null;
      _initialize = _prepareController(item);
    });
  }

  Future<void> _seekRelative(Duration offset) async {
    final controller = _controller;
    if (controller == null) return;
    final value = controller.value;
    final target = value.position + offset;
    final clamped = Duration(
      milliseconds: target.inMilliseconds.clamp(
        0,
        value.duration.inMilliseconds,
      ),
    );
    await controller.seekTo(clamped);
    _showControls();
  }

  Future<void> _toggleOrientation() async {
    final nextLandscape = !_landscape;
    setState(() {
      _landscape = nextLandscape;
      if (!nextLandscape) _playlistVisible = false;
    });
    if (nextLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  Future<void> _handleVerticalGesture(
    DragUpdateDetails details,
    BuildContext context,
  ) async {
    if (_locked) return;
    final width = MediaQuery.sizeOf(context).width;
    final sideIsRight = details.globalPosition.dx >= width / 2;
    final delta = (-details.delta.dy / 260).clamp(-.08, .08);
    if (sideIsRight) {
      final next = (_volume + delta).clamp(0.0, 1.0);
      setState(() {
        _volume = next;
        _gestureLabel = context.l10n.tr(
          'volume_percent',
          args: {'percent': '${(next * 100).round()}'},
        );
      });
      await _controller?.setVolume(next);
    } else {
      final next = (_brightness + delta).clamp(0.05, 1.0);
      setState(() {
        _brightness = next;
        _gestureLabel = context.l10n.tr(
          'brightness_percent',
          args: {'percent': '${(next * 100).round()}'},
        );
      });
      try {
        await ScreenBrightness().setScreenBrightness(next);
      } catch (_) {}
    }
    _showControls();
  }

  void _clearGestureLabel() {
    if (mounted) setState(() => _gestureLabel = null);
  }

  void _handlePlayerMenu(String value, MediaItem item) {
    switch (value) {
      case 'audio':
        setState(() => _audioOnly = !_audioOnly);
      case 'settings':
        _showPlaybackSettings();
      case 'lock':
        setState(() {
          _locked = !_locked;
          _controlsVisible = !_locked;
        });
      case 'info':
        _showInfo(item);
    }
  }

  Future<void> _loadBrightness() async {
    try {
      final value = await ScreenBrightness().current;
      if (mounted) setState(() => _brightness = value);
    } catch (_) {}
  }

  void _showPlaybackSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 10),
                child: Text(
                  context.l10n.tr('playback_settings'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Share / Audio only / Info
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _PlaybackAction(
                      icon: Icons.share_rounded,
                      label: context.l10n.tr('share'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.tr('share_video_ready')),
                          ),
                        );
                      },
                    ),
                    _PlaybackAction(
                      icon: Icons.headphones_rounded,
                      label: context.l10n.tr('audio_only'),
                      active: _audioOnly,
                      onTap: () {
                        setState(() => _audioOnly = !_audioOnly);
                        Navigator.pop(sheetContext);
                      },
                    ),
                    _PlaybackAction(
                      icon: Icons.info_outline_rounded,
                      label: context.l10n.tr('info'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _showInfo(
                          ref
                              .read(mediaLibraryProvider.notifier)
                              .itemById(_videoId)!,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Playback mode
              Padding(
                padding: EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Text(
                  context.l10n.tr('playback_mode'),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (final mode in [0, 2, 1, 3])
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() {});
                            setState(() {
                              _loopMode = mode;
                              _controller?.setLooping(mode == 1);
                            });
                          },
                          child: Icon(
                            _loopModeIcon(mode == 0 ? 0 : mode),
                            color: _loopMode == mode
                                ? const Color(0xFFFF4F4F)
                                : Colors.white54,
                            size: 28,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Speed
              Padding(
                padding: EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Text(
                  context.l10n.tr('speed'),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    for (final speed in [0.5, 1.0, 1.5, 2.0, 3.0])
                      Padding(
                        padding: const EdgeInsets.only(right: 22),
                        child: GestureDetector(
                          onTap: () {
                            setSheetState(() {});
                            setState(() => _playbackSpeed = speed);
                            _controller?.setPlaybackSpeed(speed);
                          },
                          child: Text(
                            '${speed}x',
                            style: TextStyle(
                              color: _playbackSpeed == speed
                                  ? const Color(0xFFFF4F4F)
                                  : Colors.white70,
                              fontSize: 15,
                              fontWeight: _playbackSpeed == speed
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPlaylist() {
    final videos = ref
        .read(mediaLibraryProvider.notifier)
        .visibleItems(kind: MediaKind.video);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 4, 18, 10),
              child: Row(
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    sheetContext.l10n.tr('playlist'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * .55,
              child: ListView.builder(
                itemCount: videos.length,
                itemBuilder: (_, index) {
                  final video = videos[index];
                  final isCurrent = video.id == _videoId;
                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor: Colors.white.withValues(alpha: .06),
                    leading: Container(
                      width: 72,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.bottomRight,
                      child: isCurrent
                          ? const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Color(0xFFFF4F4F),
                                size: 18,
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(4),
                              child: Text(
                                video.durationLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    title: Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent
                            ? const Color(0xFFFF4F4F)
                            : Colors.white,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      video.sizeLabel,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _playItem(video);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showResumePrompt(MediaItem item, Duration saved) async {
    final duration = _controller?.value.duration ?? item.duration;
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        title: Text(
          context.l10n.tr('resume_playing'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_format(saved)} / ${_format(duration ?? Duration.zero)}',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.tr('restart')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.tr('resume')),
          ),
        ],
      ),
    );
    return resume ?? false;
  }

  void _showInfo(MediaItem item) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          context.l10n.tr('video_info'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.tr(
                'video_duration',
                args: {'duration': _format(item.duration ?? Duration.zero)},
              ),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Text(
              context.l10n.tr('video_size', args: {'size': item.sizeLabel}),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.tr('close')),
          ),
        ],
      ),
    );
  }

  // Performance fix: only update position seconds, don't rebuild whole widget
  void _onVideoTick() {
    if (!mounted || _controller == null) return;
    final value = _controller!.value;
    if (!value.isInitialized) return;

    final second = value.position.inSeconds;
    if (second != _lastSavedSecond) {
      _lastSavedSecond = second;
      ref
          .read(mediaLibraryProvider.notifier)
          .savePlaybackPosition(_videoId, value.position);
      unawaited(_persistPlaybackPosition(_videoId, value.position));
    }
    // Only rebuild when we need to update visible state (position text, play/pause icon)
    if (mounted) setState(() {});
  }

  Future<Duration?> _savedPlaybackPosition(MediaItem item) async {
    if (item.lastPosition != null) return item.lastPosition;
    final prefs = await SharedPreferences.getInstance();
    final seconds = prefs.getInt(_playbackKey(item.id));
    if (seconds == null) return null;
    return Duration(seconds: seconds);
  }

  Future<void> _persistPlaybackPosition(String id, Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_playbackKey(id), position.inSeconds);
  }

  String _playbackKey(String id) => 'video_playback_position_$id';

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleControlsHide();
  }

  void _showControls() {
    if (mounted) setState(() => _controlsVisible = true);
    _scheduleControlsHide();
  }

  void _scheduleControlsHide() {
    _hideTimer?.cancel();
    final controller = _controller;
    if (controller == null || !controller.value.isPlaying) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  String _format(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) return '${duration.inHours}:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}

// ── Playlist panel widget (sidebar in landscape) ──────────────────────────────

class _PlaylistPanel extends StatelessWidget {
  const _PlaylistPanel({
    required this.items,
    required this.currentId,
    required this.onSelect,
    required this.onClose,
  });

  final List<MediaItem> items;
  final String currentId;
  final ValueChanged<MediaItem> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Playlist header
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
          child: Row(
            children: [
              Text(
                context.l10n.tr('playlist'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (_, index) {
              final video = items[index];
              final isCurrent = video.id == currentId;
              return GestureDetector(
                onTap: () => onSelect(video),
                child: Container(
                  color: isCurrent
                      ? Colors.white.withValues(alpha: .06)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Thumbnail with duration badge
                      Container(
                        width: 80,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: .65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.durationLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 12,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              video.sizeLabel,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Playback action button ────────────────────────────────────────────────────

class _PlaybackAction extends StatelessWidget {
  const _PlaybackAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: active
                  ? Colors.white.withValues(alpha: .12)
                  : Colors.white.withValues(alpha: .06),
              shape: BoxShape.circle,
              border: active ? Border.all(color: Colors.white24) : null,
            ),
            child: Icon(
              icon,
              color: active ? Colors.white : Colors.white70,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Round control button ──────────────────────────────────────────────────────

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.icon,
    required this.onPressed,
    this.size = 54,
    this.iconSize = 30,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: .42),
        foregroundColor: Colors.white,
        fixedSize: Size(size, size),
      ),
      icon: Icon(icon, size: iconSize),
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
