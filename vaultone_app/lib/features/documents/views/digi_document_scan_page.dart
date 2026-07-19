import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../models/digi_document.dart';
import '../document_localizations.dart';
import '../providers/digi_locker_provider.dart';

class DigiDocumentScanArgs {
  const DigiDocumentScanArgs({
    required this.file,
    required this.folderId,
    required this.card,
  });

  final PlatformFile file;
  final String folderId;
  final DigiDocumentCard card;
}

class DigiDocumentScanPage extends ConsumerStatefulWidget {
  const DigiDocumentScanPage({super.key, required this.args});

  final DigiDocumentScanArgs args;

  @override
  ConsumerState<DigiDocumentScanPage> createState() =>
      _DigiDocumentScanPageState();
}

class _DigiDocumentScanPageState extends ConsumerState<DigiDocumentScanPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;
  late Future<DigiImportAnalysis> _analysisFuture;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _analysisFuture = ref
        .read(digiLockerProvider.notifier)
        .analyzeImportFile(
          widget.args.file,
          folderId: widget.args.folderId,
          card: widget.args.card,
        )
        .whenComplete(() {
          if (mounted) _scanController.stop();
        });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _save(DigiImportAnalysis analysis) async {
    if (_isSaving) return;
    var title = widget.args.card.title;
    if (analysis.isMismatch && widget.args.card.isCustom) {
      final useDetected = await _askForDetectedTitle(analysis);
      if (useDetected == null || !mounted) return;
      if (useDetected) {
        title = analysis.suggestedTitle;
        await ref
            .read(digiLockerProvider.notifier)
            .renameCustomCard(widget.args.card.id, title);
      }
    } else if (analysis.isMismatch && !widget.args.card.isCustom) {
      final proceed = await _confirmWrongSelection(analysis);
      if (proceed != true || !mounted) return;
    }

    setState(() => _isSaving = true);
    await ref
        .read(digiLockerProvider.notifier)
        .saveAnalyzedImport(
          analysis,
          titleOverride: title,
          // The user opened a specific built-in card. Keep every upload in
          // that card even when OCR guesses a different document type.
          typeOverride: widget.args.card.type,
        );
    if (!mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: analysis.hasOcrText
          ? context.l10n.tr('document_saved_ocr')
          : context.l10n.tr('document_saved'),
    );
    context.pop(true);
  }

  Future<bool?> _confirmWrongSelection(DigiImportAnalysis analysis) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.tr('wrong_document_selected')),
          content: Text(context.l10n.tr('wrong_document_message')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.tr('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.tr('save_anyway')),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _askForDetectedTitle(DigiImportAnalysis analysis) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.tr('use_detected_document')),
          content: Text(
            context.l10n.tr(
              'use_detected_prompt',
              args: {'title': _localizedAnalysisTitle(context, analysis)},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.l10n.tr('keep_current')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(context.l10n.tr('use_detected')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppPageAppBar(
        title: localizedDocumentCardTitle(context, widget.args.card),
        onBack: () => context.pop(false),
      ),
      body: SafeArea(
        child: FutureBuilder<DigiImportAnalysis>(
          future: _analysisFuture,
          builder: (context, snapshot) {
            final analysis = snapshot.data;
            final isLoading = snapshot.connectionState != ConnectionState.done;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScanPreview(
                    file: widget.args.file,
                    color: widget.args.card.color,
                    animation: _scanController,
                    isScanning: isLoading,
                  ),
                  const SizedBox(height: 18),
                  if (snapshot.hasError)
                    _StatusCard(
                      icon: Icons.error_rounded,
                      color: AppColors.orange,
                      title: context.l10n.tr('scan_failed'),
                      message: context.l10n.tr(
                        'scanner_failed',
                        args: {'error': snapshot.error.toString()},
                      ),
                    )
                  else if (isLoading)
                    _StatusCard(
                      icon: Icons.document_scanner_rounded,
                      color: widget.args.card.color,
                      title: context.l10n.tr('scanning_document'),
                      message: context.l10n.tr('scanning_document_message'),
                      loading: true,
                    )
                  else if (analysis != null) ...[
                    if (analysis.isMismatch)
                      _StatusCard(
                        icon: Icons.warning_rounded,
                        color: AppColors.orange,
                        title: context.l10n.tr('check_selection'),
                        message: context.l10n.tr('wrong_document_message'),
                      )
                    else
                      _StatusCard(
                        icon: Icons.verified_rounded,
                        color: AppColors.success,
                        title: context.l10n.tr('document_looks_good'),
                        message: context.l10n.tr(
                          'detected_document_message',
                          args: {
                            'title': _localizedAnalysisTitle(context, analysis),
                          },
                        ),
                      ),
                    const SizedBox(height: 14),
                    _DetailsCard(analysis: analysis),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : () => _save(analysis),
                        icon: _isSaving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: AppLoadingIndicator(
                                  size: 22,
                                  color: colors.onPrimary,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          context.l10n.tr(
                            _isSaving ? 'saving' : 'save_document',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton.filled(
          onPressed: onBack,
          style: IconButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.onSurface,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.l10n.tr('scan_title', args: {'title': title}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading.copyWith(fontSize: 22),
          ),
        ),
      ],
    );
  }
}

class _ScanPreview extends StatelessWidget {
  const _ScanPreview({
    required this.file,
    required this.color,
    required this.animation,
    required this.isScanning,
  });

  final PlatformFile file;
  final Color color;
  final Animation<double> animation;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final extension = (file.extension ?? '').toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png'].contains(extension);
    final path = file.path;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * .48,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: .34), width: 1.4),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (path != null && isImage && File(path).existsSync())
                Image.file(File(path), fit: BoxFit.cover)
              else
                _FilePlaceholder(file: file, color: color),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: .04),
                      color.withValues(alpha: .08),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                bottom: 12,
                left: 12,
                child: _MovingEdge(color: color, value: animation.value),
              ),
              Positioned(
                top: 12,
                bottom: 12,
                right: 12,
                child: _MovingEdge(
                  color: AppColors.purple,
                  value: 1 - animation.value,
                ),
              ),
              if (isScanning)
                Positioned(
                  left: 18,
                  right: 18,
                  top:
                      18 +
                      (MediaQuery.of(context).size.height *
                          .38 *
                          animation.value),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: .45),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MovingEdge extends StatelessWidget {
  const _MovingEdge({required this.color, required this.value});

  final Color color;
  final double value;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return SizedBox(
          width: 5,
          child: Stack(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Positioned(
                top: (height - 72) * value,
                child: Container(
                  width: 5,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilePlaceholder extends StatelessWidget {
  const _FilePlaceholder({required this.file, required this.color});

  final PlatformFile file;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final extension = (file.extension ?? '').toUpperCase();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          extension == 'PDF'
              ? Icons.picture_as_pdf_rounded
              : Icons.description_rounded,
          color: color,
          size: 76,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Text(
            file.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label,
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.loading = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          loading
              ? AppLoadingIndicator(color: color, size: 34)
              : Icon(icon, color: color, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.body.copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _localizedAnalysisTitle(
  BuildContext context,
  DigiImportAnalysis analysis,
) {
  return analysis.detectedType == DigiDocumentType.other
      ? analysis.suggestedTitle
      : localizedDocumentType(context, analysis.detectedType);
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.analysis});

  final DigiImportAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fields = {
      context.l10n.tr('detected'): _localizedAnalysisTitle(context, analysis),
      if (analysis.detectedType != DigiDocumentType.other)
        context.l10n.tr('type'): localizedDocumentType(
          context,
          analysis.detectedType,
        ),
      ...analysis.extractedFields,
    }.entries.take(6);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.tr('important_details'),
            style: AppTextStyles.heading.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 12),
          for (final entry in fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      localizedDocumentFieldLabel(context, entry.key),
                      style: AppTextStyles.body.copyWith(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: AppTextStyles.label.copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (analysis.extractedFields.isEmpty)
            Text(
              context.l10n.tr('ocr_fields_unclear'),
              style: AppTextStyles.body.copyWith(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
