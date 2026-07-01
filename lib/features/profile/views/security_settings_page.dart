import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../providers/profile_provider.dart';

class SecuritySettingsPage extends ConsumerWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed(AppRoutes.profileName),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Vault Protection', style: AppTextStyles.heading),
          const SizedBox(height: 16),
          _SwitchTile(
            title: 'Biometric Lock',
            subtitle: 'Require fingerprint or face unlock for vault access.',
            icon: Icons.fingerprint_rounded,
            value: profile.biometricLockEnabled,
            onChanged: notifier.setBiometricLock,
          ),
          _SwitchTile(
            title: 'Secure Cloud Backup',
            subtitle: 'Keep encrypted backup enabled for recovery.',
            icon: Icons.cloud_done_rounded,
            value: profile.cloudBackupEnabled,
            onChanged: notifier.setCloudBackup,
          ),
          _SecurityAction(
            icon: Icons.password_rounded,
            title: 'Change Password',
            subtitle: 'Password reset flow can be connected with API.',
          ),
          _SecurityAction(
            icon: Icons.devices_rounded,
            title: 'Trusted Devices',
            subtitle: 'Review logged-in devices and revoke sessions.',
          ),
        ],
      ),
    );
  }
}

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed(AppRoutes.profileName),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Preferences', style: AppTextStyles.heading),
          const SizedBox(height: 16),
          _SwitchTile(
            title: 'Push Alerts',
            subtitle: 'Expiry, renewal and security notifications.',
            icon: Icons.notifications_active_rounded,
            value: profile.pushAlertsEnabled,
            onChanged: ref.read(profileProvider.notifier).setPushAlerts,
          ),
          const _SecurityAction(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: 'English selected',
          ),
          const _SecurityAction(
            icon: Icons.storage_rounded,
            title: 'Storage',
            subtitle: '24.6 GB used of 100 GB',
          ),
          const _SecurityAction(
            icon: Icons.palette_rounded,
            title: 'Theme',
            subtitle: 'System default',
          ),
        ],
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
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: AppTextStyles.label.copyWith(fontSize: 16)),
        subtitle: Text(subtitle),
        activeThumbColor: AppColors.blue,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _SecurityAction extends StatelessWidget {
  const _SecurityAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _SettingsShell(
      icon: icon,
      child: ListTile(
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
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
