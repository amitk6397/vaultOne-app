import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../models/media_item.dart';
import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';
import 'media_actions.dart';

class MediaDetailsPage extends ConsumerWidget {
  const MediaDetailsPage({super.key, required this.mediaId});

  final String mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref
        .watch(mediaLibraryProvider)
        .items
        .where((item) => item.id == mediaId)
        .firstOrNull;
    if (item == null) {
      return const Scaffold(body: Center(child: Text('Media not found')));
    }

    return MediaPageShell(
      title: item.kind == MediaKind.photo ? 'Photo Details' : 'Video Details',
      subtitle: item.title,
      icon: item.kind == MediaKind.photo
          ? Icons.image_rounded
          : Icons.movie_rounded,
      children: [
        SizedBox(height: 260, child: MediaThumbnail(item: item)),
        const SizedBox(height: 18),
        _DetailRow('Name', item.title),
        _DetailRow('Album', item.albumName),
        _DetailRow('Folder', item.folderName),
        _DetailRow('Visibility', item.isPrivate ? 'Private vault' : 'Public'),
        _DetailRow('Date', item.dateLabel),
        _DetailRow('Size', item.sizeLabel),
        if (item.duration != null) _DetailRow('Duration', item.durationLabel),
        _DetailRow(
          'Encryption',
          item.isPrivate ? 'AES-256 enabled' : 'Available for private media',
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => showMediaActions(context, ref, item),
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Manage Media'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.label),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
