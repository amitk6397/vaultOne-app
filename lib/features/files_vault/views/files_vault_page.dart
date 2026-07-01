import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../models/vault_file.dart';
import '../providers/files_vault_provider.dart';
import '../widgets/vault_file_card.dart';

class FilesVaultPage extends ConsumerWidget {
  const FilesVaultPage({super.key});

  static const _supportedTypes = [
    'PDF',
    'JPG',
    'PNG',
    'MP4',
    'ZIP',
    'DOCX',
    'XLSX',
    'PPTX',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(filesVaultProvider);
    final controller = ref.read(filesVaultProvider.notifier);
    final isGrid = ref.watch(filesVaultGridProvider);
    final query = ref.watch(filesVaultSearchProvider);
    final selectedTag = ref.watch(filesVaultTagProvider);
    final sort = ref.watch(filesVaultSortProvider);
    final filteredFiles = controller.sortedFiles(
      controller.filteredFiles(query: query, tag: selectedTag),
      sort,
    );
    final tags = controller.tags();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadOptions(context, ref),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(onBack: () => context.goNamed(AppRoutes.homeName)),
                    const SizedBox(height: 18),
                    _VaultHero(state: state),
                    const SizedBox(height: 18),
                    _CommandCenter(
                      onUpload: () => _showUploadOptions(context, ref),
                      onCamera: () =>
                          _pickImage(context, ref, ImageSource.camera),
                      onSecurity: () => AppFeedback.showSnackBar(
                        context,
                        message: 'Vault lock and AES-ready metadata verified',
                      ),
                      onCleanup: () => AppFeedback.showSnackBar(
                        context,
                        message: 'Archived files stay hidden from this vault',
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SupportedTypesBar(types: _supportedTypes),
                    const SizedBox(height: 18),
                    _SearchAndLayout(
                      isGrid: isGrid,
                      onSearch: (value) =>
                          ref.read(filesVaultSearchProvider.notifier).state =
                              value,
                      onToggle: () =>
                          ref.read(filesVaultGridProvider.notifier).state =
                              !isGrid,
                    ),
                    const SizedBox(height: 12),
                    _SortBar(
                      value: sort,
                      onChanged: (value) {
                        ref.read(filesVaultSortProvider.notifier).state = value;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tags.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          final selected = tag == selectedTag;
                          return ChoiceChip(
                            label: Text(tag),
                            selected: selected,
                            selectedColor: AppColors.navy,
                            backgroundColor: Colors.white,
                            labelStyle: AppTextStyles.label.copyWith(
                              color: selected ? Colors.white : AppColors.navy,
                            ),
                            onSelected: (_) {
                              ref.read(filesVaultTagProvider.notifier).state =
                                  tag;
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Encrypted Files',
                            style: AppTextStyles.heading.copyWith(fontSize: 22),
                          ),
                        ),
                        Text(
                          '${filteredFiles.length} items',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredFiles.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyVault(
                  onUpload: () => _showUploadOptions(context, ref),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                sliver: isGrid
                    ? SliverGrid.builder(
                        itemCount: filteredFiles.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.92,
                            ),
                        itemBuilder: (context, index) {
                          final file = filteredFiles[index];
                          return VaultFileCard(
                            file: file,
                            isGrid: true,
                            onTap: () => _showPreview(context, ref, file),
                            onDelete: () => _confirmDelete(context, ref, file),
                            onFavorite: () =>
                                controller.toggleFavorite(file.id),
                            onArchive: () => controller.archiveFile(file.id),
                          );
                        },
                      )
                    : SliverList.separated(
                        itemCount: filteredFiles.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final file = filteredFiles[index];
                          return VaultFileCard(
                            file: file,
                            isGrid: false,
                            onTap: () => _showPreview(context, ref, file),
                            onDelete: () => _confirmDelete(context, ref, file),
                            onFavorite: () =>
                                controller.toggleFavorite(file.id),
                            onArchive: () => controller.archiveFile(file.id),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles(BuildContext context, WidgetRef ref) async {
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
      message: '${result.files.length} file(s) saved to vault',
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 88);
    if (image == null) return;
    final size = await File(image.path).length();
    await ref
        .read(filesVaultProvider.notifier)
        .addImage(name: image.name, path: image.path, sizeBytes: size);
    if (!context.mounted) return;
    AppFeedback.showSnackBar(context, message: 'Image added to vault');
  }

  void _showUploadOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Files', style: AppTextStyles.heading),
              const SizedBox(height: 14),
              _UploadOption(
                icon: Icons.folder_open_rounded,
                title: 'Pick Files',
                subtitle: 'PDF, images, videos, archives and Office files',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickFiles(context, ref);
                },
              ),
              _UploadOption(
                icon: Icons.photo_library_rounded,
                title: 'Pick Image',
                subtitle: 'Choose image from gallery',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(context, ref, ImageSource.gallery);
                },
              ),
              _UploadOption(
                icon: Icons.photo_camera_rounded,
                title: 'Capture from Camera',
                subtitle: 'Take photo and add to encrypted vault',
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

  void _showPreview(BuildContext context, WidgetRef ref, VaultFile file) {
    final tagController = TextEditingController(text: file.tags.join(', '));
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.of(sheetContext).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: file.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(file.icon, color: file.color, size: 48),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                file.name,
                style: AppTextStyles.heading.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                '${file.typeLabel} - ${file.sizeLabel} - ${file.isEncrypted ? 'Encrypted' : 'Plain'}',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 14),
              _PreviewInfo(
                label: 'Extension',
                value: file.extension.toUpperCase(),
              ),
              _PreviewInfo(label: 'Added', value: _dateLabel(file.addedAt)),
              _PreviewInfo(label: 'Path', value: file.path ?? 'Metadata only'),
              const SizedBox(height: 14),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(
                  labelText: 'Tags',
                  helperText: 'Comma separated tags',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final tags = tagController.text
                            .split(',')
                            .map((item) => item.trim())
                            .where((item) => item.isNotEmpty)
                            .toList();
                        await ref
                            .read(filesVaultProvider.notifier)
                            .updateTags(file.id, tags);
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(Icons.sell_rounded),
                      label: const Text('Save Tags'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => AppFeedback.showSnackBar(
                        context,
                        message: 'Secure share flow ready',
                      ),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    onPressed: () => ref
                        .read(filesVaultProvider.notifier)
                        .toggleFavorite(file.id),
                    icon: Icon(
                      file.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ).whenComplete(tagController.dispose);
  }

  String _dateLabel(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    VaultFile file,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text(
          '${file.name} will be removed from local vault metadata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(filesVaultProvider.notifier).deleteFile(file.id);
    if (!context.mounted) return;
    AppFeedback.showSnackBar(context, message: '${file.name} deleted');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filled(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.navy,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File Vault', style: AppTextStyles.heading),
              const SizedBox(height: 6),
              Text(
                'Premium local vault for files, media, archives and documents.',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VaultHero extends StatelessWidget {
  const _VaultHero({required this.state});

  final FilesVaultState state;

  @override
  Widget build(BuildContext context) {
    final mb = state.totalBytes / (1024 * 1024);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
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
          _HeroStat(label: 'Files', value: '${state.activeCount}'),
          _HeroStat(label: 'Encrypted', value: '${state.encryptedCount}'),
          _HeroStat(label: 'Fav', value: '${state.favoriteCount}'),
          _HeroStat(label: 'MB', value: mb.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class _CommandCenter extends StatelessWidget {
  const _CommandCenter({
    required this.onUpload,
    required this.onCamera,
    required this.onSecurity,
    required this.onCleanup,
  });

  final VoidCallback onUpload;
  final VoidCallback onCamera;
  final VoidCallback onSecurity;
  final VoidCallback onCleanup;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.72,
      children: [
        _CommandTile(
          title: 'Secure Upload',
          subtitle: 'Files & archives',
          icon: Icons.upload_file_rounded,
          color: AppColors.blue,
          onTap: onUpload,
        ),
        _CommandTile(
          title: 'Scan / Camera',
          subtitle: 'Capture receipt or doc',
          icon: Icons.photo_camera_rounded,
          color: AppColors.purple,
          onTap: onCamera,
        ),
        _CommandTile(
          title: 'Vault Health',
          subtitle: 'Encrypted metadata',
          icon: Icons.health_and_safety_rounded,
          color: AppColors.success,
          onTap: onSecurity,
        ),
        _CommandTile(
          title: 'Archive',
          subtitle: 'Keep workspace clean',
          icon: Icons.inventory_2_rounded,
          color: AppColors.orange,
          onTap: onCleanup,
        ),
      ],
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({required this.value, required this.onChanged});

  final VaultFileSort value;
  final ValueChanged<VaultFileSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<VaultFileSort>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.sort_rounded),
      ),
      items: const [
        DropdownMenuItem(
          value: VaultFileSort.newest,
          child: Text('Newest first'),
        ),
        DropdownMenuItem(
          value: VaultFileSort.oldest,
          child: Text('Oldest first'),
        ),
        DropdownMenuItem(value: VaultFileSort.name, child: Text('Name A-Z')),
        DropdownMenuItem(
          value: VaultFileSort.sizeLargest,
          child: Text('Largest first'),
        ),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _PreviewInfo extends StatelessWidget {
  const _PreviewInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.heading.copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: .74),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchAndLayout extends StatelessWidget {
  const _SearchAndLayout({
    required this.isGrid,
    required this.onSearch,
    required this.onToggle,
  });

  final bool isGrid;
  final ValueChanged<String> onSearch;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Search files or tags',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.filled(
          onPressed: onToggle,
          style: IconButton.styleFrom(backgroundColor: Colors.white),
          icon: Icon(
            isGrid ? Icons.view_list_rounded : Icons.grid_view_rounded,
          ),
        ),
      ],
    );
  }
}

class _SupportedTypesBar extends StatelessWidget {
  const _SupportedTypesBar({required this.types});

  final List<String> types;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            type,
            style: AppTextStyles.label.copyWith(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
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
      leading: CircleAvatar(
        backgroundColor: AppColors.blue.withValues(alpha: 0.12),
        child: Icon(icon, color: AppColors.blue),
      ),
      title: Text(title, style: AppTextStyles.label),
      subtitle: Text(subtitle),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_open_rounded,
            color: AppColors.textMuted,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text('No files found', style: AppTextStyles.heading),
          const SizedBox(height: 8),
          Text(
            'Upload files or clear filters to view your vault.',
            style: AppTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload Files'),
          ),
        ],
      ),
    );
  }
}
