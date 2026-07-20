import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_image.dart';
import '../../../constants/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../files_vault/providers/files_vault_provider.dart';
import '../models/home_banner.dart';
import '../providers/banner_provider.dart';
import '../providers/home_customization_provider.dart';
import '../../media/models/media_item.dart';
import '../../media/providers/media_provider.dart';
import '../../passwords/providers/password_vault_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/neon_auth_widgets.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final controller = ref.read(mediaLibraryProvider.notifier);
      await controller.loadVideoStorage();
      await controller.loadPrivateVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final files = ref.watch(filesVaultProvider);
    final passwords = ref.watch(passwordVaultProvider);
    final notifications = ref.watch(notificationProvider);
    final media = ref.watch(mediaLibraryProvider);
    final customization = ref.watch(homeCustomizationProvider);
    final photoCount = media.items
        .where((item) => item.kind == MediaKind.photo && !item.isDeleted)
        .length;
    final videoCount = media.items
        .where(
          (item) =>
              item.kind == MediaKind.video &&
              item.visibility == MediaVisibility.private &&
              !item.isDeleted,
        )
        .length;

    final quickItems = <_QuickItem>[
      _QuickItem(
        HomeModuleId.connect,
        'Vault Connect',
        'Private chat & secure sharing',
        Icons.forum_rounded,
        AppImages.moduleFileVault,
        customization.colorFor(
          HomeModuleId.connect,
          _moduleColor(HomeModuleId.connect),
        ),
        AppRoutes.connectHomeName,
      ),
      _QuickItem(
        HomeModuleId.files,
        context.l10n.tr('file_vault'),
        context.l10n.tr('files_count', args: {'count': files.activeCount}),
        Icons.folder_special_rounded,
        AppImages.moduleFileVault,
        customization.colorFor(
          HomeModuleId.files,
          _moduleColor(HomeModuleId.files),
        ),
        AppRoutes.filesVaultName,
      ),
      _QuickItem(
        HomeModuleId.passwords,
        context.l10n.tr('passwords'),
        context.l10n.tr(
          'items_count',
          args: {'count': passwords.totalPasswords},
        ),
        Icons.lock_rounded,
        AppImages.modulePasswords,
        customization.colorFor(
          HomeModuleId.passwords,
          _moduleColor(HomeModuleId.passwords),
        ),
        AppRoutes.passwordsName,
      ),
      _QuickItem(
        HomeModuleId.photos,
        context.l10n.tr('photos'),
        context.l10n.tr('photos_count', args: {'count': photoCount}),
        Icons.image_rounded,
        AppImages.modulePhotos,
        customization.colorFor(
          HomeModuleId.photos,
          _moduleColor(HomeModuleId.photos),
        ),
        AppRoutes.photoGalleryName,
      ),
      _QuickItem(
        HomeModuleId.videos,
        context.l10n.tr('videos'),
        context.l10n.tr('videos_count', args: {'count': videoCount}),
        Icons.play_circle_rounded,
        AppImages.moduleVideos,
        customization.colorFor(
          HomeModuleId.videos,
          _moduleColor(HomeModuleId.videos),
        ),
        AppRoutes.videoGalleryName,
      ),
      _QuickItem(
        HomeModuleId.scanner,
        context.l10n.tr('ocr_scanner'),
        context.l10n.tr('open_scanner'),
        Icons.document_scanner_rounded,
        AppImages.moduleOcrScanner,
        customization.colorFor(
          HomeModuleId.scanner,
          _moduleColor(HomeModuleId.scanner),
        ),
        AppRoutes.scannerName,
      ),
    ];
    final orderedQuickItems = _orderedQuickItems(quickItems, customization);

    final recentItems = _recentItems(context, files, passwords);
    final notificationCount = notifications.unreadCount;
    final securityScore = (100 - passwords.weakPasswords * 8)
        .clamp(60, 100)
        .toInt();

    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 12,
          title: _HomeHeader(notificationCount: notificationCount),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(activeTab: AppNavTab.home),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.purple,
            onRefresh: () async {
              await ref.read(mediaLibraryProvider.notifier).loadPrivateVideos();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                0,
                14,
                0,
                116 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _PromoBannerCarousel(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: context.l10n.tr('quick_access'),
                          action: context.l10n.tr('customize'),
                          icon: Icons.edit_rounded,
                          onTap: () => _openCustomizeStudio(context),
                        ),
                        const SizedBox(height: 14),
                        _QuickGrid(
                          items: orderedQuickItems,
                          customization: customization,
                          onCustomize: () => _openCustomizeStudio(context),
                        ),
                        const SizedBox(height: 6),
                        _SectionHeader(
                          title: context.l10n.tr('recent_items'),
                          action: context.l10n.tr('view_all'),
                          icon: Icons.arrow_forward_rounded,
                          onTap: () =>
                              context.pushNamed(AppRoutes.filesVaultName),
                        ),
                        const SizedBox(height: 12),
                        _RecentPanel(items: recentItems),
                        const SizedBox(height: 14),
                        _InsightRow(
                          storageBytes: files.totalBytes,
                          securityScore: securityScore,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openCustomizeStudio(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _QuickAccessStudio(),
    );
  }

  static List<_QuickItem> _orderedQuickItems(
    List<_QuickItem> items,
    HomeCustomizationState customization,
  ) {
    final byId = {for (final item in items) item.id: item};
    return [
      for (final id in customization.moduleOrder)
        if (byId[id] != null && customization.isVisible(id)) byId[id]!,
    ];
  }

  static List<_RecentItem> _recentItems(
    BuildContext context,
    FilesVaultState files,
    PasswordVaultState passwords,
  ) {
    final items = <_RecentItem>[
      for (final file in files.files)
        _RecentItem(
          file.name,
          context.l10n.tr('file_vault'),
          _timeAgo(context, file.updatedAt),
          context.l10n.tr(file.isPrivate ? 'private' : 'added'),
          file.icon,
          file.color,
          file.updatedAt,
          AppRoutes.filesVaultName,
        ),
      for (final entry in passwords.entries)
        _RecentItem(
          entry.title,
          context.l10n.tr('passwords'),
          _timeAgo(context, entry.updatedAt),
          context.l10n.tr(entry.isWeak ? 'weak' : 'updated'),
          Icons.lock_rounded,
          AppColors.purple,
          entry.updatedAt,
          AppRoutes.passwordsName,
        ),
    ]..sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return items.take(4).toList();
  }

  static String _timeAgo(BuildContext context, DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return context.l10n.tr('just_now');
    if (diff.inMinutes < 60) {
      return context.l10n.tr('minutes_ago', args: {'count': diff.inMinutes});
    }
    if (diff.inHours < 24) {
      return context.l10n.tr('hours_ago', args: {'count': diff.inHours});
    }
    return context.l10n.tr('days_ago', args: {'count': diff.inDays});
  }
}

