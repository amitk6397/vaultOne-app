import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'filtered_media_page.dart';

class VideoFoldersPage extends ConsumerWidget {
  const VideoFoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(mediaLibraryProvider.notifier);
    final folders = controller.videoFolders();

    return MediaPageShell(
      title: 'Video Folders',
      subtitle: 'Folder management for public and private videos',
      icon: Icons.folder_rounded,
      children: [
        for (final folder in folders) ...[
          Builder(
            builder: (context) {
              final count = controller
                  .visibleItems(kind: MediaKind.video, folderName: folder)
                  .length;
              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FilteredMediaPage(
                        title: folder,
                        subtitle: 'Videos inside $folder',
                        icon: Icons.folder_open_rounded,
                        kind: MediaKind.video,
                        folderName: folder,
                      ),
                    ),
                  );
                },
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: const Icon(Icons.folder_rounded),
                title: Text(folder),
                subtitle: Text('$count videos'),
                trailing: const Icon(Icons.chevron_right_rounded),
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
