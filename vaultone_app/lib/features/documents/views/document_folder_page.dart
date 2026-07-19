import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../models/digi_document.dart';
import '../document_localizations.dart';
import '../providers/digi_locker_provider.dart';

class DocumentFolderPage extends ConsumerWidget {
  const DocumentFolderPage({super.key, required this.folderId});

  final String folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locker = ref.watch(digiLockerProvider);
    final controller = ref.read(digiLockerProvider.notifier);
    final folder = controller.folderById(folderId);
    final docs = controller.filteredDocuments(
      query: '',
      type: 'All',
      folderId: folderId,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(folder?.name ?? context.l10n.tr('folder')),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed(AppRoutes.documentAlertsName),
            icon: const Icon(Icons.notifications_active_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: locker.isLoading
            ? Center(
                child: AppLoadingIndicator(color: AppColors.blue, size: 48),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                children: [
                  _FolderHero(folder: folder, count: docs.length),
                  const SizedBox(height: 18),
                  Text(
                    context.l10n.tr('folder_documents'),
                    style: AppTextStyles.heading.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  if (docs.isEmpty)
                    const _EmptyFolder()
                  else
                    for (final doc in docs) ...[
                      _FolderDocTile(
                        document: doc,
                        color: folder?.color ?? AppColors.blue,
                        onTap: () => context.pushNamed(
                          AppRoutes.documentPreviewName,
                          pathParameters: {'documentId': doc.id},
                        ),
                        onDelete: () async {
                          await controller.deleteDocument(doc.id);
                          if (!context.mounted) return;
                          AppFeedback.showSnackBar(
                            context,
                            message: context.l10n.tr('document_deleted'),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
      ),
    );
  }
}

class _FolderHero extends StatelessWidget {
  const _FolderHero({required this.folder, required this.count});

  final DigiFolder? folder;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = folder?.color ?? AppColors.blue;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_rounded, color: Colors.white, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  folder?.name ?? context.l10n.tr('folder'),
                  style: AppTextStyles.heading.copyWith(color: Colors.white),
                ),
                Text(
                  context.l10n.tr(
                    'secure_documents_count',
                    args: {'count': count},
                  ),
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: .76),
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

class _FolderDocTile extends StatelessWidget {
  const _FolderDocTile({
    required this.document,
    required this.color,
    required this.onTap,
    required this.onDelete,
  });

  final DigiDocument document;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      tileColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: .12),
        child: Icon(document.icon, color: color),
      ),
      title: Text(
        localizedDocumentTitle(context, document),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${localizedDocumentType(context, document.type)} - ${document.sizeLabel}',
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline_rounded),
        color: AppColors.danger,
      ),
    );
  }
}

class _EmptyFolder extends StatelessWidget {
  const _EmptyFolder();

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
          const Icon(Icons.folder_off_rounded, size: 52),
          const SizedBox(height: 12),
          Text(
            context.l10n.tr('no_documents_here'),
            style: AppTextStyles.heading,
          ),
        ],
      ),
    );
  }
}
