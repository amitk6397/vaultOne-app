import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'media_actions.dart';

class FilteredMediaPage extends ConsumerWidget {
  const FilteredMediaPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.kind,
    this.visibility,
    this.albumId,
    this.folderName,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final MediaKind? kind;
  final MediaVisibility? visibility;
  final String? albumId;
  final String? folderName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaLibraryProvider);
    final controller = ref.read(mediaLibraryProvider.notifier);
    final items = controller.visibleItems(
      kind: kind,
      visibility: visibility,
      albumId: albumId,
      folderName: folderName,
    );

    return MediaPageShell(
      title: title,
      subtitle: subtitle,
      icon: icon,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => kind == null
            ? controller.scanAllDeviceMedia(force: true)
            : importMedia(context, ref, kind!),
        icon: Icon(
          kind == MediaKind.photo
              ? Icons.add_photo_alternate_rounded
              : Icons.video_call_rounded,
        ),
        label: Text(kind == null ? 'Refresh' : 'Import'),
      ),
      children: [
        MediaSearchAndFilters(
          query: state.query,
          sort: state.sort,
          isGrid: state.viewMode == MediaViewMode.grid,
          onQueryChanged: controller.setQuery,
          onSortChanged: controller.setSort,
          onToggleView: controller.toggleView,
        ),
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
