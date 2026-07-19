import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../models/vault_file.dart';
import '../file_localizations.dart';
import '../providers/files_vault_provider.dart';

class VaultFileDetailPage extends ConsumerWidget {
  const VaultFileDetailPage({super.key, required this.fileId});

  final String fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(filesVaultProvider);
    final controller = ref.read(filesVaultProvider.notifier);
    final file = state.files.where((item) => item.id == fileId).firstOrNull;

    if (file == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.tr('file_not_found'))),
      );
    }

    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('file_details'),
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: file.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(file.icon, color: file.color, size: 54),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              file.name,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 8),
            Text(
              '${localizedVaultFileType(context, file.type)} - ${localizedVaultFileSize(context, file)} - ${context.l10n.tr(file.isPrivate ? 'private' : 'public')}',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _openPreview(context, file),
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(context.l10n.tr('open')),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.25,
              children: [
                _QuickAction(
                  icon: Icons.download_rounded,
                  label: context.l10n.tr('download'),
                  onTap: () => _download(context, controller, file),
                ),
                _QuickAction(
                  icon: file.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  label: context.l10n.tr(
                    file.isFavorite
                        ? 'remove_favorite_title'
                        : 'add_favorite_title',
                  ),
                  onTap: () => controller.toggleFavorite(file.id),
                ),
                _QuickAction(
                  icon: file.isPrivate
                      ? Icons.public_rounded
                      : Icons.lock_rounded,
                  label: context.l10n.tr(
                    file.isPrivate ? 'move_to_public' : 'move_to_private',
                  ),
                  onTap: () => controller.togglePrivate(file.id),
                ),
                _QuickAction(
                  icon: Icons.inventory_2_rounded,
                  label: context.l10n.tr('archive'),
                  onTap: () => controller.archiveFile(file.id),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: .04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _Info(
                    label: context.l10n.tr('extension'),
                    value: file.extension.toUpperCase(),
                  ),
                  _Info(
                    label: context.l10n.tr('added'),
                    value: _dateLabel(context, file.addedAt),
                  ),
                  _Info(
                    label: context.l10n.tr('updated'),
                    value: _dateLabel(context, file.updatedAt),
                  ),
                  _Info(
                    label: context.l10n.tr('path'),
                    value: file.path ?? context.l10n.tr('metadata_only'),
                  ),
                  _Info(
                    label: context.l10n.tr('tags'),
                    value: file.tags.join(', '),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () async {
                await controller.deleteFile(file.id);
                if (!context.mounted) return;
                context.pop();
                AppFeedback.showSnackBar(
                  context,
                  message: context.l10n.tr(
                    'file_deleted_named',
                    args: {'file': file.name},
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(context.l10n.tr('delete_file')),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _download(
    BuildContext context,
    FilesVaultController controller,
    VaultFile file,
  ) async {
    final savedPath = await controller.downloadFile(file.id);
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: savedPath == null
          ? context.l10n.tr('download_failed_missing')
          : context.l10n.tr('downloaded_file', args: {'file': file.name}),
    );
  }

  Future<void> _openPreview(BuildContext context, VaultFile file) async {
    final path = file.path;
    if (path == null || path.isEmpty || !File(path).existsSync()) {
      AppFeedback.showSnackBar(
        context,
        message: context.l10n.tr('original_file_missing'),
      );
      return;
    }

    if (file.type != VaultFileType.image) {
      final result = await OpenFilex.open(path);
      if (!context.mounted) return;
      if (result.type != ResultType.done) {
        AppFeedback.showSnackBar(
          context,
          message: result.message.isEmpty
              ? context.l10n.tr('no_compatible_app')
              : result.message,
        );
      }
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Column(
              children: [
                ListTile(
                  leading: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  title: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: InteractiveViewer(
                      child: Image.file(File(path), fit: BoxFit.contain),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _dateLabel(BuildContext context, DateTime date) =>
      MaterialLocalizations.of(context).formatShortDate(date);
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: colors.primary, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
