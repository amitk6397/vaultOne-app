import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/neon_auth_widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _quickItems = [
    _QuickItem('File Vault', '128 Files', Icons.folder_special_rounded,
        Color(0xFF7C3DFF), AppRoutes.filesVaultName),
    _QuickItem('Passwords', '74 Items', Icons.lock_rounded, Color(0xFF39C978),
        AppRoutes.passwordsName),
    _QuickItem('Digi Locker', 'Documents', Icons.account_balance_rounded,
        Color(0xFF2F86FF), AppRoutes.documentsName),
    _QuickItem('Photos', '342 Photos', Icons.image_rounded,
        Color(0xFF29A8FF), AppRoutes.photoGalleryName),
    _QuickItem('Videos', '36 Videos', Icons.play_circle_rounded,
        Color(0xFF6E4BFF), AppRoutes.videoGalleryName),
    _QuickItem('OCR Scanner', '12 Scans', Icons.document_scanner_rounded,
        Color(0xFFFF8B22), AppRoutes.scannerName),
  ];

  static const _recentItems = [
    _RecentItem('Aadhaar Card.pdf', 'Digi Locker', '2 mins ago', 'Viewed',
        Icons.picture_as_pdf_rounded, Color(0xFFE92727)),
    _RecentItem('Passport Photo.jpg', 'Photos', '15 mins ago', 'Added',
        Icons.image_rounded, Color(0xFF35B45A)),
    _RecentItem('Google Account Password', 'Passwords', '1 hour ago',
        'Updated', Icons.lock_rounded, Color(0xFF7149F5)),
    _RecentItem('Electricity Bill.pdf', 'OCR Scan', '2 hours ago', 'Scanned',
        Icons.document_scanner_rounded, Color(0xFFFF8B22)),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.home),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.scaffold),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 112),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HomeHeader(),
                const SizedBox(height: 18),
                const _VaultHeroCard(),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Quick Access',
                  action: 'Customize',
                  icon: Icons.edit_rounded,
                  onTap: () => _showMessage(context, 'Customize coming soon'),
                ),
                const SizedBox(height: 14),
                const _QuickGrid(),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Recent Items',
                  action: 'View All',
                  icon: Icons.arrow_forward_rounded,
                  onTap: () => context.pushNamed(AppRoutes.filesVaultName),
                ),
                const SizedBox(height: 12),
                const _RecentPanel(),
                const SizedBox(height: 18),
                const _InsightRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareIcon(icon: Icons.menu_rounded, onTap: () {}),
        const SizedBox(width: 10),
        const VaultShieldLogo(size: 42, glass: false),
        const SizedBox(width: 8),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                text: 'vault',
                style: AppTextStyles.heading.copyWith(fontSize: 22),
                children: const [
                  TextSpan(
                    text: 'one',
                    style: TextStyle(color: AppColors.purple),
                  ),
                ],
              ),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
        _SquareIcon(icon: Icons.search_rounded, onTap: () {}),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _SquareIcon(icon: Icons.notifications_none_rounded, onTap: () {}),
            const Positioned(right: -4, top: -4, child: _Badge()),
          ],
        ),
        const SizedBox(width: 8),
        const _Avatar(),
      ],
    );
  }
}

class _VaultHeroCard extends StatelessWidget {
  const _VaultHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 198,
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF115DFF), Color(0xFF6C2DF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: .25),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good Morning, Amit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your vault is\nSafe & Encrypted',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1.16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .92),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 17),
                    SizedBox(width: 7),
                    Text(
                      'Backup: Today, 08:30 AM',
                      style: TextStyle(
                        color: Color(0xFF35217D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF35217D), size: 17),
                  ],
                ),
              ),
              const Spacer(),
              const Row(
                children: [
                  Expanded(
                    child: _SecurityChip(
                      Icons.lock_outline_rounded,
                      'AES-256\nEncryption',
                    ),
                  ),
                  Expanded(
                    child: _SecurityChip(
                      Icons.visibility_off_outlined,
                      'Zero-Knowledge\nPrivacy',
                    ),
                  ),
                  Expanded(
                    child: _SecurityChip(
                      Icons.fingerprint_rounded,
                      'Biometric\nLock',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: HomePage._quickItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: columns == 2 ? 1.05 : .98,
          ),
          itemBuilder: (context, index) =>
              _QuickCard(item: HomePage._quickItems[index]),
        );
      },
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.item});

  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pushNamed(item.routeName),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F2FA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF071943).withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: item.color, size: 34),
            ),
            const SizedBox(height: 12),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              item.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(fontSize: 12, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentPanel extends StatelessWidget {
  const _RecentPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F2FA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF071943).withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < HomePage._recentItems.length; i++)
            _RecentTile(
              item: HomePage._recentItems[i],
              showDivider: i != HomePage._recentItems.length - 1,
            ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.item, required this.showDivider});

  final _RecentItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFEDEFF7)))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: 12),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.type} - ${item.time}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.badge,
              style: TextStyle(
                color: item.color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(Icons.more_vert_rounded,
              color: Color(0xFF687492), size: 21),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _MiniInsight(
            title: 'Storage Overview',
            value: '2.34 GB',
            subtitle: 'of 10 GB used',
            icon: Icons.donut_large_rounded,
            color: AppColors.purple,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MiniInsight(
            title: 'Security Score',
            value: '98%',
            subtitle: 'Excellent',
            icon: Icons.verified_user_rounded,
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _MiniInsight extends StatelessWidget {
  const _MiniInsight({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F2FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label.copyWith(fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, color: color, size: 34),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
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
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String action;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: AppTextStyles.heading.copyWith(fontSize: 18)),
        ),
        TextButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: AppColors.purple, size: 17),
          label: Text(
            action,
            style: AppTextStyles.link.copyWith(color: AppColors.purple),
          ),
        ),
      ],
    );
  }
}

class _SquareIcon extends StatelessWidget {
  const _SquareIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF071943).withValues(alpha: .06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF111827), size: 23),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.purple, width: 2),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5FF), Color(0xFFF3ECFF)],
        ),
      ),
      child:
          const Icon(Icons.person_rounded, color: Color(0xFF111827), size: 28),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19,
      height: 19,
      alignment: Alignment.center,
      decoration:
          const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
      child: const Text(
        '3',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SecurityChip extends StatelessWidget {
  const _SecurityChip(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 19),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
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

class _RecentItem {
  const _RecentItem(
    this.title,
    this.type,
    this.time,
    this.badge,
    this.icon,
    this.color,
  );

  final String title;
  final String type;
  final String time;
  final String badge;
  final IconData icon;
  final Color color;
}