/// -------------------- HEADER --------------------

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.notificationCount});

  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
        Stack(
          clipBehavior: Clip.none,
          children: [
            _SquareIcon(
              icon: Icons.notifications_none_rounded,
              onTap: () => context.pushNamed(AppRoutes.notificationsName),
            ),
            if (notificationCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: _Badge(count: notificationCount),
              ),
          ],
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => context.pushNamed(AppRoutes.profileName),
          borderRadius: BorderRadius.circular(24),
          child: const _Avatar(),
        ),
      ],
    );
  }
}

/// -------------------- TOP PROMO BANNER CAROUSEL --------------------

class _PromoBanner {
  const _PromoBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.ctaLabel,
    this.image,
    this.routeName,
  });

  factory _PromoBanner.fromHomeBanner(BuildContext context, HomeBanner banner) {
    return _PromoBanner(
      title: banner.title,
      subtitle: banner.subtitle,
      icon: Icons.security_rounded,
      gradient: const [Color(0xFF115DFF), Color(0xFF6C2DF5)],
      ctaLabel: banner.ctaLabel.isEmpty
          ? context.l10n.tr('explore')
          : banner.ctaLabel,
      image: banner.image,
      routeName: banner.routeName,
    );
  }

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String ctaLabel;
  final String? image;
  final String? routeName;
}

