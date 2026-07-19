import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../models/subscription_models.dart';
import '../providers/subscription_provider.dart';

class PaymentVerificationPage extends ConsumerStatefulWidget {
  const PaymentVerificationPage({super.key, required this.payment});

  final UpiPaymentRequest payment;

  @override
  ConsumerState<PaymentVerificationPage> createState() =>
      _PaymentVerificationPageState();
}

class _PaymentVerificationPageState
    extends ConsumerState<PaymentVerificationPage> {
  final TextEditingController _utrController = TextEditingController();
  late final TextEditingController _amountController;

  File? _screenshot;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.payment.amountInr.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _utrController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tr('verify_payment'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              context.l10n.tr('payment_completed'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _PaymentSummary(payment: widget.payment),
            const SizedBox(height: 12),
            Text(context.l10n.tr('payment_pending_description')),
            const SizedBox(height: 20),
            TextField(
              controller: _utrController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: context.l10n.tr('utr_reference'),
                helperText: context.l10n.tr('utr_helper'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: context.l10n.tr('paid_amount_inr'),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: state.processing ? null : _pickScreenshot,
              icon: const Icon(Icons.image_rounded),
              label: Text(
                _screenshot == null
                    ? context.l10n.tr('select_payment_screenshot')
                    : _screenshot!.uri.pathSegments.last,
              ),
            ),
            if (state.error != null) ...[
              const SizedBox(height: 10),
              Text(
                context.l10n.tr(
                  'subscription_error_detail',
                  args: {'error': state.error!},
                ),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: state.processing ? null : _submit,
              child: Text(
                context.l10n.tr(
                  state.processing ? 'submitting' : 'submit_for_verification',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickScreenshot() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;
    setState(() => _screenshot = File(path));
  }

  Future<void> _submit() async {
    final utr = _utrController.text.trim();
    final paidAmount = double.tryParse(_amountController.text.trim());
    final screenshot = _screenshot;

    if (utr.length < 8 || paidAmount == null || screenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.tr('payment_validation_error'))),
      );
      return;
    }

    final submitted = await ref
        .read(subscriptionProvider.notifier)
        .submit(
          payment: widget.payment,
          utr: utr,
          amount: paidAmount,
          screenshot: screenshot,
        );

    if (!mounted || !submitted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.hourglass_top_rounded),
        title: Text(context.l10n.tr('pending_verification')),
        content: Text(context.l10n.tr('payment_proof_received')),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.tr('done')),
          ),
        ],
      ),
    );

    if (mounted) context.pop();
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.payment});

  final UpiPaymentRequest payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.tr(
                'payment_order',
                args: {'order': payment.orderId},
              ),
            ),
            Text(
              context.l10n.tr(
                'payment_payee',
                args: {'payee': payment.receiverName},
              ),
            ),
            Text(context.l10n.tr('payment_upi', args: {'upi': payment.upiId})),
            const SizedBox(height: 6),
            Text(
              context.l10n.tr(
                'exact_amount',
                args: {'amount': payment.amountInr.toStringAsFixed(2)},
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
