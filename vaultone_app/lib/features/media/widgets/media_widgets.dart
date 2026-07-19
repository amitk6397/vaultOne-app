import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/app_url.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../models/media_item.dart';
import '../media_localizations.dart';

class MediaPageShell extends StatelessWidget {
  const MediaPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.floatingActionButton,
    this.actions = const [],
    this.compactHeader = false,
  }) : slivers = null;

  const MediaPageShell.slivers({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.slivers,
    this.floatingActionButton,
    this.actions = const [],
    this.compactHeader = false,
  }) : children = const [];

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final List<Widget>? slivers;
  final Widget? floatingActionButton;
  final List<Widget> actions;
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? colors.surfaceContainerLowest
          : const Color(0xFFF7F6F2),
      floatingActionButton: floatingActionButton,
      body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: colors.surface,
              foregroundColor: colors.onSurface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 3,
              toolbarHeight: 72,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Slim back button
                    _MediaBackButton(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.goNamed(AppRoutes.homeName),
                    ),
                    const SizedBox(width: 12),
                    if (!compactHeader) ...[
                      Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 18),
                    ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 19,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (!compactHeader) Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 60),
              sliver: slivers == null
                  ? SliverList.list(children: children)
                  : SliverMainAxisGroup(slivers: slivers!),
            ),
          ],
      ),
    );
  }
}

class _MediaBackButton extends StatelessWidget {
  const _MediaBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(
        Icons.arrow_back_rounded,
        size: 22,
        color: colors.onSurface,
      ),
    );
  }
}

class MediaSearchAndFilters extends StatelessWidget {
  const MediaSearchAndFilters({
    super.key,
    required this.query,
    required this.sort,
    required this.isGrid,
    required this.onQueryChanged,
    required this.onSortChanged,
    required this.onToggleView,
    this.searchOnly = false,
  });

  final String query;
  final MediaSort sort;
  final bool isGrid;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<MediaSort> onSortChanged;
  final VoidCallback onToggleView;
  final bool searchOnly;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        TextField(
          onChanged: onQueryChanged,
          controller: TextEditingController(text: query)
            ..selection = TextSelection.collapsed(offset: query.length),
          decoration: InputDecoration(
            hintText: context.l10n.tr('search_media_hint'),
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (!searchOnly) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: PopupMenuButton<MediaSort>(
                initialValue: sort,
                onSelected: onSortChanged,
                itemBuilder: (context) => MediaSort.values
                    .map(
                      (value) => PopupMenuItem(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              value == sort
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 20,
                              color: value == sort
                                  ? colors.primary
                                  : colors.outline,
                            ),
                            const SizedBox(width: 10),
                            Text(_sortLabel(context, value)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, color: colors.primary),
                      const SizedBox(width: 10),
                      Text(
                        context.l10n.tr('filter'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: onToggleView,
              style: IconButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.primary,
              ),
              icon: Icon(
                isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
              ),
            ),
          ],
        ),
        ],
      ],
    );
  }

  String _sortLabel(BuildContext context, MediaSort value) => switch (value) {
    MediaSort.dateNewest => context.l10n.tr('newest_first'),
    MediaSort.dateOldest => context.l10n.tr('oldest_first'),
    MediaSort.name => context.l10n.tr('sort_name'),
    MediaSort.sizeLargest => context.l10n.tr('largest_size'),
  };
}

class MediaLibraryView extends StatelessWidget {
  const MediaLibraryView({
    super.key,
    required this.items,
    required this.viewMode,
    required this.selectedIds,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
    required this.onMore,
  });

  final List<MediaItem> items;
  final MediaViewMode viewMode;
  final Set<String> selectedIds;
  final ValueChanged<MediaItem> onTap;
  final ValueChanged<MediaItem> onLongPress;
  final ValueChanged<MediaItem> onFavorite;
  final ValueChanged<MediaItem> onMore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return MediaEmptyState(
        title: context.l10n.tr('no_media_found'),
        subtitle: context.l10n.tr('no_media_found_description'),
      );
    }

    if (viewMode == MediaViewMode.list) {
      return Column(
        children: [
          for (final item in items) ...[
            MediaListTile(
              item: item,
              selected: selectedIds.contains(item.id),
              onTap: () => onTap(item),
              onLongPress: () => onLongPress(item),
              onFavorite: () => onFavorite(item),
              onMore: () => onMore(item),
            ),
            const SizedBox(height: 10),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 620 ? 4 : 3;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .78,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return MediaGridTile(
              item: item,
              selected: selectedIds.contains(item.id),
              onTap: () => onTap(item),
              onLongPress: () => onLongPress(item),
              onFavorite: () => onFavorite(item),
              onMore: () => onMore(item),
            );
          },
        );
      },
    );
  }
}

