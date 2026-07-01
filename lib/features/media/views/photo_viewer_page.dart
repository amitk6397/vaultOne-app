import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'media_actions.dart';

class PhotoViewerPage extends ConsumerStatefulWidget {
  const PhotoViewerPage({super.key, required this.photoId});

  final String photoId;

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  final _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ref
        .watch(mediaLibraryProvider)
        .items
        .where((item) => item.id == widget.photoId)
        .firstOrNull;
    if (item == null) {
      return const Scaffold(body: Center(child: Text('Photo not found')));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
              title: Text(
                item.title,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Swipe-ready viewer • Double-tap zoom',
                style: TextStyle(color: Colors.white.withValues(alpha: .65)),
              ),
              trailing: IconButton(
                onPressed: () => context.pushNamed(
                  AppRoutes.photoDetailsName,
                  pathParameters: {'photoId': item.id},
                ),
                icon: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onDoubleTapDown: (details) => _doubleTapDetails = details,
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _controller,
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: MediaThumbnail(item: item),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () => ref
                        .read(mediaLibraryProvider.notifier)
                        .toggleFavorite(item.id),
                    icon: Icon(
                      item.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: item.isPrivate ? null : () {},
                    icon: const Icon(
                      Icons.ios_share_rounded,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => showMediaActions(context, ref, item),
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDoubleTap() {
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
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
