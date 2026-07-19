import 'package:flutter/material.dart';

import '../../constants/app_image.dart';

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .18),
        child: Image.asset(
          AppImages.appLogo,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, _, _) => Icon(icon, size: size * .6),
        ),
      ),
    );
  }
}
