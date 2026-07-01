import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_primary_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _nameController = TextEditingController(text: profile.fullName);
    _mobileController = TextEditingController(text: profile.mobile);
    _emailController = TextEditingController(text: profile.email);
    _cityController = TextEditingController(text: profile.city);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed(AppRoutes.profileName),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Details', style: AppTextStyles.heading),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Full Name',
              hint: 'Enter full name',
              icon: Icons.person_outline_rounded,
              controller: _nameController,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Mobile Number',
              hint: 'Enter mobile number',
              icon: Icons.phone_in_talk_outlined,
              keyboardType: TextInputType.phone,
              controller: _mobileController,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'Email Address',
              hint: 'Enter email address',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: 'City',
              hint: 'Enter city',
              icon: Icons.location_city_rounded,
              controller: _cityController,
            ),
            const SizedBox(height: 28),
            AppPrimaryButton(label: 'Save Profile', onPressed: _save),
          ],
        ),
      ),
    );
  }

  void _save() {
    ref
        .read(profileProvider.notifier)
        .updateProfile(
          fullName: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          city: _cityController.text.trim(),
        );
    AppFeedback.showSnackBar(context, message: 'Profile updated');
    context.goNamed(AppRoutes.profileName);
  }
}
