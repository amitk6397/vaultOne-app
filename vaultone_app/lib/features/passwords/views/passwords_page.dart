import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../providers/password_vault_provider.dart';
import '../password_localizations.dart';
import '../widgets/password_vault_card.dart';

class PasswordsPage extends ConsumerWidget {
  const PasswordsPage({super.key});

  static const _categories = [
    'All',
    'Social',
    'Banking',
    'Work',
    'Shopping',
    'Email',
    'Entertainment',
    'Other',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final vault = ref.watch(passwordVaultProvider);
    final controller = ref.read(passwordVaultProvider.notifier);
    final search = ref.watch(passwordSearchProvider);
    final category = ref.watch(selectedPasswordCategoryProvider);
    final entries = controller.filteredEntries(
      query: search,
      category: category,
    );

    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('password_store'),
        subtitle: context.l10n.tr('password_store_subtitle'),
        onBack: () => context.canPop()
            ? context.pop()
            : context.goNamed(AppRoutes.homeName),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.passwords),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(AppRoutes.addEditPasswordName),
        tooltip: context.l10n.tr('add_login'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _VaultHero(state: vault),
                    const SizedBox(height: 16),
                    _SearchBox(
                      value: search,
                      onChanged: (value) {
                        ref.read(passwordSearchProvider.notifier).state = value;
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final item = _categories[index];
                          final selected = item == category;
                          return _CategoryChip(
                            label: localizedPasswordCategoryName(context, item),
                            selected: selected,
                            onTap: () {
                              ref
                                      .read(
                                        selectedPasswordCategoryProvider
                                            .notifier,
                                      )
                                      .state =
                                  item;
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    _ToolGrid(
                      onGenerator: () =>
                          context.pushNamed(AppRoutes.passwordGeneratorName),
                      onNotes: () =>
                          context.pushNamed(AppRoutes.secureNotesName),
                      onBreachCheck: () =>
                          context.pushNamed(AppRoutes.breachCheckName),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          context.l10n.tr('saved_passwords'),
                          style: AppTextStyles.heading.copyWith(fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          context.l10n.tr(
                            'items_count',
                            args: {'count': entries.length},
                          ),
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12.5,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (vault.isLoading)
              const SliverFillRemaining(child: AppLoadingView())
            else if (entries.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                sliver: SliverToBoxAdapter(child: _EmptyVault()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                sliver: SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return PasswordVaultCard(
                      entry: entry,
                      onEdit: () => context.pushNamed(
                        AppRoutes.addEditPasswordName,
                        queryParameters: {'id': entry.id},
                      ),
                      onCopy: () {
                        Clipboard.setData(ClipboardData(text: entry.password));
                        AppFeedback.showSnackBar(
                          context,
                          message: context.l10n.tr('password_copied_clipboard'),
                        );
                      },
                      onFavorite: () => controller.toggleFavorite(entry.id),
                      onArchive: () => controller.toggleArchive(entry.id),
                      onDelete: () => _confirmDelete(
                        context,
                        () => controller.deleteEntry(entry.id),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Future<void> Function() delete,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.tr('delete_password_question')),
        content: Text(context.l10n.tr('delete_password_description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await delete();
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr('password_deleted'),
    );
  }
}

class _VaultHero extends StatelessWidget {
  const _VaultHero({required this.state});

  final PasswordVaultState state;

  @override
  Widget build(BuildContext context) {
    final total = state.totalPasswords;
    final atRisk = state.weakPasswords + state.reusedPasswords;
    // Simple score: fewer weak/reused relative to total = healthier vault.
    final score = total == 0
        ? 1.0
        : (1 - (atRisk / (total * 2))).clamp(0.0, 1.0);
    final scoreColor = score >= 0.8
        ? AppColors.success
        : score >= 0.5
        ? AppColors.orange
        : Colors.redAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.tr('security_score'),
                style: AppTextStyles.body.copyWith(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              Text(
                '${(score * 100).round()}%',
                style: AppTextStyles.label.copyWith(
                  color: scoreColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: .12),
              valueColor: AlwaysStoppedAnimation(scoreColor),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroMetric(
                label: context.l10n.tr('logins'),
                value: '${state.totalPasswords}',
              ),
              _HeroMetric(
                label: context.l10n.tr('weak'),
                value: '${state.weakPasswords}',
              ),
              _HeroMetric(
                label: context.l10n.tr('reused'),
                value: '${state.reusedPasswords}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.heading.copyWith(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: .6),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      onChanged: onChanged,
      style: AppTextStyles.body.copyWith(fontSize: 14),
      decoration: InputDecoration(
        hintText: context.l10n.tr('search_passwords_hint'),
        hintStyle: AppTextStyles.body.copyWith(
          fontSize: 13.5,
          color: colors.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: colors.onSurfaceVariant,
        ),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(
            fontSize: 12.5,
            color: selected ? colors.onPrimary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid({
    required this.onGenerator,
    required this.onNotes,
    required this.onBreachCheck,
  });

  final VoidCallback onGenerator;
  final VoidCallback onNotes;
  final VoidCallback onBreachCheck;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        _ToolCard(
          title: context.l10n.tr('generator'),
          icon: Icons.password_rounded,
          color: AppColors.blue,
          onTap: onGenerator,
        ),
        _ToolCard(
          title: context.l10n.tr('secure_notes'),
          icon: Icons.note_alt_rounded,
          color: AppColors.purple,
          onTap: onNotes,
        ),
        _ToolCard(
          title: context.l10n.tr('audit'),
          icon: Icons.health_and_safety_rounded,
          color: AppColors.success,
          onTap: onBreachCheck,
        ),
        _ToolCard(
          title: context.l10n.tr('local_vault'),
          icon: Icons.storage_rounded,
          color: AppColors.orange,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.label.copyWith(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              size: 26,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 14),
          Text(context.l10n.tr('no_passwords'), style: AppTextStyles.heading),
          const SizedBox(height: 6),
          Text(
            context.l10n.tr('no_passwords_hint'),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
