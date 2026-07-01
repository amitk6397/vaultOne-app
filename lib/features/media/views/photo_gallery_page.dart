import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'media_actions.dart';

class PhotoGalleryPage extends ConsumerStatefulWidget {
  const PhotoGalleryPage({super.key});

  @override
  ConsumerState<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends ConsumerState<PhotoGalleryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(mediaLibraryProvider.notifier)
          .scanDeviceMedia(MediaKind.photo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaLibraryProvider);
    final controller = ref.read(mediaLibraryProvider.notifier);
    final items = controller.visibleItems(kind: MediaKind.photo);
    final folders = controller.photoFolders();

    return MediaPageShell(
      title: 'Photos',
      subtitle:
          'Public gallery with folder view and private vault (${controller.privatePhotoCount}/${MediaLibraryController.privatePhotoLimit})',
      icon: Icons.photo_library_rounded,
      actions: [
        IconButton(
          onPressed: () => context.pushNamed(AppRoutes.albumsName),
          icon: const Icon(Icons.photo_album_rounded),
        ),
        IconButton(
          onPressed: () => context.pushNamed(AppRoutes.mediaSecurityName),
          icon: const Icon(Icons.security_rounded),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            controller.scanDeviceMedia(MediaKind.photo, force: true),
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Refresh'),
      ),
      children: [
        if (state.permissionDenied)
          const _PermissionCard()
        else if (state.isLoading)
          const LoadingSkeletonGrid(),
        if (state.permissionDenied || state.isLoading) const SizedBox(height: 16),
        MediaSearchAndFilters(
          query: state.query,
          sort: state.sort,
          isGrid: state.viewMode == MediaViewMode.grid,
          onQueryChanged: controller.setQuery,
          onSortChanged: controller.setSort,
          onToggleView: controller.toggleView,
        ),
        const SizedBox(height: 16),
        _PhotoShortcuts(),
        const SizedBox(height: 16),
        _FolderStrip(folders: folders),
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

class _PermissionCard extends StatelessWidget {
  const _PermissionCard();

  @override
  Widget build(BuildContext context) {
    return const MediaEmptyState(
      title: 'Photo permission required',
      subtitle: 'Allow gallery access to show mobile photos folder-wise.',
    );
  }
}

class _FolderStrip extends StatelessWidget {
  const _FolderStrip({required this.folders});

  final List<String> folders;

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
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: folders.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final folder = folders[index];
              return ActionChip(
                avatar: const Icon(Icons.folder_rounded),
                label: Text(folder),
                onPressed: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PhotoShortcuts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ShortcutChip(
          label: 'Public',
          icon: Icons.public_rounded,
          onTap: () => context.pushNamed(AppRoutes.publicPhotosName),
        ),
        _ShortcutChip(
          label: 'Private',
          icon: Icons.lock_rounded,
          onTap: () => context.pushNamed(AppRoutes.privatePhotosName),
        ),
        _ShortcutChip(
          label: 'Albums',
          icon: Icons.photo_album_rounded,
          onTap: () => context.pushNamed(AppRoutes.albumsName),
        ),
        _ShortcutChip(
          label: 'Deleted',
          icon: Icons.restore_from_trash_rounded,
          onTap: () => context.pushNamed(AppRoutes.deletedMediaName),
        ),
      ],
    );
  }
}

class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(avatar: Icon(icon), label: Text(label), onPressed: onTap);
  }
}
