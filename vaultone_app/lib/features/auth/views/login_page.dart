import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/light_auth_widgets.dart';
import '../models/request/auth_requests.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_ui_provider.dart';
import '../session_refresh.dart';

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
    final loginWithOtp = ref.watch(loginWithOtpProvider);
    final isLoading = ref.watch(
      authActionProvider.select((state) => state.isLoading),
    );

    return LightAuthShell(
      showBack: false,
      children: [
        const SizedBox(height: 10),
        const AuthBrandMark(center: true, logoSize: 76),
        const SizedBox(height: 8),
        Center(
          child: Text(
            context.l10n.tr('secure_tagline'),
            style: const TextStyle(
              color: AppColors.purple,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.tr('welcome_back'),
          style: AppTextStyles.heading.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text(context.l10n.tr('login_subtitle'), style: AppTextStyles.body),
        const SizedBox(height: 18),
        Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: AuthCard(
            child: Column(
              children: [
                _LoginMethodSelector(
                  loginWithOtp: loginWithOtp,
                  onChanged: (value) {
                    setState(() => _submitted = false);
                    ref.read(loginWithOtpProvider.notifier).state = value;
                  },
                ),
                const SizedBox(height: 20),
                AuthInput(
                  label: context.l10n.tr(
                    loginWithOtp ? 'email_address' : 'email_or_phone',
                  ),
                  hint: loginWithOtp
                      ? context.l10n.tr('registered_email_hint')
                      : context.l10n.tr('email_or_phone_hint'),
                  icon: Icons.mail_outline_rounded,
                  controller: _identityController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.email,
                    AutofillHints.telephoneNumber,
                  ],
                  validator: (value) =>
                      _validateIdentity(value, emailOnly: loginWithOtp),
                ),
                if (!loginWithOtp) ...[
                  const SizedBox(height: 20),
                  AuthInput(
                    label: context.l10n.tr('password'),
                    hint: context.l10n.tr('password_hint'),
                    icon: Icons.lock_outline_rounded,
                    controller: _passwordController,
                    obscureText: !isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          ref
                                  .read(loginPasswordVisibleProvider.notifier)
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
                        context.l10n.tr('remember_me'),
                        style: AppTextStyles.body.copyWith(
                          color: const Color(0xFF2F3340),
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            context.goNamed(AppRoutes.forgotPasswordName),
                        child: Text(
                          context.l10n.tr('forgot_password_question'),
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.l10n.tr('otp_email_info'),
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                GradientAuthButton(
                  label: loginWithOtp
                      ? context.l10n.tr('send_login_otp')
                      : context.l10n.tr('login_securely'),
                  isLoading: isLoading,
                  loadingLabel: context.l10n.tr('please_wait'),
                  icon: loginWithOtp
                      ? Icons.mark_email_read_outlined
                      : Icons.lock_outline_rounded,
                  onPressed: _login,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        DividerText(context.l10n.tr('or_continue_with')),
        const SizedBox(height: 14),
        Row(
          children: [
            // Expanded(
            //   child: SocialButton(
            //     label: 'Google',
            //     onPressed: () =>
            //         _showAuthMessage(context, 'Google sign-in coming soon'),
            //   ),
            // ),
            // const SizedBox(width: 14),
            // Expanded(
            //   child: SocialButton(
            //     label: 'Apple',
            //     icon: Icons.apple,
            //     onPressed: () =>
            //         _showAuthMessage(context, 'Apple sign-in coming soon'),
            //   ),
            // ),
            const SizedBox(width: 14),
            Expanded(
              child: SocialButton(
                label: context.l10n.tr('biometric_short'),
                icon: Icons.fingerprint_rounded,
                color: AppColors.blue,
                onPressed: () => _showAuthMessage(
                  context,
                  context.l10n.tr('biometric_coming_soon'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        BottomAuthLink(
          text: context.l10n.tr('no_account'),
          action: context.l10n.tr('register'),
          onTap: () => context.goNamed(AppRoutes.registerName),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  void _showAuthMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final identity = _identityController.text.trim().toLowerCase();
    final loginWithOtp = ref.read(loginWithOtpProvider);
    final notifier = ref.read(authActionProvider.notifier);
    final success = loginWithOtp
        ? await notifier.sendLoginOtp(identity)
        : await notifier.login(
            LoginRequest(
              identity: identity,
              password: _passwordController.text,
              rememberMe: ref.read(rememberMeProvider),
            ),
          );
    if (!mounted) return;

    if (!success) {
      _showAuthMessage(
        context,
        ref.read(authActionProvider).error ??
            context.l10n.tr(loginWithOtp ? 'otp_send_failed' : 'login_failed'),
      );
      return;
    }

    if (loginWithOtp) {
      final otp = ref.read(authActionProvider).lastOtp;
      _showAuthMessage(
        context,
        otp == null || otp.isEmpty
            ? context.l10n.tr('otp_sent_email')
            : context.l10n.tr('your_otp', args: {'otp': otp}),
      );
      context.goNamed(
        AppRoutes.verifyOtpName,
        queryParameters: {'identity': identity, 'purpose': 'login'},
      );
    } else {
      refreshAuthenticatedData(ref);
      context.goNamed(AppRoutes.homeName);
    }
  }

  String? _validateIdentity(String? value, {required bool emailOnly}) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return context.l10n.tr('identity_required');
    final isEmail = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(input);
    if (emailOnly && !isEmail) {
      return context.l10n.tr('registered_email_invalid');
    }
    final digits = input.replaceAll(RegExp(r'\D'), '');
    final isPhone = digits.length >= 10 && digits.length <= 13;
    if (!isEmail && !isPhone) return context.l10n.tr('identity_invalid');
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return context.l10n.tr('password_required');
    if ((value ?? '').length < 8) {
      return context.l10n.tr('password_min_length');
    }
    return null;
  }
}

class _LoginMethodSelector extends StatelessWidget {
  const _LoginMethodSelector({
    required this.loginWithOtp,
    required this.onChanged,
  });

  final bool loginWithOtp;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _MethodButton(
            label: context.l10n.tr('password'),
            icon: Icons.lock_outline_rounded,
            selected: !loginWithOtp,
            onTap: () => onChanged(false),
          ),
          _MethodButton(
            label: context.l10n.tr('otp'),
            icon: Icons.password_rounded,
            selected: loginWithOtp,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.purple : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.purple : const Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
