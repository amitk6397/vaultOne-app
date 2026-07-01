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

  static const _categories = ['All', 'Social', 'Banking', 'Work', 'Shopping'];
  static const _items = [
    _PasswordItem(
      'Google',
      'amit@gmail.com',
      'Social',
      'Strong',
      AppColors.blue,
    ),
    _PasswordItem(
      'HDFC Bank',
      'amit@bank',
      'Banking',
      'Strong',
      AppColors.success,
    ),
    _PasswordItem('GitHub', 'amit-dev', 'Work', 'Good', AppColors.purple),
    _PasswordItem('Amazon', 'amit.shop', 'Shopping', 'Fair', AppColors.orange),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(passwordSearchProvider).toLowerCase();
    final category = ref.watch(selectedPasswordCategoryProvider);
    final filteredItems = _items.where((item) {
      final matchesSearch =
          item.title.toLowerCase().contains(search) ||
          item.username.toLowerCase().contains(search);
      final matchesCategory = category == 'All' || item.category == category;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.passwords),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(AppRoutes.addEditPasswordName),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Password'),
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
                      title: 'Password Vault',
                      subtitle:
                          'Biometric-locked password manager with generator, categories, and secure notes.',
                      onBack: () => context.canPop()
                          ? context.pop()
                          : context.goNamed(AppRoutes.homeName),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      onChanged: (value) {
                        ref.read(passwordSearchProvider.notifier).state = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by site, username, or category',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
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
                            selectedColor: AppColors.blue,
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
                      onNotes: () => context.pushNamed(AppRoutes.secureNotesName),
                      onBreachCheck: () =>
                          context.pushNamed(AppRoutes.breachCheckName),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Saved Passwords',
                      style: AppTextStyles.heading.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
              sliver: SliverList.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return PasswordVaultCard(
                    title: item.title,
                    subtitle: item.strength,
                    username: item.username,
                    category: item.category,
                    color: item.color,
                    onEdit: () =>
                        context.pushNamed(AppRoutes.addEditPasswordName),
                    onCopy: () {
                      Clipboard.setData(
                        const ClipboardData(text: 'CopiedPassword'),
                      );
                      AppFeedback.showSnackBar(
                        context,
                        message:
                            'Password copied. Auto-clear after 30 seconds.',
                      );
                    },
                    onDelete: () {
                      AppFeedback.showAppDialog(
                        context,
                        title: 'Delete password?',
                        message:
                            'This is a UI placeholder. Storage delete logic can be connected later.',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(title, style: AppTextStyles.heading),
              const SizedBox(height: 6),
              Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 13)),
            ],
          ),
        ),
      ],
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
      childAspectRatio: 1.55,
      children: [
        _ToolCard(
          title: 'Password Generator',
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
          title: 'Biometric Lock',
          icon: Icons.fingerprint_rounded,
          color: AppColors.success,
          onTap: () {
            AppFeedback.showSnackBar(
              context,
              message: 'Biometric local_auth can be connected here.',
            );
          },
        ),
        _ToolCard(
          title: 'Breach Check',
          icon: Icons.security_rounded,
          color: AppColors.orange,
          onTap: onBreachCheck,
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

class _PasswordItem {
  const _PasswordItem(
    this.title,
    this.username,
    this.category,
    this.strength,
    this.color,
  );

  final String title;
  final String username;
  final String category;
  final String strength;
  final Color color;
}