class MediaLibrarySliverView extends StatelessWidget {
  const MediaLibrarySliverView({
    super.key,
    required this.items,
    required this.viewMode,
    required this.selectedIds,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
    required this.onMore,
  });

  final List<MediaItem> items;
  final MediaViewMode viewMode;
  final Set<String> selectedIds;
  final ValueChanged<MediaItem> onTap;
  final ValueChanged<MediaItem> onLongPress;
  final ValueChanged<MediaItem> onFavorite;
  final ValueChanged<MediaItem> onMore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: MediaEmptyState(
          title: context.l10n.tr('no_media_found'),
          subtitle: context.l10n.tr('no_media_found_description'),
        ),
      );
    }

    if (viewMode == MediaViewMode.list) {
      return SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return MediaListTile(
            item: item,
            selected: selectedIds.contains(item.id),
            onTap: () => onTap(item),
            onLongPress: () => onLongPress(item),
            onFavorite: () => onFavorite(item),
            onMore: () => onMore(item),
          );
        },
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.crossAxisExtent > 620 ? 4 : 3;
        return SliverGrid.builder(
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .78,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return MediaGridTile(
              item: item,
              selected: selectedIds.contains(item.id),
              onTap: () => onTap(item),
              onLongPress: () => onLongPress(item),
              onFavorite: () => onFavorite(item),
              onMore: () => onMore(item),
            );
          },
        );
      },
    );
  }
}

class MediaFolderGridSliver extends StatelessWidget {
  const MediaFolderGridSliver({
    super.key,
    required this.folders,
    required this.kind,
    required this.onTap,
  });

  final List<MediaFolderSummary> folders;
  final MediaKind kind;
  final ValueChanged<MediaFolderSummary> onTap;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return SliverToBoxAdapter(
        child: MediaEmptyState(
          title: context.l10n.tr('no_folders_found'),
          subtitle: context.l10n.tr('no_folders_description'),
        ),
      );
    }

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        if (kind == MediaKind.video) {
          return SliverList.separated(
            itemCount: folders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final folder = folders[index];
              return VideoFolderTile(
                folder: folder,
                onTap: () => onTap(folder),
              );
            },
          );
        }

        final columns = constraints.crossAxisExtent > 620 ? 4 : 2;
        return SliverGrid.builder(
          itemCount: folders.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: kind == MediaKind.photo ? .82 : 1.22,
          ),
          itemBuilder: (context, index) {
            final folder = folders[index];
            return PhotoFolderTile(folder: folder, onTap: () => onTap(folder));
          },
        );
      },
    );
  }
}

class PhotoFolderTile extends StatelessWidget {
  const PhotoFolderTile({super.key, required this.folder, required this.onTap});

