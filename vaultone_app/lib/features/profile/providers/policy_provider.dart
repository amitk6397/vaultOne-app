import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_language_controller.dart';
import '../models/response/policy_page_response.dart';
import '../repositories/policy_repository.dart';

final privacyPolicyProvider = FutureProvider<PolicyPageResponse>((ref) async {
  final language = ref.watch(appLanguageProvider);
  return ref
      .watch(policyRepositoryProvider)
      .fetchPolicy('privacy', languageCode: language.code);
});

final termsPolicyProvider = FutureProvider<PolicyPageResponse>((ref) async {
  final language = ref.watch(appLanguageProvider);
  return ref
      .watch(policyRepositoryProvider)
      .fetchPolicy('terms-and-conditions', languageCode: language.code);
});