class _PromoBannerCarousel extends ConsumerStatefulWidget {
  const _PromoBannerCarousel();

  @override
  ConsumerState<_PromoBannerCarousel> createState() =>
      _PromoBannerCarouselState();
}

class _PromoBannerCarouselState extends ConsumerState<_PromoBannerCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final apiBanners = ref.watch(homeBannersProvider);
    final banners = apiBanners.maybeWhen(
      data: (items) => items
          .map((banner) => _PromoBanner.fromHomeBanner(context, banner))
          .toList(),
      orElse: () => <_PromoBanner>[],
    );

    if (banners.isEmpty) {
      return const _BannerGlassPlaceholder();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider.builder(
          carouselController: _controller,
          itemCount: banners.length,
          itemBuilder: (context, index, realIndex) =>
              _BannerCard(banner: banners[index]),
          options: CarouselOptions(
            height: 198,
            viewportFraction: 1,
            padEnds: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 600),
            autoPlayCurve: Curves.easeInOutCubic,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() => _activeIndex = index);
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(banners.length, (index) {
              final isActive = index == _activeIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.purple
                      : AppColors.purple.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final _PromoBanner banner;

  @override
  Widget build(BuildContext context) {
    // Banners are visual assets only; title/CTA copy belongs in the banner
    // management screen, not on the home surface.
    return InkWell(
      onTap: banner.routeName == null
          ? null
          : () => context.pushNamed(banner.routeName!),
      child: SizedBox.expand(
        child: banner.image != null && banner.image!.isNotEmpty
            ? Image.network(
                banner.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _BannerGlassPlaceholder(),
              )
            : const _BannerGlassPlaceholder(),
      ),
    );
    /*
    return InkWell(
      onTap: banner.routeName == null
          ? null
          : () => context.pushNamed(banner.routeName!),
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner.image != null && banner.image!.isNotEmpty)
              Image.network(
                banner.image!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: banner.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: banner.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xDD071943), Color(0x66071943)],
                ),
              ),
            ),
            if (banner.image == null || banner.image!.isEmpty)
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(
                  banner.icon,
                  size: 110,
                  color: Colors.white.withValues(alpha: .12),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(banner.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    banner.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    banner.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .9),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .95),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          banner.ctaLabel,
                          style: TextStyle(
                            color: banner.gradient.last,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: banner.gradient.last,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ); */
  }
}

/// -------------------- QUICK ACCESS GRID --------------------

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({
    required this.items,
    required this.customization,
    required this.onCustomize,
  });

  final List<_QuickItem> items;
  final HomeCustomizationState customization;
  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyQuickAccess(onCustomize: onCustomize);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = switch (customization.columns) {
          HomeModuleColumns.two => 2,
          HomeModuleColumns.three => 3,
          HomeModuleColumns.auto => constraints.maxWidth >= 520 ? 3 : 2,
        };
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: _aspectRatio(columns, customization.cardStyle),
          ),
          itemBuilder: (context, index) => _QuickCard(
            item: items[index],
            index: index,
            style: customization.cardStyle,
            columns: columns,
          ),
        );
      },
    );
  }

  double _aspectRatio(int columns, HomeModuleCardStyle style) {
    return switch (style) {
      HomeModuleCardStyle.glassGrid => columns == 2 ? 1.05 : .74,
      HomeModuleCardStyle.commandDeck => columns == 2 ? 1.65 : .88,
      HomeModuleCardStyle.blueprint => columns == 2 ? 1.15 : .78,
    };
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.item,
    required this.index,
    required this.style,
    required this.columns,
  });

  final _QuickItem item;
  final int index;
  final HomeModuleCardStyle style;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => context.pushNamed(item.routeName),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(
          columns == 3
              ? 10
              : (style == HomeModuleCardStyle.commandDeck ? 12 : 14),
        ),
        decoration: BoxDecoration(
          color: style == HomeModuleCardStyle.blueprint
              ? item.color.withValues(alpha: isDark ? .18 : .08)
              : colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: style == HomeModuleCardStyle.blueprint
                ? item.color.withValues(alpha: .36)
                : colors.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: .22)
                  : const Color(0xFF071943).withValues(alpha: .08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: switch (style) {
          HomeModuleCardStyle.commandDeck => _CommandDeckCard(
            item: item,
            compact: columns == 3,
          ),
          HomeModuleCardStyle.blueprint => _BlueprintQuickCard(
            item: item,
            index: index,
            compact: columns == 3,
          ),
          HomeModuleCardStyle.glassGrid => _GlassQuickCard(
            item: item,
            compact: columns == 3,
          ),
        },
      ),
    );
  }
}

