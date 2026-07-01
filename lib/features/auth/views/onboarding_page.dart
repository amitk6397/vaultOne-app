import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/neon_auth_widgets.dart';
import '../providers/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();

  static const _pages = [
    _OnboardingContent(
      titleTop: 'Your Digital Life',
      titleGradient: 'Organized',
      subtitle:
          'Store documents, passwords, assets and\nimportant files securely in one place.',
      button: 'Next',
      illustration: _IllustrationKind.organized,
      features: [
        _FeatureLine(
          Icons.shield_outlined,
          'AES-256 Encryption',
          'Military-grade encryption keeps your\ndata 100% secure.',
          Color(0xFF854CFF),
        ),
        _FeatureLine(
          Icons.document_scanner_outlined,
          'OCR Scanner',
          'Scan and extract text from your\ndocuments instantly.',
          Color(0xFF0CB7F2),
        ),
        _FeatureLine(
          Icons.cloud_outlined,
          'Secure Cloud Backup',
          'Backup your data in encrypted cloud\nand never lose important things.',
          Color(0xFF04C8DD),
        ),
      ],
    ),
    _OnboardingContent(
      titleTop: 'Digital Locker for',
      titleGradient: 'Important Documents',
      subtitle:
          'Store and protect your important documents\nlike never before. Access them anytime, anywhere\nwith complete security.',
      button: 'Continue',
      illustration: _IllustrationKind.documents,
      features: [
        _FeatureLine(
          Icons.enhanced_encryption_outlined,
          'Military Grade\nEncryption',
          'AES-256 bit\nprotection',
          Color(0xFF9B45FF),
        ),
        _FeatureLine(
          Icons.document_scanner_outlined,
          'OCR Search',
          'Find text in\ndocuments\ninstantly',
          Color(0xFF16C7FF),
        ),
        _FeatureLine(
          Icons.share_outlined,
          'Secure Share',
          'Share documents\nsafely with\ncontrol',
          Color(0xFF38E0A3),
        ),
      ],
      compactFeatures: true,
    ),
    _OnboardingContent(
      titleTop: 'Everything You Need,',
      titleGradient: 'Always Protected',
      subtitle:
          'From important documents to personal memories,\nstore everything securely and access it\nanytime, anywhere.',
      button: 'Get Started',
      illustration: _IllustrationKind.protected,
      features: [
        _FeatureLine(
          Icons.verified_user_outlined,
          'Bank-Level Security',
          'Your data is protected with AES-256\nencryption and advanced security.',
          Color(0xFF27C8FF),
        ),
        _FeatureLine(
          Icons.cloud_upload_outlined,
          'Secure Cloud Backup',
          'Automatic backup ensures your data\nis always safe and never lost.',
          Color(0xFF17BAF8),
        ),
        _FeatureLine(
          Icons.devices_outlined,
          'Access Everywhere',
          'Access your vault seamlessly across\nall your devices.',
          Color(0xFF954CFF),
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(onboardingIndexProvider);

    return Scaffold(
      body: NeonAuthBackground(
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 18),
                  child: _SkipButton(
                    onTap: () => context.goNamed(AppRoutes.loginName),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) =>
                      ref.read(onboardingIndexProvider.notifier).state = index,
                  itemBuilder: (context, index) =>
                      _OnboardingSlide(content: _pages[index], index: index),
                ),
              ),
              NeonDots(length: _pages.length, index: currentIndex),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: NeonButton(
                  label: _pages[currentIndex].button,
                  onPressed: () {
                    if (currentIndex == _pages.length - 1) {
                      context.goNamed(AppRoutes.loginName);
                      return;
                    }
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: .15)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Skip',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.content, required this.index});

  final _OnboardingContent content;
  final int index;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 780;
    final tiny = size.height < 700;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, tiny ? 0 : 4, 24, 6),
          child: Column(
            children: [
              SizedBox(
                height: tiny
                    ? 118
                    : compact
                    ? 145
                    : 210,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 340,
                    height: 240,
                    child: _HeroIllustration(kind: content.illustration),
                  ),
                ),
              ),
              SizedBox(height: tiny ? 6 : 10),
              Text(
                content.titleTop,
                textAlign: TextAlign.center,
                style: AppTextStyles.heroHeading.copyWith(
                  fontSize: tiny
                      ? 23
                      : compact
                      ? 25
                      : 30,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 3),
              GradientText(
                content.titleGradient,
                textAlign: TextAlign.center,
                style: AppTextStyles.heroHeading.copyWith(
                  fontSize: tiny
                      ? 23
                      : compact
                      ? 25
                      : 30,
                  height: 1.08,
                ),
              ),
              SizedBox(height: tiny ? 8 : 12),
              Text(
                content.subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xCCFFFFFF),
                  fontSize: tiny
                      ? 12
                      : compact
                      ? 13
                      : 15,
                  height: 1.32,
                ),
              ),
              SizedBox(height: tiny ? 8 : 12),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: constraints.maxWidth - 48,
                      child: content.compactFeatures
                          ? _CompactFeatureGrid(items: content.features)
                          : _FeaturePanel(
                              items: content.features,
                              compact: compact,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration({required this.kind});

  final _IllustrationKind kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _IllustrationKind.organized:
        return const _OrganizedIllustration();
      case _IllustrationKind.documents:
        return const _DocumentsIllustration();
      case _IllustrationKind.protected:
        return const _ProtectedIllustration();
    }
  }
}

