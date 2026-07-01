import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../documents/providers/digi_locker_provider.dart';
import '../../files_vault/providers/files_vault_provider.dart';
import '../../passwords/providers/password_vault_provider.dart';
import '../models/ocr_scan_result.dart';
import '../providers/scanner_provider.dart';

class ScannerPage extends ConsumerWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scannerProvider);
    final controller = ref.read(scannerProvider.notifier);
    final latest = state.latest;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isScanning
            ? null
            : () => _scanFrom(context, ref, ImageSource.camera),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.document_scanner_rounded),
        label: const Text('Scan'),
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
                    _ScannerHero(
                      total: state.results.length,
                      scanning: state.isScanning,
                      onCamera: () =>
                          _scanFrom(context, ref, ImageSource.camera),
                      onGallery: () =>
                          _scanFrom(context, ref, ImageSource.gallery),
                    ),
                    const SizedBox(height: 18),
                    if (state.error != null)
                      _ErrorPanel(message: state.error!)
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
                      'Scan History',
                      style: AppTextStyles.heading.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
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
                          message: 'Scan deleted',
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

  Future<void> _scanFrom(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 92);
    if (image == null) return;
    final result = await ref
        .read(scannerProvider.notifier)
        .scanImagePath(image.path);
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: result?.hasText == true
          ? 'OCR scan complete'
          : 'Scan complete, no text found',
    );
  }

  void _copyText(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    AppFeedback.showSnackBar(context, message: 'OCR text copied');
  }

  Future<void> _saveToDigiLocker(
    BuildContext context,
    WidgetRef ref,
    OcrScanResult result,
  ) async {
    await ref
        .read(digiLockerProvider.notifier)
        .addScannedDocument(
          title: result.title,
          imagePath: result.imagePath,
          ocrText: result.rawText,
          documentType: result.documentType,
        );
    if (!context.mounted) return;
    AppFeedback.showSnackBar(context, message: 'Saved to Digi Locker');
  }

  Future<void> _saveToSecureNotes(
    BuildContext context,
    WidgetRef ref,
    OcrScanResult result,
  ) async {
    await ref
        .read(passwordVaultProvider.notifier)
        .saveNote(title: result.title, body: result.rawText);
    if (!context.mounted) return;
    AppFeedback.showSnackBar(context, message: 'Saved as secure note');
  }

  Future<void> _saveToFilesVault(
    BuildContext context,
    WidgetRef ref,
    OcrScanResult result,
  ) async {
    final file = File(result.imagePath);
    final size = await file.exists() ? await file.length() : 0;
    await ref
        .read(filesVaultProvider.notifier)
        .addImage(
          name: '${result.title}.jpg',
          path: result.imagePath,
          sizeBytes: size,
        );
    if (!context.mounted) return;
    AppFeedback.showSnackBar(
      context,
      message: 'Scan image saved to File Vault',
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
              Text('Scanner OCR', style: AppTextStyles.heading),
              const SizedBox(height: 4),
              Text(
                'On-device text extraction for documents, IDs, invoices and notes.',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
                  scanning ? 'Reading document...' : 'Smart OCR Engine',
                  style: AppTextStyles.label.copyWith(color: Colors.white),
                ),
              ),
              Text(
                '$total scans',
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
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: scanning ? null : onGallery,
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Gallery'),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.title,
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
              _Badge(label: result.documentType, color: AppColors.success),
              _Badge(
                label: '${result.lines.length} lines',
                color: AppColors.blue,
              ),
              _Badge(
                label: '${result.entities.length} entities',
                color: AppColors.purple,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (result.entities.isNotEmpty) ...[
            Text('Detected Fields', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.entities.take(10).map((entity) {
                return ActionChip(
                  label: Text('${entity.label}: ${entity.value}'),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: entity.value)),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],
          Text('Extracted Text', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 190),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.scaffold,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                result.rawText.isEmpty ? 'No text detected.' : result.rawText,
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
                label: const Text('Copy'),
              ),
              OutlinedButton.icon(
                onPressed: onSaveDigi,
                icon: const Icon(Icons.badge_rounded),
                label: const Text('Digi Locker'),
              ),
              OutlinedButton.icon(
                onPressed: onSaveNote,
                icon: const Icon(Icons.note_alt_rounded),
                label: const Text('Secure Note'),
              ),
              OutlinedButton.icon(
                onPressed: onSaveFile,
                icon: const Icon(Icons.folder_rounded),
                label: const Text('File Vault'),
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
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: CircleAvatar(
        backgroundColor: AppColors.success.withValues(alpha: .12),
        child: const Icon(
          Icons.document_scanner_rounded,
          color: AppColors.success,
        ),
      ),
      title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${result.documentType} - ${result.lines.length} lines'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'copy') onCopy();
          if (value == 'delete') onDelete();
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'copy', child: Text('Copy text')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Extracting text on device...'),
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
          Text('No OCR scans yet', style: AppTextStyles.heading),
          const SizedBox(height: 8),
          Text(
            'Scan from camera or gallery to extract searchable text.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
