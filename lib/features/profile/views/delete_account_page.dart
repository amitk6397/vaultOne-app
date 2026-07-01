import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';

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
      appBar: AppBar(
        title: const Text('Delete Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed(AppRoutes.profileName),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
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
            Text('Delete VaultOne account?', style: AppTextStyles.heading),
            const SizedBox(height: 10),
            Text(
              'This request will remove profile data, vault metadata, reminders and encrypted backups after verification.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 18),
            CheckboxListTile(
              value: _confirmed,
              onChanged: (value) => setState(() => _confirmed = value ?? false),
              contentPadding: EdgeInsets.zero,
              title: Text(
                'I understand this action is permanent.',
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
                label: const Text('Request Account Deletion'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _requestDelete() {
    AppFeedback.showSnackBar(
      context,
      message: 'Delete account request submitted',
    );
    context.goNamed(AppRoutes.profileName);
  }
}
