import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/widgets/feature_placeholder_page.dart';

class AssetsPage extends StatelessWidget {
  const AssetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Home Assets',
      subtitle:
          'Manage property, vehicle, jewellery and other important assets.',
      icon: Icons.home_rounded,
      color: AppColors.success,
    );
  }
}