class _GlassQuickCard extends StatelessWidget {
  const _GlassQuickCard({required this.item, required this.compact});

  final _QuickItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: compact ? 46 : 58,
          constraints: BoxConstraints.tightFor(
            width: compact ? 46 : 58,
            height: compact ? 46 : 58,
          ),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
          ),
          child: _ModuleAssetImage(
            asset: item.image,
            borderRadius: compact ? 14 : 16,
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          item.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(
            color: item.color,
            fontSize: compact ? 12 : 14,
          ),
        ),
        SizedBox(height: compact ? 2 : 4),
        Text(
          item.subtitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            fontSize: compact ? 10.5 : 12,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _CommandDeckCard extends StatelessWidget {
  const _CommandDeckCard({required this.item, required this.compact});

  final _QuickItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ModuleIconBox(item: item, size: 42),
          const SizedBox(height: 8),
          Text(
            item.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label.copyWith(
              color: item.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(fontSize: 10.5, height: 1.05),
          ),
        ],
      );
    }
    return Row(
      children: [
        _ModuleIconBox(item: item, size: 46),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label.copyWith(
                  color: item.color,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleIconBox extends StatelessWidget {
  const _ModuleIconBox({
    required this.item,
    required this.size,
  });

  final _QuickItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: .18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _ModuleAssetImage(asset: item.image, borderRadius: 14),
    );
  }
}

class _BannerGlassPlaceholder extends StatelessWidget {
  const _BannerGlassPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 198,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surfaceContainerHighest.withValues(alpha: .72),
            AppColors.purple.withValues(alpha: .10),
            colors.surface.withValues(alpha: .58),
          ],
        ),
        border: Border.all(
          color: colors.onSurface.withValues(alpha: .08),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: .08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -44,
            right: -18,
            child: _GlassOrb(
              size: 132,
              color: AppColors.purple.withValues(alpha: .12),
            ),
          ),
          Positioned(
            bottom: -50,
            left: 22,
            child: _GlassOrb(
              size: 112,
              color: colors.primary.withValues(alpha: .08),
            ),
          ),
          Center(
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: .55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.onSurface.withValues(alpha: .08),
                ),
              ),
              child: Icon(
                Icons.shield_outlined,
                color: AppColors.purple.withValues(alpha: .72),
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassOrb extends StatelessWidget {
  const _GlassOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _ModuleAssetImage extends StatelessWidget {
  const _ModuleAssetImage({
    required this.asset,
    required this.borderRadius,
  });

  final String asset;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => const Icon(Icons.apps_rounded),
      ),
    );
  }
}

class _BlueprintQuickCard extends StatelessWidget {
  const _BlueprintQuickCard({
    required this.item,
    required this.index,
    required this.compact,
  });

