import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../shared/widgets/feature_placeholder_page.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholderPage(
      title: 'Scanner OCR',
      subtitle: 'Scan documents and extract important details quickly.',
      icon: Icons.document_scanner_rounded,
      color: AppColors.success,
    );
  }
}
