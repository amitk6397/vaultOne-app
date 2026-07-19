import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/auth_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/light_auth_widgets.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
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
    final isLoading = ref.watch(
      authActionProvider.select((state) => state.isLoading),
    );

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
          context.l10n.tr('reset_password'),
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.tr('forgot_password_description'),
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
                  label: context.l10n.tr('enter_identity'),
                  hint: context.l10n.tr('email_or_phone_number'),
                  icon: Icons.mail_outline_rounded,
                  controller: _identityController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.telephoneNumber,
                  ],
                  validator: _validateEmailOrPhone,
                ),
                const SizedBox(height: 16),
                GradientAuthButton(
                  label: context.l10n.tr('send_reset_instructions'),
                  isLoading: isLoading,
                  loadingLabel: context.l10n.tr('sending'),
                  onPressed: _sendReset,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        DividerText(context.l10n.tr('or')),
        const SizedBox(height: 18),
        SecurityStrip(
          child: Text.rich(
            TextSpan(
              text: '${context.l10n.tr('security_priority')}\n',
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
              children: [
                TextSpan(
                  text: context.l10n.tr('security_privacy_note'),
                  style: const TextStyle(
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
              Text(
                context.l10n.tr('need_help'),
                style: const TextStyle(
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
                      context.l10n.tr('live_chat'),
                      context.l10n.tr('chat_with_support'),
                      () => _showHelpMessage(
                        context,
                        context.l10n.tr('opening_live_chat'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _HelpItem(
                      Icons.mail_outline_rounded,
                      context.l10n.tr('email_us'),
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
                      context.l10n.tr('call_us'),
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

        BottomAuthLink(
          text: context.l10n.tr('remember_password'),
          action: context.l10n.tr('login'),
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

  Future<void> _sendReset() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final identity = _identityController.text.trim();
    final success = await ref
        .read(authActionProvider.notifier)
        .forgotPassword(identity);
    if (!mounted) return;
    if (success) {
      final otp = ref.read(authActionProvider).lastOtp;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            otp == null || otp.isEmpty
                ? context.l10n.tr('reset_otp_sent')
                : context.l10n.tr('your_otp', args: {'otp': otp}),
          ),
          duration: AuthConstants.requestTimeout,
        ),
      );
      context.goNamed(
        AppRoutes.verifyOtpName,
        queryParameters: {'identity': identity, 'purpose': 'forgot_password'},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authActionProvider).error ??
                context.l10n.tr('reset_otp_failed'),
          ),
        ),
      );
    }
  }

  String? _validateEmailOrPhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return context.l10n.tr('identity_required');
    final isEmail = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(input);
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final isPhone = digits.length >= 10 && digits.length <= 13;
    if (!isEmail && !isPhone) return context.l10n.tr('identity_invalid');
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
