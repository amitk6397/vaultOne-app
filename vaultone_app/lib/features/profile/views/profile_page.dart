import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../files_vault/providers/files_vault_provider.dart';
import '../../media/providers/media_provider.dart';
import '../../passwords/providers/password_vault_provider.dart';
import '../../scanner/providers/scanner_provider.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final passwords = ref.watch(passwordVaultProvider);
    final files = ref.watch(filesVaultProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: isDark ? const Color(0xFF101827) : Colors.white,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : const Color(0xFFF7F6F2),
        appBar: AppPageAppBar(
          title: context.l10n.tr('profile'),
          subtitle: profile.email.isEmpty ? null : profile.email,
          actions: [
            IconButton(
              tooltip: context.l10n.tr('app_settings'),
              onPressed: () => context.pushNamed(AppRoutes.appSettingsName),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.profile),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Gradient Hero Header ──────────────────────────────────────
              _ProfileHeroHeader(
                initials: profile.avatarInitials,
                name: profile.fullName,
                email: profile.email,
                mobile: profile.mobile,
                onEdit: () => context.pushNamed(AppRoutes.editProfileName),
              ),
              // ── Stats Row ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Transform.translate(
                  offset: Offset.zero,
                  child: _StatsRow(
                    passwords: passwords.totalPasswords,
                    files: files.activeCount,
                  ),
                ),
              ),
              // ── Menu sections ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(context.l10n.tr('account')),
                    const SizedBox(height: 8),
                    _MenuCard(
                      children: [
                        _MenuTile(
                          icon: Icons.workspace_premium_rounded,
                          title: context.l10n.tr('storage_plans'),
                          subtitle: context.l10n.tr('storage_plans_subtitle'),
                          color: AppColors.purple,
                          onTap: () =>
                              context.pushNamed(AppRoutes.subscriptionsName),
                        ),
                        _MenuTile(
                          icon: Icons.edit_rounded,
                          title: context.l10n.tr('edit_profile'),
                          subtitle: context.l10n.tr('profile_details_subtitle'),
                          color: AppColors.blue,
                          onTap: () =>
                              context.pushNamed(AppRoutes.editProfileName),
                        ),
                        _MenuTile(
                          icon: Icons.security_rounded,
                          title: context.l10n.tr('security_settings'),
                          subtitle: context.l10n.tr(
                            'security_settings_subtitle',
                          ),
                          color: AppColors.purple,
                          onTap: () =>
                              context.pushNamed(AppRoutes.securitySettingsName),
                        ),
                        _MenuTile(
                          icon: Icons.settings_rounded,
                          title: context.l10n.tr('app_settings'),
                          subtitle: context.l10n.tr('app_settings_subtitle'),
                          color: AppColors.orange,
                          onTap: () =>
                              context.pushNamed(AppRoutes.appSettingsName),
                        ),
                        _MenuTile(
                          icon: Icons.privacy_tip_rounded,
                          title: context.l10n.tr('privacy_policy'),
                          subtitle: context.l10n.tr('privacy_policy_subtitle'),
                          color: AppColors.success,
                          onTap: () =>
                              context.pushNamed(AppRoutes.privacyPolicyName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionLabel(context.l10n.tr('support')),
                    const SizedBox(height: 8),
                    _MenuCard(
                      children: [
                        _MenuTile(
                          icon: Icons.help_rounded,
                          title: context.l10n.tr('help_and_support'),
                          subtitle: context.l10n.tr('help_support_subtitle'),
                          color: AppColors.cyan,
                          onTap: () => context.pushNamed(AppRoutes.supportName),
                        ),
                        _MenuTile(
                          icon: Icons.info_rounded,
                          title: context.l10n.tr('about_vaultone'),
                          subtitle: context.l10n.tr('about_vaultone_subtitle'),
                          color: AppColors.navy,
                          onTap: () => context.pushNamed(AppRoutes.aboutName),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionLabel(context.l10n.tr('danger_zone')),
                    const SizedBox(height: 8),
                    _MenuCard(
                      children: [
                        _MenuTile(
                          icon: Icons.logout_rounded,
                          title: context.l10n.tr('logout'),
                          subtitle: context.l10n.tr('logout_subtitle'),
                          color: AppColors.danger,
                          onTap: () => _showLogoutSheet(context, ref),
                        ),
                        _MenuTile(
                          icon: Icons.delete_forever_rounded,
                          title: context.l10n.tr('delete_account'),
                          subtitle: context.l10n.tr('delete_account_subtitle'),
                          color: AppColors.danger,
                          onTap: () =>
                              context.pushNamed(AppRoutes.deleteAccountName),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutSheet(BuildContext context, WidgetRef ref) async {
    var backupBeforeLogout = false;
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      context.l10n.tr('logout_from_vaultone'),
                      style: AppTextStyles.heading.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Logging out removes VaultOne-managed local data from '
                      'this device. Your original phone gallery stays safe.',
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      value: backupBeforeLogout,
                      onChanged: (value) => setSheetState(
                        () => backupBeforeLogout = value ?? false,
                      ),
                      activeColor: AppColors.purple,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Back up local data before logout'),
                      subtitle: const Text(
                        'Uploads passwords, secure notes, files and photos to '
                        'your account before clearing them from this device. '
                        'Videos are not uploaded because they can quickly fill '
                        'the storage included in your plan.',
                      ),
                    ),
                    const Text(
                      'Private videos stored by VaultOne will be removed from '
                      'this device on logout. Move or back them up manually if '
                      'you need to keep them.',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext, false),
                            child: Text(context.l10n.tr('cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => Navigator.pop(sheetContext, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.danger,
                            ),
                            child: Text(context.l10n.tr('logout')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!(shouldLogout ?? false)) return;
    if (backupBeforeLogout) {
      try {
        await ref.read(passwordVaultProvider.notifier).syncAllToDatabase();
        await ref.read(filesVaultProvider.notifier).syncNonVideoToDatabase();
        await ref
            .read(mediaLibraryProvider.notifier)
            .syncLocalPhotosToDatabase();
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Backup could not finish, but logout will continue: '
                '$error',
              ),
            ),
          );
        }
      }
    }
    final cleanupErrors = <Object>[];
    Future<void> clearSafely(Future<void> Function() clear) async {
      try {
        await clear();
      } catch (error) {
        cleanupErrors.add(error);
      }
    }

    await clearSafely(
      () => ref.read(passwordVaultProvider.notifier).clearLocalCache(),
    );
    await clearSafely(
      () => ref.read(filesVaultProvider.notifier).clearLocalCache(),
    );
    await clearSafely(
      () => ref.read(mediaLibraryProvider.notifier).clearVaultOneLocalData(),
    );
    await clearSafely(
      () => ref.read(scannerProvider.notifier).clearLocalCache(),
    );
    await ref
        .read(profileProvider.notifier)
        .clearSession(deleteSavedData: true);
    ref.invalidate(subscriptionProvider);
    ref.invalidate(notificationProvider);
    ref.invalidate(passwordVaultProvider);
    ref.invalidate(filesVaultProvider);
    ref.invalidate(mediaLibraryProvider);
    ref.invalidate(scannerProvider);
    ref.invalidate(profileProvider);
    if (context.mounted) {
      context.goNamed(AppRoutes.loginName);
      if (cleanupErrors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Logged out. Some damaged local cache could not be removed.',
            ),
          ),
        );
      }
    }
  }
}

// ── Gradient Hero Header ──────────────────────────────────────────────────────

class _ProfileHeroHeader extends StatelessWidget {
  const _ProfileHeroHeader({
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
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF202C4A), Color(0xFF34446C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24071943),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle mesh circles
          Positioned(
            right: -24,
            top: -18,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .06),
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: 18,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .04),
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: 40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: .25),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: .30),
                            Colors.white.withValues(alpha: .12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .55),
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x220D5FFF),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Color(0xFF0D5FFF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .78),
                            fontSize: 13,
                          ),
                        ),
                      if (mobile.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            mobile,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .6),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.passwords, required this.files});

  final int passwords;
  final int files;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D5FFF).withValues(alpha: .1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(
                icon: Icons.lock_rounded,
                label: context.l10n.tr('passwords'),
                value: '$passwords',
                color: AppColors.purple,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: colors.outlineVariant.withValues(alpha: .5),
            ),
            Expanded(
              child: _StatCell(
                icon: Icons.folder_special_rounded,
                label: context.l10n.tr('files'),
                value: '$files',
                color: AppColors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.body.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.label.copyWith(
          fontSize: 10.5,
          letterSpacing: 1.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ── Menu card ─────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .5)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: .12)
                : const Color(0xFF071943).withValues(alpha: .04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 58,
                color: colors.outlineVariant.withValues(alpha: .45),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Menu tile ─────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  const _MenuTile({
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
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title, style: AppTextStyles.label.copyWith(fontSize: 13.5)),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body.copyWith(fontSize: 11),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: colors.onSurfaceVariant.withValues(alpha: .5),
      ),
    );
  }
}