class _OrganizedIllustration extends StatelessWidget {
  const _OrganizedIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned(bottom: 20, child: _GlowRing(width: 295)),
        const Positioned(
          top: 26,
          left: 70,
          child: _FloatingCard(
            icon: Icons.description_rounded,
            width: 104,
            height: 82,
            angle: -.18,
          ),
        ),
        const Positioned(
          top: 112,
          left: 20,
          child: _FloatingCard(
            icon: Icons.image_rounded,
            width: 88,
            height: 72,
            angle: -.20,
            color: Color(0xFF4E5BFF),
          ),
        ),
        const Positioned(top: 28, right: 46, child: _CloudUpload()),
        const Positioned(
          top: 122,
          right: 12,
          child: _FloatingCard(
            icon: Icons.password_rounded,
            width: 112,
            height: 78,
            angle: .18,
            color: Color(0xFF715DFF),
          ),
        ),
        const Positioned(bottom: 74, right: 62, child: _FolderIcon()),
        Positioned(
          top: 82,
          child: Container(
            width: 150,
            height: 188,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF596BFF), Color(0xFF130C4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFF82A4FF), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA6035FF),
                  blurRadius: 35,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: const Center(child: VaultShieldLogo(size: 76, glass: false)),
          ),
        ),
        Positioned(top: 168, child: _Dial(size: 70)),
      ],
    );
  }
}

class _DocumentsIllustration extends StatelessWidget {
  const _DocumentsIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned(bottom: 28, child: _GlowRing(width: 302)),
        const Positioned(
          top: 30,
          left: 30,
          child: _DocBadge(
            label: 'PASSPORT',
            icon: Icons.language_rounded,
            angle: -.22,
          ),
        ),
        const Positioned(
          top: 88,
          right: 10,
          child: _DocBadge(
            label: 'AADHAAR',
            icon: Icons.badge_outlined,
            angle: .14,
            wide: true,
          ),
        ),
        const Positioned(
          top: 172,
          left: 10,
          child: _DocBadge(
            label: 'INSURANCE',
            icon: Icons.shield_outlined,
            angle: -.10,
          ),
        ),
        const Positioned(
          top: 190,
          right: 18,
          child: _DocBadge(
            label: 'CERTIFICATE',
            icon: Icons.workspace_premium_outlined,
            angle: .12,
            color: Color(0xFFFFE7C3),
          ),
        ),
        Positioned(
          top: 92,
          child: Container(
            width: 168,
            height: 182,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF22286C), Color(0xFF08072E)],
              ),
              border: Border.all(color: const Color(0xFF6978FF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA6F35FF),
                  blurRadius: 38,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: Stack(
              children: const [
                Positioned(
                  right: 24,
                  top: 38,
                  child: Icon(
                    Icons.folder_rounded,
                    color: Color(0xFFFFD091),
                    size: 92,
                  ),
                ),
                Positioned(
                  left: -8,
                  top: 22,
                  child: VaultShieldLogo(size: 104, glass: false),
                ),
              ],
            ),
          ),
        ),
        const Positioned(bottom: 55, right: 74, child: _MiniShieldLock()),
      ],
    );
  }
}

