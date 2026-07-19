import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../models/digi_document.dart';
import '../document_localizations.dart';
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
      return Scaffold(
        body: Center(child: Text(context.l10n.tr('document_not_found'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizedDocumentTitle(context, doc)),
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
            _InfoTile(
              label: context.l10n.tr('type'),
              value: localizedDocumentType(context, doc.type),
            ),
            _InfoTile(label: context.l10n.tr('file'), value: doc.fileName),
            _InfoTile(label: context.l10n.tr('size'), value: doc.sizeLabel),
            _InfoTile(
              label: context.l10n.tr('issuer'),
              value: doc.issuer.isEmpty
                  ? '-'
                  : localizedDocumentIssuer(context, doc.issuer),
            ),
            _InfoTile(
              label: context.l10n.tr('document_number'),
              value: doc.documentNumber.isEmpty ? '-' : doc.documentNumber,
            ),
            _InfoTile(
              label: context.l10n.tr('expiry'),
              value: localizedExpiryLabel(context, doc.expiryDate),
            ),
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
                  label: Text(context.l10n.tr('expiry')),
                ),
                OutlinedButton.icon(
                  onPressed: () => AppFeedback.showSnackBar(
                    context,
                    message: context.l10n.tr('share_link_generated'),
                  ),
                  icon: const Icon(Icons.ios_share_rounded),
                  label: Text(context.l10n.tr('share')),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.folder_rounded),
                  label: Text(context.l10n.tr('back')),
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
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
            localizedDocumentTitle(context, document),
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.tr(
              document.isVerified
                  ? 'verified_document'
                  : 'local_secure_document',
            ),
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
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      tileColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(label, style: AppTextStyles.label),
      subtitle: Text(value),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
