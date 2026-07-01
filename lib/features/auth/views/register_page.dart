import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/light_auth_widgets.dart';
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
  var _password = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPasswordVisible = ref.watch(registerPasswordVisibleProvider);
    final isConfirmVisible = ref.watch(registerConfirmPasswordVisibleProvider);
    final termsAccepted = ref.watch(termsAcceptedProvider);
    final strength = PasswordStrength.from(_password);

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
          'Create Your Account',
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        const Text.rich(
          TextSpan(
            text: 'Start securing your important\nthings with ',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.35,
            ),
            children: [
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
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                controller: _nameController,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: _validateName,
              ),
              const SizedBox(height: 12),
              AuthInput(
                label: 'Email Address',
                hint: 'Enter your email address',
                icon: Icons.mail_outline_rounded,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              AuthInput(
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: _validatePhone,
              ),
              const SizedBox(height: 12),
              AuthInput(
                label: 'Password',
                hint: 'Create a password',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => _validateStrongPassword(value, strength),
                onChanged: (value) => setState(() => _password = value),
                suffixIcon: IconButton(
                  onPressed: () =>
                      ref.read(registerPasswordVisibleProvider.notifier).state =
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
              Row(
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
                    strength.label,
                    style: TextStyle(
                      color: strength.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AuthInput(
                label: 'Confirm Password',
                hint: 'Confirm your password',
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
                                registerConfirmPasswordVisibleProvider.notifier,
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
                    onChanged: (value) =>
                        ref.read(termsAcceptedProvider.notifier).state =
                            value ?? false,
                    activeColor: AppColors.purple,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: 'I agree to the ',
                        style: TextStyle(
                          color: Color(0xFF2F3340),
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: AppColors.purple,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.purple,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GradientAuthButton(
                label: 'Create Account',
                icon: Icons.person_add_alt_1_outlined,
                onPressed: termsAccepted ? _createAccount : null,
              ),
              const SizedBox(height: 14),
              const DividerText('Or sign up with'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SocialButton(
                      label: 'Google',
                      onPressed: () => _showAuthMessage(
                        context,
                        'Google sign-up coming soon',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SocialButton(
                      label: 'Apple',
                      icon: Icons.apple,
                      onPressed: () => _showAuthMessage(
                        context,
                        'Apple sign-up coming soon',
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SocialButton(
                      label: 'Bio',
                      icon: Icons.fingerprint_rounded,
                      color: AppColors.blue,
                      onPressed: () => _showAuthMessage(
                        context,
                        'Biometric sign-up coming soon',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BottomAuthLink(
                text: 'Already have an account?',
                action: 'Login',
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

  void _createAccount() {
    setState(() => _submitted = true);
    if (!ref.read(termsAcceptedProvider)) {
      _showAuthMessage(context, 'Please accept Terms of Service and Privacy Policy');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account details validated')),
    );
    context.goNamed(AppRoutes.verifyOtpName);
  }

  String? _validateName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Full name is required';
    if (input.length < 3) return 'Enter your full name';
    return null;
  }

  String? _validateEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email address is required';
    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(input)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Phone number is required';
    if (digits.length < 10 || digits.length > 13) return 'Enter a valid phone number';
    return null;
  }

  String? _validateStrongPassword(String? value, PasswordStrength strength) {
    if ((value ?? '').isEmpty) return 'Password is required';
    if (strength.score < 4) {
      return 'Use 8+ chars with uppercase, number, and symbol';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
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
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    if (password.isEmpty) return const PasswordStrength(0, 'Empty', Color(0xFF9CA3AF));
    if (score <= 1) return const PasswordStrength(1, 'Weak', Color(0xFFDC2626));
    if (score == 2) return const PasswordStrength(2, 'Fair', Color(0xFFF59E0B));
    if (score == 3) return const PasswordStrength(3, 'Good', Color(0xFF2563EB));
    return const PasswordStrength(4, 'Strong', Color(0xFF16B46F));
  }
}
