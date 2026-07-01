import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class AppAuthShell extends StatelessWidget {
  const AppAuthShell({
    super.key,
    required this.child,
    this.hero,
    this.darkHeader = false,
  });

  final Widget child;
  final Widget? hero;
  final bool darkHeader;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            margin: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 32,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              children: [
                if (hero != null)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: darkHeader ? AppColors.darkHeroGradient : null,
                      color: darkHeader ? null : AppColors.mint,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                        bottom: Radius.circular(32),
                      ),
                    ),
                    child: hero,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
