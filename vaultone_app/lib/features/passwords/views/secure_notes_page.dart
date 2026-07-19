import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../models/secure_note.dart';
import '../providers/password_vault_provider.dart';
import '../../scanner/repositories/ai_ocr_repository.dart';

class SecureNotesPage extends ConsumerWidget {
  const SecureNotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final vault = ref.watch(passwordVaultProvider);
    final controller = ref.read(passwordVaultProvider.notifier);

    return Scaffold(
      appBar: AppPageAppBar(
        title: 'Secure Notes',
        subtitle: 'Private notes stored locally with your vault.',
        onBack: () => context.goNamed(AppRoutes.passwordsName),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNoteSheet(context, ref, controller),
        tooltip: 'New Note',
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: const Icon(Icons.note_add_rounded),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (vault.notes.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(child: _EmptyNotes()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                sliver: SliverList.builder(
                  itemCount: vault.notes.length,
                  itemBuilder: (context, index) {
                    final note = vault.notes[index];
                    return _NoteCard(
                      note: note,
                      onEdit: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => _SecureNoteEditorPage(
                            note: note,
                            controller: controller,
                          ),
                        ),
                      ),
                      onDelete: () async {
                        await controller.deleteNote(note.id);
                        if (!context.mounted) return;
                        AppFeedback.showSnackBar(
                          context,
                          message: 'Note deleted',
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

  Future<void> _showNoteSheet(
    BuildContext context,
    WidgetRef ref,
    PasswordVaultController controller, [
    SecureNote? note,
  ]) async {
    final titleController = TextEditingController(text: note?.title ?? '');
    final bodyController = TextEditingController(text: note?.body ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note == null ? 'New Secure Note' : 'Edit Secure Note',
                style: AppTextStyles.heading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 16),
              if (note == null) ...[
                OutlinedButton.icon(
                  onPressed: () async {
                    final source = await showModalBottomSheet<ImageSource>(
                      context: context,
                      builder: (sourceContext) => SafeArea(
                        child: Wrap(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.camera_alt_rounded),
                              title: const Text('Take photo'),
                              onTap: () => Navigator.pop(
                                sourceContext,
                                ImageSource.camera,
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.photo_library_rounded),
                              title: const Text('Choose from gallery'),
                              onTap: () => Navigator.pop(
                                sourceContext,
                                ImageSource.gallery,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                    if (source == null) return;
                    final image = await ImagePicker().pickImage(
                      source: source,
                      imageQuality: 88,
                      maxWidth: 2200,
                    );
                    if (image == null) return;
                    try {
                      final result = await ref
                          .read(aiOcrRepositoryProvider)
                          .extract(image.path, target: 'secure_note');
                      titleController.text = result.title;
                      bodyController.text = result.rawText;
                      if (result.title.trim().isEmpty ||
                          result.rawText.trim().isEmpty) {
                        throw Exception('AI could not read note text clearly');
                      }
                      await controller.saveNote(
                        title: result.title.trim(),
                        body: result.rawText.trim(),
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.document_scanner_rounded),
                  label: const Text('Scan note with AI'),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                minLines: 5,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.note_alt_rounded),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final body = bodyController.text.trim();
                  if (title.isEmpty || body.isEmpty) return;
                  await controller.saveNote(
                    id: note?.id,
                    title: title,
                    body: body,
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Note'),
              ),
            ],
          ),
        );
      },
    );
    titleController.dispose();
    bodyController.dispose();
  }
}

class _SecureNoteEditorPage extends StatefulWidget {
  const _SecureNoteEditorPage({required this.note, required this.controller});

  final SecureNote note;
  final PasswordVaultController controller;

  @override
  State<_SecureNoteEditorPage> createState() => _SecureNoteEditorPageState();
}

class _SecureNoteEditorPageState extends State<_SecureNoteEditorPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _bodyController = TextEditingController(text: widget.note.body);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (_saving || title.isEmpty || body.isEmpty) return;
    setState(() => _saving = true);
    await widget.controller.saveNote(
      id: widget.note.id,
      title: title,
      body: body,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Secure note',
          style: AppTextStyles.label.copyWith(fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Save note',
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: AppTextStyles.heading.copyWith(fontSize: 25, height: 1.2),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Title',
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.body.copyWith(
                    color: colors.onSurface,
                    fontSize: 16,
                    height: 1.55,
                  ),
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Start writing…',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  final SecureNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(18),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.note_alt_rounded, color: AppColors.purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note.title, style: AppTextStyles.label),
                const SizedBox(height: 6),
                Text(
                  note.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
        ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.note_add_rounded, size: 52, color: AppColors.purple),
          const SizedBox(height: 12),
          Text('No secure notes', style: AppTextStyles.heading),
          const SizedBox(height: 8),
          Text(
            'Create private notes for recovery codes, PIN hints and memos.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
