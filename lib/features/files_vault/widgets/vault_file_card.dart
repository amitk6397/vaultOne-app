import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
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
  });

  final VaultFile file;
  final bool isGrid;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final content = isGrid ? _gridContent() : _listContent();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.fieldBorder),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _gridContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FileIcon(file: file),
            const Spacer(),
            IconButton(
              onPressed: onFavorite,
              icon: Icon(
                file.isFavorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
              ),
              color: AppColors.orange,
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'archive') onArchive();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'archive', child: Text('Archive')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
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
          '${file.typeLabel} • ${file.sizeLabel}',
          style: AppTextStyles.body.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 8),
        _StatusRow(file: file),
      ],
    );
  }

  Widget _listContent() {
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
                '${file.typeLabel} • ${file.sizeLabel}',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onFavorite,
          icon: Icon(
            file.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
          ),
          color: AppColors.orange,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'archive') onArchive();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'archive', child: Text('Archive')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
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
          label: file.isEncrypted ? 'Encrypted' : 'Plain',
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
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: file.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(file.icon, color: file.color, size: 30),
    );
  }
}
