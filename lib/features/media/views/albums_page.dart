import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'media_actions.dart';

class AlbumsPage extends ConsumerWidget {
  const AlbumsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaLibraryProvider);
    final controller = ref.read(mediaLibraryProvider.notifier);
    final albums = state.albums
        .where((album) => album.kind == MediaKind.photo)
        .toList();

    return MediaPageShell(
      title: 'Albums',
      subtitle: 'Create, rename, delete and organize photo albums',
      icon: Icons.photo_album_rounded,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAlbumNameDialog(
          context: context,
          title: 'Create Album',
          initialValue: '',
          onSubmit: (name) => controller.createAlbum(name, MediaKind.photo),
        ),
        icon: const Icon(Icons.create_new_folder_rounded),
        label: const Text('Album'),
      ),
      children: [
        for (final album in albums) ...[
          AlbumCard(
            album: album,
            count: state.items
                .where((item) => item.albumId == album.id && !item.isDeleted)
                .length,
            onTap: () => context.pushNamed(
              AppRoutes.albumDetailsName,
              pathParameters: {'albumId': album.id},
            ),
            onRename: () => showAlbumNameDialog(
              context: context,
              title: 'Rename Album',
              initialValue: album.name,
              onSubmit: (name) => controller.renameAlbum(album.id, name),
            ),
            onDelete: () => controller.deleteAlbum(album.id),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
