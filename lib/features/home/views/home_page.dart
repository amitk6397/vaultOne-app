import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/neon_auth_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _quickItems = [
    _QuickItem(
      'Documents',
      '128 Files',
      Icons.folder_rounded,
      Color(0xFF8D55FF),
      AppRoutes.documentsName,
    ),
    _QuickItem(
      'Photos',
      '342 Files',
      Icons.image_rounded,
      Color(0xFF36A9FF),
      AppRoutes.photoGalleryName,
    ),
    _QuickItem(
      'Videos',
      '36 Items',
      Icons.video_library_rounded,
      Color(0xFF653CF2),
      AppRoutes.videoGalleryName,
    ),
    _QuickItem(
      'Passwords',
      '74 Items',
      Icons.lock_rounded,
      Color(0xFF37D081),
      AppRoutes.passwordsName,
    ),
    _QuickItem(
      'Secure Notes',
      '23 Notes',
      Icons.edit_note_rounded,
      Color(0xFFFF8A22),
      AppRoutes.secureNotesName,
    ),
    _QuickItem(
      'IDs & Cards',
      '19 Items',
      Icons.badge_rounded,
      Color(0xFFFF4F8B),
      AppRoutes.assetsName,
    ),
    _QuickItem(
      'OCR Scanner',
      '12 Scans',
      Icons.document_scanner_rounded,
      Color(0xFF19B7C8),
      AppRoutes.scannerName,
    ),
    _QuickItem(
      'Private Media',
      'PIN Locked',
      Icons.lock_rounded,
      Color(0xFF2F8EFF),
      AppRoutes.privatePhotosName,
    ),
    _QuickItem(
      'Deleted Media',
      '8 Items',
      Icons.restore_from_trash_rounded,
      Color(0xFF8F55FF),
      AppRoutes.deletedMediaName,
    ),
  ];

  static const _activity = [
    _ActivityItem(
      'Aadhar Card.pdf',
      'Document',
      '2 mins ago',
      'Viewed',
      Icons.description_rounded,
      Color(0xFF2FCF84),
      Color(0xFFE7FFF2),
    ),
    _ActivityItem(
      'Instagram Password',
      'Password',
      '15 mins ago',
      'Updated',
      Icons.lock_rounded,
      Color(0xFF4C7DFF),
      Color(0xFFEAF0FF),
    ),
    _ActivityItem(
      'Vacation Photos.zip',
      'Photos',
      '1 hour ago',
      'Added',
      Icons.image_rounded,
      Color(0xFF8B55FF),
      Color(0xFFF2ECFF),
    ),
    _ActivityItem(
      'Scan_2024_05_24.pdf',
      'OCR Scan',
      '2 hours ago',
      'Scanned',
      Icons.document_scanner_rounded,
      Color(0xFFFF8A22),
      Color(0xFFFFF1E6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.home),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.scaffold),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              16,
              AppSizes.screenPadding,
              112,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                const SizedBox(height: 24),
                const _VaultStatusCard(),
                const SizedBox(height: 26),
                _SectionHeader(
                  title: 'Quick Access',
                  action: 'View All',
                  onTap: () => context.goNamed(AppRoutes.documentsName),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width >= 720
                        ? 4
                        : width >= 430
                        ? 3
                        : 2;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _quickItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: columns == 2 ? 1.18 : .92,
                      ),
                      itemBuilder: (context, index) =>
                          _QuickCard(item: _quickItems[index]),
                    );
                  },
                ),
                const SizedBox(height: 26),
                _SectionHeader(
                  title: 'Recent Activity',
                  action: 'Photos',
                  onTap: () => context.goNamed(AppRoutes.photoGalleryName),
                ),
                const SizedBox(height: 16),
                const _ActivityPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _RoundIcon(icon: Icons.menu_rounded),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Hello, ',
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: 'Amit',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(text: ' hi'),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Welcome to your secure vault',
                style: AppTextStyles.body.copyWith(fontSize: 15),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: const [
            Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF111827),
              size: 31,
            ),
            Positioned(right: -2, top: -5, child: _Badge()),
          ],
        ),
        const SizedBox(width: 16),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.purple, width: 2),
            gradient: const LinearGradient(
              colors: [Color(0xFFE8F5FF), Color(0xFFF5EDFF)],
            ),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Color(0xFF111827),
            size: 31,
          ),
        ),
      ],
    );
  }
}

