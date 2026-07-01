import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class BreachCheckPage extends StatelessWidget {
  const BreachCheckPage({super.key});

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
              Text('Breach Check', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                'Future module for HaveIBeenPwned API breach detection.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              const AppTextField(
                label: 'Email Address',
                hint: 'Enter email to check',
                icon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'Roadmap: connect breach-check API and show impacted sites here.',
                  style: AppTextStyles.label.copyWith(color: AppColors.orange),
                ),
              ),
              const Spacer(),
              AppPrimaryButton(label: 'Check Breaches', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
