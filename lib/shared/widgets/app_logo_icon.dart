import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class AppLogoIcon extends StatelessWidget {
  const AppLogoIcon({
    super.key,
    this.size = 190,
    this.dark = false,
    this.icon = Icons.folder_copy_rounded,
  });

  final double size;
  final bool dark;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(size * 0.18),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
          ),
          Icon(
            icon,
            size: size * 0.48,
            color: dark ? Colors.white : AppColors.purple,
          ),
          Positioned(
            right: size * 0.16,
            bottom: size * 0.12,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: size * 0.18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