class _VaultStatusCard extends StatelessWidget {
  const _VaultStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radius),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: .24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: 22,
            child: Icon(
              Icons.inventory_2_rounded,
              color: Colors.white.withValues(alpha: .28),
              size: 112,
            ),
          ),
          Positioned(
            right: 16,
            top: 48,
            child: Icon(
              Icons.verified_user_rounded,
              color: Colors.white.withValues(alpha: .85),
              size: 70,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VaultShieldLogo(size: 78, glass: false),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    const Text(
                      'Your vault is',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'Secure & Protected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Last backup: Today, 08:45 AM',
                            style: TextStyle(
                              color: Color(0xFF3B2B80),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Positioned(
            left: 4,
            right: 4,
            bottom: 0,
            child: Row(
              children: [
                Expanded(
                  child: _SecurityFeature(
                    Icons.lock_outline_rounded,
                    'AES-256\nEncryption',
                  ),
                ),
                Expanded(
                  child: _SecurityFeature(
                    Icons.visibility_off_outlined,
                    'Zero-Knowledge\nPrivacy',
                  ),
                ),
                Expanded(
                  child: _SecurityFeature(
                    Icons.fingerprint_rounded,
                    'Biometric\nEnabled',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title;
  final String action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: AppTextStyles.heading.copyWith(fontSize: 21)),
      ),
      TextButton(
        onPressed: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              action,
              style: AppTextStyles.link.copyWith(
                color: AppColors.purple,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 7),
            const Icon(Icons.arrow_forward_rounded, color: AppColors.purple),
          ],
        ),
      ),
    ],
  );
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.item});
  final _QuickItem item;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.goNamed(item.routeName),
    borderRadius: BorderRadius.circular(13),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: .7),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.color, size: 34),
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(fontSize: 12, height: 1.12),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: item.subtitle.contains('Up')
                  ? AppColors.success
                  : AppColors.textMuted,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel();
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6454C8).withValues(alpha: .10),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var i = 0; i < HomePage._activity.length; i++)
          _ActivityTile(
            item: HomePage._activity[i],
            showDivider: i != HomePage._activity.length - 1,
          ),
      ],
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item, required this.showDivider});
  final _ActivityItem item;
  final bool showDivider;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      border: showDivider
          ? const Border(bottom: BorderSide(color: Color(0xFFEDEAF3)))
          : null,
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: item.bg, shape: BoxShape.circle),
          child: Icon(item.icon, color: item.color, size: 24),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.type}  •  ${item.time}',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: item.bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.badge,
            style: TextStyle(
              color: item.color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.more_vert_rounded, color: Color(0xFF111827)),
      ],
    ),
  );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 54,
    height: 54,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6454C8).withValues(alpha: .12),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Icon(icon, color: const Color(0xFF111827), size: 30),
  );
}

class _Badge extends StatelessWidget {
  const _Badge();
  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      color: AppColors.blue,
      shape: BoxShape.circle,
    ),
    child: const Text(
      '3',
      style: TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _SecurityFeature extends StatelessWidget {
  const _SecurityFeature(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: Colors.white, size: 21),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
    ],
  );
}

class _QuickItem {
  const _QuickItem(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.routeName,
  );
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String routeName;
}

class _ActivityItem {
  const _ActivityItem(
    this.title,
    this.type,
    this.time,
    this.badge,
    this.icon,
    this.color,
    this.bg,
  );
  final String title;
  final String type;
  final String time;
  final String badge;
  final IconData icon;
  final Color color;
  final Color bg;
}
