import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../models/password_entry.dart';
import '../providers/password_vault_provider.dart';

class BreachCheckPage extends ConsumerWidget {
  const BreachCheckPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(passwordVaultProvider);
    final reused = _reusedEntries(vault.entries);
    final weak = vault.entries
        .where((entry) => !entry.isArchived && entry.isWeak)
        .toList();
    final missingUrls = vault.entries
        .where((entry) => !entry.isArchived && entry.website.trim().isEmpty)
        .toList();

    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('vault_audit'),
        subtitle: context.l10n.tr('vault_audit_description'),
        onBack: () => context.goNamed(AppRoutes.passwordsName),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              sliver: SliverList.list(
                children: [
                  _AuditTile(
                    title: context.l10n.tr('weak_passwords'),
                    value: weak.length,
                    icon: Icons.warning_rounded,
                    color: AppColors.orange,
                    entries: weak,
                  ),
                  _AuditTile(
                    title: context.l10n.tr('reused_passwords'),
                    value: reused.length,
                    icon: Icons.copy_all_rounded,
                    color: AppColors.danger,
                    entries: reused,
                  ),
                  _AuditTile(
                    title: context.l10n.tr('missing_website_url'),
                    value: missingUrls.length,
                    icon: Icons.link_off_rounded,
                    color: AppColors.purple,
                    entries: missingUrls,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      context.l10n.tr('local_audit_notice'),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.blue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PasswordEntry> _reusedEntries(List<PasswordEntry> entries) {
    final counts = <String, int>{};
    for (final entry in entries.where((entry) => !entry.isArchived)) {
      counts.update(entry.password, (value) => value + 1, ifAbsent: () => 1);
    }
    return entries
        .where(
          (entry) => !entry.isArchived && (counts[entry.password] ?? 0) > 1,
        )
        .toList();
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.entries,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final List<PasswordEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: AppTextStyles.label)),
              Text(
                '$value',
                style: AppTextStyles.heading.copyWith(fontSize: 24),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final entry in entries.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${entry.title} - ${entry.username}',
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
