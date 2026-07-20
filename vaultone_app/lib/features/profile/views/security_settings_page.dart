import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_language_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/language_selector_sheet.dart';
import '../../../shared/widgets/module_storage_sheet.dart';
import '../../../core/storage/module_storage_controller.dart';
import '../providers/profile_provider.dart';

class SecuritySettingsPage extends ConsumerWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('security'),
        subtitle: context.l10n.tr('security_page_subtitle'),
        onBack: () => context.goNamed(AppRoutes.profileName),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _SwitchTile(
              title: context.l10n.tr('biometric_lock'),
              subtitle: context.l10n.tr('biometric_lock_subtitle'),
              icon: Icons.fingerprint_rounded,
              value: profile.biometricLockEnabled,
              onChanged: notifier.setBiometricLock,
            ),
            _SwitchTile(
              title: context.l10n.tr('secure_cloud_backup'),
              subtitle: context.l10n.tr('secure_cloud_backup_subtitle'),
              icon: Icons.cloud_done_rounded,
              value: profile.cloudBackupEnabled,
              onChanged: notifier.setCloudBackup,
            ),
            _SecurityAction(
              icon: Icons.password_rounded,
              title: context.l10n.tr('change_password'),
              subtitle: context.l10n.tr('change_password_subtitle'),
              onTap: () => AppFeedback.showSnackBar(
                context,
                message: context.l10n.tr('password_reset_api_pending'),
              ),
            ),
            _SecurityAction(
              icon: Icons.devices_rounded,
              title: context.l10n.tr('trusted_devices'),
              subtitle: context.l10n.tr('trusted_devices_subtitle'),
              onTap: () => AppFeedback.showSnackBar(
                context,
                message: context.l10n.tr('trusted_devices_api_pending'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final language = ref.watch(appLanguageProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).colorScheme.surfaceContainerLowest
          : const Color(0xFFF7F6F2),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 3,
            toolbarHeight: 72,
            leading: IconButton(
              onPressed: () => context.goNamed(AppRoutes.profileName),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.tr('app_settings'),
                  style: AppTextStyles.heading.copyWith(fontSize: 19),
                ),
                Text(
                  context.l10n.tr('app_settings_page_subtitle'),
                  style: AppTextStyles.body.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList.list(
              children: [
                const _SettingsSectionLabel('GENERAL'),
                _SwitchTile(
                  title: context.l10n.tr('push_alerts'),
                  subtitle: context.l10n.tr('push_alerts_subtitle'),
                  icon: Icons.notifications_active_rounded,
                  value: profile.pushAlertsEnabled,
                  onChanged: ref.read(profileProvider.notifier).setPushAlerts,
                ),
                const _SettingsSectionLabel('PRIVACY & SECURITY'),
                _SecurityAction(
                  icon: Icons.admin_panel_settings_rounded,
                  title: context.l10n.tr('module_security'),
                  subtitle: context.l10n.tr('module_security_action_subtitle'),
                  onTap: () => context.pushNamed(AppRoutes.moduleSecurityName),
                ),
                _SecurityAction(
                  icon: Icons.language_rounded,
                  title: context.l10n.tr('language'),
                  subtitle: context.l10n.tr(
                    'language_selected',
                    args: {
                      'language': context.l10n.tr(
                        language == AppLanguage.hindi ? 'hindi' : 'english',
                      ),
                    },
                  ),
                  onTap: () => showLanguageSelectorSheet(context, ref),
                ),
                const SizedBox(height: 8),
                const _SettingsSectionLabel('DATA & STORAGE'),
                const _ModuleStorageCard(),
                _SecurityAction(
                  icon: Icons.cleaning_services_rounded,
                  title: context.l10n.tr('delete_my_data'),
                  subtitle: context.l10n.tr('delete_my_data_action_subtitle'),
                  onTap: () => context.pushNamed(AppRoutes.deleteDataName),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleStorageCard extends ConsumerWidget {
  const _ModuleStorageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(moduleStorageProvider);
    return _SettingsShell(
      icon: Icons.storage_rounded,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Module storage',
              style: AppTextStyles.label.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              'Choose storage separately for each module',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            for (final module in StorageModule.values)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(_storageModuleIcon(module), size: 20),
                title: Text(moduleLabel(module)),
                subtitle: Text(
                  storage.targetFor(module) == ModuleStorageTarget.database
                      ? 'Vault database'
                      : storage.targetFor(module) == ModuleStorageTarget.local
                      ? 'On this device'
                      : 'Not selected',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    chooseModuleStorage(context, ref, module, force: true),
              ),
          ],
        ),
      ),
    );
  }

  IconData _storageModuleIcon(StorageModule module) => switch (module) {
    StorageModule.videos => Icons.video_library_rounded,
    StorageModule.photos => Icons.photo_library_rounded,
    StorageModule.fileVault => Icons.folder_special_rounded,
  };
}

class _SettingsSectionLabel extends StatelessWidget {
  const _SettingsSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsShell(
      icon: icon,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Transform.scale(
              scale: .78,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityAction extends StatelessWidget {
  const _SecurityAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SettingsShell(
      icon: icon,
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: AppTextStyles.label.copyWith(fontSize: 16)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _SettingsShell extends StatelessWidget {
  const _SettingsShell({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.blue.withValues(alpha: 0.12),
            child: Icon(icon, color: AppColors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
