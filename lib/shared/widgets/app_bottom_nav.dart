import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../routes/app_routes.dart';

enum AppNavTab { home, documents, ai, passwords, profile }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.activeTab});

  final AppNavTab activeTab;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      height: 92,
      color: Colors.white,
      elevation: 18,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: activeTab == AppNavTab.home,
              onTap: () => context.pushNamed(AppRoutes.homeName),
            ),
            _NavItem(
              icon: Icons.folder_rounded,
              label: 'Docs',
              active: activeTab == AppNavTab.documents,
              onTap: () => context.pushNamed(AppRoutes.documentsName),
            ),
            _AiNavItem(active: activeTab == AppNavTab.ai),
            _NavItem(
              icon: Icons.lock_rounded,
              label: 'Vault',
              active: activeTab == AppNavTab.passwords,
              onTap: () => context.pushNamed(AppRoutes.passwordsName),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              active: activeTab == AppNavTab.profile,
              onTap: () => context.pushNamed(AppRoutes.profileName),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiNavItem extends StatelessWidget {
  const _AiNavItem({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: InkWell(
        onTap: () => context.pushNamed(AppRoutes.aiName),
        borderRadius: BorderRadius.circular(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
                border: active
                    ? Border.all(color: Colors.white, width: 3)
                    : null,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'AI',
              style: AppTextStyles.link.copyWith(
                color: active ? AppColors.blue : AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.blue : AppColors.textMuted;
    return SizedBox(
      width: 58,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.link.copyWith(color: color, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
