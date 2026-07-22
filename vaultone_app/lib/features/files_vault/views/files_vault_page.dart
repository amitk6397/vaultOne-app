import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/module_storage_sheet.dart';
import '../../../core/storage/module_storage_controller.dart';
import '../providers/files_vault_provider.dart';
import '../../subscriptions/providers/subscription_provider.dart';

class FilesVaultPage extends ConsumerWidget {
  const FilesVaultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(filesVaultProvider);
    final subscription = ref.watch(subscriptionProvider);
    final mb = state.totalBytes / (1024 * 1024);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? colors.surfaceContainerLowest
          : const Color(0xFFF8F7FF),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUploadOptions(context, ref),
        tooltip: context.l10n.tr('upload'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: const Icon(Icons.upload_rounded),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 3,
            shadowColor: AppColors.shadow,
            toolbarHeight: 76,
            automaticallyImplyLeading: false,
            titleSpacing: 20,
            title: Row(
              children: [
                _IconBox(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.goNamed(AppRoutes.homeName),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tr('file_vault_title'),
                        style: AppTextStyles.heading,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.tr('file_vault_description'),
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12.5,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (subscription.shouldShowSubscription)
                  IconButton.filledTonal(
                    tooltip: context.l10n.tr('storage_full_upgrade'),
                    onPressed: () =>
                        context.pushNamed(AppRoutes.subscriptionsName),
                    icon: const Icon(Icons.workspace_premium_rounded),
                  ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
            sliver: SliverList.list(
              children: [

            // Stats card — flat, 2x2 grid for readability
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(
                      label: context.l10n.tr('total_files'),
                      value: '${state.activeCount}',
                    ),
                  ),
                  const _StatDivider(),
                  Expanded(
                    child: _Stat(
                      label: context.l10n.tr('private'),
                      value: '${state.privateCount}',
                    ),
                  ),
                  const _StatDivider(),
                  Expanded(
                    child: _Stat(
                      label: context.l10n.tr('favorites'),
                      value: '${state.favoriteCount}',
                    ),
                  ),
                  const _StatDivider(),
                  Expanded(
                    child: _Stat(
                      label: context.l10n.tr('used_space'),
                      value: '${mb.toStringAsFixed(1)} MB',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Vault tiles — soft tinted icon boxes, outlined cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.4,
              children: [
                _VaultTile(
                  title: context.l10n.tr('all_files'),
                  subtitle: context.l10n.tr(
                    'public_files_count',
                    args: {'count': state.publicCount},
                  ),
                  icon: Icons.folder_rounded,
                  color: AppColors.blue,
                  onTap: () => context.pushNamed(AppRoutes.filesVaultFilesName),
                ),
                _VaultTile(
                  title: context.l10n.tr('private'),
                  subtitle: context.l10n.tr(
                    'locked_files_count',
                    args: {'count': state.privateCount},
                  ),
                  icon: Icons.lock_rounded,
                  color: AppColors.purple,
                  onTap: () =>
                      context.pushNamed(AppRoutes.filesVaultPrivateName),
                ),
                _VaultTile(
                  title: context.l10n.tr('upload'),
                  subtitle: context.l10n.tr('upload_types_short'),
                  icon: Icons.upload_rounded,
                  color: AppColors.success,
                  onTap: () => _showUploadOptions(context, ref),
                ),
                _VaultTile(
                  title: context.l10n.tr('archive'),
                  subtitle: context.l10n.tr('archive_description'),
                  icon: Icons.archive_rounded,
                  color: AppColors.orange,
                  onTap: () =>
                      context.pushNamed(AppRoutes.filesVaultArchiveName),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Supported files — outlined chips instead of solid filled
            Text(
              context.l10n.tr('supported_files'),
              style: AppTextStyles.heading.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                'PDF',
                'JPG',
                'PNG',
                'MP4',
                'ZIP',
                'DOCX',
                'XLSX',
                'PPTX',
              ].map((type) => _FileTypeChip(label: type)).toList(),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles(BuildContext context, WidgetRef ref) async {
    final storage = await chooseModuleStorage(
      context,
      ref,
      StorageModule.fileVault,
      force: true,
    );
    if (storage == null || !context.mounted) return;
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'mp4',
        'mov',
        'zip',
        'rar',
        '7z',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
      ],
    );
    if (result == null || result.files.isEmpty) return;
    await ref
        .read(filesVaultProvider.notifier)
        .importPlatformFiles(result.files);
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr(
        'files_saved_vault',
        args: {'count': result.files.length},
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final storage = await chooseModuleStorage(
      context,
      ref,
      StorageModule.fileVault,
      force: true,
    );
    if (storage == null || !context.mounted) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 88);
    if (image == null) return;
    final size = await File(image.path).length();
    await ref
        .read(filesVaultProvider.notifier)
        .addImage(name: image.name, path: image.path, sizeBytes: size);
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr('image_added_vault'),
    );
  }

  void _showUploadOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewPaddingOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(22, 8, 22, 28 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.tr('add_files'), style: AppTextStyles.heading),
              const SizedBox(height: 14),
              _UploadOption(
                icon: Icons.folder_rounded,
                title: context.l10n.tr('pick_files'),
                subtitle: context.l10n.tr('pick_files_description'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickFiles(context, ref);
                },
              ),
              _UploadOption(
                icon: Icons.photo_library_rounded,
                title: context.l10n.tr('pick_image'),
                subtitle: context.l10n.tr('pick_image_description'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(context, ref, ImageSource.gallery);
                },
              ),
              _UploadOption(
                icon: Icons.photo_camera_rounded,
                title: context.l10n.tr('capture_camera'),
                subtitle: context.l10n.tr('capture_camera_description'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(context, ref, ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon, size: 22, color: colors.onSurface),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextStyles.heading.copyWith(
              color: Colors.white,
              fontSize: 17,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: Colors.white.withValues(alpha: .65),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 34,
    color: Colors.white.withValues(alpha: .14),
  );
}

class _VaultTile extends StatelessWidget {
  const _VaultTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const Spacer(),
            Text(title, style: AppTextStyles.label),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontSize: 11.5,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileTypeChip extends StatelessWidget {
  const _FileTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  const _UploadOption({
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
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.blue, size: 20),
      ),
      title: Text(title, style: AppTextStyles.label),
      subtitle: Text(subtitle),
    );
  }
}