class _ProtectedIllustration extends StatelessWidget {
  const _ProtectedIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned(bottom: 28, child: _GlowRing(width: 300)),
        const Positioned(
          top: 70,
          left: 6,
          child: _SideTile(
            icon: Icons.folder_rounded,
            label: 'Files',
            angle: -.12,
            color: Color(0xFFFFB649),
          ),
        ),
        const Positioned(
          top: 206,
          left: 2,
          child: _SideTile(
            icon: Icons.lock_rounded,
            label: 'Passwords',
            angle: -.16,
            color: Color(0xFFC6CFFF),
          ),
        ),
        const Positioned(
          top: 76,
          right: 0,
          child: _SideTile(
            icon: Icons.receipt_long_rounded,
            label: 'Invoices',
            angle: .18,
            color: Color(0xFFFFFFFF),
          ),
        ),
        const Positioned(
          top: 214,
          right: 8,
          child: _SideTile(
            icon: Icons.photo_rounded,
            label: 'Media',
            angle: .16,
            color: Color(0xFF7AA3FF),
          ),
        ),
        const Positioned(top: 0, child: _LargeCloud()),
        Positioned(
          top: 122,
          child: Container(
            width: 142,
            height: 206,
            padding: const EdgeInsets.fromLTRB(14, 48, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF07091F),
              border: Border.all(color: const Color(0xFF546BFF), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xAA5435FF),
                  blurRadius: 40,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              children: const [
                Text(
                  'All in One\nSecure Vault',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 10),
                _PhoneRow(Icons.description_rounded, 'Documents'),
                _PhoneRow(
                  Icons.lock_rounded,
                  'Passwords',
                  color: Color(0xFFAA4DFF),
                ),
                _PhoneRow(Icons.image_rounded, 'Photos'),
                _PhoneRow(
                  Icons.folder_rounded,
                  'Invoices',
                  color: Color(0xFFFFB22E),
                ),
              ],
            ),
          ),
        ),
        const Positioned(bottom: 34, child: _RoundLock()),
      ],
    );
  }
}

class _FeaturePanel extends StatelessWidget {
  const _FeaturePanel({required this.items, required this.compact});

  final List<_FeatureLine> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .11)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Padding(
              padding: EdgeInsets.all(compact ? 9 : 12),
              child: Row(
                children: [
                  _FeatureIcon(
                    icon: items[i].icon,
                    color: items[i].color,
                    size: compact ? 44 : 54,
                  ),
                  SizedBox(width: compact ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          items[i].title,
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white,
                            fontSize: compact ? 14 : 16,
                          ),
                        ),
                        SizedBox(height: compact ? 2 : 4),
                        Text(
                          items[i].subtitle,
                          style: AppTextStyles.body.copyWith(
                            color: const Color(0xBFFFFFFF),
                            fontSize: compact ? 11.5 : 13,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (i != items.length - 1)
              Divider(height: 1, color: Colors.white.withValues(alpha: .09)),
          ],
        ],
      ),
    );
  }
}

class _CompactFeatureGrid extends StatelessWidget {
  const _CompactFeatureGrid({required this.items});

  final List<_FeatureLine> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final item in items) ...[
          Expanded(
            child: Container(
              height: 108,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: .11)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureIcon(icon: item.icon, color: item.color, size: 46),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.fieldBorder,
                      fontSize: 10,
                      height: 1.18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (item != items.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  const _FeatureIcon({
    required this.icon,
    required this.color,
    this.size = 58,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: .95),
            const Color(0xFF193087).withValues(alpha: .82),
          ],
        ),
      ),
      child: Icon(icon, color: Colors.white, size: size * .45),
    );
  }
}

class _GlowRing extends StatelessWidget {
  const _GlowRing({required this.width});
  final double width;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: 36,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFF20D6FF), width: 2),
      boxShadow: const [BoxShadow(color: Color(0xFF7B2DFF), blurRadius: 28)],
    ),
  );
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({
    required this.icon,
    required this.width,
    required this.height,
    required this.angle,
    this.color = const Color(0xFFFFFFFF),
  });
  final IconData icon;
  final double width;
  final double height;
  final double angle;
  final Color color;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: width,
      height: height,
      decoration: _glassBox(14),
      child: Icon(icon, color: color, size: 38),
    ),
  );
}

