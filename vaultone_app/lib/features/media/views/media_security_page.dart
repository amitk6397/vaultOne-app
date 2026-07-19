import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';

class MediaSecurityPage extends ConsumerWidget {
  const MediaSecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(
      mediaLibraryProvider.select((state) => state.security),
    );
    final controller = ref.read(mediaLibraryProvider.notifier);

    return MediaPageShell(
      title: context.l10n.tr('media_security'),
      subtitle: context.l10n.tr('media_security_description'),
      icon: Icons.security_rounded,
      children: [
        SecuritySwitchTile(
          icon: Icons.pin_rounded,
          title: context.l10n.tr('pin_lock'),
          subtitle: context.l10n.tr('pin_lock_description'),
          value: security.pinEnabled,
          onChanged: (value) =>
              controller.updateSecurity(security.copyWith(pinEnabled: value)),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.fingerprint_rounded,
          title: context.l10n.tr('photo_biometrics'),
          subtitle: context.l10n.tr('photo_biometrics_description'),
          value: security.photoBiometricsEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(photoBiometricsEnabled: value),
          ),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.fingerprint_rounded,
          title: context.l10n.tr('video_biometrics'),
          subtitle: context.l10n.tr('video_biometrics_description'),
          value: security.videoBiometricsEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(videoBiometricsEnabled: value),
          ),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.enhanced_encryption_rounded,
          title: context.l10n.tr('encrypt_private_media'),
          subtitle: context.l10n.tr('encrypt_private_media_description'),
          value: security.encryptionEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(encryptionEnabled: value),
          ),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.lock_clock_rounded,
          title: context.l10n.tr('auto_lock'),
          subtitle: context.l10n.tr('auto_lock_description'),
          value: security.autoLockEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(autoLockEnabled: value),
          ),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.screenshot_monitor_rounded,
          title: context.l10n.tr('screenshot_protection'),
          subtitle: context.l10n.tr('screenshot_protection_description'),
          value: security.screenshotProtectionEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(screenshotProtectionEnabled: value),
          ),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.visibility_off_rounded,
          title: context.l10n.tr('hidden_private_vault'),
          subtitle: context.l10n.tr('hidden_private_vault_description'),
          value: security.hiddenVaultEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(hiddenVaultEnabled: value),
          ),
        ),
      ],
    );
  }
}
