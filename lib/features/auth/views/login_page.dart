import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/light_auth_widgets.dart';
import '../providers/auth_ui_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();
  var _submitted = false;

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPasswordVisible = ref.watch(loginPasswordVisibleProvider);
    final rememberMe = ref.watch(rememberMeProvider);

    return LightAuthShell(
      showBack: false,
      children: [
        const SizedBox(height: 10),
        const AuthBrandMark(center: true, logoSize: 76),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Secure Everything. Access Anywhere.',
            style: TextStyle(
              color: AppColors.purple,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome Back',
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text(
          'Login to continue to your secure vault',
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 18),
        Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: AuthCard(
            child: Column(
            children: [
              AuthInput(
                label: 'Email or Phone',
                hint: 'Enter email or phone number',
                icon: Icons.mail_outline_rounded,
                controller: _identityController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
                validator: _validateEmailOrPhone,
              ),
              const SizedBox(height: 20),
              AuthInput(
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                validator: _validatePassword,
                suffixIcon: IconButton(
                  onPressed: () =>
                      ref.read(loginPasswordVisibleProvider.notifier).state =
                          !isPasswordVisible,
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    onChanged: (value) =>
                        ref.read(rememberMeProvider.notifier).state =
                            value ?? false,
                    activeColor: AppColors.purple,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    'Remember me',
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFF2F3340),
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        context.goNamed(AppRoutes.forgotPasswordName),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GradientAuthButton(
                label: 'Login Securely',
                icon: Icons.lock_outline_rounded,
                onPressed: _login,
              ),
            ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const DividerText('Or continue with'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SocialButton(
                label: 'Google',
                onPressed: () =>
                    _showAuthMessage(context, 'Google sign-in coming soon'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SocialButton(
                label: 'Apple',
                icon: Icons.apple,
                onPressed: () =>
                    _showAuthMessage(context, 'Apple sign-in coming soon'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SocialButton(
                label: 'Bio',
                icon: Icons.fingerprint_rounded,
                color: AppColors.blue,
                onPressed: () =>
                    _showAuthMessage(context, 'Biometric login coming soon'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        BottomAuthLink(
          text: "Don't have an account?",
          action: 'Register',
          onTap: () => context.goNamed(AppRoutes.registerName),
        ),
        const SizedBox(height: 18),
        const BottomSafeArt(),
      ],
    );
  }

  void _showAuthMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _login() {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.goNamed(AppRoutes.homeName);
  }

  String? _validateEmailOrPhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email or phone number is required';
    final isEmail = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(input);
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final isPhone = digits.length >= 10 && digits.length <= 13;
    if (!isEmail && !isPhone) return 'Enter a valid email or phone number';
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required';
    if ((value ?? '').length < 8) return 'Password must be at least 8 characters';
    return null;
  }
}