class _CloudUpload extends StatelessWidget {
  const _CloudUpload();
  @override
  Widget build(BuildContext context) => const Icon(
    Icons.cloud_upload_rounded,
    color: Color(0xFF7557FF),
    size: 92,
    shadows: [Shadow(color: Color(0xFF21CFFF), blurRadius: 18)],
  );
}

class _LargeCloud extends StatelessWidget {
  const _LargeCloud();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 210,
    height: 120,
    child: Stack(
      alignment: Alignment.center,
      children: const [
        Icon(
          Icons.cloud_rounded,
          color: Color(0xFF3C59FF),
          size: 192,
          shadows: [Shadow(color: Color(0xFF8A2DFF), blurRadius: 20)],
        ),
        VaultShieldLogo(size: 88, glass: false),
      ],
    ),
  );
}

class _FolderIcon extends StatelessWidget {
  const _FolderIcon();
  @override
  Widget build(BuildContext context) => const Icon(
    Icons.folder_rounded,
    color: Color(0xFFFFB84D),
    size: 78,
    shadows: [Shadow(color: Color(0xAAFF8F18), blurRadius: 18)],
  );
}

class _Dial extends StatelessWidget {
  const _Dial({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [Color(0xFFB5C0FF), Color(0xFF171A67)],
      ),
      border: Border.all(color: Colors.white.withValues(alpha: .5), width: 2),
    ),
    child: const Icon(
      Icons.radio_button_checked_rounded,
      color: Colors.white70,
    ),
  );
}

class _DocBadge extends StatelessWidget {
  const _DocBadge({
    required this.label,
    required this.icon,
    required this.angle,
    this.wide = false,
    this.color = const Color(0xFFBFC6FF),
  });
  final String label;
  final IconData icon;
  final double angle;
  final bool wide;
  final Color color;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: wide ? 122 : 94,
      height: 82,
      padding: const EdgeInsets.all(10),
      decoration: _glassBox(12, fill: color.withValues(alpha: .18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Icon(icon, color: color, size: 31),
        ],
      ),
    ),
  );
}

class _MiniShieldLock extends StatelessWidget {
  const _MiniShieldLock();
  @override
  Widget build(BuildContext context) => const Icon(
    Icons.lock_rounded,
    color: Color(0xFFC5D5FF),
    size: 58,
    shadows: [Shadow(color: Color(0xFF28D5FF), blurRadius: 18)],
  );
}

class _SideTile extends StatelessWidget {
  const _SideTile({
    required this.icon,
    required this.label,
    required this.angle,
    required this.color,
  });
  final IconData icon;
  final String label;
  final double angle;
  final Color color;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 92,
      height: 92,
      decoration: _glassBox(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow(
    this.icon,
    this.label, {
    this.color = const Color(0xFF24C9FF),
  });
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    height: 30,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
      ],
    ),
  );
}

class _RoundLock extends StatelessWidget {
  const _RoundLock();
  @override
  Widget build(BuildContext context) => Container(
    width: 76,
    height: 76,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF11135E),
      border: Border.all(color: const Color(0xFF2ACFFF), width: 2),
      boxShadow: const [BoxShadow(color: Color(0xFF2BCBFF), blurRadius: 20)],
    ),
    child: const Icon(
      Icons.lock_outline_rounded,
      color: Color(0xFF7DEAFF),
      size: 42,
    ),
  );
}

BoxDecoration _glassBox(double radius, {Color? fill}) => BoxDecoration(
  borderRadius: BorderRadius.circular(radius),
  color: fill ?? Colors.white.withValues(alpha: .08),
  border: Border.all(color: Colors.white.withValues(alpha: .13)),
  boxShadow: const [
    BoxShadow(color: Color(0x663225FF), blurRadius: 18, offset: Offset(0, 10)),
  ],
);

class _OnboardingContent {
  const _OnboardingContent({
    required this.titleTop,
    required this.titleGradient,
    required this.subtitle,
    required this.button,
    required this.illustration,
    required this.features,
    this.compactFeatures = false,
  });
  final String titleTop;
  final String titleGradient;
  final String subtitle;
  final String button;
  final _IllustrationKind illustration;
  final List<_FeatureLine> features;
  final bool compactFeatures;
}

class _FeatureLine {
  const _FeatureLine(this.icon, this.title, this.subtitle, this.color);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

enum _IllustrationKind { organized, documents, protected }
