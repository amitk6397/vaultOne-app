import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/localization/app_language_controller.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../constants/app_image.dart';
import '../../../core/security/secure_token_store.dart';
import '../../../constants/auth_constants.dart';

class LanguageSelectionPage extends ConsumerStatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  ConsumerState<LanguageSelectionPage> createState() =>
      _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends ConsumerState<LanguageSelectionPage> {
  AppLanguage _selectedLanguage = AppLanguage.english;
  bool _isSaving = false;

  Future<void> _continue() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    await ref.read(appLanguageProvider.notifier).select(_selectedLanguage);
    if (!mounted) return;
    final isLoggedIn = await SecureTokenStore.instance.isLoggedIn();
    if (!mounted) return;
    if (isLoggedIn) {
      context.goNamed(AppRoutes.homeName);
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    final onboardingCompleted =
        preferences.getBool(AuthConstants.onboardingCompletedKey) ?? false;
    context.goNamed(
      onboardingCompleted ? AppRoutes.loginName : AppRoutes.onboardingName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = AppLocalizations(_selectedLanguage.locale);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    AppImages.appLogo,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Text(
                preview.tr('choose_language'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                preview.tr('choose_language_description'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: AppLanguage.values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final language = AppLanguage.values[index];
                    return _LanguageTile(
                      title: language.nativeName,
                      subtitle: language.englishName,
                      selected: _selectedLanguage == language,
                      onTap: () => setState(() => _selectedLanguage = language),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _isSaving ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2457E6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const AppLoadingIndicator(size: 28)
                      : Text(
                          preview.tr('continue'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEEF4FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? const Color(0xFF2457E6) : const Color(0xFFE4E7EC),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF101828),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? const Color(0xFF2457E6)
                    : const Color(0xFF98A2B3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
