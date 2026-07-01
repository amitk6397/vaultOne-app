import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';

class DeletedMediaPage extends ConsumerWidget {
  const DeletedMediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(mediaLibraryProvider.notifier);
    final deleted = controller.visibleItems(includeDeleted: true);

    return MediaPageShell(
      title: 'Deleted Media',
      subtitle: 'Restore photos and videos before permanent deletion',
      icon: Icons.restore_from_trash_rounded,
      children: [
        if (deleted.isEmpty)
          const MediaEmptyState(
            title: 'Trash is empty',
            subtitle: 'Deleted photos and videos will appear here.',
          )
        else
          for (final item in deleted) ...[
            ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              leading: SizedBox(
                width: 58,
                height: 58,
                child: MediaThumbnail(item: item),
              ),
              title: Text(item.title),
              subtitle: Text('${item.kind.name} • ${item.sizeLabel}'),
              trailing: Wrap(
                spacing: 6,
                children: [
                  TextButton(
                    onPressed: () async {
                      await controller.permanentlyDeleteItem(item.id);
                    },
                    child: const Text('Delete'),
                  ),
                  FilledButton(
                    onPressed: () => controller.restoreItem(item.id),
                    child: const Text('Restore'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}
