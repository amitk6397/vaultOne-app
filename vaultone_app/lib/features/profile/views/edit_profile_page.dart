import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_page_header.dart';
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
  var _saving = false;

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
      appBar: AppPageAppBar(
        title: context.l10n.tr('edit_profile'),
        subtitle: context.l10n.tr('edit_profile_subtitle'),
        onBack: () => context.goNamed(AppRoutes.profileName),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: context.l10n.tr('full_name'),
                hint: context.l10n.tr('enter_full_name'),
                icon: Icons.person_outline_rounded,
                controller: _nameController,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: context.l10n.tr('mobile_number'),
                hint: context.l10n.tr('enter_mobile_number'),
                icon: Icons.phone_in_talk_outlined,
                keyboardType: TextInputType.phone,
                controller: _mobileController,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: context.l10n.tr('email_address'),
                hint: context.l10n.tr('enter_email_address'),
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: context.l10n.tr('city'),
                hint: context.l10n.tr('enter_city'),
                icon: Icons.location_city_rounded,
                controller: _cityController,
              ),
              const SizedBox(height: 28),
              AppPrimaryButton(
                label: context.l10n.tr(_saving ? 'saving' : 'save_profile'),
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(profileProvider.notifier)
          .updateProfileFromApi(
            fullName: _nameController.text.trim(),
            mobile: _mobileController.text.trim(),
            email: _emailController.text.trim(),
            city: _cityController.text.trim(),
          );
      if (!mounted) return;
      AppFeedback.showSnackBar(
        context,
        message: context.l10n.tr('profile_updated'),
      );
      context.goNamed(AppRoutes.profileName);
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showSnackBar(
        context,
        message: context.l10n.tr(
          'profile_update_failed',
          args: {'error': error.toString()},
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
