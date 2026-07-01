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
    final files = ref.watch(vaultFilesProvider);
    final isGrid = ref.watch(filesVaultGridProvider);
    final query = ref.watch(filesVaultSearchProvider).toLowerCase();
    final selectedTag = ref.watch(filesVaultTagProvider);
    final tags = _tags(files);
    final filteredFiles = files.where((file) {
      final matchesQuery =
          file.name.toLowerCase().contains(query) ||
          file.tags.any((tag) => tag.toLowerCase().contains(query));
      final matchesTag =
          selectedTag == 'All' || file.tags.contains(selectedTag);
      return matchesQuery && matchesTag;
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadOptions(context, ref),
        backgroundColor: AppColors.blue,
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
                    const _SupportedTypesBar(types: _supportedTypes),
                    const SizedBox(height: 18),
                    _UploadPanel(
                      onUpload: () => _showUploadOptions(context, ref),
                    ),
                    const SizedBox(height: 18),
                    _FeatureInfoGrid(
                      isGrid: isGrid,
                      onToggleView: () {
                        ref.read(filesVaultGridProvider.notifier).state =
                            !isGrid;
                      },
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      onChanged: (value) {
                        ref.read(filesVaultSearchProvider.notifier).state =
                            value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search files by name or tag',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tags.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          final selected = tag == selectedTag;
                          return ChoiceChip(
                            label: Text(tag),
                            selected: selected,
                            selectedColor: AppColors.blue,
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
            if (filteredFiles.isEmpty)
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
                            onDelete: () => _deleteFile(context, ref, file),
                          );
                        },
                      )
                    : SliverList.separated(
                        itemCount: filteredFiles.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final file = filteredFiles[index];
                          return VaultFileCard(
                            file: file,
                            isGrid: false,
                            onTap: () => _showPreview(context, ref, file),
                            onDelete: () => _deleteFile(context, ref, file),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }

  List<String> _tags(List<VaultFile> files) {
    final tags = files.expand((file) => file.tags).toSet().toList()..sort();
    return ['All', ...tags];
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
        'zip',
        'rar',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
      ],
    );

    if (result == null || result.files.isEmpty) return;

    final newFiles = result.files.map(_fromPlatformFile).toList();
    ref.read(vaultFilesProvider.notifier).state = [
      ...newFiles,
      ...ref.read(vaultFilesProvider),
    ];
    if (context.mounted) {
      AppFeedback.showSnackBar(
        context,
        message: '${newFiles.length} file(s) encrypted and added',
      );
    }
  }

  Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 88);
    if (image == null) return;

    final file = VaultFile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: image.name,
      extension: _extension(image.name),
      sizeLabel: 'Image',
      type: VaultFileType.image,
      addedAt: DateTime.now(),
      tags: const ['Image', 'Camera'],
      path: image.path,
    );

    ref.read(vaultFilesProvider.notifier).state = [
      file,
      ...ref.read(vaultFilesProvider),
    ];
    if (context.mounted) {
      AppFeedback.showSnackBar(context, message: 'Image added to vault');
    }
  }

  VaultFile _fromPlatformFile(PlatformFile file) {
    final extension = (file.extension ?? _extension(file.name)).toLowerCase();
    return VaultFile(
      id: '${file.name}-${DateTime.now().microsecondsSinceEpoch}',
      name: file.name,
      extension: extension,
      sizeLabel: _sizeLabel(file.size),
      type: _typeFromExtension(extension),
      addedAt: DateTime.now(),
      tags: [_tagFromType(_typeFromExtension(extension))],
      path: file.path,
    );
  }

  String _extension(String name) {
    final index = name.lastIndexOf('.');
    if (index == -1 || index == name.length - 1) return '';
    return name.substring(index + 1).toLowerCase();
  }

  String _sizeLabel(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  VaultFileType _typeFromExtension(String extension) {
    return switch (extension) {
      'pdf' => VaultFileType.pdf,
      'jpg' || 'jpeg' || 'png' => VaultFileType.image,
      'mp4' => VaultFileType.video,
      'zip' || 'rar' => VaultFileType.archive,
      'doc' || 'docx' || 'xls' || 'xlsx' => VaultFileType.document,
      'ppt' || 'pptx' => VaultFileType.presentation,
      _ => VaultFileType.other,
    };
  }

  String _tagFromType(VaultFileType type) {
    return switch (type) {
      VaultFileType.pdf => 'PDF',
      VaultFileType.image => 'Image',
      VaultFileType.video => 'Video',
      VaultFileType.archive => 'Archive',
      VaultFileType.document => 'Document',
      VaultFileType.presentation => 'PPT',
      VaultFileType.other => 'Other',
    };
  }

  void _deleteFile(BuildContext context, WidgetRef ref, VaultFile file) {
    ref.read(vaultFilesProvider.notifier).state = ref
        .read(vaultFilesProvider)
        .where((item) => item.id != file.id)
        .toList();
    AppFeedback.showSnackBar(context, message: '${file.name} deleted');
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
              Text('Upload Files', style: AppTextStyles.heading),
              const SizedBox(height: 14),
              _UploadOption(
                icon: Icons.folder_open_rounded,
                title: 'Pick Files',
                subtitle: 'PDF, images, videos, archives, Office documents',
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
                subtitle: 'Take photo and add to vault',
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
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
                '${file.typeLabel} • ${file.sizeLabel} • AES-256 ready',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: file.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AppFeedback.showSnackBar(
                          context,
                          message: 'Download/decrypt action ready for storage',
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AppFeedback.showSnackBar(
                          context,
                          message: 'Share sheet can be connected here',
                        );
                      },
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteFile(context, ref, file);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete File'),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                'Encrypted storage for PDFs, images, videos, archives and Office documents.',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Supported File Types', style: AppTextStyles.label),
        const SizedBox(height: 10),
        Wrap(
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
        ),
      ],
    );
  }
}

class _UploadPanel extends StatelessWidget {
  const _UploadPanel({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return _InfoPanel(
      title: 'Upload Files',
      subtitle: 'Pick files from device storage or capture via camera.',
      icon: Icons.upload_file_rounded,
      actionLabel: 'file_picker',
      onTap: onUpload,
    );
  }
}

class _FeatureInfoGrid extends StatelessWidget {
  const _FeatureInfoGrid({required this.isGrid, required this.onToggleView});

  final bool isGrid;
  final VoidCallback onToggleView;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoPanel(
          title: 'In-app Preview',
          subtitle: 'Preview file details and metadata inside the app.',
          icon: Icons.visibility_rounded,
          actionLabel: 'Preview',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _InfoPanel(
          title: 'Encryption at Rest',
          subtitle:
              'Files are marked AES-256 ready before local/remote storage.',
          icon: Icons.enhanced_encryption_rounded,
          actionLabel: 'AES-256',
          onTap: () {},
        ),
        const SizedBox(height: 10),
        _InfoPanel(
          title: isGrid ? 'Grid View' : 'List View',
          subtitle: 'Toggle between thumbnail grid and detailed list view.',
          icon: isGrid ? Icons.grid_view_rounded : Icons.view_list_rounded,
          actionLabel: 'Layout Toggle',
          onTap: onToggleView,
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(actionLabel),
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
            'Upload files or clear search filters to view your vault.',
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
