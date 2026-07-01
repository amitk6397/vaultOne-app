import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../models/password_entry.dart';

class PasswordVaultCard extends StatelessWidget {
  const PasswordVaultCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onCopy,
    required this.onFavorite,
    required this.onArchive,
    required this.onDelete,
  });

  final PasswordEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  Color get _accent {
    return switch (entry.category) {
      PasswordCategory.banking => AppColors.success,
      PasswordCategory.work => AppColors.purple,
      PasswordCategory.shopping => AppColors.orange,
      PasswordCategory.email => AppColors.cyan,
      PasswordCategory.entertainment => AppColors.blue,
      PasswordCategory.social => AppColors.blue,
      PasswordCategory.other => AppColors.navy,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withValues(alpha: .62)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                entry.title.isEmpty ? '?' : entry.title[0].toUpperCase(),
                style: AppTextStyles.heading.copyWith(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(fontSize: 16),
                      ),
                    ),
                    if (entry.isFavorite)
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.orange,
                        size: 18,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  entry.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(text: entry.categoryLabel, color: _accent),
                    _Chip(
                      text: entry.strengthLabel,
                      color: entry.isWeak
                          ? AppColors.orange
                          : AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(onPressed: onCopy, icon: const Icon(Icons.copy_rounded)),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'favorite') onFavorite();
              if (value == 'archive') onArchive();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'favorite',
                child: Text(
                  entry.isFavorite ? 'Remove favorite' : 'Add favorite',
                ),
              ),
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}
