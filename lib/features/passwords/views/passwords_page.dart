import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../providers/password_vault_provider.dart';
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
    final vault = ref.watch(passwordVaultProvider);
    final controller = ref.read(passwordVaultProvider.notifier);
    final search = ref.watch(passwordSearchProvider);
    final category = ref.watch(selectedPasswordCategoryProvider);
    final entries = controller.filteredEntries(
      query: search,
      category: category,
    );

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.passwords),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.addEditPasswordName),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Login'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      onBack: () => context.canPop()
                          ? context.pop()
                          : context.goNamed(AppRoutes.homeName),
                    ),
                    const SizedBox(height: 18),
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
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final item = _categories[index];
                          final selected = item == category;
                          return ChoiceChip(
                            label: Text(item),
                            selected: selected,
                            onSelected: (_) {
                              ref
                                      .read(
                                        selectedPasswordCategoryProvider
                                            .notifier,
                                      )
                                      .state =
                                  item;
                            },
                            selectedColor: AppColors.navy,
                            backgroundColor: Colors.white,
                            labelStyle: AppTextStyles.label.copyWith(
                              color: selected ? Colors.white : AppColors.navy,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ToolGrid(
                      onGenerator: () =>
                          context.pushNamed(AppRoutes.passwordGeneratorName),
                      onNotes: () =>
                          context.pushNamed(AppRoutes.secureNotesName),
                      onBreachCheck: () =>
                          context.pushNamed(AppRoutes.breachCheckName),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          'Saved Passwords',
                          style: AppTextStyles.heading.copyWith(fontSize: 22),
                        ),
                        const Spacer(),
                        Text(
                          '${entries.length} items',
                          style: AppTextStyles.body.copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            if (vault.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (entries.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                sliver: SliverToBoxAdapter(child: _EmptyVault()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                sliver: SliverList.builder(
                  itemCount: entries.length,
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
                          message: 'Password copied to clipboard',
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
        title: const Text('Delete password?'),
        content: const Text('This login will be removed from local storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await delete();
    if (!context.mounted) return;
    AppFeedback.showSnackBar(context, message: 'Password deleted');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filled(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.navy,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Password Vault', style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                'Local encrypted-ready Hive vault for logins and notes.',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VaultHero extends StatelessWidget {
  const _VaultHero({required this.state});

  final PasswordVaultState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'Security Overview',
                style: AppTextStyles.label.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroMetric(label: 'Logins', value: '${state.totalPasswords}'),
              _HeroMetric(label: 'Weak', value: '${state.weakPasswords}'),
              _HeroMetric(label: 'Reused', value: '${state.reusedPasswords}'),
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
              fontSize: 26,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 12,
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
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search site, username, URL, category',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
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
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _ToolCard(
          title: 'Generator',
          icon: Icons.password_rounded,
          color: AppColors.blue,
          onTap: onGenerator,
        ),
        _ToolCard(
          title: 'Secure Notes',
          icon: Icons.note_alt_rounded,
          color: AppColors.purple,
          onTap: onNotes,
        ),
        _ToolCard(
          title: 'Audit',
          icon: Icons.health_and_safety_rounded,
          color: AppColors.success,
          onTap: onBreachCheck,
        ),
        _ToolCard(
          title: 'Local Vault',
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: AppTextStyles.label)),
          ],
        ),
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_open_rounded, size: 54, color: AppColors.blue),
          const SizedBox(height: 12),
          Text('No passwords yet', style: AppTextStyles.heading),
          const SizedBox(height: 8),
          Text(
            'Add your first login to store it locally with Hive.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
