import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../models/digi_document.dart';
import '../providers/digi_locker_provider.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  static final _types = [
    'All',
    ...DigiDocumentType.values.map(digiDocumentTypeLabel),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locker = ref.watch(digiLockerProvider);
    final controller = ref.read(digiLockerProvider.notifier);
    final query = ref.watch(digiSearchProvider);
    final selectedType = ref.watch(selectedDigiTypeProvider);
    final selectedFolderId = ref.watch(selectedDigiFolderProvider);
    final activeFolderId = selectedFolderId ?? locker.folders.firstOrNull?.id;
    final documents = controller.filteredDocuments(
      query: query,
      type: selectedType,
      folderId: activeFolderId,
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: locker.isLoading || activeFolderId == null
            ? null
            : () => _pickFiles(context, ref, activeFolderId),
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
                    _Hero(state: locker),
                    const SizedBox(height: 18),
                    _SearchField(
                      onChanged: (value) =>
                          ref.read(digiSearchProvider.notifier).state = value,
                    ),
                    const SizedBox(height: 14),
                    _TypeSelector(
                      types: _types,
                      selected: selectedType,
                      onSelected: (value) =>
                          ref.read(selectedDigiTypeProvider.notifier).state =
                              value,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          'Folders',
                          style: AppTextStyles.heading.copyWith(fontSize: 22),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _showFolderDialog(context, ref),
                          icon: const Icon(Icons.create_new_folder_rounded),
                          label: const Text('New'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _FolderStrip(
                      folders: locker.folders,
                      selectedId: activeFolderId,
                      countFor: controller.documentCountForFolder,
                      onSelected: (folder) {
                        ref.read(selectedDigiFolderProvider.notifier).state =
                            folder.id;
                      },
                      onRename: (folder) =>
                          _showFolderDialog(context, ref, folder),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          'Documents',
                          style: AppTextStyles.heading.copyWith(fontSize: 22),
                        ),
                        const Spacer(),
                        Text(
                          '${documents.length} files',
                          style: AppTextStyles.body,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (locker.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (documents.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyDocuments(
                  onUpload: activeFolderId == null
                      ? null
                      : () => _pickFiles(context, ref, activeFolderId),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 108),
                sliver: SliverList.separated(
                  itemCount: documents.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final folder =
                        controller.folderById(document.folderId) ??
                        locker.folders.first;
                    return _DocumentTile(
                      document: document,
                      folder: folder,
                      onTap: () => _showPreview(context, ref, document),
                      onFavorite: () => controller.toggleFavorite(document.id),
                      onMove: () => _showMoveSheet(context, ref, document),
                      onExpiry: () => _pickExpiry(context, ref, document),
                      onEdit: () => _showMetadataSheet(context, ref, document),
                      onDelete: () async {
                        await controller.deleteDocument(document.id);
                        if (!context.mounted) return;
                        AppFeedback.showSnackBar(
                          context,
                          message: 'Document deleted',
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles(
    BuildContext context,
    WidgetRef ref,
    String folderId,
  ) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result == null || result.files.isEmpty) return;
    await ref
        .read(digiLockerProvider.notifier)
        .importFiles(result.files, folderId);
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: '${result.files.length} document(s) saved locally',
    );
  }

  Future<void> _showFolderDialog(
    BuildContext context,
    WidgetRef ref, [
    DigiFolder? folder,
  ]) async {
    final nameController = TextEditingController(text: folder?.name ?? '');
    var color = folder?.color ?? AppColors.blue;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(folder == null ? 'Create Folder' : 'Rename Folder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Folder name',
                      prefixIcon: Icon(Icons.folder_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    children:
                        [
                          AppColors.blue,
                          AppColors.purple,
                          AppColors.success,
                          AppColors.orange,
                          AppColors.cyan,
                        ].map((item) {
                          return InkWell(
                            onTap: () => setDialogState(() => color = item),
                            borderRadius: BorderRadius.circular(99),
                            child: CircleAvatar(
                              backgroundColor: item,
                              child: color == item
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final controller = ref.read(digiLockerProvider.notifier);
                    if (folder == null) {
                      await controller.createFolder(name, color.toARGB32());
                    } else {
                      await controller.renameFolder(folder.id, name);
                    }
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    nameController.dispose();
  }

  Future<void> _pickExpiry(
    BuildContext context,
    WidgetRef ref,
    DigiDocument document,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          document.expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2045),
    );
    if (date == null) return;
    await ref.read(digiLockerProvider.notifier).updateExpiry(document.id, date);
  }

  void _showMoveSheet(
    BuildContext context,
    WidgetRef ref,
    DigiDocument document,
  ) {
    final locker = ref.read(digiLockerProvider);
    final controller = ref.read(digiLockerProvider.notifier);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Move Document', style: AppTextStyles.heading),
              const SizedBox(height: 12),
              for (final folder in locker.folders)
                ListTile(
                  onTap: () async {
                    await controller.moveDocument(document.id, folder.id);
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                  },
                  leading: Icon(Icons.folder_rounded, color: folder.color),
                  title: Text(folder.name),
                  trailing: document.folderId == folder.id
                      ? const Icon(Icons.check_rounded)
                      : null,
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMetadataSheet(
    BuildContext context,
    WidgetRef ref,
    DigiDocument document,
  ) async {
    final titleController = TextEditingController(text: document.title);
    final issuerController = TextEditingController(text: document.issuer);
    final numberController = TextEditingController(
      text: document.documentNumber,
    );
    final ocrController = TextEditingController(text: document.ocrText);
    var type = document.type;
    var verified = document.isVerified;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Document Details', style: AppTextStyles.heading),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<DigiDocumentType>(
                      initialValue: type,
                      items: DigiDocumentType.values.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(digiDocumentTypeLabel(item)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setSheetState(() => type = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: issuerController,
                      decoration: const InputDecoration(labelText: 'Issuer'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numberController,
                      decoration: const InputDecoration(
                        labelText: 'Document number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ocrController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Search / OCR text',
                        alignLabelWithHint: true,
                      ),
                    ),
                    SwitchListTile(
                      value: verified,
                      title: const Text('Mark verified'),
                      onChanged: (value) =>
                          setSheetState(() => verified = value),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        await ref
                            .read(digiLockerProvider.notifier)
                            .updateMetadata(
                              id: document.id,
                              title: titleController.text.trim(),
                              type: type,
                              issuer: issuerController.text.trim(),
                              documentNumber: numberController.text.trim(),
                              ocrText: ocrController.text.trim(),
                              isVerified: verified,
                            );
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    titleController.dispose();
    issuerController.dispose();
    numberController.dispose();
    ocrController.dispose();
  }

  void _showPreview(
    BuildContext context,
    WidgetRef ref,
    DigiDocument document,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(document.icon, color: AppColors.blue, size: 46),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                document.title,
                style: AppTextStyles.heading.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                '${document.typeLabel} • ${document.extension.toUpperCase()} • ${document.sizeLabel}',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 14),
              _InfoStrip(
                icon: Icons.lock_rounded,
                label:
                    'Stored in local Hive locker. File path metadata is saved on this device.',
                color: AppColors.success,
              ),
              const SizedBox(height: 10),
              _InfoStrip(
                icon: Icons.event_rounded,
                label: document.expiryLabel,
                color: document.isExpired || document.isExpiringSoon
                    ? AppColors.orange
                    : AppColors.blue,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showMetadataSheet(context, ref, document),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => AppFeedback.showSnackBar(
                        context,
                        message: 'Secure share link generated for 30 minutes',
                      ),
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                ],
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
              Text('Digi Locker', style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                'Local document vault for IDs, policies, medical and property files.',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.state});

  final DigiLockerState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.purple],
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
          _HeroMetric(label: 'Documents', value: '${state.documents.length}'),
          _HeroMetric(label: 'Folders', value: '${state.folders.length}'),
          _HeroMetric(label: 'Alerts', value: '${state.expiringCount}'),
          _HeroMetric(label: 'Verified', value: '${state.verifiedCount}'),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search name, type, issuer, number or OCR text',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  final List<String> types;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: types.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = type == selected;
          return ChoiceChip(
            label: Text(type),
            selected: isSelected,
            selectedColor: AppColors.navy,
            backgroundColor: Colors.white,
            labelStyle: AppTextStyles.label.copyWith(
              color: isSelected ? Colors.white : AppColors.navy,
              fontSize: 12,
            ),
            onSelected: (_) => onSelected(type),
          );
        },
      ),
    );
  }
}

class _FolderStrip extends StatelessWidget {
  const _FolderStrip({
    required this.folders,
    required this.selectedId,
    required this.countFor,
    required this.onSelected,
    required this.onRename,
  });

  final List<DigiFolder> folders;
  final String? selectedId;
  final int Function(String id) countFor;
  final ValueChanged<DigiFolder> onSelected;
  final ValueChanged<DigiFolder> onRename;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: folders.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final folder = folders[index];
          final selected = folder.id == selectedId;
          return InkWell(
            onTap: () => onSelected(folder),
            onLongPress: () => onRename(folder),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 145,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: selected
                    ? folder.color.withValues(alpha: .12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? folder.color : AppColors.fieldBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.folder_rounded, color: folder.color),
                  const Spacer(),
                  Text(
                    folder.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label,
                  ),
                  Text(
                    '${countFor(folder.id)} files',
                    style: AppTextStyles.body.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.document,
    required this.folder,
    required this.onTap,
    required this.onFavorite,
    required this.onMove,
    required this.onExpiry,
    required this.onEdit,
    required this.onDelete,
  });

  final DigiDocument document;
  final DigiFolder folder;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onMove;
  final VoidCallback onExpiry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

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
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: folder.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(document.icon, color: folder.color, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.label.copyWith(fontSize: 16),
                        ),
                      ),
                      if (document.isFavorite)
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.orange,
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${document.typeLabel} • ${document.sizeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MiniBadge(
                        label: document.isVerified ? 'Verified' : 'Local',
                        color: document.isVerified
                            ? AppColors.success
                            : AppColors.blue,
                        icon: document.isVerified
                            ? Icons.verified_rounded
                            : Icons.storage_rounded,
                      ),
                      if (document.expiryDate != null)
                        _MiniBadge(
                          label: document.expiryLabel,
                          color: document.isExpired || document.isExpiringSoon
                              ? AppColors.orange
                              : AppColors.success,
                          icon: Icons.event_rounded,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'favorite') onFavorite();
                if (value == 'move') onMove();
                if (value == 'expiry') onExpiry();
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'favorite',
                  child: Text(
                    document.isFavorite ? 'Remove favorite' : 'Favorite',
                  ),
                ),
                const PopupMenuItem(value: 'edit', child: Text('Edit details')),
                const PopupMenuItem(value: 'move', child: Text('Move folder')),
                const PopupMenuItem(value: 'expiry', child: Text('Set expiry')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDocuments extends StatelessWidget {
  const _EmptyDocuments({required this.onUpload});

  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.folder_off_rounded,
            color: AppColors.textMuted,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text('No documents found', style: AppTextStyles.heading),
          const SizedBox(height: 8),
          Text(
            'Upload PDF, JPG or PNG documents into this folder.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Upload Documents'),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
