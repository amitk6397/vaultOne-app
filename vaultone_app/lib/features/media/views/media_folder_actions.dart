import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';

Future<void> createMediaFolder(
  BuildContext context,
  WidgetRef ref,
  MediaKind kind,
) async {
  final name = await _askFolderName(context);
  if (name == null || name.trim().isEmpty || !context.mounted) return;
  ref
      .read(mediaLibraryProvider.notifier)
      .createAlbum(name.trim(), kind, isPrivate: true);
}

Future<void> moveOrCopySelectedMedia(
  BuildContext context,
  WidgetRef ref,
  MediaKind kind,
) async {
  final controller = ref.read(mediaLibraryProvider.notifier);
  final state = ref.read(mediaLibraryProvider);
  final albums = state.albums
      .where((album) => album.kind == kind && album.isPrivate)
      .toList();
  if (albums.isEmpty) {
    await createMediaFolder(context, ref, kind);
    if (!context.mounted) return;
  }
  final refreshed = ref
      .read(mediaLibraryProvider)
      .albums
      .where((album) => album.kind == kind && album.isPrivate)
      .toList();
  if (refreshed.isEmpty || !context.mounted) return;
  final choice = await showModalBottomSheet<(MediaAlbum, bool)>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Choose folder'),
            subtitle: Text('Move or copy selected items'),
          ),
          for (final album in refreshed)
            ListTile(
              leading: const Icon(Icons.folder_rounded),
              title: Text(album.name),
              trailing: Wrap(
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(sheetContext, (album, false)),
                    child: const Text('Move'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetContext, (album, true)),
                    child: const Text('Copy'),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
  if (choice == null) return;
  choice.$2
      ? controller.copySelectedToAlbum(choice.$1, kind)
      : controller.moveSelectedToAlbum(choice.$1, kind);
}

Future<String?> _askFolderName(BuildContext context) async {
  final textController = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Create new folder'),
      content: TextField(
        controller: textController,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(hintText: 'Folder name'),
        onSubmitted: (value) => Navigator.pop(dialogContext, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, textController.text),
          child: const Text('Create'),
        ),
      ],
    ),
  );
  textController.dispose();
  return result;
}
