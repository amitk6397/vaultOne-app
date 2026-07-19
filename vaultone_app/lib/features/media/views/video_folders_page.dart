import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'filtered_media_page.dart';

class VideoFoldersPage extends ConsumerWidget {
  const VideoFoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(mediaLibraryProvider);
    final controller = ref.read(mediaLibraryProvider.notifier);
    final folders = controller.mediaFolders(kind: MediaKind.video);

    return MediaPageShell(
      title: context.l10n.tr('video_folders'),
      subtitle: context.l10n.tr('video_folders_description'),
      icon: Icons.folder_rounded,
      children: [
        if (folders.isEmpty)
          MediaEmptyState(
            title: context.l10n.tr('no_videos_found'),
            subtitle: context.l10n.tr('video_folders_description'),
          )
        else
          for (final folder in folders) ...[
            VideoFolderTile(
              folder: folder,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FilteredMediaPage(
                    title: folder.name,
                    subtitle: context.l10n.tr(
                      'video_count',
                      args: {'count': folder.videoCount},
                    ),
                    icon: Icons.folder_open_rounded,
                    kind: MediaKind.video,
                    folderName: folder.name,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}
