import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';

Future<void> importMedia(
  BuildContext context,
  WidgetRef ref,
  MediaKind kind,
) async {
  final controller = ref.read(mediaLibraryProvider.notifier);
  final count = kind == MediaKind.photo
      ? await controller.importPhotos()
      : await controller.importVideos();
  if (!context.mounted || count == 0) return;
  AppFeedback.showSnackBar(
    context,
    message: '$count ${kind == MediaKind.photo ? 'photo' : 'video'} imported',
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
              title: 'Details',
              onTap: () {
                Navigator.of(sheetContext).pop();
                openMediaDetails(context, item);
              },
            ),
            _ActionTile(
              icon: item.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              title: item.isFavorite ? 'Remove Favorite' : 'Favorite',
              onTap: () {
                controller.toggleFavorite(item.id);
                Navigator.of(sheetContext).pop();
              },
            ),
            _ActionTile(
              icon: item.isPrivate ? Icons.public_rounded : Icons.lock_rounded,
              title: item.isPrivate ? 'Move to Public' : 'Move to Private',
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
                      message ??
                      (item.isPrivate
                          ? 'Moved to public library'
                          : 'Added to private vault'),
                );
              },
            ),
            _ActionTile(
              icon: item.isHidden
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              title: item.isHidden ? 'Unhide' : 'Hide',
              onTap: () {
                controller.toggleHidden(item.id);
                Navigator.of(sheetContext).pop();
              },
            ),
            if (!item.isPrivate)
              _ActionTile(
                icon: Icons.ios_share_rounded,
                title:
                    'Share Public ${item.kind == MediaKind.photo ? 'Photo' : 'Video'}',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  AppFeedback.showSnackBar(
                    context,
                    message: 'Share sheet placeholder ready',
                  );
                },
              ),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              title: item.isDeleted ? 'Delete Permanently' : 'Delete',
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
                        ? 'Media permanently deleted'
                        : 'Could not delete from device',
                  );
                } else {
                  controller.deleteItem(item.id);
                  AppFeedback.showSnackBar(
                    context,
                    message: 'Moved to deleted media',
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
          decoration: const InputDecoration(labelText: 'Album name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) onSubmit(value);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
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
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.purple),
      title: Text(title, style: TextStyle(color: color ?? AppColors.navy)),
    );
  }
}
