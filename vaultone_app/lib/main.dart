import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vaultone_app/routes/app_page.dart';

import 'core/theme/app_theme.dart';
import 'core/storage/hive_initializer.dart';
import 'core/localization/app_language_controller.dart';
import 'core/localization/app_localizations.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  final savedLanguage = await loadSavedAppLanguage();
  runApp(
    ProviderScope(
      overrides: [
        appLanguageProvider.overrideWith(
          (ref) => AppLanguageController(
            initial: savedLanguage ?? AppLanguage.english,
          ),
        ),
      ],
      child: const VaultOneApp(),
    ),
  );
  // Initialize storage after Flutter has drawn the splash's first frame.
  // Awaiting this before runApp leaves users staring at the native window.
  unawaited(ensureHiveInitialized());
}

class VaultOneApp extends ConsumerWidget {
  const VaultOneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'VaultOne',
      theme: AppTheme.light(),
      themeMode: ThemeMode.light,
      locale: language.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
    );
  }
}
