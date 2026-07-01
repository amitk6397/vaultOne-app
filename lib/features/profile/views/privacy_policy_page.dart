import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoPage(
      title: 'Privacy Policy',
      icon: Icons.privacy_tip_rounded,
      color: AppColors.success,
      sections: const [
        _InfoSection(
          'What VaultOne Stores',
          'VaultOne stores profile details, vault metadata, reminders and user-selected files only when you add them.',
        ),
        _InfoSection(
          'Security',
          'Sensitive vault items are designed for encrypted storage and protected access before sync or sharing.',
        ),
        _InfoSection(
          'User Control',
          'You can update profile details, disable alerts and request account deletion from the profile area.',
        ),
      ],
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoPage(
      title: 'About VaultOne',
      icon: Icons.info_rounded,
      color: AppColors.blue,
      sections: const [
        _InfoSection(
          'VaultOne',
          'A digital locker app for documents, passwords, assets, reminders and secure sharing.',
        ),
        _InfoSection('Version', '1.0.0'),
        _InfoSection(
          'Modules',
          'Digital Locker, Password Vault, AI Assistant, Reports, Scanner and Profile management.',
        ),
      ],
    );
  }
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _InfoPage(
      title: 'Help & Support',
      icon: Icons.help_rounded,
      color: AppColors.cyan,
      sections: const [
        _InfoSection(
          'Contact',
          'Email support@vaultone.app for account, vault or billing help.',
        ),
        _InfoSection(
          'FAQs',
          'Use search, folders and expiry alerts to keep your important records organized.',
        ),
        _InfoSection(
          'Security Help',
          'If you suspect unauthorized access, change your password and disable shared links.',
        ),
      ],
    );
  }
}

class _InfoPage extends StatelessWidget {
  const _InfoPage({
    required this.title,
    required this.icon,
    required this.color,
    required this.sections,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<_InfoSection> sections;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.goNamed(AppRoutes.profileName),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading,
          ),
          const SizedBox(height: 18),
          ...sections.map(
            (section) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: AppTextStyles.label.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(section.body, style: AppTextStyles.body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection {
  const _InfoSection(this.title, this.body);

  final String title;
  final String body;
}
