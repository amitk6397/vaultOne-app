import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/home_banner.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(ref.watch(apiServiceProvider));
});

class BannerRepository {
  const BannerRepository(this._api);

  final BaseApiService _api;

  Future<List<HomeBanner>> fetchBanners(String languageCode) async {
    final response = await _api.get(
      AppUrl.banners,
      queryParameters: {'lang': languageCode},
    );
    final list = response is Map<String, dynamic>
        ? response['data'] as List<dynamic>? ?? const []
        : response as List<dynamic>;
    return list
        .map((item) => HomeBanner.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
