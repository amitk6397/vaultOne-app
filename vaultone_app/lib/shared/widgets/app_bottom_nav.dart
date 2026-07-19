import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../core/localization/app_localizations.dart';
import '../../routes/app_routes.dart';

enum AppNavTab { home, documents, ai, passwords, profile }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.activeTab});

  final AppNavTab activeTab;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 76 + MediaQuery.viewPaddingOf(context).bottom,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          Material(
            color: colors.surface,
            elevation: 18,
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 76,
                child: Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: Icons.home_rounded,
                        label: context.l10n.tr('home'),
                        active: activeTab == AppNavTab.home,
                        onTap: () => context.pushNamed(AppRoutes.homeName),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.folder_rounded,
                        label: context.l10n.tr('docs'),
                        active: activeTab == AppNavTab.documents,
                        onTap: () => context.pushNamed(AppRoutes.documentsName),
                      ),
                    ),
                    const SizedBox(width: 68),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.lock_rounded,
                        label: context.l10n.tr('vault'),
                        active: activeTab == AppNavTab.passwords,
                        onTap: () => context.pushNamed(AppRoutes.passwordsName),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: Icons.person_rounded,
                        label: context.l10n.tr('profile'),
                        active: activeTab == AppNavTab.profile,
                        onTap: () => context.pushNamed(AppRoutes.profileName),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(top: 2, child: _AiFab(active: activeTab == AppNavTab.ai)),
        ],
      ),
    );
  }
}

class _AiFab extends StatefulWidget {
  const _AiFab({required this.active});

  final bool active;

  @override
  State<_AiFab> createState() => _AiFabState();
}

class _AiFabState extends State<_AiFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _turn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scale = Tween<double>(begin: 1, end: 1.07).animate(curve);
    _turn = Tween<double>(begin: -.018, end: .018).animate(curve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: RotationTransition(
        turns: _turn,
        child: FloatingActionButton(
          heroTag: 'vaultone-ai-fab',
          tooltip: 'AI',
          onPressed: () => context.pushNamed(AppRoutes.aiName),
          elevation: 10,
          backgroundColor: Colors.transparent,
          shape: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              border: widget.active
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
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
    final colors = Theme.of(context).colorScheme;
    final color = active ? AppColors.blue : AppColors.textMuted;
    final inactiveColor = Theme.of(context).brightness == Brightness.dark
        ? colors.onSurfaceVariant
        : color;
    final effectiveColor = active ? colors.primary : inactiveColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: effectiveColor, size: 23),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppTextStyles.link.copyWith(
                  color: effectiveColor,
                  fontSize: 11,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
