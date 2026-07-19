import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_language_controller.dart';
import '../models/home_banner.dart';
import '../repositories/banner_repository.dart';

final homeBannersProvider = FutureProvider<List<HomeBanner>>((ref) async {
  final language = ref.watch(appLanguageProvider);
  return ref.watch(bannerRepositoryProvider).fetchBanners(language.code);
});
