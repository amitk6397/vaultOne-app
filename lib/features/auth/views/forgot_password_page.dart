import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/light_auth_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  var _submitted = false;

  @override
  void dispose() {
    _identityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LightAuthShell(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Expanded(child: AuthBrandMark(logoSize: 58)),
            SizedBox(width: 8),
            Expanded(
              child: AuthHeroArt(kind: AuthHeroKind.forgot, height: 140),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Reset Password',
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 12),
        Text(
          "No worries! Enter your email or\nphone number and we'll send you\ninstructions to reset your password.",
          style: AppTextStyles.body.copyWith(
            color: const Color(0xFF4B5563),
            fontSize: 13,
            height: 1.45,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthInput(
                label: 'Enter your email or phone number',
                hint: 'Email or phone number',
                icon: Icons.mail_outline_rounded,
                controller: _identityController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
                validator: _validateEmailOrPhone,
              ),
              const SizedBox(height: 16),
              GradientAuthButton(
                label: 'Send Reset Instructions',
                onPressed: _sendReset,
              ),
            ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const DividerText('OR'),
        const SizedBox(height: 18),
        const SecurityStrip(
          child: Text.rich(
            TextSpan(
              text: 'Your security is our priority\n',
              style: TextStyle(
                color: AppColors.purple,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
              children: [
                TextSpan(
                  text: "We'll never share your information\nwith anyone.",
                  style: TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        AuthCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need help?',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _HelpItem(
                      Icons.chat_bubble_rounded,
                      'Live Chat',
                      'Chat with support',
                      () => _showHelpMessage(context, 'Opening live chat soon'),
                    ),
                  ),
                  Expanded(
                    child: _HelpItem(
                      Icons.mail_outline_rounded,
                      'Email Us',
                      'support@vaultone.app',
                      () => _showHelpMessage(
                        context,
                        'Email support@vaultone.app',
                      ),
                    ),
                  ),
                  Expanded(
                    child: _HelpItem(
                      Icons.phone_outlined,
                      'Call Us',
                      '+91 98765 43210',
                      () => _showHelpMessage(context, 'Call +91 98765 43210'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const BottomSafeArt(),
        BottomAuthLink(
          text: 'Remember your password?',
          action: 'Login',
          onTap: () => context.goNamed(AppRoutes.loginName),
        ),
      ],
    );
  }

  static void _showHelpMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _sendReset() {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset OTP sent')),
    );
    context.goNamed(AppRoutes.verifyOtpName);
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
}

class _HelpItem extends StatelessWidget {
  const _HelpItem(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Icon(icon, color: AppColors.purple, size: 30),
          const SizedBox(height: 8),
          Text(title, style: AppTextStyles.label.copyWith(fontSize: 12)),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontSize: 10),
          ),
        ],
      ),
    ),
  );
}
