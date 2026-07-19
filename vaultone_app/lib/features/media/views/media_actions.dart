import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/module_storage_sheet.dart';
import '../../../core/storage/module_storage_controller.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';

Future<void> importMedia(
  BuildContext context,
  WidgetRef ref,
  MediaKind kind,
) async {
  final controller = ref.read(mediaLibraryProvider.notifier);
  final storage = kind == MediaKind.photo
      ? await chooseModuleStorage(context, ref, StorageModule.photos)
      : null;
  if (kind == MediaKind.photo && storage == null) return;
  final count = kind == MediaKind.photo
      ? await controller.importPhotos(
          visibility: MediaVisibility.private,
          storage: storage!,
        )
      : 0;
  if (!context.mounted || count == 0) return;
  AppFeedback.showSnackBar(
    context,
    message: context.l10n.tr(
      kind == MediaKind.photo ? 'photo_added_private' : 'video_imported',
      args: {'count': count},
    ),
  );
}

void openMedia(BuildContext context, MediaItem item) {
  if (item.kind == MediaKind.photo) {
    context.pushNamed(
      AppRoutes.photoViewerName,
      pathParameters: {'photoId': item.id},
    );
  } else {
    context.pushNamed(
      AppRoutes.videoPlayerName,
      pathParameters: {'videoId': item.id},
    );
  }
}

void openMediaDetails(BuildContext context, MediaItem item) {
  context.pushNamed(
    item.kind == MediaKind.photo
        ? AppRoutes.photoDetailsName
        : AppRoutes.videoDetailsName,
    pathParameters: {
      item.kind == MediaKind.photo ? 'photoId' : 'videoId': item.id,
    },
  );
}

void showMediaActions(BuildContext context, WidgetRef ref, MediaItem item) {
  final controller = ref.read(mediaLibraryProvider.notifier);
  final isPrivatePhoto =
      item.kind == MediaKind.photo &&
      item.visibility == MediaVisibility.private;
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.title,
              style: AppTextStyles.heading.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.info_outline_rounded,
              title: context.l10n.tr('details'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                openMediaDetails(context, item);
              },
            ),
            _ActionTile(
              icon: item.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              title: context.l10n.tr(
                item.isFavorite ? 'remove_favorite_title' : 'favorite',
              ),
              onTap: () {
                controller.toggleFavorite(item.id);
                Navigator.of(sheetContext).pop();
              },
            ),
            if (!isPrivatePhoto)
              _ActionTile(
                icon: item.isPrivate
                    ? Icons.public_rounded
                    : Icons.lock_rounded,
                title: context.l10n.tr(
                  item.isPrivate ? 'move_public' : 'move_private',
                ),
                onTap: () {
                  final message = controller.moveVisibility(
                    item.id,
                    item.isPrivate
                        ? MediaVisibility.public
                        : MediaVisibility.private,
                  );
                  Navigator.of(sheetContext).pop();
                  AppFeedback.showSnackBar(
                    context,
                    message:
                        (message == 'Media not found'
                            ? context.l10n.tr('media_not_found')
                            : null) ??
                        (item.isPrivate
                            ? context.l10n.tr('moved_public_library')
                            : context.l10n.tr('added_private_vault')),
                  );
                },
              ),
            if (!isPrivatePhoto)
              _ActionTile(
                icon: item.isHidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                title: context.l10n.tr(item.isHidden ? 'unhide' : 'hide'),
                onTap: () {
                  controller.toggleHidden(item.id);
                  Navigator.of(sheetContext).pop();
                },
              ),
            if (!item.isPrivate)
              _ActionTile(
                icon: Icons.ios_share_rounded,
                title: context.l10n.tr(
                  item.kind == MediaKind.photo
                      ? 'share_public_photo'
                      : 'share_public_video',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  AppFeedback.showSnackBar(
                    context,
                    message: context.l10n.tr('share_placeholder'),
                  );
                },
              ),
            if (isPrivatePhoto)
              _ActionTile(
                icon: Icons.remove_circle_outline_rounded,
                title: context.l10n.tr('remove_from_vault'),
                onTap: () {
                  controller.removeItem(item.id);
                  Navigator.of(sheetContext).pop();
                  AppFeedback.showSnackBar(
                    context,
                    message: context.l10n.tr('photo_removed_private'),
                  );
                },
              ),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              title: context.l10n.tr(
                item.isDeleted ? 'delete_permanently' : 'delete',
              ),
              color: AppColors.danger,
              onTap: () async {
                if (item.isDeleted) {
                  final deleted = await controller.permanentlyDeleteItem(
                    item.id,
                  );
                  if (!context.mounted) return;
                  AppFeedback.showSnackBar(
                    context,
                    message: deleted
                        ? context.l10n.tr('media_permanently_deleted')
                        : context.l10n.tr('media_delete_failed'),
                  );
                } else {
                  controller.deleteItem(item.id);
                  AppFeedback.showSnackBar(
                    context,
                    message: item.kind == MediaKind.photo
                        ? context.l10n.tr('photo_moved_deleted')
                        : context.l10n.tr('moved_deleted_media'),
                  );
                }
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showAlbumNameDialog({
  required BuildContext context,
  required String title,
  required String initialValue,
  required ValueChanged<String> onSubmit,
}) async {
  final controller = TextEditingController(text: initialValue);
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: context.l10n.tr('album_name')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) onSubmit(value);
              Navigator.of(context).pop();
            },
            child: Text(context.l10n.tr('save')),
          ),
        ],
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.purple),
      title: Text(title, style: TextStyle(color: color ?? colors.onSurface)),
    );
  }
}
