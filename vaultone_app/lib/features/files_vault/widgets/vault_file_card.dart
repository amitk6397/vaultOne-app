import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../file_localizations.dart';
import '../models/vault_file.dart';

class VaultFileCard extends StatelessWidget {
  const VaultFileCard({
    super.key,
    required this.file,
    required this.isGrid,
    required this.onTap,
    required this.onDelete,
    required this.onFavorite,
    required this.onArchive,
    required this.onTogglePrivate,
  });

  final VaultFile file;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;
  final VoidCallback onTogglePrivate;

  @override
  Widget build(BuildContext context) {
    final content = isGrid ? _gridContent(context) : _listContent(context);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: .18)
                  : AppColors.shadow.withValues(alpha: .6),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _gridContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FileIcon(file: file),
            const Spacer(),
            IconButton(
              onPressed: onFavorite,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              icon: Icon(
                file.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
              ),
              color: AppColors.orange,
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(Icons.more_vert_rounded, size: 20),
              ),
              onSelected: (value) {
                if (value == 'private') onTogglePrivate();
                if (value == 'archive') onArchive();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'private',
                  child: Text(
                    context.l10n.tr(
                      file.isPrivate ? 'move_to_public' : 'make_private',
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(context.l10n.tr('archive')),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(context.l10n.tr('delete')),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        Text(
          file.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          '${localizedVaultFileType(context, file.type)} • ${localizedVaultFileSize(context, file)}',
          style: AppTextStyles.body.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 8),
        _StatusRow(file: file),
      ],
    );
  }

  Widget _listContent(BuildContext context) {
    return Row(
      children: [
        _FileIcon(file: file),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                '${localizedVaultFileType(context, file.type)} • ${localizedVaultFileSize(context, file)}',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onFavorite,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          icon: Icon(
            file.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
          ),
          color: AppColors.orange,
        ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          child: const SizedBox(
            width: 34,
            height: 34,
            child: Icon(Icons.more_vert_rounded, size: 20),
          ),
          onSelected: (value) {
            if (value == 'private') onTogglePrivate();
            if (value == 'archive') onArchive();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'private',
              child: Text(
                context.l10n.tr(
                  file.isPrivate ? 'move_to_public' : 'make_private',
                ),
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              child: Text(context.l10n.tr('archive')),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(context.l10n.tr('delete')),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.file});

  final VaultFile file;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _Badge(
          label: context.l10n.tr(file.isPrivate ? 'private' : 'encrypted'),
          color: file.isEncrypted ? AppColors.success : AppColors.orange,
        ),
        if (file.tags.isNotEmpty)
          _Badge(label: file.tags.first, color: file.color),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  const _FileIcon({required this.file});

  final VaultFile file;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: file.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(file.icon, color: file.color, size: 26),
    );
  }
}
