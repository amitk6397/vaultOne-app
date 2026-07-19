import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../models/media_item.dart';
import '../media_localizations.dart';
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
      return Scaffold(
        body: Center(child: Text(context.l10n.tr('media_not_found'))),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final isPhoto = item.kind == MediaKind.photo;

    return MediaPageShell(
      title: context.l10n.tr(isPhoto ? 'photo_details' : 'video_details'),
      subtitle: item.title,
      icon: isPhoto ? Icons.image_rounded : Icons.movie_rounded,
      children: [
        // ── Thumbnail ──────────────────────────────────────────────────────
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: MediaThumbnail(item: item),
          ),
        ),
        const SizedBox(height: 18),

        // ── Info Card ──────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: .6),
            ),
          ),
          child: Column(
            children: [
              _DetailRow(
                icon: Icons.title_rounded,
                label: context.l10n.tr('name'),
                value: item.title,
                isFirst: true,
              ),
              _DetailRow(
                icon: Icons.photo_album_rounded,
                label: context.l10n.tr('album'),
                value: localizedMediaCollectionName(context, item.albumName),
              ),
              _DetailRow(
                icon: Icons.folder_rounded,
                label: context.l10n.tr('folder'),
                value: localizedMediaCollectionName(context, item.folderName),
              ),
              _DetailRow(
                icon: Icons.visibility_rounded,
                label: context.l10n.tr('visibility'),
                value: context.l10n.tr(
                  item.isPrivate ? 'private_vault' : 'public',
                ),
                valueColor: item.isPrivate
                    ? AppColors.purple
                    : AppColors.success,
              ),
              _DetailRow(
                icon: Icons.calendar_today_rounded,
                label: context.l10n.tr('date'),
                value: MaterialLocalizations.of(
                  context,
                ).formatShortDate(item.createdAt),
              ),
              _DetailRow(
                icon: Icons.data_usage_rounded,
                label: context.l10n.tr('size'),
                value: item.sizeLabel,
              ),
              if (item.duration != null)
                _DetailRow(
                  icon: Icons.timer_rounded,
                  label: context.l10n.tr('duration'),
                  value: item.durationLabel,
                ),
              _DetailRow(
                icon: Icons.lock_rounded,
                label: context.l10n.tr('encryption'),
                value: context.l10n.tr(
                  item.isPrivate ? 'aes_enabled' : 'private_media_available',
                ),
                valueColor: item.isPrivate ? AppColors.success : null,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Action Button ──────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => showMediaActions(context, ref, item),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.tune_rounded),
            label: Text(context.l10n.tr('manage_media')),
          ),
        ),
      ],
    );
  }
}

// ── Detail Row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: colors.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    fontSize: 13,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 62,
            color: colors.outlineVariant.withValues(alpha: .5),
          ),
      ],
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