  final MediaFolderSummary folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cover = folder.cover;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: cover == null
                  ? const _FolderFallback(icon: Icons.photo_library_rounded)
                  : MediaThumbnail(item: cover),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.tr(
                      'photo_count',
                      args: {'count': folder.photoCount},
                    ),
                    style: AppTextStyles.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoFolderTile extends StatelessWidget {
  const VideoFolderTile({super.key, required this.folder, required this.onTap});

  final MediaFolderSummary folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cover = folder.cover;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .7),
            ),
          ),
          child: Row(
            children: [
              // Thumbnail / fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: SizedBox(
                  width: 62,
                  height: 56,
                  child: cover == null
                      ? DecoratedBox(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.blue, AppColors.purple],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.video_collection_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        )
                      : MediaThumbnail(item: cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.play_circle_outline_rounded,
                          size: 13,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.tr(
                            folder.videoCount == 1
                                ? 'single_video_count'
                                : 'video_count',
                            args: {'count': folder.videoCount},
                          ),
                          style: AppTextStyles.body.copyWith(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GroupedMediaSliverView extends StatelessWidget {
  const GroupedMediaSliverView({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
    required this.onMore,
  });

  final List<MediaItem> items;
  final Set<String> selectedIds;
  final ValueChanged<MediaItem> onTap;
  final ValueChanged<MediaItem> onLongPress;
  final ValueChanged<MediaItem> onFavorite;
  final ValueChanged<MediaItem> onMore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: MediaEmptyState(
          title: context.l10n.tr('no_media_found'),
          subtitle: context.l10n.tr('no_media_found_description'),
        ),
      );
    }

    final groups = _groupByDay(items);
    return SliverList.separated(
      itemCount: groups.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayLabel(context, group.date),
              style: AppTextStyles.heading.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 620 ? 5 : 3;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, itemIndex) {
                    final item = group.items[itemIndex];
                    return InkWell(
                      onTap: () => onTap(item),
                      onLongPress: () => onLongPress(item),
                      child: MediaThumbnail(
                        item: item,
                        selected: selectedIds.contains(item.id),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<_DateMediaGroup> _groupByDay(List<MediaItem> source) {
    final grouped = <DateTime, List<MediaItem>>{};
    for (final item in source) {
      final day = DateTime(
        item.createdAt.year,
        item.createdAt.month,
        item.createdAt.day,
      );
      grouped.putIfAbsent(day, () => <MediaItem>[]).add(item);
    }
    final groups =
        grouped.entries
            .map((entry) => _DateMediaGroup(entry.key, entry.value))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return groups;
  }

  String _dayLabel(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatMediumDate(date);
}

class _DateMediaGroup {
  const _DateMediaGroup(this.date, this.items);

  final DateTime date;
  final List<MediaItem> items;
}

class _FolderFallback extends StatelessWidget {
  const _FolderFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: .1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Center(child: Icon(icon, color: AppColors.blue, size: 42)),
    );
  }
}

class MediaGridTile extends StatelessWidget {
  const MediaGridTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
    required this.onMore,
  });

  final MediaItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavorite;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MediaThumbnail(item: item, selected: selected),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(fontSize: 12),
                    ),
                  ),
                  InkWell(
                    onTap: onFavorite,
                    child: Icon(
                      item.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: item.isFavorite
                          ? AppColors.danger
                          : colors.onSurfaceVariant,
                      size: 18,
                    ),
                  ),
                  InkWell(
                    onTap: onMore,
                    child: const Icon(Icons.more_vert_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MediaListTile extends StatelessWidget {
  const MediaListTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
    required this.onMore,
  });

  final MediaItem item;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavorite;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      tileColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      leading: SizedBox(
        width: 58,
        height: 58,
        child: MediaThumbnail(item: item, selected: selected),
      ),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${localizedMediaCollectionName(context, item.albumName)} • ${item.sizeLabel} • ${MaterialLocalizations.of(context).formatShortDate(item.createdAt)}',
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            onPressed: onFavorite,
            icon: Icon(
              item.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: item.isFavorite
                  ? AppColors.danger
                  : colors.onSurfaceVariant,
            ),
          ),
          IconButton(
            onPressed: onMore,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }
}

