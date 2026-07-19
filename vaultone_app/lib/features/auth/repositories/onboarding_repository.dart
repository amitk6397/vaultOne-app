import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/onboarding_slide.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(apiServiceProvider));
});

class OnboardingRepository {
  const OnboardingRepository(this._api);

  final BaseApiService _api;

  Future<List<OnboardingSlide>> fetchSlides(String languageCode) async {
    final response = await _api.get(
      AppUrl.onboarding,
      queryParameters: {'lang': languageCode},
    );
    final list = response is Map<String, dynamic>
        ? response['data'] as List<dynamic>? ?? const []
        : response as List<dynamic>;
    return list
        .map((item) => OnboardingSlide.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
