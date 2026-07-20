import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/auth_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/light_auth_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_ui_provider.dart';
import '../session_refresh.dart';

class VerifyOtpPage extends ConsumerStatefulWidget {
  const VerifyOtpPage({super.key});

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  Timer? _timer;
  int _secondsLeft = 60;
  var _showError = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 60);
    _timer = Timer.periodic(AuthConstants.otpTick, (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  Widget build(BuildContext context) {
    final otpCode = ref.watch(otpCodeProvider);
    final isLoading = ref.watch(
      authActionProvider.select((state) => state.isLoading),
    );
    final params = GoRouterState.of(context).uri.queryParameters;
    final identity = params['identity'] ?? '';
    final purpose = params['purpose'] ?? 'register';

    return LightAuthShell(
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: AuthBrandMark(logoSize: 58)),
            SizedBox(width: 8),
            Expanded(child: AuthHeroArt(kind: AuthHeroKind.otp, height: 135)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              context.l10n.tr('verify_email'),
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Icon(Icons.verified_rounded, color: AppColors.purple),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.tr('otp_sent_to'),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ),
            IconButton(
              onPressed: () => context.goNamed(
                purpose == 'forgot_password'
                    ? AppRoutes.forgotPasswordName
                    : purpose == 'login'
                    ? AppRoutes.loginName
                    : AppRoutes.registerName,
              ),
              tooltip: context.l10n.tr('edit_identity'),
              icon: const Icon(Icons.edit_rounded, color: AppColors.purple),
            ),
          ],
        ),
        Text(
          identity.isEmpty ? context.l10n.tr('registered_email') : identity,
          style: TextStyle(
            color: AppColors.blue,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        AuthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.tr('enter_otp'),
                style: AppTextStyles.heading.copyWith(fontSize: 19),
              ),
              SizedBox(height: 8),
              Text(
                context.l10n.tr('enter_otp_description'),
                style: AppTextStyles.body.copyWith(fontSize: 12.5),
              ),
              const SizedBox(height: 16),
              _OtpEntryField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                code: otpCode,
                showError: _showError,
                onChanged: (value) {
                  final clean = value.replaceAll(RegExp(r'\D'), '');
                  if (_otpController.text != clean) {
                    _otpController.value = TextEditingValue(
                      text: clean,
                      selection: TextSelection.collapsed(offset: clean.length),
                    );
                  }
                  ref.read(otpCodeProvider.notifier).state = clean;
                  if (_showError && clean.length == 6) {
                    setState(() => _showError = false);
                  }
                },
              ),
              const SizedBox(height: 10),
              if (_showError)
                Text(
                  context.l10n.tr('enter_otp_error'),
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 14),
              _OtpMetaRow(
                secondsLeft: _secondsLeft,
                onResend: () {
                  _resendOtp(identity: identity, purpose: purpose);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SecurityStrip(
          child: Text.rich(
            TextSpan(
              text: '${context.l10n.tr('data_is')} ',
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
              children: [
                TextSpan(
                  text: context.l10n.tr('secure_percent'),
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(text: ' ${context.l10n.tr('with_vaultone')}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GradientAuthButton(
          label: context.l10n.tr('verify_otp'),
          isLoading: isLoading,
          loadingLabel: context.l10n.tr('verifying'),
          icon: Icons.verified_user_outlined,
          onPressed: _secondsLeft == 0
              ? null
              : () => _verifyOtp(identity: identity, purpose: purpose),
        ),
        const SizedBox(height: 18),
        Center(
          child: Text(
            context.l10n.tr('email_privacy_note'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _verifyOtp({
    required String identity,
    required String purpose,
  }) async {
    final code = ref.read(otpCodeProvider);
    if (code.length != 6) {
      setState(() => _showError = true);
      _otpFocusNode.requestFocus();
      return;
    }
    if (identity.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.tr('email_missing'))));
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await ref
        .read(authActionProvider.notifier)
        .verifyOtp(identity: identity, otp: code, purpose: purpose);
    if (!mounted) return;
    if (success) {
      if (purpose != 'forgot_password') {
        refreshAuthenticatedData(ref);
      }
      ref.read(otpCodeProvider.notifier).state = '';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.tr('otp_verified'))));
      context.goNamed(
        purpose == 'forgot_password'
            ? AppRoutes.resetPasswordName
            : AppRoutes.homeName,
        queryParameters: purpose == 'forgot_password'
            ? {'identity': identity, 'otp': code}
            : const {},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authActionProvider).error ??
                context.l10n.tr('otp_verification_failed'),
          ),
        ),
      );
    }
  }

  Future<void> _resendOtp({
    required String identity,
    required String purpose,
  }) async {
    if (identity.isEmpty) return;
    final success = await ref
        .read(authActionProvider.notifier)
        .resendOtp(identity: identity, purpose: purpose);
    if (!mounted) return;
    if (success) {
      ref.read(otpCodeProvider.notifier).state = '';
      _otpController.clear();
      setState(() => _showError = false);
      _startTimer();
      final otp = ref.read(authActionProvider).lastOtp;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            otp == null || otp.isEmpty
                ? context.l10n.tr('otp_resent')
                : context.l10n.tr('your_otp', args: {'otp': otp}),
          ),
          duration: AuthConstants.requestTimeout,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authActionProvider).error ??
                context.l10n.tr('otp_resend_failed'),
          ),
        ),
      );
    }
  }
}

class _OtpEntryField extends StatelessWidget {
  const _OtpEntryField({
    required this.controller,
    required this.focusNode,
    required this.code,
    required this.showError,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String code;
  final bool showError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.01,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: onChanged,
            decoration: const InputDecoration(counterText: ''),
          ),
        ),
        GestureDetector(
          onTap: focusNode.requestFocus,
          child: Row(
            children: List.generate(6, (index) {
              final active = index == code.length && code.length < 6;
              final value = index < code.length ? code[index] : '';
              return Expanded(
                child: Container(
                  height: 48,
                  margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: showError
                          ? const Color(0xFFDC2626)
                          : active
                          ? AppColors.purple
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    value.isEmpty ? '-' : value,
                    style: TextStyle(
                      color: value.isEmpty
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF111827),
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _OtpMetaRow extends StatelessWidget {
  const _OtpMetaRow({required this.secondsLeft, required this.onResend});

  final int secondsLeft;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final remaining =
        '00:${secondsLeft.toString().padLeft(2, '0').substring(secondsLeft > 99 ? 1 : 0)}';
    return Wrap(
      runSpacing: 10,
      spacing: 16,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, color: AppColors.purple, size: 21),
            const SizedBox(width: 8),
            Text(
              '${context.l10n.tr('otp_expires_in')} ',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            ),
            Text(
              remaining,
              style: const TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: secondsLeft == 0 ? onResend : null,
          child: Text.rich(
            TextSpan(
              text: '${context.l10n.tr('otp_not_received')} ',
              style: AppTextStyles.body.copyWith(fontSize: 14),
              children: [
                TextSpan(
                  text: context.l10n.tr('resend'),
                  style: AppTextStyles.link.copyWith(
                    color: secondsLeft == 0
                        ? AppColors.purple
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
