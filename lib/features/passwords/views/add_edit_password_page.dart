import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../widgets/password_strength_bar.dart';

class AddEditPasswordPage extends StatefulWidget {
  const AddEditPasswordPage({super.key});

  @override
  State<AddEditPasswordPage> createState() => _AddEditPasswordPageState();
}

class _AddEditPasswordPageState extends State<AddEditPasswordPage> {
  final _passwordController = TextEditingController(text: 'VaultOne@123');

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton.filled(
                onPressed: () => context.goNamed(AppRoutes.passwordsName),
                style: IconButton.styleFrom(backgroundColor: Colors.white),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 18),
              Text('Add / Edit Password', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                'Store site URL, username, password, category, and private notes.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              const AppTextField(
                label: 'Site Name',
                hint: 'Example: Google',
                icon: Icons.language_rounded,
              ),
              const SizedBox(height: 18),
              const AppTextField(
                label: 'Username / Email',
                hint: 'Enter username or email',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Password',
                hint: 'Enter password',
                icon: Icons.lock_outline_rounded,
                controller: _passwordController,
              ),
              const SizedBox(height: 18),
              PasswordStrengthBar(password: _passwordController.text),
              const SizedBox(height: 18),
              const AppTextField(
                label: 'Category',
                hint: 'Social, Banking, Work...',
                icon: Icons.category_rounded,
              ),
              const SizedBox(height: 18),
              const AppTextField(
                label: 'Secure Notes',
                hint: 'PINs, hints, secret questions...',
                icon: Icons.note_alt_outlined,
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: 'Save Password',
                onPressed: () {
                  AppFeedback.showSnackBar(
                    context,
                    message: 'Password saved securely',
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
}
