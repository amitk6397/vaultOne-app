import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
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
      title: album?.name ?? context.l10n.tr('album_details'),
      subtitle: context.l10n.tr('album_details_description'),
      icon: Icons.photo_album_rounded,
      kind: album?.kind ?? MediaKind.photo,
      albumId: albumId,
    );
  }
}
