import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/light_auth_widgets.dart';
import '../providers/auth_ui_provider.dart';

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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
        const Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              'Verify Your Number',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            Icon(Icons.verified_rounded, color: AppColors.purple),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                "We've sent a 6-digit OTP to",
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ),
            IconButton(
              onPressed: () => context.goNamed(AppRoutes.forgotPasswordName),
              tooltip: 'Edit number',
              icon: const Icon(Icons.edit_rounded, color: AppColors.purple),
            ),
          ],
        ),
        const Text(
          '+91 98765 43210',
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
                'Enter 6-digit OTP',
                style: AppTextStyles.heading.copyWith(fontSize: 19),
              ),
              SizedBox(height: 8),
              Text(
                'Please enter the OTP sent to your number',
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
                const Text(
                  'Please enter the 6-digit OTP',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 14),
              _OtpMetaRow(
                secondsLeft: _secondsLeft,
                onResend: () {
                  ref.read(otpCodeProvider.notifier).state = '';
                  _otpController.clear();
                  setState(() => _showError = false);
                  _startTimer();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('OTP resent')));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SecurityStrip(
          child: Text.rich(
            TextSpan(
              text: 'Your data is ',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
              children: [
                TextSpan(
                  text: '100% secure',
                  style: TextStyle(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(text: ' with vaultOne'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GradientAuthButton(
          label: 'Verify OTP',
          icon: Icons.verified_user_outlined,
          onPressed: _secondsLeft == 0 ? null : _verifyOtp,
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'We never share your number with anyone',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _verifyOtp() {
    final code = ref.read(otpCodeProvider);
    if (code.length != 6) {
      setState(() => _showError = true);
      _otpFocusNode.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    ref.read(otpCodeProvider.notifier).state = '';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP verified successfully')));
    context.goNamed(AppRoutes.homeName);
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
            const Text(
              'OTP will expire in ',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
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
              text: "Didn't receive OTP? ",
              style: AppTextStyles.body.copyWith(fontSize: 14),
              children: [
                TextSpan(
                  text: 'Resend',
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
