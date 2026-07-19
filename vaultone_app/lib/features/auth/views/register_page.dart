import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/app_language_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/light_auth_widgets.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../models/request/auth_requests.dart';
import '../../profile/models/response/policy_page_response.dart';
import '../../profile/repositories/policy_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_ui_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _submitted = false;
  final _passwordStrength = ValueNotifier<PasswordStrength>(
    PasswordStrength.from(''),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordStrength.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPasswordVisible = ref.watch(registerPasswordVisibleProvider);
    final isConfirmVisible = ref.watch(registerConfirmPasswordVisibleProvider);
    final termsAccepted = ref.watch(termsAcceptedProvider);
    final isSubmitting = ref.watch(
      authActionProvider.select((state) => state.isLoading),
    );
    return LightAuthShell(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Expanded(child: AuthBrandMark(logoSize: 58)),
            SizedBox(width: 10),
            Expanded(
              child: AuthHeroArt(kind: AuthHeroKind.register, height: 130),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.tr('create_account_title'),
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: '${context.l10n.tr('create_account_subtitle')} ',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.35,
            ),
            children: const [
              TextSpan(
                text: 'vaultOne',
                style: TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: AuthCard(
            child: Column(
              children: [
                AuthInput(
                  label: context.l10n.tr('full_name'),
                  hint: context.l10n.tr('full_name_hint'),
                  icon: Icons.person_outline_rounded,
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: _validateName,
                ),
                const SizedBox(height: 12),
                AuthInput(
                  label: context.l10n.tr('email_address'),
                  hint: context.l10n.tr('email_hint'),
                  icon: Icons.mail_outline_rounded,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                AuthInput(
                  label: context.l10n.tr('phone_number'),
                  hint: context.l10n.tr('phone_hint'),
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: _validatePhone,
                ),
                const SizedBox(height: 12),
                AuthInput(
                  label: context.l10n.tr('password'),
                  hint: context.l10n.tr('create_password_hint'),
                  icon: Icons.lock_outline_rounded,
                  controller: _passwordController,
                  obscureText: !isPasswordVisible,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: _validateStrongPassword,
                  onChanged: (value) =>
                      _passwordStrength.value = PasswordStrength.from(value),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        ref
                                .read(registerPasswordVisibleProvider.notifier)
                                .state =
                            !isPasswordVisible,
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<PasswordStrength>(
                  valueListenable: _passwordStrength,
                  builder: (context, strength, _) => Row(
                    children: [
                      for (var i = 0; i < 4; i++)
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                            decoration: BoxDecoration(
                              color: i < strength.score
                                  ? strength.color
                                  : const Color(0xFFE5E7EB),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Text(
                        context.l10n.tr(strength.label),
                        style: TextStyle(
                          color: strength.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AuthInput(
                  label: context.l10n.tr('confirm_password'),
                  hint: context.l10n.tr('confirm_password_required'),
                  icon: Icons.lock_outline_rounded,
                  controller: _confirmPasswordController,
                  obscureText: !isConfirmVisible,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: _validateConfirmPassword,
                  suffixIcon: IconButton(
                    onPressed: () =>
                        ref
                                .read(
                                  registerConfirmPasswordVisibleProvider
                                      .notifier,
                                )
                                .state =
                            !isConfirmVisible,
                    icon: Icon(
                      isConfirmVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      value: termsAccepted,
                      onChanged: (value) {
                        if (termsAccepted) {
                          ref.read(termsAcceptedProvider.notifier).state =
                              false;
                          return;
                        }
                        _showPolicyAcceptanceSheet();
                      },
                      activeColor: AppColors.purple,
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _showPolicyAcceptanceSheet,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text.rich(
                            TextSpan(
                              text: '${context.l10n.tr('agree_to')} ',
                              style: const TextStyle(
                                color: Color(0xFF2F3340),
                                fontSize: 12,
                              ),
                              children: [
                                TextSpan(
                                  text: context.l10n.tr('terms_of_service'),
                                  style: const TextStyle(
                                    color: AppColors.purple,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(text: ' ${context.l10n.tr('and')} '),
                                TextSpan(
                                  text: context.l10n.tr('privacy_policy'),
                                  style: const TextStyle(
                                    color: AppColors.purple,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GradientAuthButton(
                  label: context.l10n.tr('create_account'),
                  isLoading: isSubmitting,
                  loadingLabel: context.l10n.tr('creating'),
                  icon: Icons.person_add_alt_1_outlined,
                  onPressed: termsAccepted ? _createAccount : null,
                ),
                const SizedBox(height: 16),
                BottomAuthLink(
                  text: context.l10n.tr('already_have_account'),
                  action: context.l10n.tr('login'),
                  onTap: () => context.goNamed(AppRoutes.loginName),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAuthMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showPolicyAcceptanceSheet() async {
    final policyRepository = ref.read(policyRepositoryProvider);
    final languageCode = ref.read(appLanguageProvider).code;
    final policiesFuture = Future.wait([
      policyRepository.fetchPolicy(
        'terms-and-conditions',
        languageCode: languageCode,
      ),
      policyRepository.fetchPolicy('privacy', languageCode: languageCode),
    ]);

    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: .78,
          minChildSize: .45,
          maxChildSize: .92,
          builder: (context, scrollController) {
            return FutureBuilder<List<PolicyPageResponse>>(
              future: policiesFuture,
              builder: (context, snapshot) {
                final isLoading =
                    snapshot.connectionState != ConnectionState.done;
                final policies = snapshot.data ?? const <PolicyPageResponse>[];

                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 14, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.tr('terms_privacy_title'),
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: isLoading
                          ? const Center(
                              child: AppLoadingIndicator(
                                color: AppColors.purple,
                                size: 42,
                              ),
                            )
                          : snapshot.hasError
                          ? _PolicyError(
                              message: context.l10n.tr('policy_load_failed'),
                              onRetry: () {
                                Navigator.pop(context, false);
                                _showPolicyAcceptanceSheet();
                              },
                            )
                          : ListView(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              children: [
                                for (final policy in policies)
                                  _PolicyBlock(policy: policy),
                              ],
                            ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                        child: GradientAuthButton(
                          label: context.l10n.tr('agree_continue'),
                          icon: Icons.verified_user_outlined,
                          onPressed: isLoading || snapshot.hasError
                              ? null
                              : () => Navigator.pop(context, true),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (accepted ?? false) {
      ref.read(termsAcceptedProvider.notifier).state = true;
    }
  }

  Future<void> _createAccount() async {
    setState(() => _submitted = true);
    if (!ref.read(termsAcceptedProvider)) {
      _showAuthMessage(context, context.l10n.tr('accept_terms_required'));
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim().toLowerCase();
    final success = await ref
        .read(authActionProvider.notifier)
        .register(
          RegisterRequest(
            fullName: _nameController.text.trim(),
            email: email,
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            termsAccepted: ref.read(termsAcceptedProvider),
          ),
        );
    if (!mounted) return;
    if (success) {
      final otp = ref.read(authActionProvider).lastOtp;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            otp == null || otp.isEmpty
                ? context.l10n.tr('otp_sent_email')
                : context.l10n.tr('your_otp', args: {'otp': otp}),
          ),
          duration: AuthConstants.requestTimeout,
        ),
      );
      context.goNamed(
        AppRoutes.verifyOtpName,
        queryParameters: {'identity': email, 'purpose': 'register'},
      );
    } else {
      _showAuthMessage(
        context,
        ref.read(authActionProvider).error ??
            context.l10n.tr('registration_failed'),
      );
    }
  }

  String? _validateName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return context.l10n.tr('full_name_required');
    if (input.length < 3) return context.l10n.tr('full_name_hint');
    return null;
  }

  String? _validateEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return context.l10n.tr('email_required');
    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(input)) {
      return context.l10n.tr('email_invalid');
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return context.l10n.tr('phone_required');
    if (digits.length < 10 || digits.length > 13) {
      return context.l10n.tr('phone_invalid');
    }
    return null;
  }

  String? _validateStrongPassword(String? value) {
    if ((value ?? '').isEmpty) return context.l10n.tr('password_required');
    if (!AuthConstants.isStrongPassword(value!)) {
      return context.l10n.tr('strong_password_rule');
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) {
      return context.l10n.tr('confirm_password_required');
    }
    if (value != _passwordController.text) {
      return context.l10n.tr('passwords_mismatch');
    }
    return null;
  }
}

class _PolicyBlock extends StatelessWidget {
  const _PolicyBlock({required this.policy});

  final PolicyPageResponse policy;

  @override
  Widget build(BuildContext context) {
    if (policy.sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            policy.title,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final section in policy.sections) ...[
            Text(
              section.title,
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.body,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _PolicyError extends StatelessWidget {
  const _PolicyError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.purple),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

class PasswordStrength {
  const PasswordStrength(this.score, this.label, this.color);

  final int score;
  final String label;
  final Color color;

  static PasswordStrength from(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (AuthConstants.uppercasePattern.hasMatch(password)) score++;
    if (AuthConstants.digitPattern.hasMatch(password)) score++;
    if (AuthConstants.specialCharacterPattern.hasMatch(password)) score++;
    if (password.isEmpty) {
      return const PasswordStrength(0, 'strength_empty', Color(0xFF9CA3AF));
    }
    if (score <= 1) {
      return const PasswordStrength(1, 'strength_weak', Color(0xFFDC2626));
    }
    if (score == 2) {
      return const PasswordStrength(2, 'strength_fair', Color(0xFFF59E0B));
    }
    if (score == 3) {
      return const PasswordStrength(3, 'strength_good', Color(0xFF2563EB));
    }
    return const PasswordStrength(4, 'strength_strong', Color(0xFF16B46F));
  }
}
