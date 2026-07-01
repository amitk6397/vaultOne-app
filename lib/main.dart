import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vaultone_app/routes/app_page.dart';

import 'constants/app_colors.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: VaultOneApp()));
}

class VaultOneApp extends StatelessWidget {
  const VaultOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'VaultOne',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffold,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
      ),
      routerConfig: appRouter,
    );
  }
}
