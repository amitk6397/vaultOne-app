import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('delete_account'),
        subtitle: context.l10n.tr('delete_account_subtitle'),
        onBack: () => context.goNamed(AppRoutes.profileName),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.danger.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppColors.danger,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.tr('delete_vaultone_account'),
                style: AppTextStyles.heading,
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.tr('delete_account_description'),
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 18),
              CheckboxListTile(
                value: _confirmed,
                onChanged: (value) =>
                    setState(() => _confirmed = value ?? false),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.l10n.tr('delete_account_confirmation'),
                  style: AppTextStyles.label,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _confirmed ? _requestDelete : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(context.l10n.tr('request_account_deletion')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _requestDelete() {
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr('delete_account_request_submitted'),
    );
    context.goNamed(AppRoutes.profileName);
  }
}
