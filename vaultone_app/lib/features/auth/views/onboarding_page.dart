import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/auth_constants.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../shared/widgets/app_loading_indicator.dart';
import '../../../shared/widgets/neon_auth_widgets.dart';
import '../models/onboarding_slide.dart';
import '../providers/onboarding_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();

  List<OnboardingSlide> _fallbackSlides(BuildContext context) => [
    OnboardingSlide(
      id: 0,
      image: '',
      title: context.l10n.tr('digital_life_organized'),
      subtitle: context.l10n.tr('digital_life_description'),
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
    final slidesAsync = ref.watch(onboardingSlidesProvider);

    return slidesAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF07061B),
        body: Center(child: _OnboardingLoader()),
      ),
      error: (_, _) => _OnboardingScaffold(
        controller: _controller,
        slides: _fallbackSlides(context),
        currentIndex: 0,
        onPageChanged: _setIndex,
        onComplete: _completeOnboarding,
      ),
      data: (slides) {
        final visibleSlides = slides.isEmpty
            ? _fallbackSlides(context)
            : slides;
        final safeIndex = currentIndex.clamp(0, visibleSlides.length - 1);
        return _OnboardingScaffold(
          controller: _controller,
          slides: visibleSlides,
          currentIndex: safeIndex,
          onPageChanged: _setIndex,
          onComplete: _completeOnboarding,
        );
      },
    );
  }

  void _setIndex(int index) {
    ref.read(onboardingIndexProvider.notifier).state = index;
  }

  Future<void> _completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(AuthConstants.onboardingCompletedKey, true);
    if (mounted) context.goNamed(AppRoutes.loginName);
  }
}

class _OnboardingLoader extends StatelessWidget {
  const _OnboardingLoader();

  @override
  Widget build(BuildContext context) {
    return const AppLoadingIndicator(size: 44);
  }
}

class _OnboardingScaffold extends StatelessWidget {
  const _OnboardingScaffold({
    required this.controller,
    required this.slides,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onComplete,
  });

  final PageController controller;
  final List<OnboardingSlide> slides;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07061B),
      body: Stack(
        children: [
          PageView.builder(
            controller: controller,
            itemCount: slides.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) =>
                _OnboardingSlideView(slide: slides[index]),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 18),
                child: _SkipButton(onTap: onComplete),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeonDots(length: slides.length, index: currentIndex),
                    const SizedBox(height: 18),
                    NeonButton(
                      label: currentIndex == slides.length - 1
                          ? context.l10n.tr('get_started')
                          : context.l10n.tr('next'),
                      onPressed: () {
                        if (currentIndex == slides.length - 1) {
                          onComplete();
                          return;
                        }
                        controller.nextPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.tr('skip'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
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

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 780;

    return Stack(
      fit: StackFit.expand,
      children: [
        _FullscreenImage(imageUrl: slide.image),
        const _ImageScrim(),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              26,
              compact ? 78 : 96,
              26,
              compact ? 154 : 178,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heroHeading.copyWith(
                    color: Colors.white,
                    fontSize: compact ? 28 : 34,
                    height: 1.08,
                    shadows: const [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 18,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 14 : 18),
                Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xE6FFFFFF),
                    fontSize: compact ? 14 : 15.5,
                    height: 1.45,
                    shadows: const [
                      Shadow(
                        color: Color(0x99000000),
                        blurRadius: 14,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FullscreenImage extends StatelessWidget {
  const _FullscreenImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return const _FallbackBackground();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _FallbackBackground();
      },
      errorBuilder: (_, _, _) => const _FallbackBackground(),
    );
  }
}

class _ImageScrim extends StatelessWidget {
  const _ImageScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x66000000), Color(0x1A000000), Color(0xF207061B)],
          stops: [0, .42, 1],
        ),
      ),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  const _FallbackBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF854CFF), Color(0xFF0CB7F2), Color(0xFF07061B)],
        ),
      ),
      child: const Center(child: VaultShieldLogo(size: 132)),
    );
  }
}
