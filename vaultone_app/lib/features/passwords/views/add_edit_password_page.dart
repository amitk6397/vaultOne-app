import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/password_entry.dart';
import '../providers/password_vault_provider.dart';
import '../widgets/password_strength_bar.dart';
import '../../scanner/repositories/ai_ocr_repository.dart';

class AddEditPasswordPage extends ConsumerStatefulWidget {
  const AddEditPasswordPage({super.key, this.passwordId});

  final String? passwordId;

  @override
  ConsumerState<AddEditPasswordPage> createState() =>
      _AddEditPasswordPageState();
}

class _AddEditPasswordPageState extends ConsumerState<AddEditPasswordPage> {
  final _siteController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _hydrated = false;

  @override
  void dispose() {
    _siteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(passwordVaultProvider);
    final controller = ref.read(passwordVaultProvider.notifier);
    final existing = widget.passwordId == null
        ? null
        : controller.entryById(widget.passwordId!);
    if (!_hydrated && existing != null) {
      _siteController.text = existing.title;
      _usernameController.text = existing.username;
      _passwordController.text = existing.password;
      _hydrated = true;
    }

    return Scaffold(
      appBar: AppPageAppBar(
        title: context.l10n.tr(
          existing == null ? 'add_password' : 'edit_password',
        ),
        subtitle: context.l10n.tr('stored_locally_hive'),
        onBack: _returnToPasswords,
        actions: [
          IconButton(
            tooltip: context.l10n.tr('scan_login_ai'),
            onPressed: _scanPassword,
            icon: const Icon(Icons.document_scanner_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: context.l10n.tr('site_name'),
                hint: context.l10n.tr('site_example'),
                icon: Icons.language_rounded,
                controller: _siteController,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: context.l10n.tr('username_email'),
                hint: context.l10n.tr('username_hint'),
                icon: Icons.person_outline_rounded,
                controller: _usernameController,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: context.l10n.tr('password'),
                hint: context.l10n.tr('password_hint'),
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
                obscureText: _obscure,
                suffixIcon: Wrap(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() => _obscure = !_obscure);
                      },
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                    IconButton(
                      onPressed: _fillGeneratedPassword,
                      icon: const Icon(Icons.auto_awesome_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _passwordController,
                builder: (context, value, _) {
                  return PasswordStrengthBar(password: value.text);
                },
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: context.l10n.tr(
                  vault.isLoading ? 'preparing' : 'save_password',
                ),
                onPressed: vault.isLoading
                    ? null
                    : () async {
                        final title = _siteController.text.trim();
                        final username = _usernameController.text.trim();
                        final password = _passwordController.text;
                        if (title.isEmpty ||
                            username.isEmpty ||
                            password.isEmpty) {
                          AppFeedback.showSnackBar(
                            context,
                            message: context.l10n.tr(
                              'password_fields_required',
                            ),
                          );
                          return;
                        }
                        await controller.saveEntry(
                          id: existing?.id,
                          title: title,
                          username: username,
                          password: password,
                          category: PasswordCategory.other,
                        );
                        if (!context.mounted) return;
                        AppFeedback.showSnackBar(
                          context,
                          message: context.l10n.tr('password_saved_local'),
                        );
                        _returnToPasswords();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fillGeneratedPassword() {
    final password = generatePassword(
      length: ref.read(passwordLengthProvider).round(),
      includeSymbols: ref.read(includeSymbolsProvider),
      includeNumbers: ref.read(includeNumbersProvider),
      includeUppercase: ref.read(includeUppercaseProvider),
    );
    _passwordController.text = password;
    Clipboard.setData(ClipboardData(text: password));
    AppFeedback.showSnackBar(
      context,
      message: context.l10n.tr('generated_password_copied'),
    );
  }

  Future<void> _scanPassword() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(context.l10n.tr('take_photo')),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(context.l10n.tr('choose_gallery')),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final image = await ImagePicker().pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 2200,
    );
    if (image == null) return;
    try {
      final result = await ref
          .read(aiOcrRepositoryProvider)
          .extract(image.path, target: 'password');
      if (!mounted) return;
      setState(() {
        _siteController.text = result.fields['site'] ?? result.title;
        _usernameController.text = result.fields['username'] ?? '';
        _passwordController.text = result.fields['password'] ?? '';
      });
      final title = _siteController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      if (title.isEmpty || username.isEmpty || password.isEmpty) {
        AppFeedback.showSnackBar(
          context,
          message: context.l10n.tr('ocr_fields_missing'),
        );
        return;
      }
      await ref
          .read(passwordVaultProvider.notifier)
          .saveEntry(
            id: widget.passwordId,
            title: title,
            username: username,
            password: password,
            category: PasswordCategory.other,
          );
      if (!mounted) return;
      AppFeedback.showSnackBar(
        context,
        message: context.l10n.tr('ai_password_saved'),
      );
      _returnToPasswords();
    } catch (error) {
      if (mounted) AppFeedback.showSnackBar(context, message: error.toString());
    }
  }

  void _returnToPasswords() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoutes.passwordsName);
    }
  }
}
