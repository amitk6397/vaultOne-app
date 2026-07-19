import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_url.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/support_models.dart';

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => SupportRepository(ref.watch(apiServiceProvider)),
);

class SupportRepository {
  const SupportRepository(this._api);
  final BaseApiService _api;
  Future<AppContent> fetchContent(String key) async {
    final r = await _api.get('${AppUrl.supportContent}/$key');
    return AppContent.fromJson(Map<String, dynamic>.from(r['data'] as Map));
  }

  Future<List<SupportChatMessage>> fetchMessages() async {
    final r = await _api.get(AppUrl.supportMessages);
    return (r['data'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((x) => SupportChatMessage.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<SupportChatMessage> sendMessage(String message) async {
    final r = await _api.post(
      AppUrl.supportMessages,
      data: {'message': message},
    );
    return SupportChatMessage.fromJson(
      Map<String, dynamic>.from(r['data'] as Map),
    );
  }
}
