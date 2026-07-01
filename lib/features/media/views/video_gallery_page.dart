import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'filtered_media_page.dart';
import 'media_actions.dart';

class VideoGalleryPage extends ConsumerStatefulWidget {
  const VideoGalleryPage({super.key});

  @override
  ConsumerState<VideoGalleryPage> createState() => _VideoGalleryPageState();
}

class _VideoGalleryPageState extends ConsumerState<VideoGalleryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(mediaLibraryProvider.notifier).scanAllDeviceMedia(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaLibraryProvider);
    final controller = ref.read(mediaLibraryProvider.notifier);
    final items = controller.visibleItems(kind: MediaKind.video);
    final folders = controller.mediaFolders();
    final privateUsed = controller.privateVideoUsedMb.toStringAsFixed(0);

    return MediaPageShell(
      title: 'Videos',
      subtitle:
          'Folder video player with private vault: $privateUsed/${MediaLibraryController.privateVideoLimitMb.toStringAsFixed(0)} MB used',
      icon: Icons.video_library_rounded,
      actions: [
        IconButton(
          onPressed: () => context.pushNamed(AppRoutes.videoFoldersName),
          icon: const Icon(Icons.folder_rounded),
        ),
        IconButton(
          onPressed: () => context.pushNamed(AppRoutes.mediaSecurityName),
          icon: const Icon(Icons.security_rounded),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => controller.scanAllDeviceMedia(force: true),
        icon: const Icon(Icons.video_call_rounded),
        label: const Text('Refresh'),
      ),
      children: [
        if (state.permissionDenied)
          const MediaEmptyState(
            title: 'Video permission required',
            subtitle: 'Allow gallery access to show mobile videos folder-wise.',
          )
        else if (state.isLoading)
          const LoadingSkeletonGrid(),
        if (state.permissionDenied || state.isLoading)
          const SizedBox(height: 16),
        MediaSearchAndFilters(
          query: state.query,
          sort: state.sort,
          isGrid: state.viewMode == MediaViewMode.grid,
          onQueryChanged: controller.setQuery,
          onSortChanged: controller.setSort,
          onToggleView: controller.toggleView,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ActionChip(
              avatar: const Icon(Icons.public_rounded),
              label: const Text('Public'),
              onPressed: () => context.pushNamed(AppRoutes.publicVideosName),
            ),
            ActionChip(
              avatar: const Icon(Icons.lock_rounded),
              label: const Text('Private'),
              onPressed: () => context.pushNamed(AppRoutes.privateVideosName),
            ),
            ActionChip(
              avatar: const Icon(Icons.play_circle_rounded),
              label: const Text('Continue Watching'),
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        _VideoFolderStrip(folders: folders),
        const SizedBox(height: 16),
        MediaLibraryView(
          items: items,
          viewMode: state.viewMode,
          selectedIds: state.selectedIds,
          onTap: (item) => openMedia(context, item),
          onLongPress: (item) => controller.toggleSelection(item.id),
          onFavorite: (item) => controller.toggleFavorite(item.id),
          onMore: (item) => showMediaActions(context, ref, item),
        ),
      ],
    );
  }
}

class _VideoFolderStrip extends StatelessWidget {
  const _VideoFolderStrip({required this.folders});

  final List<MediaFolderSummary> folders;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Device folders',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final folder in folders)
              ActionChip(
                avatar: const Icon(Icons.folder_rounded),
                label: Text(
                  '${folder.name} (${folder.photoCount}P/${folder.videoCount}V)',
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FilteredMediaPage(
                        title: folder.name,
                        subtitle:
                            '${folder.photoCount} photos, ${folder.videoCount} videos',
                        icon: Icons.folder_open_rounded,
                        folderName: folder.name,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
