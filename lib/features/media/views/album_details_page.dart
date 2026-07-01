import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/media_item.dart';
import '../providers/media_provider.dart';
import 'filtered_media_page.dart';

class AlbumDetailsPage extends ConsumerWidget {
  const AlbumDetailsPage({super.key, required this.albumId});

  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final album = ref.read(mediaLibraryProvider.notifier).albumById(albumId);
    return FilteredMediaPage(
      title: album?.name ?? 'Album Details',
      subtitle: 'Album details with move, favorite, hide and delete actions',
      icon: Icons.photo_album_rounded,
      kind: album?.kind ?? MediaKind.photo,
      albumId: albumId,
    );
  }
}
