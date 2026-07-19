import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../providers/digi_locker_provider.dart';
import '../document_localizations.dart';

class DocumentAlertsPage extends ConsumerWidget {
  const DocumentAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final docs =
        ref
            .watch(digiLockerProvider)
            .documents
            .where((doc) => doc.isExpired || doc.isExpiringSoon)
            .toList()
          ..sort((a, b) {
            final left = a.expiryDate ?? DateTime(2100);
            final right = b.expiryDate ?? DateTime(2100);
            return left.compareTo(right);
          });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tr('expiry_alerts'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.orange,
                    size: 42,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.l10n.tr(
                        'documents_need_attention',
                        args: {'count': docs.length},
                      ),
                      style: AppTextStyles.heading.copyWith(fontSize: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (docs.isEmpty)
              Text(
                context.l10n.tr('no_expiring_documents'),
                style: AppTextStyles.body,
              )
            else
              for (final doc in docs) ...[
                ListTile(
                  onTap: () => context.pushNamed(
                    AppRoutes.documentPreviewName,
                    pathParameters: {'documentId': doc.id},
                  ),
                  tileColor: colors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(
                    Icons.event_busy_rounded,
                    color: AppColors.orange,
                  ),
                  title: Text(localizedDocumentTitle(context, doc)),
                  subtitle: Text(localizedExpiryLabel(context, doc.expiryDate)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}
