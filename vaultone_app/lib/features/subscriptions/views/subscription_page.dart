import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../models/subscription_models.dart';
import '../providers/subscription_provider.dart';

class SubscriptionPage extends ConsumerWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionProvider);
    final controller = ref.read(subscriptionProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(context.l10n.tr('plans_and_storage')),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: context.l10n.tr('refresh'),
            onPressed: state.loading ? null : controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.loading
          ? const AppLoadingView()
          : RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  const _SubscriptionHero(),
                  const SizedBox(height: 16),
                  if (state.error != null)
                    _MessageBanner(
                      text: context.l10n.tr(
                        'subscription_error_detail',
                        args: {'error': state.error!},
                      ),
                      color: Theme.of(context).colorScheme.error,
                    ),
                  if (state.activeSubscription != null)
                    _ActiveSubscriptionCard(
                      subscription: state.activeSubscription!,
                    ),
                  if (state.storage != null)
                    _StorageUsageCard(storage: state.storage!),
                  for (final offer in state.offers) _OfferBanner(offer: offer),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.tr('choose_your_plan'),
                          style: AppTextStyles.heading.copyWith(fontSize: 22),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 14,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 5),
                            Text(
                              context.l10n.tr('secure_upi'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.tr('plan_intro'),
                    style: AppTextStyles.body,
                  ),
                  const SizedBox(height: 16),
                  for (final plan in state.plans)
                    _PlanCard(
                      plan: plan,
                      busy: state.processingPlanId == plan.id,
                      disabled: state.processingPlanId == plan.id,
                      onBuy: () => _buyPlan(context, ref, plan),
                    ),
                  if (state.payments.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.tr('recent_payments'),
                      style: AppTextStyles.heading,
                    ),
                    const SizedBox(height: 8),
                    for (final payment in state.payments.take(5))
                      _PaymentStatusTile(payment: payment),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _buyPlan(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlan plan,
  ) async {
    final controller = ref.read(subscriptionProvider.notifier);
    final payment = await controller.createPayment(plan.id);
    if (payment == null || !context.mounted) return;

    final launched = await launchUrl(
      Uri.parse(payment.upiUri),
      mode: LaunchMode.externalApplication,
    );

    if (!context.mounted) return;
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('upi_app_open_failed'))),
      );
      return;
    }

    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.account_balance_wallet_rounded),
        title: Text(context.l10n.tr('complete_payment_upi')),
        content: Text(context.l10n.tr('complete_payment_upi_description')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.tr('pay_later')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.tr('i_completed_payment')),
          ),
        ],
      ),
    );

    if (completed == true && context.mounted) {
      await context.pushNamed<void>(
        AppRoutes.paymentVerificationName,
        extra: payment,
      );
    }

    await controller.load();
  }
}

