import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton.filled(
                      onPressed: () => context.goNamed(AppRoutes.passwordsName),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Vault Audit', style: AppTextStyles.heading),
                          const SizedBox(height: 4),
                          Text(
                            'Local security checks for weak and reused passwords.',
                            style: AppTextStyles.body.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              sliver: SliverList.list(
                children: [
                  _AuditTile(
                    title: 'Weak passwords',
                    value: weak.length,
                    icon: Icons.warning_rounded,
                    color: AppColors.orange,
                    entries: weak,
                  ),
                  _AuditTile(
                    title: 'Reused passwords',
                    value: reused.length,
                    icon: Icons.copy_all_rounded,
                    color: AppColors.danger,
                    entries: reused,
                  ),
                  _AuditTile(
                    title: 'Missing website URL',
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
                      'Online breach lookup is intentionally not called here. This screen audits local vault data only.',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
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
