import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'filtered_media_page.dart';

class VideoFoldersPage extends ConsumerWidget {
  const VideoFoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(mediaLibraryProvider.notifier);
    final folders = controller.mediaFolders();

    return MediaPageShell(
      title: 'Media Folders',
      subtitle: 'Device folders with photos and videos together',
      icon: Icons.folder_rounded,
      children: [
        for (final folder in folders) ...[
          Builder(
            builder: (context) {
              return ListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FilteredMediaPage(
                        title: folder.name,
                        subtitle:
                            '${folder.photoCount} photos, ${folder.videoCount} videos',
                        icon: Icons.folder_open_rounded,
                        folderName: folder.name,
                      ),
                    ),
                  );
                },
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: const Icon(Icons.folder_rounded),
                title: Text(folder.name),
                subtitle: Text(
                  '${folder.totalCount} items - ${folder.photoCount} photos, ${folder.videoCount} videos',
                ),
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
