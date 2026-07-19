import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../documents/providers/digi_locker_provider.dart';
import '../../files_vault/providers/files_vault_provider.dart';
import '../../passwords/providers/password_vault_provider.dart';
import '../../passwords/models/password_entry.dart';
import '../models/ocr_scan_result.dart';
import '../providers/scanner_provider.dart';

class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(scannerProvider);
    final controller = ref.read(scannerProvider.notifier);
    final latest = state.latest;

    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('ai_scanner'),
        subtitle: context.l10n.tr('ai_scanner_subtitle'),
        onBack: () => context.goNamed(AppRoutes.homeName),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: state.isScanning ? null : () => _startScan(context, ref),
        tooltip: context.l10n.tr('scan'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: const Icon(Icons.document_scanner_rounded),
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
                    _ScannerHero(
                      total: state.results.length,
                      scanning: state.isScanning,
                      onCamera: () =>
                          _startScan(context, ref, source: ImageSource.camera),
                      onGallery: () => _startScan(context, ref, pickFile: true),
                    ),
                    const SizedBox(height: 18),
                    if (state.error != null)
                      _ErrorPanel(
                        message: context.l10n.tr(
                          'scan_error_detail',
                          args: {'error': state.error!},
                        ),
                      )
                    else if (state.isScanning)
                      const _ScanningPanel()
                    else if (latest != null)
                      _ResultPanel(
                        result: latest,
                        onCopy: () => _copyText(context, latest.rawText),
                        onFavorite: () => controller.toggleFavorite(latest.id),
                        onSaveDigi: () =>
                            _saveToDigiLocker(context, ref, latest),
                        onSaveNote: () =>
                            _saveToSecureNotes(context, ref, latest),
                        onSaveFile: () =>
                            _saveToFilesVault(context, ref, latest),
                      ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.tr('scan_history'),
                      style: AppTextStyles.heading.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(child: AppLoadingView())
            else if (state.results.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyHistory(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                sliver: SliverList.separated(
                  itemCount: state.results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final result = state.results[index];
                    return _HistoryTile(
                      result: result,
                      onTap: () => _showResultSheet(context, ref, result),
                      onCopy: () => _copyText(context, result.rawText),
                      onDelete: () async {
                        await controller.delete(result.id);
                        if (!context.mounted) return;
                        AppFeedback.showSnackBar(
                          context,
                          message: context.l10n.tr('scan_deleted'),
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

  Future<void> _startScan(
    BuildContext context,
    WidgetRef ref, {
    ImageSource? source,
    bool pickFile = false,
  }) async {
    final target = await _chooseTarget(context);
    if (target == null || !context.mounted) return;
    String? path;
    if (pickFile) {
      final picked = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      path = picked?.files.single.path;
    } else if (source != null) {
      path = (await ImagePicker().pickImage(
        source: source,
        imageQuality: 92,
      ))?.path;
    } else {
      final selectedSource = await _chooseSource(context);
      if (selectedSource == null || !context.mounted) return;
      if (selectedSource == _ScanSource.camera) {
        path = (await ImagePicker().pickImage(
          source: ImageSource.camera,
          imageQuality: 92,
        ))?.path;
      } else {
        final picked = await FilePicker.pickFiles(
          allowMultiple: false,
          type: FileType.custom,
          allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
        );
        path = picked?.files.single.path;
      }
    }
    if (path == null) return;
    final controller = ref.read(scannerProvider.notifier);
    final result = await ref
        .read(scannerProvider.notifier)
        .scanImagePath(path, target: target.apiValue);
    if (!context.mounted) return;
    if (result?.hasText == true) {
      await _saveTarget(
        context,
        ref,
        target,
        result!,
        controller.lastAiResult?.fields ?? const {},
      );
    }
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: result?.hasText == true
          ? context.l10n.tr('ocr_scan_complete')
          : context.l10n.tr('scan_complete_no_text'),
    );
  }

  Future<_ScanTarget?> _chooseTarget(BuildContext context) {
    return showModalBottomSheet<_ScanTarget>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.tr('what_are_you_scanning'),
                style: AppTextStyles.heading,
              ),
              const SizedBox(height: 8),
              for (final target in _ScanTarget.values)
                ListTile(
                  leading: CircleAvatar(child: Icon(target.icon)),
                  title: Text(sheetContext.l10n.tr(target.labelKey)),
                  subtitle: Text(sheetContext.l10n.tr(target.subtitleKey)),
                  onTap: () => Navigator.pop(sheetContext, target),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<_ScanSource?> _chooseSource(BuildContext context) {
    return showModalBottomSheet<_ScanSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(sheetContext.l10n.tr('camera')),
              onTap: () => Navigator.pop(sheetContext, _ScanSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(sheetContext.l10n.tr('gallery_image_or_pdf')),
              onTap: () => Navigator.pop(sheetContext, _ScanSource.file),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTarget(
    BuildContext context,
    WidgetRef ref,
    _ScanTarget target,
    OcrScanResult result,
    Map<String, String> fields,
  ) async {
    switch (target) {
      case _ScanTarget.password:
        final site = (fields['site'] ?? result.title).trim();
        final username = (fields['username'] ?? '').trim();
        final password = fields['password'] ?? '';
        if (site.isEmpty || username.isEmpty || password.isEmpty) {
          AppFeedback.showSnackBar(
            context,
            message: context.l10n.tr('password_fields_incomplete'),
          );
          return;
        }
        await ref
            .read(passwordVaultProvider.notifier)
            .saveEntry(
              title: site,
              username: username,
              password: password,
              category: PasswordCategory.other,
            );
        break;
      case _ScanTarget.secureNote:
        await _saveToSecureNotes(context, ref, result);
        break;
      case _ScanTarget.document:
        await _saveToDigiLocker(context, ref, result);
        break;
    }
  }

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr('ocr_text_copied'),
    );
  }

  Future<void> _saveToDigiLocker(
    BuildContext context,
    WidgetRef ref,
    OcrScanResult result,
  ) async {
    await ref
        .read(digiLockerProvider.notifier)
        .addScannedDocument(
          title: _localizedScanTitle(context, result.title),
          imagePath: result.imagePath,
          ocrText: result.rawText,
          documentType: result.documentType,
        );
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr('saved_to_digi_locker'),
    );
  }

  Future<void> _saveToSecureNotes(
    BuildContext context,
    WidgetRef ref,
    OcrScanResult result,
  ) async {
    await ref
        .read(passwordVaultProvider.notifier)
        .saveNote(
          title: _localizedScanTitle(context, result.title),
          body: result.rawText,
        );
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr('saved_as_secure_note'),
    );
  }

  Future<void> _saveToFilesVault(
    BuildContext context,
    WidgetRef ref,
    OcrScanResult result,
  ) async {
    final localizedTitle = _localizedScanTitle(context, result.title);
    final file = File(result.imagePath);
    final size = await file.exists() ? await file.length() : 0;
    await ref
        .read(filesVaultProvider.notifier)
        .addImage(
          name: '$localizedTitle.jpg',
          path: result.imagePath,
          sizeBytes: size,
        );
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr('scan_saved_to_file_vault'),
    );
  }

  void _showResultSheet(
    BuildContext context,
    WidgetRef ref,
    OcrScanResult result,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: SingleChildScrollView(
            child: _ResultPanel(
              result: result,
              onCopy: () => _copyText(context, result.rawText),
              onFavorite: () =>
                  ref.read(scannerProvider.notifier).toggleFavorite(result.id),
              onSaveDigi: () => _saveToDigiLocker(context, ref, result),
              onSaveNote: () => _saveToSecureNotes(context, ref, result),
              onSaveFile: () => _saveToFilesVault(context, ref, result),
            ),
          ),
        );
      },
    );
  }
}

enum _ScanSource { camera, file }

String _localizedDocumentType(BuildContext context, String type) {
  final key = switch (type.trim().toLowerCase()) {
    'general' => 'document_type_general',
    'invoice' => 'document_type_invoice',
    'receipt' => 'document_type_receipt',
    'identity' || 'id' || 'identity card' => 'document_type_identity',
    'note' => 'document_type_note',
    _ => null,
  };
  return key == null ? type : context.l10n.tr(key);
}

String _localizedScanTitle(BuildContext context, String title) {
  final match = RegExp(r'^Scan (\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(title);
  if (match == null) return title;
  final date = DateTime(
    int.parse(match.group(3)!),
    int.parse(match.group(2)!),
    int.parse(match.group(1)!),
  );
  return context.l10n.tr(
    'scan_on_date',
    args: {'date': MaterialLocalizations.of(context).formatShortDate(date)},
  );
}

enum _ScanTarget {
  password,
  secureNote,
  document;

  String get apiValue => switch (this) {
    _ScanTarget.password => 'password',
    _ScanTarget.secureNote => 'secure_note',
    _ScanTarget.document => 'document',
  };

  String get labelKey => switch (this) {
    _ScanTarget.password => 'password',
    _ScanTarget.secureNote => 'secure_note',
    _ScanTarget.document => 'digi_locker_document',
  };

  String get subtitleKey => switch (this) {
    _ScanTarget.password => 'scan_password_subtitle',
    _ScanTarget.secureNote => 'scan_note_subtitle',
    _ScanTarget.document => 'scan_document_subtitle',
  };

  IconData get icon => switch (this) {
    _ScanTarget.password => Icons.password_rounded,
    _ScanTarget.secureNote => Icons.note_alt_rounded,
    _ScanTarget.document => Icons.folder_shared_rounded,
  };
}

class _ScannerHero extends StatelessWidget {
  const _ScannerHero({
    required this.total,
    required this.scanning,
    required this.onCamera,
    required this.onGallery,
  });

  final int total;
  final bool scanning;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.success],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.document_scanner_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.tr(
                    scanning ? 'reading_document' : 'smart_ocr_engine',
                  ),
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
              Text(
                context.l10n.tr('scan_count', args: {'count': '$total'}),
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: scanning ? null : onCamera,
                  icon: const Icon(Icons.photo_camera_rounded),
                  label: Text(context.l10n.tr('camera')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: scanning ? null : onGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: Text(context.l10n.tr('gallery')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.result,
    required this.onCopy,
    required this.onFavorite,
    required this.onSaveDigi,
    required this.onSaveNote,
    required this.onSaveFile,
  });

  final OcrScanResult result;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;
  final VoidCallback onSaveDigi;
  final VoidCallback onSaveNote;
  final VoidCallback onSaveFile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _localizedScanTitle(context, result.title),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading.copyWith(fontSize: 22),
                ),
              ),
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  result.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                ),
                color: AppColors.orange,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(
                label: _localizedDocumentType(context, result.documentType),
                color: AppColors.success,
              ),
              _Badge(
                label: context.l10n.tr(
                  'line_count',
                  args: {'count': '${result.lines.length}'},
                ),
                color: AppColors.blue,
              ),
              _Badge(
                label: context.l10n.tr(
                  'entity_count',
                  args: {'count': '${result.entities.length}'},
                ),
                color: AppColors.purple,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (result.entities.isNotEmpty) ...[
            Text(
              context.l10n.tr('detected_fields'),
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.entities.take(10).map((entity) {
                return ActionChip(
                  label: Text(
                    '${context.l10n.tr('ocr_entity_${entity.type.name}')}: ${entity.value}',
                  ),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: entity.value)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],
          Text(context.l10n.tr('extracted_text'), style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 190),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                result.rawText.isEmpty
                    ? context.l10n.tr('no_text_detected')
                    : result.rawText,
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: Text(context.l10n.tr('copy')),
              ),
              OutlinedButton.icon(
                onPressed: onSaveDigi,
                icon: const Icon(Icons.badge_rounded),
                label: Text(context.l10n.tr('digi_locker')),
              ),
              OutlinedButton.icon(
                onPressed: onSaveNote,
                icon: const Icon(Icons.note_alt_rounded),
                label: Text(context.l10n.tr('secure_note')),
              ),
              OutlinedButton.icon(
                onPressed: onSaveFile,
                icon: const Icon(Icons.folder_rounded),
                label: Text(context.l10n.tr('file_vault')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.result,
    required this.onTap,
    required this.onCopy,
    required this.onDelete,
  });

  final OcrScanResult result;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      tileColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant),
      ),
      leading: CircleAvatar(
        backgroundColor: AppColors.success.withValues(alpha: .12),
        child: const Icon(
          Icons.document_scanner_rounded,
          color: AppColors.success,
        ),
      ),
      title: Text(
        _localizedScanTitle(context, result.title),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        context.l10n.tr(
          'scan_history_subtitle',
          args: {
            'type': _localizedDocumentType(context, result.documentType),
            'count': '${result.lines.length}',
          },
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'copy') onCopy();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'copy',
            child: Text(context.l10n.tr('copy_text')),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(context.l10n.tr('delete')),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTextStyles.label.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}

class _ScanningPanel extends StatelessWidget {
  const _ScanningPanel();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          const AppLoadingIndicator(),
          const SizedBox(height: 16),
          Text(context.l10n.tr('extracting_text_on_device')),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: AppTextStyles.label.copyWith(color: AppColors.danger),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.document_scanner_outlined,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(context.l10n.tr('no_ocr_scans'), style: AppTextStyles.heading),
          const SizedBox(height: 8),
          Text(
            context.l10n.tr('no_ocr_scans_description'),
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
