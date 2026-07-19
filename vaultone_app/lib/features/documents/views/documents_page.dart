import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../document_localizations.dart';
import '../models/digi_document.dart';
import '../providers/digi_locker_provider.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locker = ref.watch(digiLockerProvider);
    final showSubscription = ref.watch(
      subscriptionProvider.select((state) => state.shouldShowSubscription),
    );
    final cards = [...defaultDigiDocumentCards, ...locker.customCards];

    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('digi_locker'),
        subtitle: context.l10n.tr('documents_identity_subtitle'),
        onBack: () => context.goNamed(AppRoutes.homeName),
      ),
      body: SafeArea(
        child: locker.isLoading
            ? const AppLoadingView(color: AppColors.blue, size: 48)
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.tr('digi_locker'),
                            style: AppTextStyles.heading.copyWith(fontSize: 24),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showCustomCardDialog(context, ref),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(context.l10n.tr('create')),
                        ),
                        if (showSubscription)
                          IconButton(
                            tooltip: context.l10n.tr('storage_full_upgrade'),
                            onPressed: () =>
                                context.pushNamed(AppRoutes.subscriptionsName),
                            icon: const Icon(Icons.workspace_premium_rounded),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _DocumentCardGrid(
                      cards: cards,
                      onTap: (card) => context.pushNamed(
                        AppRoutes.documentCardName,
                        pathParameters: {'cardId': card.id},
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _showCustomCardDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.tr('create_document_card')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: context.l10n.tr('document_card_example'),
            prefixIcon: const Icon(Icons.note_add_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: Text(context.l10n.tr('cancel')),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final card = await ref
                  .read(digiLockerProvider.notifier)
                  .createCustomCard(name);
              if (!dialogContext.mounted) return;
              dialogContext.pop();
              if (context.mounted) {
                context.pushNamed(
                  AppRoutes.documentCardName,
                  pathParameters: {'cardId': card.id},
                );
              }
            },
            child: Text(context.l10n.tr('create')),
          ),
        ],
      ),
    );
    controller.dispose();
  }
}

class _DocumentCardGrid extends StatelessWidget {
  const _DocumentCardGrid({required this.cards, required this.onTap});

  final List<DigiDocumentCard> cards;
  final ValueChanged<DigiDocumentCard> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 180,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return _DocumentTypeCard(card: card, onTap: () => onTap(card));
      },
    );
  }
}

class _DocumentTypeCard extends StatelessWidget {
  const _DocumentTypeCard({required this.card, required this.onTap});

  final DigiDocumentCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: card.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(card.icon, color: card.color, size: 22),
                ),
                const Spacer(),
                Icon(Icons.upload_file_rounded, color: card.color, size: 20),
              ],
            ),
            const Spacer(),
            Text(
              localizedDocumentCardTitle(context, card),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 3),
            Text(
              localizedDocumentCardSubtitle(context, card),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
