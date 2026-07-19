import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../media_localizations.dart';
import '../widgets/media_widgets.dart';
import 'media_actions.dart';

class VideoFolderVideosPage extends ConsumerStatefulWidget {
  const VideoFolderVideosPage({
    super.key,
    required this.folderId,
    required this.folderName,
  });

  final String folderId;
  final String folderName;

  @override
  ConsumerState<VideoFolderVideosPage> createState() =>
      _VideoFolderVideosPageState();
}

class _VideoFolderVideosPageState extends ConsumerState<VideoFolderVideosPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(mediaLibraryProvider.notifier)
          .loadVideoFolder(widget.folderId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaLibraryProvider);
    final videos =
        state.items
            .where(
              (item) =>
                  item.kind == MediaKind.video &&
                  item.albumId == widget.folderId,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return MediaPageShell.slivers(
      title: localizedMediaCollectionName(context, widget.folderName),
      subtitle: context.l10n.tr('video_count', args: {'count': videos.length}),
      icon: Icons.folder_open_rounded,
      slivers: [
        if (state.isLoading)
          const SliverToBoxAdapter(child: _VideoLoadingSkeleton())
        else if (videos.isEmpty)
          SliverToBoxAdapter(
            child: MediaEmptyState(
              title: context.l10n.tr('no_videos_found'),
              subtitle: context.l10n.tr('video_folders_description'),
            ),
          )
        else
          SliverList.separated(
            itemCount: videos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final video = videos[index];
              return _VideoListTile(
                video: video,
                onTap: () {
                  ref
                      .read(mediaLibraryProvider.notifier)
                      .markVideoFolderSeen(widget.folderId);
                  openMedia(context, video);
                },
                onMore: () => showMediaActions(context, ref, video),
              );
            },
          ),
      ],
    );
  }
}

// ── Video List Tile ──────────────────────────────────────────────────────────

class _VideoListTile extends StatelessWidget {
  const _VideoListTile({
    required this.video,
    required this.onTap,
    required this.onMore,
  });

  final MediaItem video;
  final VoidCallback onTap;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .65),
            ),
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 54,
                  child: MediaThumbnail(item: video),
                ),
              ),
              const SizedBox(width: 13),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(fontSize: 13.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: .1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            video.durationLabel,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 11,
                              color: AppColors.purple,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          video.sizeLabel,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Play button
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              // More button
              IconButton(
                onPressed: onMore,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading Skeleton ─────────────────────────────────────────────────────────

class _VideoLoadingSkeleton extends StatelessWidget {
  const _VideoLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(
        5,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}
