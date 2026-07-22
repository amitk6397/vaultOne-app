import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../core/storage/module_storage_controller.dart';
import '../../../shared/widgets/module_storage_sheet.dart';
import '../../../shared/widgets/local_auth_gate.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'media_actions.dart';
import 'media_folder_actions.dart';

class ProtectedPhotoGalleryPage extends ConsumerWidget {
  const ProtectedPhotoGalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LocalAuthGate(
      section: VaultSecuritySection.photos,
      title: context.l10n.tr('private_photos'),
      reason: context.l10n.tr('private_photos_auth_reason'),
      child: const PhotoGalleryPage(),
    );
  }
}

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
      () => ref.read(mediaLibraryProvider.notifier).loadPrivatePhotos(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaLibraryProvider);
    final controller = ref.read(mediaLibraryProvider.notifier);
    final photos = controller.visibleItems(
      kind: MediaKind.photo,
      visibility: MediaVisibility.private,
    );

    return MediaPageShell.slivers(
      title: context.l10n.tr('private_photos'),
      subtitle: context.l10n.tr(
        'photo_count',
        args: {'count': controller.privatePhotoCount},
      ),
      icon: Icons.lock_rounded,
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
                moveOrCopySelectedMedia(context, ref, MediaKind.photo),
            icon: Badge(
              label: Text('${state.selectedIds.length}'),
              child: const Icon(Icons.drive_file_move_rounded),
            ),
          ),
        ] else
          IconButton(
            tooltip: 'Create new folder',
            onPressed: () => createMediaFolder(context, ref, MediaKind.photo),
            icon: const Icon(Icons.create_new_folder_rounded),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (value) async {
            if (value == 'storage') {
              await chooseModuleStorage(
                context,
                ref,
                StorageModule.photos,
                force: true,
              );
            } else {
              context.pushNamed(AppRoutes.mediaSecurityName);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'storage', child: Text('Change storage')),
            PopupMenuItem(value: 'security', child: Text('Security')),
          ],
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: PrivateMediaVaultOverview(
            kind: MediaKind.photo,
            count: controller.privatePhotoCount,
            onAdd: () => importMedia(context, ref, MediaKind.photo),
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
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        if (photos.isEmpty)
          SliverToBoxAdapter(
            child: PrivateMediaEmptyState(
              kind: MediaKind.photo,
              onAdd: () => importMedia(context, ref, MediaKind.photo),
            ),
          )
        else
          MediaLibrarySliverView(
            items: photos,
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

  Future<void> _deleteSelected(
    BuildContext context,
    MediaLibraryController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete selected photos?'),
        content: const Text('Selected photos will be removed from VaultOne.'),
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
    if (confirmed == true) controller.deleteSelected(MediaKind.photo);
  }
}

class _PhotoVaultOverview extends StatelessWidget {
  const _PhotoVaultOverview({
    required this.count,
    required this.limit,
    required this.onAddPhoto,
  });

  final int count;
  final int limit;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = limit == 0 ? 0.0 : (count / limit).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primary.withValues(alpha: .12),
            AppColors.purple.withValues(alpha: .06),
            colors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: .14)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: .25),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.enhanced_encryption_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tr('private_photos'),
                      style: AppTextStyles.label.copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.tr('secure_percent'),
                      style: AppTextStyles.body.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                '$count / $limit',
                style: AppTextStyles.label.copyWith(color: colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: colors.primary.withValues(alpha: .1),
            ),
          ),
          const SizedBox(height: 16),
          DottedBorderBox(
            color: colors.primary.withValues(alpha: .55),
            borderRadius: 18,
            child: Material(
              color: colors.primary.withValues(alpha: .045),
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: onAddPhoto,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: .12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_rounded,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.tr('add_photo'),
                              style: AppTextStyles.label,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.tr('import'),
                              style: AppTextStyles.body.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: colors.primary),
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
