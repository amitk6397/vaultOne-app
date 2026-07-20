import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_routes.dart';
import '../../../core/localization/app_language_controller.dart';
import '../../../constants/auth_constants.dart';
import '../../../constants/app_image.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../core/security/secure_token_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_openApp());
  }

  Future<void> _openApp() async {
    final preferencesFuture = SharedPreferences.getInstance();
    await Future<void>.delayed(AuthConstants.splashDelay);
    final preferences = await preferencesFuture;
    if (!mounted) return;

    final languageCode = preferences.getString(appLanguagePreferenceKey);
    if (languageCode == null || languageCode.isEmpty) {
      context.goNamed(AppRoutes.languageName);
      return;
    }
    final isLoggedIn = await SecureTokenStore.instance.isLoggedIn();
    if (!mounted) return;
    if (isLoggedIn) {
      context.goNamed(AppRoutes.homeName);
      return;
    }
    final onboardingCompleted =
        preferences.getBool(AuthConstants.onboardingCompletedKey) ?? false;
    context.goNamed(
      onboardingCompleted ? AppRoutes.loginName : AppRoutes.onboardingName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: TweenAnimationBuilder<double>(
              duration: AuthConstants.splashAnimationDuration,
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: .92 + (.08 * value),
                  child: child,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x243D52F5),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Image.asset(
                        AppImages.appLogo,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'VaultOne',
                    style: TextStyle(
                      color: Color(0xFF101828),
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 26),
                  const AppLoadingIndicator(
                    size: 34,
                    color: AuthConstants.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
