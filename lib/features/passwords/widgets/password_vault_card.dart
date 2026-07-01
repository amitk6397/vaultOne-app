import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';

class PasswordVaultCard extends StatelessWidget {
  const PasswordVaultCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.username,
    required this.category,
    required this.color,
    required this.onEdit,
    required this.onCopy,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final String username;
  final String category;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.lock_rounded, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  username,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    _Chip(text: category, color: color),
                    _Chip(text: subtitle, color: AppColors.success),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'copy') onCopy();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'copy', child: Text('Copy password')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
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