  final _QuickItem item;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          right: -16,
          top: -12,
          child: Icon(
            item.icon,
            color: item.color.withValues(alpha: .12),
            size: 86,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '0${index + 1}',
                  style: TextStyle(
                    color: item.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Icon(Icons.drag_indicator_rounded, color: item.color, size: 18),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: compact ? 28 : 34,
              height: compact ? 28 : 34,
              child: _ModuleAssetImage(asset: item.image, borderRadius: 9),
            ),
            SizedBox(height: compact ? 6 : 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.label.copyWith(
                color: item.color,
                fontSize: compact ? 12 : 13,
              ),
            ),
            SizedBox(height: compact ? 2 : 3),
            Text(
              item.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontSize: compact ? 10.5 : 11,
                height: 1.05,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyQuickAccess extends StatelessWidget {
  const _EmptyQuickAccess({required this.onCustomize});

  final VoidCallback onCustomize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.dashboard_customize_rounded, color: colors.primary),
          const SizedBox(height: 8),
          Text(
            context.l10n.tr('all_modules_hidden'),
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.tr('restore_modules_hint'),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCustomize,
            icon: const Icon(Icons.tune_rounded),
            label: Text(context.l10n.tr('customize')),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessStudio extends ConsumerWidget {
  const _QuickAccessStudio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(homeCustomizationProvider);
    final controller = ref.read(homeCustomizationProvider.notifier);
    final colors = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .86,
      minChildSize: .52,
      maxChildSize: .94,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tr('blueprint_studio'),
                        style: AppTextStyles.heading.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.tr('blueprint_description'),
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.tr('reset'),
                  onPressed: controller.reset,
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BlueprintPreview(config: config),
            const SizedBox(height: 18),
            _StudioSection(
              title: context.l10n.tr('layout'),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: HomeModuleColumns.values.map((item) {
                  return _StudioChoiceChip(
                    selected: item == config.columns,
                    icon: switch (item) {
                      HomeModuleColumns.auto => Icons.auto_mode_rounded,
                      HomeModuleColumns.two => Icons.grid_view_rounded,
                      HomeModuleColumns.three => Icons.grid_3x3_rounded,
                    },
                    label: switch (item) {
                      HomeModuleColumns.auto => context.l10n.tr('auto'),
                      HomeModuleColumns.two => context.l10n.tr('two_columns'),
                      HomeModuleColumns.three => context.l10n.tr(
                        'three_columns',
                      ),
                    },
                    onTap: () => controller.setColumns(item),
                  );
                }).toList(),
              ),
            ),
            _StudioSection(
              title: context.l10n.tr('card_design'),
              child: Column(
                children: HomeModuleCardStyle.values.map((item) {
                  final selected = item == config.cardStyle;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primary.withValues(alpha: .12)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? colors.primary
                            : colors.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => controller.setCardStyle(item),
                      leading: Icon(_styleIcon(item), color: colors.primary),
                      title: Text(
                        _styleTitle(context, item),
                        style: AppTextStyles.label.copyWith(fontSize: 15),
                      ),
                      subtitle: Text(_styleSubtitle(context, item)),
                      trailing: selected
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: colors.primary,
                            )
                          : const Icon(Icons.circle_outlined),
                    ),
                  );
                }).toList(),
              ),
            ),
            _StudioSection(
              title: context.l10n.tr('modules'),
              child: Column(
                children: config.moduleOrder.map((id) {
                  final visible = config.isVisible(id);
                  return _ModuleControlTile(
                    id: id,
                    visible: visible,
                    color: config.colorFor(id, _moduleColor(id)),
                    onVisibleChanged: (value) =>
                        controller.setModuleVisible(id, value),
                    onColorChanged: (color) =>
                        controller.setModuleColor(id, color),
                    onMoveUp: () => controller.moveModule(id, -1),
                    onMoveDown: () => controller.moveModule(id, 1),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _styleIcon(HomeModuleCardStyle style) {
    return switch (style) {
      HomeModuleCardStyle.glassGrid => Icons.auto_awesome_rounded,
      HomeModuleCardStyle.commandDeck => Icons.view_agenda_rounded,
      HomeModuleCardStyle.blueprint => Icons.architecture_rounded,
    };
  }

  String _styleTitle(BuildContext context, HomeModuleCardStyle style) {
    return switch (style) {
      HomeModuleCardStyle.glassGrid => context.l10n.tr('glass_grid'),
      HomeModuleCardStyle.commandDeck => context.l10n.tr('command_deck'),
      HomeModuleCardStyle.blueprint => context.l10n.tr('blueprint_cards'),
    };
  }

  String _styleSubtitle(BuildContext context, HomeModuleCardStyle style) {
    return switch (style) {
      HomeModuleCardStyle.glassGrid => context.l10n.tr(
        'glass_grid_description',
      ),
      HomeModuleCardStyle.commandDeck => context.l10n.tr(
        'command_deck_description',
      ),
      HomeModuleCardStyle.blueprint => context.l10n.tr(
        'blueprint_cards_description',
      ),
    };
  }
}

class _BlueprintPreview extends StatelessWidget {
  const _BlueprintPreview({required this.config});

  final HomeCustomizationState config;

  @override
  Widget build(BuildContext context) {
    final columns = switch (config.columns) {
      HomeModuleColumns.three => 3,
      HomeModuleColumns.two => 2,
      HomeModuleColumns.auto => 2,
    };
    final visible = config.moduleOrder.where(config.isVisible).toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF071943),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF2F86FF).withValues(alpha: .38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schema_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                context.l10n.tr(
                  'blueprint_summary',
                  args: {'count': visible.length, 'columns': columns},
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.isEmpty ? 1 : visible.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: columns == 3 ? 1.25 : 1.55,
            ),
            itemBuilder: (context, index) {
              if (visible.isEmpty) {
                return _BlueprintPreviewTile(
                  label: context.l10n.tr('hidden'),
                  icon: Icons.visibility_off_rounded,
                  color: Color(0xFF687492),
                  muted: true,
                );
              }
              final id = visible[index];
              return _BlueprintPreviewTile(
                label: _moduleTitle(context, id),
                icon: _moduleIcon(id),
                color: config.colorFor(id, _moduleColor(id)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BlueprintPreviewTile extends StatelessWidget {
  const _BlueprintPreviewTile({
    required this.label,
    required this.icon,
    required this.color,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: muted ? .08 : .22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const Spacer(),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioSection extends StatelessWidget {
  const _StudioSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading.copyWith(fontSize: 17)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _StudioChoiceChip extends StatelessWidget {
  const _StudioChoiceChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(
        icon,
        color: selected ? colors.onPrimary : colors.primary,
        size: 17,
      ),
      label: Text(label),
      selectedColor: colors.primary,
      labelStyle: TextStyle(
        color: selected ? colors.onPrimary : colors.onSurface,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ModuleControlTile extends StatelessWidget {
  const _ModuleControlTile({
    required this.id,
    required this.visible,
    required this.color,
    required this.onVisibleChanged,
    required this.onColorChanged,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final HomeModuleId id;
  final bool visible;
  final Color color;
  final ValueChanged<bool> onVisibleChanged;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: visible
            ? colors.surface
            : colors.surfaceContainerHighest.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: .14),
                  child: Icon(_moduleIcon(id), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _moduleTitle(context, id),
                        style: AppTextStyles.label.copyWith(
                          color: color,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        context.l10n.tr(
                          visible ? 'visible_on_home' : 'hidden_from_home',
                        ),
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.tr('move_up'),
                  onPressed: onMoveUp,
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
                IconButton(
                  tooltip: context.l10n.tr('move_down'),
                  onPressed: onMoveDown,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                Switch(value: visible, onChanged: onVisibleChanged),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _modulePalette.map((candidate) {
                  final selected = candidate.toARGB32() == color.toARGB32();
                  return InkWell(
                    onTap: () => onColorChanged(candidate),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: candidate,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? colors.onSurface
                              : colors.outlineVariant,
                          width: selected ? 2.4 : 1,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- RECENT ITEMS --------------------

class _RecentPanel extends StatelessWidget {
  const _RecentPanel({required this.items});

  final List<_RecentItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withValues(alpha: .18)
                : const Color(0xFF071943).withValues(alpha: .06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(context.l10n.tr('no_recent_items')),
            )
          else
            for (var i = 0; i < items.length; i++)
              _RecentTile(item: items[i], showDivider: i != items.length - 1),
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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.outlineVariant))
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
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.type} - ${item.time}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
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
          PopupMenuButton<String>(
            tooltip: context.l10n.tr('recent_item_actions'),
            onSelected: (value) {
              if (value == 'open') {
                context.pushNamed(item.routeName);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'open',
                child: Text(context.l10n.tr('open_module')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// -------------------- INSIGHTS --------------------

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.storageBytes, required this.securityScore});

  final int storageBytes;
  final int securityScore;

  @override
  Widget build(BuildContext context) {
    final storageGb = storageBytes / (1024 * 1024 * 1024);
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: .04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniInsight(
              title: context.l10n.tr('storage_overview'),
              value: '${storageGb.toStringAsFixed(storageGb >= 1 ? 2 : 3)} GB',
              subtitle: context.l10n.tr('local_vault_used'),
              icon: Icons.donut_large_rounded,
              color: AppColors.purple,
            ),
          ),
          Container(
            width: 1,
            height: 58,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: colors.outlineVariant,
          ),
          Expanded(
            child: _MiniInsight(
              title: context.l10n.tr('security_score'),
              value: '$securityScore%',
              subtitle: context.l10n.tr(
                securityScore >= 90 ? 'excellent' : 'needs_review',
              ),
              icon: Icons.verified_user_rounded,
              color: AppColors.success,
            ),
          ),
        ],
      ),
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
    return Column(
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
    );
  }
}

/// -------------------- SHARED SMALL WIDGETS --------------------

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
          child: Text(
            title,
            style: AppTextStyles.heading.copyWith(fontSize: 18),
          ),
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
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF071943).withValues(alpha: .06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, color: colors.onSurface, size: 23),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.purple, width: 2),
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF14243B), Color(0xFF241943)]
              : const [Color(0xFFE8F5FF), Color(0xFFF3ECFF)],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        color: isDark ? Colors.white : const Color(0xFF111827),
        size: 28,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19,
      height: 19,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.blue,
        shape: BoxShape.circle,
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _QuickItem {
  const _QuickItem(
    this.id,
    this.title,
    this.subtitle,
    this.icon,
    this.image,
    this.color,
    this.routeName,
  );

  final HomeModuleId id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String image;
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
    this.sortDate,
    this.routeName,
  );

  final String title;
  final String type;
  final String time;
  final String badge;
  final IconData icon;
  final Color color;
  final DateTime sortDate;
  final String routeName;
}

String _moduleTitle(BuildContext context, HomeModuleId id) {
  return switch (id) {
    HomeModuleId.connect => 'Vault Connect',
    HomeModuleId.files => context.l10n.tr('file_vault'),
    HomeModuleId.passwords => context.l10n.tr('passwords'),
    HomeModuleId.photos => context.l10n.tr('photos'),
    HomeModuleId.videos => context.l10n.tr('videos'),
    HomeModuleId.scanner => context.l10n.tr('ocr_scanner'),
  };
}

IconData _moduleIcon(HomeModuleId id) {
  return switch (id) {
    HomeModuleId.connect => Icons.forum_rounded,
    HomeModuleId.files => Icons.folder_special_rounded,
    HomeModuleId.passwords => Icons.lock_rounded,
    HomeModuleId.photos => Icons.image_rounded,
    HomeModuleId.videos => Icons.play_circle_rounded,
    HomeModuleId.scanner => Icons.document_scanner_rounded,
  };
}

Color _moduleColor(HomeModuleId id) {
  return switch (id) {
    HomeModuleId.connect => const Color(0xFF5B4BFF),
    HomeModuleId.files => const Color(0xFF7C3DFF),
    HomeModuleId.passwords => const Color(0xFF39C978),
    HomeModuleId.photos => const Color(0xFF29A8FF),
    HomeModuleId.videos => const Color(0xFF6E4BFF),
    HomeModuleId.scanner => const Color(0xFFFF8B22),
  };
}

const _modulePalette = [
  Color(0xFF7C3DFF),
  Color(0xFF2F86FF),
  Color(0xFF29A8FF),
  Color(0xFF39C978),
  Color(0xFFFF8B22),
  Color(0xFFE84A5F),
  Color(0xFF20A9C8),
  Color(0xFF9B7CFF),
];
