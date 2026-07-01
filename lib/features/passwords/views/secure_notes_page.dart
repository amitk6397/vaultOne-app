import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../models/secure_note.dart';
import '../providers/password_vault_provider.dart';

class SecureNotesPage extends ConsumerWidget {
  const SecureNotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(passwordVaultProvider);
    final controller = ref.read(passwordVaultProvider.notifier);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNoteSheet(context, controller),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Note'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    IconButton.filled(
                      onPressed: () => context.goNamed(AppRoutes.passwordsName),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Secure Notes', style: AppTextStyles.heading),
                          const SizedBox(height: 4),
                          Text(
                            'Private notes stored locally with your vault.',
                            style: AppTextStyles.body.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                      onEdit: () => _showNoteSheet(context, controller, note),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.fieldBorder),
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
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder),
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
