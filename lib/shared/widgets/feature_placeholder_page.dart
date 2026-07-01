import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  const FeaturePlaceholderPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton.filled(
                onPressed: () => context.pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navy,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(height: 44),
              Center(
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Icon(icon, size: 58, color: color),
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  title,
                  style: AppTextStyles.heading,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  subtitle,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
