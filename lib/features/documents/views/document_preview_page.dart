import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../models/digi_document.dart';
import '../providers/digi_locker_provider.dart';

class DocumentPreviewPage extends ConsumerWidget {
  const DocumentPreviewPage({super.key, required this.documentId});

  final String documentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locker = ref.watch(digiLockerProvider);
    final controller = ref.read(digiLockerProvider.notifier);
    final doc = locker.documents
        .where((item) => item.id == documentId)
        .firstOrNull;

    if (doc == null) {
      return const Scaffold(body: Center(child: Text('Document not found')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title),
        actions: [
          IconButton(
            onPressed: () => controller.toggleFavorite(doc.id),
            icon: Icon(
              doc.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            _PreviewHero(document: doc),
            const SizedBox(height: 18),
            _InfoTile(label: 'Type', value: doc.typeLabel),
            _InfoTile(label: 'File', value: doc.fileName),
            _InfoTile(label: 'Size', value: doc.sizeLabel),
            _InfoTile(
              label: 'Issuer',
              value: doc.issuer.isEmpty ? '-' : doc.issuer,
            ),
            _InfoTile(
              label: 'Document No.',
              value: doc.documentNumber.isEmpty ? '-' : doc.documentNumber,
            ),
            _InfoTile(label: 'Expiry', value: doc.expiryLabel),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate:
                          doc.expiryDate ??
                          DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2045),
                    );
                    if (date != null) {
                      await controller.updateExpiry(doc.id, date);
                    }
                  },
                  icon: const Icon(Icons.event_rounded),
                  label: const Text('Expiry'),
                ),
                OutlinedButton.icon(
                  onPressed: () => AppFeedback.showSnackBar(
                    context,
                    message: 'Secure share link generated for 30 minutes',
                  ),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: const Text('Share'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.folder_rounded),
                  label: const Text('Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewHero extends StatelessWidget {
  const _PreviewHero({required this.document});

  final DigiDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.fieldBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(document.icon, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 16),
          Text(
            document.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            document.isVerified ? 'Verified document' : 'Local secure document',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(label, style: AppTextStyles.label),
      subtitle: Text(value),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
