import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../file_localizations.dart';
import '../models/vault_file.dart';
import '../providers/files_vault_provider.dart';
import '../widgets/vault_file_card.dart';

enum VaultFilesMode { public, private, archive }

enum _FileFilter { all, documents, images, videos }

class VaultFilesListPage extends ConsumerStatefulWidget {
  const VaultFilesListPage({super.key, required this.mode});

  final VaultFilesMode mode;

  @override
  ConsumerState<VaultFilesListPage> createState() => _VaultFilesListPageState();
}

class _VaultFilesListPageState extends ConsumerState<VaultFilesListPage> {
  String _query = '';
  VaultFileSort _sort = VaultFileSort.newest;
  _FileFilter _filter = _FileFilter.all;
  bool _grid = true;
  String? _folderId;
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(filesVaultProvider);
    final controller = ref.read(filesVaultProvider.notifier);
    final files = _sorted(_filtered(context, state.files));

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? colors.surfaceContainerLowest
          : const Color(0xFFF8F7FF),
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
            toolbarHeight: 72,
            automaticallyImplyLeading: false,
            titleSpacing: 20,
            title: _Header(
              title: _title(context),
              count: files.length,
              sort: _sort,
              onBack: () => context.pop(),
              onSortChanged: (value) => setState(() => _sort = value),
            ),
            actions: [
              if (_selectedIds.isNotEmpty)
                IconButton(
                  tooltip: 'Move or copy',
                  onPressed: () =>
                      _moveOrCopy(context, controller, state.folders),
                  icon: Badge(
                    label: Text('${_selectedIds.length}'),
                    child: const Icon(Icons.drive_file_move_rounded),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Create new folder',
                  onPressed: () => _createFolder(context, controller),
                  icon: const Icon(Icons.create_new_folder_rounded),
                ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: TextField(
                            onChanged: (value) =>
                                setState(() => _query = value),
                            decoration: InputDecoration(
                              hintText: context.l10n.tr('search_files_hint'),
                              hintStyle: AppTextStyles.body.copyWith(
                                fontSize: 12,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 19,
                              ),
                              filled: true,
                              fillColor: colors.surface,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: colors.outlineVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _SquareButton(
                        icon: _grid
                            ? Icons.grid_view_rounded
                            : Icons.view_list_rounded,
                        color: AppColors.purple,
                        onTap: () => setState(() => _grid = !_grid),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  if (widget.mode != VaultFilesMode.archive) ...[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All folders'),
                            selected: _folderId == null,
                            onSelected: (_) => setState(() => _folderId = null),
                          ),
                          const SizedBox(width: 8),
                          for (final folder in state.folders) ...[
                            ChoiceChip(
                              avatar: const Icon(
                                Icons.folder_rounded,
                                size: 18,
                              ),
                              label: Text(folder.name),
                              selected: _folderId == folder.id,
                              onSelected: (_) =>
                                  setState(() => _folderId = folder.id),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),
                  ],
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _FileFilter.values.map((filter) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(_filterLabel(filter)),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                            showCheckmark: false,
                            labelStyle: AppTextStyles.body.copyWith(
                              fontSize: 11,
                              color: _filter == filter
                                  ? Colors.white
                                  : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            selectedColor: AppColors.purple,
                            backgroundColor: colors.surface,
                            side: BorderSide(
                              color: _filter == filter
                                  ? AppColors.purple
                                  : colors.outlineVariant,
                            ),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (state.isUploading) ...[
                    const SizedBox(height: 14),
                    const LinearProgressIndicator(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.tr(
                        'uploading_file',
                        args: {
                          'file':
                              state.uploadingFileName ??
                              context.l10n.tr('generic_file'),
                        },
                      ),
                      style: AppTextStyles.body.copyWith(fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          if (files.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyVault(mode: widget.mode, onAdd: () => context.pop()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
              sliver: _grid
                  ? SliverGrid.builder(
                      itemCount: files.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            mainAxisExtent: 220,
                          ),
                      itemBuilder: (context, index) =>
                          _card(context, controller, files[index], true),
                    )
                  : SliverList.separated(
                      itemCount: files.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _card(context, controller, files[index], false),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    FilesVaultController controller,
    VaultFile file,
    bool isGrid,
  ) {
    final selected = _selectedIds.contains(file.id);
    return GestureDetector(
      onLongPress: () => setState(() => _selectedIds.add(file.id)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.purple : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: VaultFileCard(
          file: file,
          isGrid: isGrid,
          onTap: () {
            if (_selectedIds.isNotEmpty) {
              setState(
                () => selected
                    ? _selectedIds.remove(file.id)
                    : _selectedIds.add(file.id),
              );
            } else {
              context.pushNamed(
                AppRoutes.filesVaultPreviewName,
                pathParameters: {'fileId': file.id},
              );
            }
          },
          onDelete: () async {
            await controller.deleteFile(file.id);
            if (!context.mounted) return;
            AppFeedback.showSnackBar(
              context,
              message: context.l10n.tr(
                'file_deleted_named',
                args: {'file': file.name},
              ),
            );
          },
          onFavorite: () => controller.toggleFavorite(file.id),
          onArchive: () => controller.archiveFile(file.id),
          onTogglePrivate: () => controller.togglePrivate(file.id),
        ),
      ),
    );
  }

  List<VaultFile> _filtered(BuildContext context, List<VaultFile> files) {
    final query = _query.trim().toLowerCase();
    return files.where((file) {
      final modeMatch = switch (widget.mode) {
        VaultFilesMode.public => !file.isArchived && !file.isPrivate,
        VaultFilesMode.private => !file.isArchived && file.isPrivate,
        VaultFilesMode.archive => file.isArchived,
      };
      final typeMatch = switch (_filter) {
        _FileFilter.all => true,
        _FileFilter.documents => const [
          VaultFileType.pdf,
          VaultFileType.document,
          VaultFileType.presentation,
        ].contains(file.type),
        _FileFilter.images => file.type == VaultFileType.image,
        _FileFilter.videos => file.type == VaultFileType.video,
      };
      if (!modeMatch || !typeMatch) return false;
      if (_folderId != null && file.folderId != _folderId) return false;
      if (query.isEmpty) return true;
      return file.name.toLowerCase().contains(query) ||
          file.extension.toLowerCase().contains(query) ||
          localizedVaultFileType(
            context,
            file.type,
          ).toLowerCase().contains(query) ||
          file.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  List<VaultFile> _sorted(List<VaultFile> files) {
    final items = [...files];
    items.sort((a, b) {
      if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
      return switch (_sort) {
        VaultFileSort.newest => b.updatedAt.compareTo(a.updatedAt),
        VaultFileSort.oldest => a.updatedAt.compareTo(b.updatedAt),
        VaultFileSort.name => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        VaultFileSort.sizeLargest => b.sizeBytes.compareTo(a.sizeBytes),
      };
    });
    return items;
  }

  String _title(BuildContext context) => switch (widget.mode) {
    VaultFilesMode.public => context.l10n.tr('all_files_title'),
    VaultFilesMode.private => context.l10n.tr('private_files'),
    VaultFilesMode.archive => context.l10n.tr('archive'),
  };

  String _filterLabel(_FileFilter filter) => switch (filter) {
    _FileFilter.all => 'All',
    _FileFilter.documents => 'Docs',
    _FileFilter.images => 'Images',
    _FileFilter.videos => 'Videos',
  };

  Future<void> _createFolder(
    BuildContext context,
    FilesVaultController controller,
  ) async {
    final textController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create new folder'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, textController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (name != null) await controller.createFolder(name);
  }

  Future<void> _moveOrCopy(
    BuildContext context,
    FilesVaultController controller,
    List<VaultFolder> folders,
  ) async {
    if (folders.isEmpty) {
      await _createFolder(context, controller);
      folders = ref.read(filesVaultProvider).folders;
    }
    if (folders.isEmpty || !context.mounted) return;
    final choice = await showModalBottomSheet<(String, bool)>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Choose folder'),
              subtitle: Text('Move or copy selected files'),
            ),
            for (final folder in folders)
              ListTile(
                leading: const Icon(Icons.folder_rounded),
                title: Text(folder.name),
                trailing: Wrap(
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, (folder.id, false)),
                      child: const Text('Move'),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, (folder.id, true)),
                      child: const Text('Copy'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    if (choice.$2) {
      await controller.copyFilesToFolder(_selectedIds, choice.$1);
    } else {
      await controller.moveFilesToFolder(_selectedIds, choice.$1);
    }
    if (mounted) setState(_selectedIds.clear);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.count,
    required this.sort,
    required this.onBack,
    required this.onSortChanged,
  });
  final String title;
  final int count;
  final VaultFileSort sort;
  final VoidCallback onBack;
  final ValueChanged<VaultFileSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading.copyWith(fontSize: 20)),
              Text(
                '$count files',
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: AppColors.purple,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<VaultFileSort>(
          initialValue: sort,
          onSelected: onSortChanged,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: VaultFileSort.newest,
              child: Text(context.l10n.tr('newest_first')),
            ),
            PopupMenuItem(
              value: VaultFileSort.oldest,
              child: Text(context.l10n.tr('oldest_first')),
            ),
            PopupMenuItem(
              value: VaultFileSort.name,
              child: Text(context.l10n.tr('name_az')),
            ),
            PopupMenuItem(
              value: VaultFileSort.sizeLargest,
              child: Text(context.l10n.tr('largest_first')),
            ),
          ],
          child: const _SquareButton(icon: Icons.more_vert_rounded),
        ),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, this.onTap, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: AppColors.shadow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: color ?? colors.onSurface),
        ),
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  const _EmptyVault({required this.mode, required this.onAdd});
  final VaultFilesMode mode;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isArchive = mode == VaultFilesMode.archive;
    final title = isArchive
        ? 'Nothing archived yet'
        : mode == VaultFilesMode.private
        ? 'No private files yet'
        : 'No files yet';
    final description = isArchive
        ? 'Archived files will appear here.\nMove files to archive to keep things tidy.'
        : mode == VaultFilesMode.private
        ? 'Private files will appear here.\nAdd files to keep them protected.'
        : 'Your files will appear here.\nAdd or import a file to get started.';
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 28),
      child: Column(
        children: [
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: .055),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  isArchive
                      ? Icons.inventory_2_outlined
                      : Icons.folder_outlined,
                  size: 42,
                  color: AppColors.purple.withValues(alpha: .55),
                ),
              ),
              const Positioned(
                right: -5,
                top: -7,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.purple,
                  child: Icon(Icons.add_rounded, size: 16, color: Colors.white),
                ),
              ),
              Positioned(
                right: -8,
                bottom: -7,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.purple.withValues(alpha: .10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            title,
            style: AppTextStyles.heading.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onAdd,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: Text(
                  'Add file',
                  style: AppTextStyles.button.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: 9),
              OutlinedButton.icon(
                onPressed: onAdd,
                style: OutlinedButton.styleFrom(
                  backgroundColor: colors.surface,
                  side: BorderSide(color: colors.outlineVariant),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.file_download_outlined,
                  size: 15,
                  color: AppColors.purple,
                ),
                label: Text(
                  'Import',
                  style: AppTextStyles.label.copyWith(
                    fontSize: 12,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ],
          ),
          if (isArchive) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outlineVariant),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 25,
                        height: 25,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.orange,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How archive works',
                        style: AppTextStyles.label.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  const _Tip(
                    'Long-press any file and tap Archive to move it here.',
                  ),
                  const _Tip(
                    'Archived files stay encrypted and safe inside your vault.',
                  ),
                  const _Tip('Restore anytime from the file menu.'),
                ],
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(Icons.circle, size: 5, color: AppColors.purple),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(fontSize: 9.5, height: 1.45),
          ),
        ),
      ],
    ),
  );
}