class _SubscriptionHero extends StatelessWidget {
  const _SubscriptionHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF155EEF), Color(0xFF6D35F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: .24),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -18,
            child: Icon(
              Icons.cloud_done_rounded,
              size: 118,
              color: Colors.white.withValues(alpha: .1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBadge(),
              SizedBox(height: 18),
              Text(
                context.l10n.tr('vault_room_to_grow'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 10),
              Text(
                context.l10n.tr('private_cloud_description'),
                style: const TextStyle(
                  color: Color(0xFFDDE7FF),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _HeroFeature(Icons.lock_rounded, context.l10n.tr('private')),
                  _HeroFeature(
                    Icons.bolt_rounded,
                    context.l10n.tr('fast_upload'),
                  ),
                  _HeroFeature(
                    Icons.cloud_sync_rounded,
                    context.l10n.tr('cloud_backup'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      context.l10n.tr('vaultone_cloud'),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _HeroFeature extends StatelessWidget {
  const _HeroFeature(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 15, color: Colors.white),
      const SizedBox(width: 5),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _StorageUsageCard extends StatelessWidget {
  const _StorageUsageCard({required this.storage});
  final Map<String, dynamic> storage;

  @override
  Widget build(BuildContext context) {
    final used = (storage['used_bytes'] as num? ?? 0).toDouble();
    final limit = (storage['limit_bytes'] as num? ?? 1).toDouble();
    final percent = (used / limit).clamp(0.0, 1.0);
    String mb(double value) =>
        '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.cloud_rounded, color: AppColors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tr('cloud_storage'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        context.l10n.tr('synced_vault_data'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 9,
                backgroundColor: AppColors.blue.withValues(alpha: .1),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.tr('storage_used', args: {'size': mb(used)}),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.tr('storage_total', args: {'size': mb(limit)}),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner({required this.offer});
  final Map<String, dynamic> offer;
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.tertiaryContainer,
    margin: const EdgeInsets.only(bottom: 14),
    child: ListTile(
      leading: const Icon(Icons.local_offer_rounded),
      title: Text(
        offer['title']?.toString() ?? context.l10n.tr('special_offer'),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(offer['description']?.toString() ?? ''),
      trailing:
          offer['discount_percent'] == null || offer['discount_percent'] == 0
          ? null
          : Text(
              context.l10n.tr(
                'percent_off',
                args: {'percent': '${offer['discount_percent']}'},
              ),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
    ),
  );
}

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard({required this.subscription});

  final Map<String, dynamic> subscription;

  @override
  Widget build(BuildContext context) {
    final expiry = DateTime.tryParse(
      subscription['expires_at']?.toString() ?? '',
    );
    final storageGb = subscription['storage_gb'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.success,
            child: Icon(Icons.check_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.tr('active_plan'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  context.l10n.tr(
                    'gb_cloud_storage',
                    args: {'gb': '$storageGb'},
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (expiry != null)
                  Text(
                    context.l10n.tr(
                      'valid_until',
                      args: {
                        'date': MaterialLocalizations.of(
                          context,
                        ).formatShortDate(expiry),
                      },
                    ),
                    style: const TextStyle(fontSize: 11),
                  ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: AppColors.success),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.busy,
    required this.disabled,
    required this.onBuy,
  });

  final SubscriptionPlan plan;
  final bool busy;
  final bool disabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: plan.isPremium
          ? AppColors.purple.withValues(alpha: .055)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: plan.isPremium
            ? const BorderSide(color: AppColors.purple, width: 2)
            : BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (plan.isPremium)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  context.l10n.tr('recommended_best_value'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .5,
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: AppTextStyles.heading.copyWith(fontSize: 21),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        context.l10n.tr(
                          'gb_secure_storage',
                          args: {'gb': '${plan.storageGb}'},
                        ),
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${plan.priceInr.toStringAsFixed(0)}',
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 25,
                        color: plan.isPremium ? AppColors.purple : null,
                      ),
                    ),
                    Text(
                      context.l10n.tr(plan.periodKey),
                      style: AppTextStyles.body.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            if (plan.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                plan.description,
                style: AppTextStyles.body.copyWith(fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.savings_rounded,
                    size: 17,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.tr(
                      'price_per_gb',
                      args: {
                        'price': (plan.priceInr / plan.storageGb)
                            .toStringAsFixed(2),
                      },
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final feature in plan.features)
              _BenefitLine(
                icon: Icons.check_circle_rounded,
                text: feature,
                color: AppColors.success,
              ),
            if (plan.whyPurchase.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                context.l10n.tr('why_purchase_plan'),
                style: AppTextStyles.label,
              ),
              for (final reason in plan.whyPurchase)
                _BenefitLine(
                  icon: Icons.auto_awesome_rounded,
                  text: reason,
                  color: AppColors.purple,
                ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: disabled ? null : onBuy,
                style: FilledButton.styleFrom(
                  backgroundColor: plan.isPremium
                      ? AppColors.purple
                      : AppColors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: busy
                    ? const AppLoadingIndicator(size: 24)
                    : const Icon(Icons.arrow_forward_rounded, size: 19),
                label: Text(
                  busy
                      ? context.l10n.tr('please_wait')
                      : context.l10n.tr(
                          'choose_plan_name',
                          args: {'plan': plan.name},
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitLine extends StatelessWidget {
  const _BenefitLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _PaymentStatusTile extends StatelessWidget {
  const _PaymentStatusTile({required this.payment});

  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final statusKey = switch (payment.status.toLowerCase()) {
      'pending' || 'pending_verification' => 'payment_status_pending',
      'verified' || 'approved' || 'success' => 'payment_status_verified',
      'rejected' || 'failed' => 'payment_status_rejected',
      _ => null,
    };
    final statusText = statusKey == null
        ? payment.status.replaceAll('_', ' ')
        : context.l10n.tr(statusKey);
    return Card(
      child: ListTile(
        title: Text(payment.orderId),
        subtitle: Text(payment.rejectionReason ?? statusText),
        trailing: Text('₹${payment.amountInr.toStringAsFixed(2)}'),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}
