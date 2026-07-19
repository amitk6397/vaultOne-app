import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/response/policy_page_response.dart';

final policyRepositoryProvider = Provider<PolicyRepository>((ref) {
  return PolicyRepository(ref.watch(apiServiceProvider));
});

class PolicyRepository {
  const PolicyRepository(this._api);

  final BaseApiService _api;

  Future<PolicyPageResponse> fetchPolicy(
    String type, {
    required String languageCode,
  }) async {
    final endpoint = type == 'terms-and-conditions'
        ? AppUrl.termsPolicy
        : AppUrl.privacyPolicy;
    final response = await _api.get(
      endpoint,
      queryParameters: {'lang': languageCode},
    );
    return PolicyPageResponse.fromJson(response as Map<String, dynamic>);
  }
}
