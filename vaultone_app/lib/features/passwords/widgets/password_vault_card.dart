import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../models/password_entry.dart';
import '../password_localizations.dart';

class PasswordVaultCard extends StatelessWidget {
  const PasswordVaultCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onCopy,
    required this.onFavorite,
    required this.onArchive,
    required this.onDelete,
    this.selected = false,
    this.selectionMode = false,
    this.onSelect,
  });

  final PasswordEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final bool selected;
  final bool selectionMode;
  final VoidCallback? onSelect;

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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onLongPress: onSelect,
      onTap: selectionMode ? onSelect : null,
      child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.purple : colors.outlineVariant,
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: .18)
                : AppColors.shadow,
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
                    _Chip(
                      text: localizedPasswordCategory(context, entry.category),
                      color: _accent,
                    ),
                    _Chip(
                      text: localizedPasswordStrength(
                        context,
                        entry.strengthScore,
                      ),
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
          if (selected)
            const Icon(Icons.check_circle_rounded, color: AppColors.purple)
          else
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'favorite') onFavorite();
              if (value == 'archive') onArchive();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Text(context.l10n.tr('edit')),
              ),
              PopupMenuItem(
                value: 'favorite',
                child: Text(
                  context.l10n.tr(
                    entry.isFavorite ? 'remove_favorite' : 'add_favorite',
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
