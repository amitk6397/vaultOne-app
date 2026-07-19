import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/localization/app_language_controller.dart';
import '../models/onboarding_slide.dart';
import '../repositories/onboarding_repository.dart';

final onboardingIndexProvider = StateProvider<int>((ref) => 0);

final onboardingSlidesProvider = FutureProvider<List<OnboardingSlide>>((
  ref,
) async {
  final language = ref.watch(appLanguageProvider);
  return ref.watch(onboardingRepositoryProvider).fetchSlides(language.code);
});
