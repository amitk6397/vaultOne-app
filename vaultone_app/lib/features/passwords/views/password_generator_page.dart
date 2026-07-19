import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_page_header.dart';
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

    void regenerate() {
      ref.read(generatedPasswordProvider.notifier).state = generatePassword(
        length: ref.read(passwordLengthProvider).round(),
        includeSymbols: ref.read(includeSymbolsProvider),
        includeNumbers: ref.read(includeNumbersProvider),
        includeUppercase: ref.read(includeUppercaseProvider),
      );
    }

    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr('password_generator'),
        subtitle: context.l10n.tr('password_generator_description'),
        onBack: () => context.goNamed(AppRoutes.passwordsName),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navy, AppColors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      password,
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    PasswordStrengthBar(password: password),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: regenerate,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text(context.l10n.tr('regenerate')),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: password));
                            AppFeedback.showSnackBar(
                              context,
                              message: context.l10n.tr('password_copied'),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                context.l10n.tr(
                  'password_length',
                  args: {'count': length.round()},
                ),
                style: AppTextStyles.label,
              ),
              Slider(
                value: length,
                min: 8,
                max: 40,
                divisions: 32,
                onChanged: (value) {
                  ref.read(passwordLengthProvider.notifier).state = value;
                  regenerate();
                },
              ),
              _SwitchTile(
                value: symbols,
                title: context.l10n.tr('include_symbols'),
                onChanged: (value) {
                  ref.read(includeSymbolsProvider.notifier).state = value;
                  regenerate();
                },
              ),
              _SwitchTile(
                value: numbers,
                title: context.l10n.tr('include_numbers'),
                onChanged: (value) {
                  ref.read(includeNumbersProvider.notifier).state = value;
                  regenerate();
                },
              ),
              _SwitchTile(
                value: uppercase,
                title: context.l10n.tr('include_uppercase'),
                onChanged: (value) {
                  ref.read(includeUppercaseProvider.notifier).state = value;
                  regenerate();
                },
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: context.l10n.tr('copy_password'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: password));
                  AppFeedback.showSnackBar(
                    context,
                    message: context.l10n.tr('password_copied'),
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

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.value,
    required this.title,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SwitchListTile(
      value: value,
      title: Text(title, style: AppTextStyles.label),
      onChanged: onChanged,
      tileColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
