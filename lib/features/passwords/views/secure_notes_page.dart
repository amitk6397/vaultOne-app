import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_primary_button.dart';

class SecureNotesPage extends StatelessWidget {
  const SecureNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton.filled(
                onPressed: () => context.goNamed(AppRoutes.passwordsName),
                style: IconButton.styleFrom(backgroundColor: Colors.white),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 18),
              Text('Secure Notes', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                'Encrypted free-text notes for PINs, secret questions, and private memos.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TextField(
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: 'Write secure note...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: AppColors.fieldBorder,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AppPrimaryButton(
                label: 'Save Note',
                onPressed: () {
                  AppFeedback.showSnackBar(
                    context,
                    message: 'Secure note saved',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
