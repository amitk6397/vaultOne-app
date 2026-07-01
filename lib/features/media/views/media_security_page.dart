import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/media_provider.dart';
import '../widgets/media_widgets.dart';

class MediaSecurityPage extends ConsumerWidget {
  const MediaSecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(mediaLibraryProvider).security;
    final controller = ref.read(mediaLibraryProvider.notifier);

    return MediaPageShell(
      title: 'Media Security',
      subtitle: 'PIN, biometrics, encryption, auto-lock and hidden vault',
      icon: Icons.security_rounded,
      children: [
        SecuritySwitchTile(
          icon: Icons.pin_rounded,
          title: 'PIN Lock',
          subtitle: 'Require PIN before opening private photos and videos.',
          value: security.pinEnabled,
          onChanged: (value) =>
              controller.updateSecurity(security.copyWith(pinEnabled: value)),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.fingerprint_rounded,
          title: 'Biometrics',
          subtitle: 'Unlock private vault with device biometrics.',
          value: security.biometricsEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(biometricsEnabled: value),
          ),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.enhanced_encryption_rounded,
          title: 'Encrypt Private Media',
          subtitle: 'Mark private photos and videos as encrypted.',
          value: security.encryptionEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(encryptionEnabled: value),
          ),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.lock_clock_rounded,
          title: 'Auto Lock',
          subtitle: 'Lock private media after inactivity.',
          value: security.autoLockEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(autoLockEnabled: value),
          ),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.screenshot_monitor_rounded,
          title: 'Screenshot Protection',
          subtitle: 'Protect private vault screens from screenshots.',
          value: security.screenshotProtectionEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(screenshotProtectionEnabled: value),
          ),
        ),
        const SizedBox(height: 10),
        SecuritySwitchTile(
          icon: Icons.visibility_off_rounded,
          title: 'Hidden Private Vault',
          subtitle: 'Hide private photos and videos from public surfaces.',
          value: security.hiddenVaultEnabled,
          onChanged: (value) => controller.updateSecurity(
            security.copyWith(hiddenVaultEnabled: value),
          ),
        ),
      ],
    );
  }
}
