import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/module_storage_sheet.dart';
import '../../../core/storage/module_storage_controller.dart';
import '../models/digi_document.dart';
import '../document_localizations.dart';
import '../providers/digi_locker_provider.dart';
import 'digi_document_scan_page.dart';

class DigiDocumentCardPage extends ConsumerWidget {
  const DigiDocumentCardPage({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locker = ref.watch(digiLockerProvider);
    final controller = ref.read(digiLockerProvider.notifier);
    final cards = [...defaultDigiDocumentCards, ...locker.customCards];
    final card = cards.firstWhere(
      (item) => item.id == cardId,
      orElse: () => defaultDigiDocumentCards.first,
    );
    final documents = controller.documentsForCard(card);

    return Scaffold(
      appBar: AppPageAppBar(
        title: localizedDocumentCardTitle(context, card),
        subtitle: localizedDocumentCardSubtitle(context, card),
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: locker.isLoading
            ? Center(
                child: AppLoadingIndicator(color: AppColors.blue, size: 48),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (documents.isEmpty)
                      _EmptyUploadTarget(
                        card: card,
                        onUpload: () => _upload(context, ref, card),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => _upload(context, ref, card),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(
                                context.l10n.tr('add_more_documents'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.tr(
                          'uploaded_documents_count',
                          args: {'count': documents.length},
                        ),
                        style: AppTextStyles.heading.copyWith(fontSize: 20),
                      ),
                      const SizedBox(height: 12),
                      for (final document in documents) ...[
                        _UploadedDocumentCard(
                          document: document,
                          card: card,
                          onOpen: () => context.pushNamed(
                            AppRoutes.documentPreviewName,
                            pathParameters: {'documentId': document.id},
                          ),
                          onDelete: () async {
                            await controller.deleteDocument(document.id);
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
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _upload(
    BuildContext context,
    WidgetRef ref,
    DigiDocumentCard card,
  ) async {
    final storage = await chooseModuleStorage(
      context,
      ref,
      StorageModule.digiLocker,
    );
    if (storage == null || !context.mounted) return;
    final folderId = ref.read(digiLockerProvider).folders.firstOrNull?.id;
    if (folderId == null) {
      AppFeedback.showSnackBar(
        context,
        message: context.l10n.tr('locker_not_ready'),
      );
      return;
    }
    final file = await _selectDocument(context);
    if (file == null || !context.mounted) return;
    await context.pushNamed<bool>(
      AppRoutes.documentScanName,
      extra: DigiDocumentScanArgs(file: file, folderId: folderId, card: card),
    );
    if (!context.mounted) return;
  }

  Future<PlatformFile?> _selectDocument(BuildContext context) async {
    final useCamera = Platform.isAndroid
        ? await showModalBottomSheet<bool>(
            context: context,
            showDragHandle: true,
            builder: (sheetContext) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.document_scanner_rounded),
                      title: Text(context.l10n.tr('scan_with_camera')),
                      subtitle: Text(
                        context.l10n.tr('camera_scan_description'),
                      ),
                      onTap: () => Navigator.pop(sheetContext, true),
                    ),
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf_rounded),
                      title: Text(context.l10n.tr('pick_pdf_or_image')),
                      subtitle: Text(context.l10n.tr('scan_selected_pages')),
                      onTap: () => Navigator.pop(sheetContext, false),
                    ),
                  ],
                ),
              ),
            ),
          )
        : false;
    if (useCamera == null) return null;
    if (!useCamera) {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
      );
      return result?.files.firstOrNull;
    }

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 2200,
      );
      if (image == null) return null;
      return PlatformFile(
        name: image.name,
        path: image.path,
        size: await File(image.path).length(),
      );
    } catch (error) {
      if (context.mounted) {
        AppFeedback.showSnackBar(
          context,
          message: context.l10n.tr('scanner_failed', args: {'error': error}),
        );
      }
    }
    return null;
  }
}

class _UploadedDocumentCard extends StatelessWidget {
  const _UploadedDocumentCard({
    required this.document,
    required this.card,
    required this.onOpen,
    required this.onDelete,
  });

  final DigiDocument document;
  final DigiDocumentCard card;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: card.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(document.icon, color: card.color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${document.extension.toUpperCase()} • ${document.sizeLabel}',
                    style: AppTextStyles.body.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    context.l10n.tr(
                      'uploaded_on',
                      args: {
                        'date':
                            '${document.addedAt.day}/${document.addedAt.month}/${document.addedAt.year}',
                      },
                    ),
                    style: AppTextStyles.body.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: context.l10n.tr('delete_document'),
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.card});

  final DigiDocumentCard card;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton.filled(
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: card.color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(card.icon, color: card.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizedDocumentCardTitle(context, card),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 3),
              Text(
                localizedDocumentCardSubtitle(context, card),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyUploadTarget extends StatelessWidget {
  const _EmptyUploadTarget({required this.card, required this.onUpload});

  final DigiDocumentCard card;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onUpload,
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        painter: _DottedBorderPainter(color: card.color),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * .56,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.upload_file_rounded,
                  color: card.color,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.tr('upload_document'),
                style: AppTextStyles.heading.copyWith(fontSize: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  const _DottedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 9), paint);
        distance += 17;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