class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({super.key, required this.item, this.selected = false});

  final MediaItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.accent.withValues(alpha: .9), AppColors.navy],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              item.kind == MediaKind.photo
                  ? Icons.image_rounded
                  : Icons.play_circle_fill_rounded,
              color: Colors.white.withValues(alpha: .88),
              size: 42,
            ),
          ),
          if (item.assetEntity != null)
            FutureBuilder(
              future: item.assetEntity!.thumbnailDataWithSize(
                const ThumbnailSize.square(360),
              ),
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null) return const SizedBox.shrink();
                return Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  gaplessPlayback: true,
                );
              },
            )
          else if (item.path != null && item.kind == MediaKind.photo)
            AppUrl.isNetworkResourceUrl(item.path)
                ? Image.network(
                    AppUrl.resolveResourceUrl(item.path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  )
                : Image.file(
                    File(item.path!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
          Positioned(
            left: 8,
            top: 8,
            child: Wrap(
              spacing: 4,
              children: [
                if (item.isPrivate) const _MediaBadge(icon: Icons.lock_rounded),
                if (item.isHidden)
                  const _MediaBadge(icon: Icons.visibility_off_rounded),
                if (selected) const _MediaBadge(icon: Icons.check_rounded),
              ],
            ),
          ),
          if (item.kind == MediaKind.video)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .56),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.durationLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    required this.count,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final MediaAlbum album;
  final int count;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: album.accent.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                album.kind == MediaKind.photo
                    ? Icons.photo_album_rounded
                    : Icons.video_library_rounded,
                color: album.accent,
                size: 34,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: AppTextStyles.label.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.tr(
                      'album_items_visibility',
                      args: {
                        'count': count,
                        'visibility': context.l10n.tr(
                          album.isPrivate ? 'private' : 'public',
                        ),
                      },
                    ),
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) =>
                  value == 'rename' ? onRename() : onDelete(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'rename',
                  child: Text(context.l10n.tr('rename')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(context.l10n.tr('delete')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PrivateMediaVaultOverview extends StatelessWidget {
  const PrivateMediaVaultOverview({
    super.key,
    required this.kind,
    required this.count,
    required this.onAdd,
    this.limit,
    this.isBusy = false,
  });

  final MediaKind kind;
  final int count;
  final int? limit;
  final VoidCallback onAdd;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final isPhoto = kind == MediaKind.photo;
    final progress = limit == null || limit == 0 ? 0.0 : (count / limit!).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF202C4A),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isPhoto ? 'SAVED IN VAULT' : 'VIDEOS UPLOADED',
              style: const TextStyle(color: Color(0xFF9CADCE), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(height: 5),
            Text.rich(TextSpan(
              text: '$count',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              children: limit == null ? const [] : [TextSpan(text: ' / $limit', style: const TextStyle(color: Color(0xFF9CADCE), fontSize: 12))],
            )),
          ])),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(10)),
            child: Icon(isPhoto ? Icons.lock_outline_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 20),
          ),
        ]),
        if (isPhoto) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: Colors.white24, color: Colors.white),
          ),
        ],
        const SizedBox(height: 14),
        DottedBorderBox(
          color: const Color(0xFF75819C),
          borderRadius: 13,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isBusy ? null : onAdd,
              borderRadius: BorderRadius.circular(13),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(9)),
                    child: isBusy ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isBusy ? 'Uploading…' : isPhoto ? 'Add photo' : 'Add video', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(isPhoto ? 'Import from device' : 'Files under 100 MB only', style: const TextStyle(color: Color(0xFFB6C2DD), fontSize: 9.5)),
                  ])),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFB6C2DD), size: 17),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class PrivateMediaEmptyState extends StatelessWidget {
  const PrivateMediaEmptyState({
    super.key,
    required this.kind,
    required this.onAdd,
  });

  final MediaKind kind;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPhoto = kind == MediaKind.photo;
    return DottedBorderBox(
      color: colors.outlineVariant,
      borderRadius: 18,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 240),
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 26),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF0EA),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPhoto ? Icons.image_outlined : Icons.play_arrow_rounded,
                size: 29,
                color: const Color(0xFF62806A),
              ),
            ),
            const SizedBox(height: 17),
            Text(
              isPhoto ? 'No photos yet' : 'No videos yet',
              style: AppTextStyles.label.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 7),
            Text(
              isPhoto
                  ? 'Your vault is private and encrypted on this device. Add a photo to get started.'
                  : 'Stored locally on this device only. Add a video under 100 MB to begin.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 11.5, height: 1.55),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF11131A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(isPhoto ? 'Add photo' : 'Add video'),
            ),
          ],
        ),
      ),
    );
  }
}

class MediaEmptyState extends StatelessWidget {
  const MediaEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DottedBorderBox(
      color: colors.outlineVariant,
      borderRadius: 20,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest.withValues(alpha: .5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.perm_media_outlined,
                size: 30,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppTextStyles.label.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    required this.color,
    this.borderRadius = 16,
  });

  final Widget child;
  final Color color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DottedBorderPainter(
        color: color,
        radius: borderRadius,
      ),
      child: child,
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  const _DottedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

class LoadingSkeletonGrid extends StatelessWidget {
  const LoadingSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: .82,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
}

class SecuritySwitchTile extends StatelessWidget {
  const SecuritySwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: AppColors.purple),
      title: Text(title, style: AppTextStyles.label),
      subtitle: Text(subtitle),
      tileColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
    );
  }
}

class VideoPlayerChrome extends StatelessWidget {
  const VideoPlayerChrome({
    super.key,
    required this.item,
    required this.playing,
    required this.speed,
    required this.position,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSpeedChanged,
  });

  final MediaItem item;
  final bool playing;
  final double speed;
  final double position;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
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
                context.l10n.tr('gesture_features'),
                style: TextStyle(color: Colors.white.withValues(alpha: .7)),
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.navy, item.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.movie_rounded,
                          color: Colors.white,
                          size: 86,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: onPlayPause,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .18),
                        foregroundColor: Colors.white,
                        fixedSize: const Size(72, 72),
                      ),
                      icon: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 44,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                children: [
                  Slider(value: position, onChanged: onSeek),
                  Row(
                    children: [
                      const Icon(Icons.volume_up_rounded, color: Colors.white),
                      const SizedBox(width: 18),
                      const Icon(
                        Icons.brightness_6_rounded,
                        color: Colors.white,
                      ),
                      const Spacer(),
                      DropdownButton<double>(
                        value: speed,
                        dropdownColor: AppColors.navy,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: .5, child: Text('0.5x')),
                          DropdownMenuItem(value: 1, child: Text('1x')),
                          DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                          DropdownMenuItem(value: 2, child: Text('2x')),
                        ],
                        onChanged: (value) {
                          if (value != null) onSpeedChanged(value);
                        },
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.screen_rotation_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.closed_caption_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.picture_in_picture_alt_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .48),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}
