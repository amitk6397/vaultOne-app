import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../models/media_item.dart';

class MediaPageShell extends StatelessWidget {
  const MediaPageShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.floatingActionButton,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final Widget? floatingActionButton;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton.filled(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.goNamed(AppRoutes.homeName),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.navy,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.heading.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
              sliver: SliverList.list(children: children),
            ),
          ],
        ),
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
  });

  final String query;
  final MediaSort sort;
  final bool isGrid;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<MediaSort> onSortChanged;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: onQueryChanged,
          controller: TextEditingController(text: query)
            ..selection = TextSelection.collapsed(offset: query.length),
          decoration: InputDecoration(
            hintText: 'Search photos, videos, albums',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<MediaSort>(
                initialValue: sort,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(
                    value: MediaSort.dateNewest,
                    child: Text('Newest first'),
                  ),
                  DropdownMenuItem(
                    value: MediaSort.dateOldest,
                    child: Text('Oldest first'),
                  ),
                  DropdownMenuItem(value: MediaSort.name, child: Text('Name')),
                  DropdownMenuItem(
                    value: MediaSort.sizeLargest,
                    child: Text('Size'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) onSortChanged(value);
                },
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: onToggleView,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.purple,
              ),
              icon: Icon(
                isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
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
      return const MediaEmptyState(
        title: 'No media found',
        subtitle: 'Import media or change your search and filters.',
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
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.blue : AppColors.fieldBorder,
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
                          : AppColors.textMuted,
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
    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.blue : AppColors.fieldBorder,
        ),
      ),
      leading: SizedBox(
        width: 58,
        height: 58,
        child: MediaThumbnail(item: item, selected: selected),
      ),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${item.albumName} • ${item.sizeLabel} • ${item.dateLabel}',
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
              color: item.isFavorite ? AppColors.danger : AppColors.textMuted,
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
          if (item.path != null && item.kind == MediaKind.photo)
            Image.file(
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.fieldBorder),
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
                    '$count items • ${album.isPrivate ? 'Private' : 'Public'}',
                    style: AppTextStyles.body.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) =>
                  value == 'rename' ? onRename() : onDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 14),
          Text(title, style: AppTextStyles.heading.copyWith(fontSize: 22)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class LoadingSkeletonGrid extends StatelessWidget {
  const LoadingSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white.withValues(alpha: .72),
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
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: AppColors.purple),
      title: Text(title, style: AppTextStyles.label),
      subtitle: Text(subtitle),
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                'Gesture controls • Subtitles ready • PiP ready',
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
