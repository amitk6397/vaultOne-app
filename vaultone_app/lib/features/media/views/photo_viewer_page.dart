import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

import '../../../constants/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../constants/app_url.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';

class PhotoViewerPage extends ConsumerStatefulWidget {
  const PhotoViewerPage({super.key, required this.photoId});

  final String photoId;

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  final _controller = TransformationController();
  PageController? _pageController;
  TapDownDetails? _doubleTapDetails;
  int _currentIndex = 0;
  bool _chromeVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scheduleChromeHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pageController?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(mediaLibraryProvider);
    final library = ref.read(mediaLibraryProvider.notifier);
    final fallback = library.itemById(widget.photoId);
    final photos = library.visibleItems(
      kind: MediaKind.photo,
      folderName: fallback?.folderName,
    );
    final initialIndex = photos.indexWhere((item) => item.id == widget.photoId);
    final items = photos.isEmpty && fallback != null ? [fallback] : photos;

    if (_pageController == null && items.isNotEmpty) {
      _currentIndex = initialIndex < 0 ? 0 : initialIndex;
      _pageController = PageController(initialPage: _currentIndex);
    }

    if (items.isEmpty) {
      return Scaffold(
        body: Center(child: Text(context.l10n.tr('photo_not_found'))),
      );
    }

    final item = items[_currentIndex.clamp(0, items.length - 1)];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: items.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _controller.value = Matrix4.identity();
                });
                _scheduleChromeHide();
              },
              itemBuilder: (context, index) {
                final photo = items[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onDoubleTapDown: (details) => _doubleTapDetails = details,
                  onDoubleTap: _handleDoubleTap,
                  onTap: _toggleChrome,
                  child: InteractiveViewer(
                    transformationController:
                        index == _currentIndex ? _controller : null,
                    minScale: 1,
                    maxScale: 5,
                    child: Center(child: _PhotoContent(item: photo)),
                  ),
                );
              },
            ),
            _AnimatedChrome(
              visible: _chromeVisible,
              alignment: Alignment.topCenter,
              child: SafeArea(
                bottom: false,
                minimum: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: _GlassPanel(
                  child: Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _viewerDateLabel(context, item.createdAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _viewerTimeLabel(context, item.createdAt),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _GlassIconButton(
                        icon: Icons.more_vert_rounded,
                        tooltip: context.l10n.tr('details'),
                        onPressed: () => context.pushNamed(
                          AppRoutes.photoDetailsName,
                          pathParameters: {'photoId': item.id},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _AnimatedChrome(
              visible: _chromeVisible,
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _GlassPanel(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                  child: Row(
                    children: [
                      _ViewerAction(
                        icon: Icons.ios_share_rounded,
                        label: context.l10n.tr('share'),
                        onPressed: () => _share(item),
                      ),
                      _ViewerAction(
                        icon: Icons.tune_rounded,
                        label: context.l10n.tr('edit'),
                        onPressed: () => _edit(item),
                      ),
                      _ViewerAction(
                        icon: Icons.photo_album_outlined,
                        label: context.l10n.tr('add_to'),
                        onPressed: () => _addToAlbum(item),
                      ),
                      _ViewerAction(
                        icon: Icons.delete_outline_rounded,
                        label: context.l10n.tr('trash'),
                        destructive: true,
                        onPressed: () => _moveToTrash(item),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDoubleTap() {
    _scheduleChromeHide();
    if (_controller.value != Matrix4.identity()) {
      _controller.value = Matrix4.identity();
      return;
    }
    final position = _doubleTapDetails?.localPosition ?? Offset.zero;
    _controller.value = Matrix4.identity()
      ..setEntry(0, 0, 2.2)
      ..setEntry(1, 1, 2.2)
      ..setEntry(0, 3, -position.dx)
      ..setEntry(1, 3, -position.dy);
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    if (_chromeVisible) _scheduleChromeHide();
  }

  void _scheduleChromeHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _chromeVisible = false);
    });
  }

  Future<void> _share(MediaItem item) async {
    _hideTimer?.cancel();
    if (item.isPrivate) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.l10n.tr('share')),
          content: const Text(
            'This photo is private. Sharing creates a copy outside your vault.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.l10n.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.l10n.tr('share')),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) return;
    }

    final path = await ref
        .read(mediaLibraryProvider.notifier)
        .resolveFilePath(item.id);
    if (!mounted) return;
    if (path == null || path.isEmpty) {
      AppFeedback.showSnackBar(
        context,
        message: context.l10n.tr('original_file_missing'),
      );
      return;
    }
    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      final params = AppUrl.isNetworkResourceUrl(path)
          ? ShareParams(
              uri: Uri.parse(AppUrl.resolveResourceUrl(path)),
              sharePositionOrigin: origin,
            )
          : ShareParams(
              files: [XFile(path)],
              title: item.title,
              sharePositionOrigin: origin,
            );
      await SharePlus.instance.share(params);
    } catch (_) {
      if (!mounted) return;
      AppFeedback.showSnackBar(
        context,
        message: context.l10n.tr('share_placeholder'),
      );
    } finally {
      if (mounted) _scheduleChromeHide();
    }
  }

  Future<void> _edit(MediaItem item) async {
    _hideTimer?.cancel();
    final path = await ref
        .read(mediaLibraryProvider.notifier)
        .resolveFilePath(item.id);
    if (!mounted) return;
    if (path == null || path.isEmpty || AppUrl.isNetworkResourceUrl(path)) {
      AppFeedback.showSnackBar(
        context,
        message: context.l10n.tr('original_file_missing'),
      );
      return;
    }
    final result = await OpenFilex.open(path);
    if (!mounted) return;
    if (result.type != ResultType.done) {
      AppFeedback.showSnackBar(
        context,
        message: result.message,
      );
    }
    _scheduleChromeHide();
  }

  Future<void> _addToAlbum(MediaItem item) async {
    _hideTimer?.cancel();
    final state = ref.read(mediaLibraryProvider);
    final albums = state.albums
        .where((album) => album.kind == MediaKind.photo)
        .toList();
    final album = await showModalBottomSheet<MediaAlbum>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Text(
              context.l10n.tr('add_to'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (albums.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No albums yet',
                  textAlign: TextAlign.center,
                ),
              )
            else
              for (final candidate in albums)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: candidate.accent.withValues(alpha: .12),
                    child: Icon(
                      Icons.photo_album_rounded,
                      color: candidate.accent,
                    ),
                  ),
                  title: Text(candidate.name),
                  trailing: candidate.id == item.albumId
                      ? const Icon(Icons.check_rounded)
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(sheetContext, candidate),
                ),
          ],
        ),
      ),
    );
    if (album == null || !mounted) {
      if (mounted) _scheduleChromeHide();
      return;
    }
    ref.read(mediaLibraryProvider.notifier).moveToAlbum(item.id, album);
    AppFeedback.showSnackBar(
      context,
      message: 'Added to ${album.name}',
    );
    _scheduleChromeHide();
  }

  Future<void> _moveToTrash(MediaItem item) async {
    _hideTimer?.cancel();
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.tr('trash')),
        content: const Text('Move this photo to Deleted Media?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.tr('trash')),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) {
      if (mounted) _scheduleChromeHide();
      return;
    }
    ref.read(mediaLibraryProvider.notifier).deleteItem(item.id);
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr('photo_moved_deleted'),
    );
    if (context.canPop()) context.pop();
  }

  String _viewerDateLabel(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatShortMonthDay(date);

  String _viewerTimeLabel(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(
        context,
      ).formatTimeOfDay(TimeOfDay.fromDateTime(date));
}

class _AnimatedChrome extends StatelessWidget {
  const _AnimatedChrome({
    required this.visible,
    required this.alignment,
    required this.child,
  });

  final bool visible;
  final Alignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final fromTop = alignment == Alignment.topCenter;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: visible
              ? Offset.zero
              : Offset(0, fromTop ? -.35 : .35),
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: Align(alignment: alignment, child: child),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF111827).withValues(alpha: .52),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: .18)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: .10),
      ),
      icon: Icon(icon),
    );
  }
}

class _ViewerAction extends StatelessWidget {
  const _ViewerAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFFF8C98) : Colors.white;
    return Expanded(
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoContent extends ConsumerWidget {
  const _PhotoContent({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: ref.read(mediaLibraryProvider.notifier).resolveFilePath(item.id),
      builder: (context, snapshot) {
        final path = snapshot.data;
        if (path != null && path.isNotEmpty) {
          if (AppUrl.isNetworkResourceUrl(path)) {
            return Image.network(
              AppUrl.resolveResourceUrl(path),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => MediaThumbnail(item: item),
            );
          }
          return Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => MediaThumbnail(item: item),
          );
        }
        return MediaThumbnail(item: item);
      },
    );
  }
}
