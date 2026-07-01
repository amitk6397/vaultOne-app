import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/password_entry.dart';
import '../providers/password_vault_provider.dart';
import '../widgets/password_strength_bar.dart';

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
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();
  PasswordCategory _category = PasswordCategory.social;
  bool _obscure = true;
  bool _hydrated = false;

  @override
  void dispose() {
    _siteController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
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
      _websiteController.text = existing.website;
      _notesController.text = existing.notes;
      _category = existing.category;
      _hydrated = true;
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton.filled(
                    onPressed: () => context.goNamed(AppRoutes.passwordsName),
                    style: IconButton.styleFrom(backgroundColor: Colors.white),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      existing == null ? 'Add Password' : 'Edit Password',
                      style: AppTextStyles.heading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Stored locally in Hive on this device.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Site Name',
                hint: 'Example: Google',
                icon: Icons.language_rounded,
                controller: _siteController,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Website / App URL',
                hint: 'https://example.com',
                icon: Icons.link_rounded,
                controller: _websiteController,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Username / Email',
                hint: 'Enter username or email',
                icon: Icons.person_outline_rounded,
                controller: _usernameController,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Password',
                hint: 'Enter password',
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
              const SizedBox(height: 18),
              Text('Category', style: AppTextStyles.label),
              const SizedBox(height: 10),
              DropdownButtonFormField<PasswordCategory>(
                initialValue: _category,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.fieldBorder),
                  ),
                ),
                items: PasswordCategory.values.map((category) {
                  final label = PasswordEntry(
                    id: '',
                    title: '',
                    username: '',
                    password: '',
                    category: category,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ).categoryLabel;
                  return DropdownMenuItem(value: category, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 18),
              Text('Secure Notes', style: AppTextStyles.label),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                minLines: 4,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'PINs, recovery hints, secret questions...',
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.fieldBorder),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: vault.isLoading ? 'Preparing...' : 'Save Password',
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
                            message: 'Site, username and password are required',
                          );
                          return;
                        }
                        await controller.saveEntry(
                          id: existing?.id,
                          title: title,
                          username: username,
                          password: password,
                          website: _websiteController.text.trim(),
                          category: _category,
                          notes: _notesController.text.trim(),
                        );
                        if (!context.mounted) return;
                        AppFeedback.showSnackBar(
                          context,
                          message: 'Password saved locally',
                        );
                        context.goNamed(AppRoutes.passwordsName);
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
      message: 'Strong password generated and copied',
    );
  }
}
