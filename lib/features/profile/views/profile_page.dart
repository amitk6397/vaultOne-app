import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.profile),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: AppTextStyles.heading.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage account, privacy, security and app preferences.',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 14),
              _ProfileHero(
                initials: profile.avatarInitials,
                name: profile.fullName,
                email: profile.email,
                mobile: profile.mobile,
                onEdit: () => context.pushNamed(AppRoutes.editProfileName),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    label: 'Documents',
                    value: '58',
                    color: AppColors.blue,
                    icon: Icons.folder_rounded,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Passwords',
                    value: '32',
                    color: AppColors.purple,
                    icon: Icons.lock_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Account',
                style: AppTextStyles.heading.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              _ProfileMenuCard(
                children: [
                  _ProfileMenuTile(
                    icon: Icons.edit_rounded,
                    title: 'Edit Profile',
                    subtitle: 'Name, phone, email and city',
                    color: AppColors.blue,
                    onTap: () => context.pushNamed(AppRoutes.editProfileName),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    subtitle: 'Data usage and user rights',
                    color: AppColors.success,
                    onTap: () => context.pushNamed(AppRoutes.privacyPolicyName),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.security_rounded,
                    title: 'Security Settings',
                    subtitle: 'Biometric lock and secure backup',
                    color: AppColors.purple,
                    onTap: () =>
                        context.pushNamed(AppRoutes.securitySettingsName),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.settings_rounded,
                    title: 'App Settings',
                    subtitle: 'Notifications, language and storage',
                    color: AppColors.orange,
                    onTap: () => context.pushNamed(AppRoutes.appSettingsName),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Support',
                style: AppTextStyles.heading.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              _ProfileMenuCard(
                children: [
                  _ProfileMenuTile(
                    icon: Icons.help_rounded,
                    title: 'Help & Support',
                    subtitle: 'FAQs and contact support',
                    color: AppColors.cyan,
                    onTap: () => context.pushNamed(AppRoutes.supportName),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.info_rounded,
                    title: 'About VaultOne',
                    subtitle: 'Version, terms and app details',
                    color: AppColors.navy,
                    onTap: () => context.pushNamed(AppRoutes.aboutName),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    subtitle: 'Request permanent account deletion',
                    color: AppColors.danger,
                    onTap: () => context.pushNamed(AppRoutes.deleteAccountName),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.initials,
    required this.name,
    required this.email,
    required this.mobile,
    required this.onEdit,
  });

  final String initials;
  final String name;
  final String email;
  final String mobile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppColors.darkHeroGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: AppTextStyles.heading.copyWith(
                color: AppColors.blue,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.heroHeading.copyWith(fontSize: 19),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
                Text(
                  mobile,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onEdit,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.blue,
            ),
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTextStyles.heading.copyWith(fontSize: 18),
                  ),
                  Text(label, style: AppTextStyles.body.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: AppTextStyles.label.copyWith(fontSize: 14)),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body.copyWith(fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}
