import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../providers/password_vault_provider.dart';
import '../widgets/password_strength_bar.dart';

class PasswordGeneratorPage extends ConsumerWidget {
  const PasswordGeneratorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final password = ref.watch(generatedPasswordProvider);
    final length = ref.watch(passwordLengthProvider);
    final symbols = ref.watch(includeSymbolsProvider);
    final numbers = ref.watch(includeNumbersProvider);
    final uppercase = ref.watch(includeUppercaseProvider);

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
              Text('Password Generator', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                'Configure length, symbols, numbers, and uppercase toggles.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.fieldBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      password,
                      style: AppTextStyles.heading.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 18),
                    PasswordStrengthBar(password: password),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text('Length: ${length.round()}', style: AppTextStyles.label),
              Slider(
                value: length,
                min: 8,
                max: 32,
                divisions: 24,
                onChanged: (value) {
                  ref.read(passwordLengthProvider.notifier).state = value;
                },
              ),
              SwitchListTile(
                value: symbols,
                title: const Text('Include symbols'),
                onChanged: (value) {
                  ref.read(includeSymbolsProvider.notifier).state = value;
                },
              ),
              SwitchListTile(
                value: numbers,
                title: const Text('Include numbers'),
                onChanged: (value) {
                  ref.read(includeNumbersProvider.notifier).state = value;
                },
              ),
              SwitchListTile(
                value: uppercase,
                title: const Text('Include uppercase'),
                onChanged: (value) {
                  ref.read(includeUppercaseProvider.notifier).state = value;
                },
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Copy Password',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: password));
                  AppFeedback.showSnackBar(context, message: 'Password copied');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
