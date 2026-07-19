import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/light_auth_widgets.dart';
import '../providers/auth_provider.dart';
import '../../../constants/auth_constants.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final formKey = GlobalKey<FormState>();
  final password = TextEditingController();
  final confirmation = TextEditingController();

  @override
  void dispose() {
    password.dispose();
    confirmation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(
      authActionProvider.select((state) => state.isLoading),
    );
    return LightAuthShell(
      children: [
        const AuthBrandMark(logoSize: 64),
        const SizedBox(height: 20),
        Text(
          context.l10n.tr('create_new_password'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        AuthCard(
          child: Form(
            key: formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.tr('new_password'),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirmation,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.tr('confirm_password'),
                  ),
                  validator: (value) => value != password.text
                      ? context.l10n.tr('passwords_mismatch')
                      : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        GradientAuthButton(
          label: context.l10n.tr('reset_password'),
          isLoading: loading,
          loadingLabel: context.l10n.tr('resetting'),
          icon: Icons.lock_reset,
          onPressed: _submit,
        ),
      ],
    );
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (!AuthConstants.isStrongPassword(text)) {
      return context.l10n.tr('strong_password_rule');
    }
    return null;
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    final params = GoRouterState.of(context).uri.queryParameters;
    final identity = params['identity'] ?? '';
    final otp = params['otp'] ?? '';
    if (identity.isEmpty || otp.length != 6) {
      context.goNamed(AppRoutes.forgotPasswordName);
      return;
    }
    final success = await ref
        .read(authActionProvider.notifier)
        .resetPassword(
          identity: identity,
          otp: otp,
          password: password.text,
          confirmPassword: confirmation.text,
        );
    if (!mounted) return;
    final message = success
        ? context.l10n.tr('password_reset_success')
        : (ref.read(authActionProvider).error ??
              context.l10n.tr('password_reset_failed'));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (success) context.goNamed(AppRoutes.loginName);
  }
}
