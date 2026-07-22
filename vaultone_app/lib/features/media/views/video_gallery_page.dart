import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../shared/widgets/local_auth_gate.dart';
import '../../../shared/widgets/module_storage_sheet.dart';
import '../../../core/storage/module_storage_controller.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'media_actions.dart';
import 'media_folder_actions.dart';

class ProtectedVideoGalleryPage extends ConsumerWidget {
  const ProtectedVideoGalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LocalAuthGate(
      section: VaultSecuritySection.videos,
      title: context.l10n.tr('private_videos'),
      reason: context.l10n.tr('private_videos_auth_reason'),
      child: const VideoGalleryPage(),
    );
  }
}

class VideoGalleryPage extends ConsumerStatefulWidget {
  const VideoGalleryPage({super.key});
  @override
  ConsumerState<VideoGalleryPage> createState() => _VideoGalleryPageState();
}

class _VideoGalleryPageState extends ConsumerState<VideoGalleryPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final controller = ref.read(mediaLibraryProvider.notifier);
      await controller.loadVideoStorage();
      await controller.loadPrivateVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaLibraryProvider);
    final controller = ref.read(mediaLibraryProvider.notifier);
    final videos = controller.visibleItems(
      kind: MediaKind.video,
      visibility: MediaVisibility.private,
    );
    return MediaPageShell.slivers(
      title: context.l10n.tr('private_videos'),
      subtitle: context.l10n.tr(
        'private_videos_count',
        args: {'count': videos.length},
      ),
      icon: Icons.video_library_rounded,
      compactHeader: true,
      actions: [
        if (state.selectedIds.isNotEmpty) ...[
          IconButton(
            tooltip: 'Delete selected',
            onPressed: () => _deleteSelected(context, controller),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
          IconButton(
            tooltip: 'Move or copy',
            onPressed: () =>
                moveOrCopySelectedMedia(context, ref, MediaKind.video),
            icon: Badge(
              label: Text('${state.selectedIds.length}'),
              child: const Icon(Icons.drive_file_move_rounded),
            ),
          ),
        ] else
          IconButton(
            tooltip: 'Create new folder',
            onPressed: () => createMediaFolder(context, ref, MediaKind.video),
            icon: const Icon(Icons.create_new_folder_rounded),
          ),
        PopupMenuButton<_VideoMenuAction>(
          tooltip: context.l10n.tr('video_options'),
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (action) {
            switch (action) {
              case _VideoMenuAction.storage:
                _chooseStorage(change: true);
                break;
              case _VideoMenuAction.subscription:
                context.pushNamed(AppRoutes.subscriptionsName);
                break;
              case _VideoMenuAction.security:
                context.pushNamed(AppRoutes.mediaSecurityName);
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _VideoMenuAction.storage,
              child: Text(context.l10n.tr('change_storage')),
            ),
            PopupMenuItem(
              value: _VideoMenuAction.subscription,
              child: Text(context.l10n.tr('buy_storage')),
            ),
            PopupMenuItem(
              value: _VideoMenuAction.security,
              child: Text(context.l10n.tr('security')),
            ),
          ],
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: PrivateMediaVaultOverview(
            kind: MediaKind.video,
            count: videos.length,
            isBusy: state.isUploadingVideo,
            onAdd: _upload,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
        SliverToBoxAdapter(
          child: MediaSearchAndFilters(
            query: state.query,
            sort: state.sort,
            isGrid: state.viewMode == MediaViewMode.grid,
            onQueryChanged: controller.setQuery,
            onSortChanged: controller.setSort,
            onToggleView: controller.toggleView,
            searchOnly: true,
          ),
        ),
        if (state.isUploadingVideo)
          const SliverToBoxAdapter(child: LinearProgressIndicator()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (videos.isEmpty)
          SliverToBoxAdapter(
            child: PrivateMediaEmptyState(
              kind: MediaKind.video,
              onAdd: _upload,
            ),
          )
        else
          MediaLibrarySliverView(
            items: videos,
            viewMode: state.viewMode,
            selectedIds: state.selectedIds,
            onTap: (item) => state.selectedIds.isEmpty
                ? openMedia(context, item)
                : controller.toggleSelection(item.id),
            onLongPress: (item) => controller.toggleSelection(item.id),
            onFavorite: (item) => controller.toggleFavorite(item.id),
            onMore: (item) => showMediaActions(context, ref, item),
          ),
      ],
    );
  }

  Future<void> _upload() async {
    var storage = ref.read(mediaLibraryProvider).videoStorage;
    storage ??= await _chooseStorage();
    if (storage == null || !mounted) return;
    final error = await ref
        .read(mediaLibraryProvider.notifier)
        .importVideos(storage);
    if (!mounted || error == '') return;
    AppFeedback.showSnackBar(
      context,
      message: error == null
          ? context.l10n.tr('video_added_private')
          : context.l10n.tr(error),
    );
  }

  Future<void> _deleteSelected(
    BuildContext context,
    MediaLibraryController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete selected videos?'),
        content: const Text('Selected videos will be removed from VaultOne.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.deleteSelected(MediaKind.video);
  }

  Future<VideoStorage?> _chooseStorage({bool change = false}) async {
    final selected = await chooseModuleStorage(
      context,
      ref,
      StorageModule.videos,
      force: change,
    );
    final choice = selected == null
        ? null
        : selected == ModuleStorageTarget.database
        ? VideoStorage.database
        : VideoStorage.local;
    if (choice != null) {
      await ref.read(mediaLibraryProvider.notifier).setVideoStorage(choice);
    }
    return choice;
  }
}

enum _VideoMenuAction { storage, subscription, security }

class _VideoVaultOverview extends StatelessWidget {
  const _VideoVaultOverview({
    required this.count,
    required this.storage,
    required this.isUploading,
    required this.onUpload,
  });

  final int count;
  final VideoStorage? storage;
  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final storageLabel = storage == VideoStorage.database
        ? context.l10n.tr('vault_database')
        : context.l10n.tr('on_this_device');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.purple.withValues(alpha: .10),
            colors.primary.withValues(alpha: .04),
            colors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.purple.withValues(alpha: .12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: .22),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.video_collection_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tr('private_videos'),
                      style: AppTextStyles.label.copyWith(fontSize: 15.5),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          storage == VideoStorage.database
                              ? Icons.cloud_done_rounded
                              : Icons.phone_android_rounded,
                          size: 12,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            storageLabel,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 11.5,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Count badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: .18),
                  ),
                ),
                child: Text(
                  context.l10n.tr('video_count', args: {'count': count}),
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.purple,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Upload dotted area
          DottedBorderBox(
            color: AppColors.purple.withValues(alpha: .5),
            borderRadius: 16,
            child: Material(
              color: AppColors.purple.withValues(alpha: .04),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: isUploading ? null : onUpload,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: .1),
                          shape: BoxShape.circle,
                        ),
                        child: isUploading
                            ? const Padding(
                                padding: EdgeInsets.all(11),
                                child: AppLoadingIndicator(size: 26),
                              )
                            : const Icon(
                                Icons.video_call_rounded,
                                color: AppColors.purple,
                                size: 20,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.tr(
                                isUploading ? 'uploading' : 'add_video',
                              ),
                              style: AppTextStyles.label.copyWith(
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.tr('video_upload_size_limit'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.purple,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
