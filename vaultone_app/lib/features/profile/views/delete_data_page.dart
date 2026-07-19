import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../documents/providers/digi_locker_provider.dart';
import '../../files_vault/providers/files_vault_provider.dart';
import '../../media/models/media_item.dart';
import '../../media/providers/media_provider.dart';
import '../../passwords/providers/password_vault_provider.dart';
import '../repositories/profile_repository.dart';

class DeleteDataPage extends ConsumerStatefulWidget {
  const DeleteDataPage({super.key});

  @override
  ConsumerState<DeleteDataPage> createState() => _DeleteDataPageState();
}

class _DeleteDataPageState extends ConsumerState<DeleteDataPage> {
  String? _deleting;

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(filesVaultProvider.select((state) => state.files));
    final documents = ref.watch(
      digiLockerProvider.select((state) => state.documents),
    );
    final passwords = ref.watch(passwordVaultProvider);
    final media = ref.watch(
      mediaLibraryProvider.select((state) => state.items),
    );
    final sections = [
      _DataSection('files', 'Files', Icons.folder_delete_rounded, files.length),
      _DataSection(
        'documents',
        'Documents',
        Icons.file_copy_rounded,
        documents.length,
      ),
      _DataSection(
        'passwords',
        'Passwords & notes',
        Icons.password_rounded,
        passwords.entries.length + passwords.notes.length,
      ),
      _DataSection(
        'photos',
        'Photos',
        Icons.photo_library_rounded,
        media.where((item) => item.kind == MediaKind.photo).length,
      ),
      _DataSection(
        'videos',
        'Videos',
        Icons.video_library_rounded,
        media.where((item) => item.kind == MediaKind.video).length,
      ),
    ];

    return Scaffold(
      appBar: AppPageAppBar(
        title: 'Delete My Data',
        subtitle: 'Permanently remove data from selected sections',
        onBack: () => context.goNamed(AppRoutes.appSettingsName),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Deleted data and cloud files cannot be recovered. Each section requires separate confirmation.',
              ),
            ),
            const SizedBox(height: 16),
            for (final section in sections) ...[
              Card(
                child: ListTile(
                  leading: Icon(section.icon, color: AppColors.danger),
                  title: Text(section.label),
                  subtitle: Text('${section.count} stored items'),
                  trailing: _deleting == section.id
                      ? const AppLoadingIndicator(size: 24)
                      : TextButton(
                          onPressed: _deleting == null && section.count > 0
                              ? () => _confirmDelete(section)
                              : null,
                          child: const Text('Delete'),
                        ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(_DataSection section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${section.label}?'),
        content: Text(
          'Are you sure you want to permanently delete all ${section.count} items from ${section.label}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, delete data'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final authenticated = await _authenticateForDeletion(section.label);
    if (!authenticated || !mounted) return;
    setState(() => _deleting = section.id);
    try {
      await ref.read(profileRepositoryProvider).deleteDataSection(section.id);
      await _clearLocalSection(section.id);
      if (mounted) {
        AppFeedback.showSnackBar(
          context,
          message: '${section.label} deleted successfully',
        );
      }
    } catch (error) {
      if (mounted) AppFeedback.showSnackBar(context, message: error.toString());
    } finally {
      if (mounted) setState(() => _deleting = null);
    }
  }

  Future<bool> _authenticateForDeletion(String label) async {
    try {
      final auth = LocalAuthentication();
      final supported = await auth.isDeviceSupported();
      if (!supported) {
        if (mounted) {
          AppFeedback.showSnackBar(
            context,
            message: 'Set a device PIN, pattern, password or biometric first.',
          );
        }
        return false;
      }
      return await auth.authenticate(
        localizedReason: 'Confirm identity to permanently delete $label',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (error) {
      if (mounted) {
        AppFeedback.showSnackBar(
          context,
          message: 'Device authentication failed: $error',
        );
      }
      return false;
    }
  }

  Future<void> _clearLocalSection(String section) async {
    if (section == 'files') {
      final ids = ref
          .read(filesVaultProvider)
          .files
          .map((item) => item.id)
          .toList();
      for (final id in ids) {
        await ref.read(filesVaultProvider.notifier).deleteFile(id);
      }
    } else if (section == 'documents') {
      final ids = ref
          .read(digiLockerProvider)
          .documents
          .map((item) => item.id)
          .toList();
      for (final id in ids) {
        await ref.read(digiLockerProvider.notifier).deleteDocument(id);
      }
    } else if (section == 'passwords') {
      final state = ref.read(passwordVaultProvider);
      for (final item in state.entries.toList()) {
        await ref.read(passwordVaultProvider.notifier).deleteEntry(item.id);
      }
      for (final item in state.notes.toList()) {
        await ref.read(passwordVaultProvider.notifier).deleteNote(item.id);
      }
    } else {
      final kind = section == 'photos' ? MediaKind.photo : MediaKind.video;
      final ids = ref
          .read(mediaLibraryProvider)
          .items
          .where((item) => item.kind == kind)
          .map((item) => item.id)
          .toList();
      for (final id in ids) {
        ref.read(mediaLibraryProvider.notifier).removeItem(id);
      }
    }
  }
}

class _DataSection {
  const _DataSection(this.id, this.label, this.icon, this.count);
  final String id;
  final String label;
  final IconData icon;
  final int count;
}
