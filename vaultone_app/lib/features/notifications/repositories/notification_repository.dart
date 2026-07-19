import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_url.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../data/base_api_service.dart';
import '../../../data/network_api_service.dart';
import '../models/device_token_request.dart';
import '../models/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final repository = NotificationRepository(ref.watch(apiServiceProvider));
  NotificationService.instance.setTokenSyncHandler(repository.registerToken);
  return repository;
});

class NotificationRepository {
  const NotificationRepository(this._api);

  final BaseApiService _api;

  Future<List<AppNotification>> fetchNotifications() async {
    final response = await _api.get(AppUrl.userNotifications);
    final data = response['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<AppNotification> fetchNotification(int notificationId) async {
    final response = await _api.get(
      '${AppUrl.userNotifications}/$notificationId',
    );
    return AppNotification.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  Future<int> fetchUnreadCount() async {
    final response = await _api.get(AppUrl.notificationCount);
    final data = response['data'];
    return data is Map ? (data['unread_count'] as num?)?.toInt() ?? 0 : 0;
  }

  Future<void> markAsRead(int notificationId) async {
    await _api.patch('${AppUrl.userNotifications}/$notificationId/read');
  }

  Future<void> markAllAsRead() async {
    await _api.patch(AppUrl.readAllNotifications);
  }

  Future<void> deleteNotification(int notificationId) async {
    await _api.delete('${AppUrl.userNotifications}/$notificationId');
  }

  Future<void> deleteAllNotifications() async {
    await _api.delete(AppUrl.deleteAllNotifications);
  }

  String get _platform => kIsWeb
      ? 'web'
      : defaultTargetPlatform == TargetPlatform.iOS
      ? 'ios'
      : 'android';

  Future<void> syncStoredToken() async {
    final token = await NotificationService.instance.getStoredToken();
    if (token == null || token.isEmpty) return;
    await registerToken(token);
  }

  Future<void> registerToken(String token) async {
    final request = DeviceTokenRequest(token: token, platform: _platform);
    await _api.post(AppUrl.notificationDeviceToken, data: request.toJson());
  }

  Future<void> unregisterStoredToken() async {
    final token = await NotificationService.instance.getStoredToken();
    if (token == null || token.isEmpty) return;
    final request = DeviceTokenRequest(token: token, platform: _platform);
    await _api.post(
      AppUrl.unregisterNotificationDeviceToken,
      data: request.toJson(),
    );
  }
}
