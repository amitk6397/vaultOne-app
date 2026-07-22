import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../providers/profile_provider.dart';
import '../repositories/profile_repository.dart';

class DeleteAccountPage extends ConsumerStatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  ConsumerState<DeleteAccountPage> createState() =>
      _DeleteAccountPageState();
}

class _DeleteAccountPageState extends ConsumerState<DeleteAccountPage> {
  static const _reasons = <String, String>{
    'not_using': 'I no longer use VaultOne',
    'privacy': 'Privacy or data concerns',
    'technical_issues': 'Technical issues',
    'too_expensive': 'Subscription is too expensive',
    'switching_service': 'I am switching to another service',
    'other': 'Other reason',
  };

  final _details = TextEditingController();
  String? _reason;
  bool _confirmed = false;
  bool _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _confirmed &&
        _reason != null &&
        (_reason != 'other' || _details.text.trim().length >= 3) &&
        !_submitting;
    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('delete_account'),
        subtitle: 'Send a request for administrator review',
        onBack: () => context.goNamed(AppRoutes.profileName),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: .2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    child: Icon(Icons.person_remove_alt_1_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Before you continue',
                          style: AppTextStyles.label.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your account is not deleted immediately. The request is sent to the admin panel for review. You will be logged out after it is submitted.',
                          style: AppTextStyles.body.copyWith(height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Why are you leaving?', style: AppTextStyles.heading),
            const SizedBox(height: 6),
            Text(
              'Choose the closest reason. This helps us improve VaultOne.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 12),
            for (final entry in _reasons.entries)
              RadioListTile<String>(
                value: entry.key,
                groupValue: _reason,
                onChanged: (value) => setState(() => _reason = value),
                title: Text(entry.value),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.danger,
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _details,
              onChanged: (_) => setState(() {}),
              maxLength: 1000,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: _reason == 'other'
                    ? 'Tell us your reason (required)'
                    : 'Additional details (optional)',
                hintText: 'You can enter your own feedback here',
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (value) =>
                  setState(() => _confirmed = value ?? false),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.danger,
              title: Text(
                context.l10n.tr('delete_account_confirmation'),
                style: AppTextStyles.label,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: canSubmit ? _requestDelete : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.outbox_rounded),
              label: const Text('Submit request and logout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestDelete() async {
    setState(() => _submitting = true);
    try {
      await ref.read(profileRepositoryProvider).requestAccountDeletion(
            reasonCode: _reason!,
            reasonText: _details.text.trim().isEmpty
                ? null
                : _details.text.trim(),
          );
      await ref
          .read(profileProvider.notifier)
          .clearSession(deleteSavedData: true);
      if (!mounted) return;
      AppFeedback.showSnackBar(
        context,
        message: context.l10n.tr('delete_account_request_submitted'),
      );
      context.goNamed(AppRoutes.loginName);
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showSnackBar(
        context,
        message: 'Could not submit the request: $error',
      );
      setState(() => _submitting = false);
    }
  }
}
