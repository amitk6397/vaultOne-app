import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(apiServiceProvider));
});

class AiRepository {
  const AiRepository(this._api);

  final BaseApiService _api;

  Future<String> sendMessage(
    String message, {
    Map<String, dynamic>? appContext,
  }) async {
    final response = await _api.post(
      AppUrl.userAiChat,
      data: {'message': message, 'app_context': ?appContext},
    );
    final data = response is Map<String, dynamic>
        ? response['data'] as Map<String, dynamic>? ?? response
        : <String, dynamic>{};
    return data['reply']?.toString() ?? 'AI response empty mila.';
  }
}
