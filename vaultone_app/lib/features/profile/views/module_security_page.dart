import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../providers/profile_provider.dart';

class ModuleSecurityPage extends ConsumerWidget {
  const ModuleSecurityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final modules = <_ModuleSecurityItem>[
      _ModuleSecurityItem(
        'files_vault',
        'protect_files_vault',
        Icons.folder_copy_rounded,
        const Color(0xFF2563EB),
        profile.filesSecurityEnabled,
        notifier.setFilesSecurity,
      ),
      _ModuleSecurityItem(
        'password_store',
        'protect_password_store',
        Icons.password_rounded,
        const Color(0xFF7C3AED),
        profile.passwordSecurityEnabled,
        notifier.setPasswordSecurity,
      ),
      _ModuleSecurityItem(
        'secure_notes',
        'protect_secure_notes',
        Icons.note_alt_rounded,
        const Color(0xFF0891B2),
        profile.secureNotesSecurityEnabled,
        notifier.setSecureNotesSecurity,
      ),
      _ModuleSecurityItem(
        'digi_locker',
        'protect_digi_locker',
        Icons.folder_shared_rounded,
        const Color(0xFFEA580C),
        profile.digiLockerSecurityEnabled,
        notifier.setDigiLockerSecurity,
      ),
      _ModuleSecurityItem(
        'private_photos',
        'protect_private_photos',
        Icons.photo_library_rounded,
        const Color(0xFFDB2777),
        profile.photosSecurityEnabled,
        notifier.setPhotosSecurity,
      ),
      _ModuleSecurityItem(
        'private_videos',
        'protect_private_videos',
        Icons.video_library_rounded,
        const Color(0xFFDC2626),
        profile.videosSecurityEnabled,
        notifier.setVideosSecurity,
      ),
      _ModuleSecurityItem(
        'ai_scanner',
        'protect_ai_scanner',
        Icons.document_scanner_rounded,
        const Color(0xFF16A34A),
        profile.scannerSecurityEnabled,
        notifier.setScannerSecurity,
      ),
    ];
    final enabledCount = modules.where((item) => item.enabled).length;

    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('module_security'),
        subtitle: context.l10n.tr('module_security_subtitle'),
        onBack: () => context.goNamed(AppRoutes.appSettingsName),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF172554), Color(0xFF4338CA)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.security_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.tr(
                            'modules_protected',
                            args: {
                              'enabled': '$enabledCount',
                              'total': '${modules.length}',
                            },
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.tr('module_security_fallback'),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...modules.map((item) => _ModuleCard(item: item)),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.item});
  final _ModuleSecurityItem item;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: item.color.withValues(alpha: .12),
            child: Icon(item.icon, color: item.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.tr(item.titleKey),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(context.l10n.tr(item.subtitleKey)),
              ],
            ),
          ),
          Transform.scale(
            scale: .78,
            child: Switch(value: item.enabled, onChanged: item.onChanged),
          ),
        ],
      ),
    ),
  );
}

class _ModuleSecurityItem {
  const _ModuleSecurityItem(
    this.titleKey,
    this.subtitleKey,
    this.icon,
    this.color,
    this.enabled,
    this.onChanged,
  );
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color color;
  final bool enabled;
  final ValueChanged<bool> onChanged;
}
